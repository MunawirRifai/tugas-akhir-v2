import 'package:flutter/foundation.dart';

import '../../../data/services/directions_service.dart';
import '../../../domain/models/smart_cart_item.dart';

class SmartCartController extends ChangeNotifier {
  final DirectionsService directionsService;

  SmartCartController({
    required this.directionsService,
  });

  static const int maxTotalOrders = 3;
  static const int maxYellowOrders = 1;

  final List<SmartCartItem> _items = [];

  SmartGeoPoint? _userLocation;
  PickupTransportMode _transportMode = PickupTransportMode.driving;
  DirectionsRouteData _routeData = const DirectionsRouteData.empty();

  bool _isRouteLoading = false;
  String? _routeError;

  List<SmartCartItem> get items {
    return List<SmartCartItem>.unmodifiable(_items);
  }

  SmartGeoPoint? get userLocation {
    return _userLocation;
  }

  PickupTransportMode get transportMode {
    return _transportMode;
  }

  DirectionsRouteData get routeData {
    return _routeData;
  }

  bool get isRouteLoading {
    return _isRouteLoading;
  }

  String? get routeError {
    return _routeError;
  }

  bool get isEmpty {
    return _items.isEmpty;
  }

  bool get isFull {
    return _items.length >= maxTotalOrders;
  }

  int get totalCount {
    return _items.length;
  }

  int get yellowCount {
    return _items
        .where(
          (item) => item.condition == FoodReadinessCondition.consumeSoon,
        )
        .length;
  }

  SmartCartItem? get activeTarget {
    if (_items.isEmpty) return null;
    return _items.first;
  }

  bool get hasActiveRoute {
    return _routeData.hasRoute;
  }

  void setUserLocation(SmartGeoPoint location) {
    _userLocation = location;
    sortQueue();
    notifyListeners();
  }

  Future<void> loadInitialItems({
    required List<SmartCartItem> items,
    required SmartGeoPoint userLocation,
  }) async {
    _items.clear();
    _userLocation = userLocation;

    for (final SmartCartItem item in items) {
      final SmartCartMutationResult validation = canClaimItem(item);

      if (!validation.isSuccess) {
        continue;
      }

      _items.add(item);

      if (_items.length >= maxTotalOrders) {
        break;
      }
    }

    sortQueue();

    notifyListeners();

    await refreshRouteForTop();
  }

  SmartCartMutationResult canClaimItem(SmartCartItem item) {
    if (_items.any((cartItem) => cartItem.id == item.id)) {
      return const SmartCartMutationResult.failure(
        'Makanan ini sudah ada di Smart Cart.',
      );
    }

    if (_items.length >= maxTotalOrders) {
      return const SmartCartMutationResult.failure(
        'Smart Cart penuh. Maksimal 3 pesanan sekaligus.',
      );
    }

    if (item.condition == FoodReadinessCondition.consumeSoon &&
        yellowCount >= maxYellowOrders) {
      return const SmartCartMutationResult.failure(
        'Makanan kuning/segara basi hanya boleh 1 pesanan dalam Smart Cart.',
      );
    }

    return const SmartCartMutationResult.success(
      'Makanan dapat ditambahkan ke Smart Cart.',
    );
  }

  Future<SmartCartMutationResult> addItem(SmartCartItem item) async {
    final SmartCartMutationResult validation = canClaimItem(item);

    if (!validation.isSuccess) {
      return validation;
    }

    _items.add(item);

    sortQueue();

    notifyListeners();

    await refreshRouteForTop();

    return SmartCartMutationResult.success(
      '${item.foodName} masuk ke Smart Cart.',
    );
  }

  Future<SmartCartMutationResult> addFoodMap(
    Map<String, dynamic> food,
  ) async {
    final SmartCartItem item = SmartCartItem.fromFoodMap(food);
    return addItem(item);
  }

  Future<void> removeItem(String itemId) async {
    _items.removeWhere((item) => item.id == itemId);

    sortQueue();

    notifyListeners();

    await refreshRouteForTop();
  }

  Future<void> completeTopAndAdvance() async {
    if (_items.isEmpty) return;

    _items.removeAt(0);

    sortQueue();

    notifyListeners();

    await refreshRouteForTop();
  }

  Future<void> completeByIdAndAdvance(String itemId) async {
    _items.removeWhere((item) => item.id == itemId);

    sortQueue();

    notifyListeners();

    await refreshRouteForTop();
  }

  Future<void> clearCart() async {
    _items.clear();
    _routeData = DirectionsRouteData.empty(
      mode: _transportMode,
    );
    _routeError = null;
    _isRouteLoading = false;

    notifyListeners();
  }

  void sortQueue() {
    final SmartGeoPoint? location = _userLocation;

    if (location == null) {
      return;
    }

    /*
      Weighted Scoring Algorithm:
      - Kuning / Segera Basi = 100 poin
      - Hijau / Tahan Lama = 60 poin
      - Merah / Kompos/Pakan = 30 poin
      - Pengurang jarak = jarakKm * 10
      - Total skor = baseScore - (jarakKm * 10)

      Catatan arsitektur:
      Sorting final nanti boleh dieksekusi ulang di Back-End.
      Logic ini tetap dipertahankan di FE sebagai fallback UX agar urutan cart
      tetap responsif sebelum response BE diterima.
    */
    _items.sort((a, b) {
      final double scoreA = a.priorityScoreFrom(location);
      final double scoreB = b.priorityScoreFrom(location);

      return scoreB.compareTo(scoreA);
    });
  }

  double scoreOf(SmartCartItem item) {
    final SmartGeoPoint? location = _userLocation;

    if (location == null) {
      return item.condition.baseScore.toDouble();
    }

    return item.priorityScoreFrom(location);
  }

  double distanceKmOf(SmartCartItem item) {
    final SmartGeoPoint? location = _userLocation;

    if (location == null) {
      return 0;
    }

    return item.distanceKmFrom(location);
  }

  Future<void> setTransportMode(PickupTransportMode mode) async {
    if (_transportMode == mode) return;

    _transportMode = mode;

    notifyListeners();

    await refreshRouteForTop();
  }

  Future<void> refreshRouteForTop() async {
    final SmartGeoPoint? location = _userLocation;
    final SmartCartItem? target = activeTarget;

    if (location == null || target == null) {
      _routeData = DirectionsRouteData.empty(
        mode: _transportMode,
      );
      _routeError = null;
      _isRouteLoading = false;

      notifyListeners();
      return;
    }

    _isRouteLoading = true;
    _routeError = null;

    notifyListeners();

    try {
      /*
        Saat ini DirectionsService mengembalikan mock response seperti dari BE.

        Nanti ketika endpoint BE siap, DirectionsService cukup diarahkan ke:
        POST /directions

        SmartPickupMapPage tetap dapat memakai data yang sama:
        - priorityDonor
        - polyline points
        - distanceText
        - durationText
        - networkLatencyMs
        - responseBytes
      */
      final DirectionsRouteData data =
          await directionsService.getRouteToTopPriorityDonor(
        origin: location,
        destination: target.donorLocation,
        mode: _transportMode,
        alternatives: true,
        optimizeWaypoints: true,
      );

      _routeData = data;
      _routeError = null;
    } catch (error) {
      _routeError = error.toString();
      _routeData = DirectionsRouteData.empty(
        mode: _transportMode,
      );
    }

    _isRouteLoading = false;

    notifyListeners();
  }
}