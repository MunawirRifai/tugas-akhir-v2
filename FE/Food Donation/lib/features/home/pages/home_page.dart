import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/food_mapper.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/food_service.dart';
import '../../../data/services/route_service.dart';
import '../../../shared/widgets/badges/halal_badge.dart';
import '../../../shared/widgets/badges/status_pill.dart';
import '../../../shared/widgets/common/app_info_panel.dart';
import '../../../shared/widgets/common/app_surface_card.dart';
import '../../../shared/widgets/common/shimmer_box.dart';
import '../../../shared/widgets/maps/map_marker_shell.dart';
import '../../../shared/widgets/media/app_network_image.dart';
import '../../pickup/widgets/proof_of_pickup_sheet.dart';
import '../widgets/clustered_food_marker_layer.dart';
import '../widgets/filter_bottom_sheet_widget.dart';

class HomePage extends StatefulWidget {
  final String token;

  const HomePage({super.key, required this.token});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();

  Timer? _refreshTimer;
  StreamSubscription<Position>? _positionSubscription;

  bool _isLoading = true;
  bool _isRefreshing = false;
  bool _isActionBusy = false;
  bool _locationAllowed = false;

  int? _currentUserId;
  int _claimQuantity = 1;

  String _searchQuery = '';
  HomeFoodFilter _activeFilter = const HomeFoodFilter.empty();

  LatLng _currentLocation = const LatLng(-6.9730, 107.6300);
  LatLng? _selectedDestination;

  List<dynamic> _foods = [];
  List<LatLng> _routePoints = [];

  Map<String, dynamic>? _selectedFood;

  double? get _activeRadiusMeters {
    final double? radiusKm = _activeFilter.radiusKm;

    if (radiusKm == null) {
      return null;
    }

    return radiusKm * 1000;
  }

  bool get _hasActiveSearchOrFilter {
    return _searchQuery.trim().isNotEmpty || _activeFilter.hasActiveFilters;
  }

  @override
  void initState() {
    super.initState();

    _bootstrap();

    _refreshTimer = Timer.periodic(
      const Duration(seconds: 15),
      (timer) => _loadFoods(),
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _positionSubscription?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    await Future.wait([_prepareLocation(), _loadCurrentUser(), _loadFoods()]);

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _prepareLocation() async {
    try {
      final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();

      if (!mounted) return;

      if (!serviceEnabled) {
        setState(() {
          _locationAllowed = false;
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (!mounted) return;

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        setState(() {
          _locationAllowed = false;
        });
        return;
      }

      final Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
      );

      if (!mounted) return;

      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
        _locationAllowed = true;
      });

      _startLocationStream();
    } catch (error) {
      debugPrint('LOCATION ERROR: $error');

      if (!mounted) return;

      setState(() {
        _locationAllowed = false;
      });
    }
  }

  void _startLocationStream() {
    _positionSubscription?.cancel();

    _positionSubscription =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.best,
            distanceFilter: 8,
          ),
        ).listen(
          (position) {
            if (!mounted) return;

            setState(() {
              _currentLocation = LatLng(position.latitude, position.longitude);
            });
          },
          onError: (Object error) {
            debugPrint('LOCATION STREAM ERROR: $error');
          },
        );
  }

  Future<void> _loadCurrentUser() async {
    try {
      final Map<String, dynamic> profile = await AuthService.getProfile(
        widget.token,
      );

      if (!mounted) return;

      final Map<String, dynamic> data = FoodMapper.mapOf(profile['data']);
      final Map<String, dynamic> user = FoodMapper.mapOf(data['user']);
      final Map<String, dynamic> source = user.isNotEmpty ? user : data;

      setState(() {
        _currentUserId = FoodMapper.nullableIntOf(
          FoodMapper.valueOf(source, ['id', 'user_id', 'userId']),
        );
      });
    } catch (error) {
      debugPrint('LOAD CURRENT USER ERROR: $error');
    }
  }

  Future<void> _loadFoods({bool showRefreshState = false}) async {
    if (showRefreshState && mounted) {
      setState(() {
        _isRefreshing = true;
      });
    }

    try {
      final List<dynamic> result = await FoodService.getFoods(widget.token);

      if (!mounted) return;

      setState(() {
        _foods = result;
      });
    } catch (error) {
      debugPrint('LOAD FOOD ERROR: $error');

      if (mounted && showRefreshState) {
        _showSnack(
          'Gagal memuat data makanan. Periksa koneksi atau backend.',
          isError: true,
        );
      }
    } finally {
      if (mounted && showRefreshState) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  Future<void> _refreshFoods() async {
    await _loadFoods(showRefreshState: true);
  }

  Future<void> _requestLocationAgain() async {
    await _prepareLocation();

    if (!mounted || !_locationAllowed) return;

    _mapController.move(_currentLocation, 15);
  }

  Future<void> _focusCurrentLocation() async {
    if (!_locationAllowed) {
      await _requestLocationAgain();
      return;
    }

    _mapController.move(_currentLocation, 15);
  }

  Future<void> _openFilterSheet() async {
    final HomeFoodFilter? result = await FilterBottomSheetWidget.show(
      context,
      initialFilter: _activeFilter,
    );

    if (result == null || !mounted) return;

    setState(() {
      _activeFilter = result;
    });
  }

  void _onSearchChanged(String value) {
    setState(() {
      _searchQuery = value;
    });
  }

  void _clearSearch() {
    _searchController.clear();

    setState(() {
      _searchQuery = '';
    });
  }

  Future<void> _showRouteForFood(
    Map<String, dynamic> food,
    int quantity,
  ) async {
    final double? latitude = _toDouble(
      FoodMapper.valueOf(food, ['latitude', 'lat']),
    );

    final double? longitude = _toDouble(
      FoodMapper.valueOf(food, ['longitude', 'lng', 'lon']),
    );

    if (latitude == null || longitude == null) {
      _showSnack('Lokasi makanan tidak valid.', isError: true);
      return;
    }

    final LatLng destination = LatLng(latitude, longitude);

    setState(() {
      _selectedFood = food;
      _selectedDestination = destination;
      _claimQuantity = quantity;
      _routePoints = [];
    });

    try {
      final List<LatLng> points = await RouteService.getRoute(
        currentLocation: _currentLocation,
        latitude: latitude,
        longitude: longitude,
      );

      if (!mounted) return;

      setState(() {
        _routePoints = points;
      });

      final LatLng center = LatLng(
        (_currentLocation.latitude + latitude) / 2,
        (_currentLocation.longitude + longitude) / 2,
      );

      _mapController.move(center, points.isEmpty ? 14 : 13);

      if (points.isEmpty) {
        _showSnack(
          'Rute belum tersedia. Marker lokasi tetap ditampilkan.',
          isError: false,
        );
      }
    } catch (error) {
      debugPrint('ROUTE ERROR: $error');

      if (!mounted) return;

      _showSnack(
        'Gagal memuat rute. Marker lokasi tetap ditampilkan.',
        isError: true,
      );
    }
  }

  Future<void> _claimSelectedFood() async {
    final Map<String, dynamic>? food = _selectedFood;

    if (food == null) return;

    final int? foodId = _toInt(
      FoodMapper.valueOf(food, ['id', 'food_id', 'foodId']),
    );

    if (foodId == null) {
      _showSnack('ID makanan tidak valid.', isError: true);
      return;
    }

    setState(() {
      _isActionBusy = true;
    });

    try {
      final Map<String, dynamic> response = await FoodService.pickFood(
        token: widget.token,
        foodId: foodId,
        quantity: _claimQuantity,
      );

      final bool isSuccess = response['success'] != false;

      if (!isSuccess) {
        throw Exception(
          response['message']?.toString() ?? 'Gagal mengambil makanan.',
        );
      }

      await _loadFoods();

      if (!mounted) return;

      setState(() {
        _selectedFood = {
          ...food,
          'status': 'ON_THE_WAY',
          'claimed_by': _currentUserId,
          'claimed_quantity': _claimQuantity,
          'claimed_at': DateTime.now().toIso8601String(),
        };
      });

      _showSnack('Makanan ditandai sedang diambil.', isError: false);
    } catch (error) {
      debugPrint('PICK FOOD ERROR: $error');

      if (!mounted) return;

      _showSnack(
        'Gagal mengambil makanan. Stok mungkin tidak cukup.',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isActionBusy = false;
        });
      }
    }
  }

  Future<void> _openProofOfPickup() async {
    final Map<String, dynamic>? food = _selectedFood;

    if (food == null) return;

    final int? foodId = _toInt(
      FoodMapper.valueOf(food, ['id', 'food_id', 'foodId']),
    );

    if (foodId == null) {
      _showSnack('ID makanan tidak valid.', isError: true);
      return;
    }

    final FoodRecord foodRecord = FoodRecord(food);

    final bool? completed = await ProofOfPickupSheet.show(
      context: context,
      token: widget.token,
      foodId: foodId,
      foodName: foodRecord.name,
    );

    if (completed != true || !mounted) return;

    await _loadFoods();

    if (!mounted) return;

    _clearSelection();

    _showSnack(
      'Pengambilan selesai. Bukti foto berhasil diproses.',
      isError: false,
    );
  }

  Future<void> _cancelPickup() async {
    final Map<String, dynamic>? food = _selectedFood;

    if (food == null) return;

    final int? foodId = _toInt(
      FoodMapper.valueOf(food, ['id', 'food_id', 'foodId']),
    );

    if (foodId == null) {
      _showSnack('ID makanan tidak valid.', isError: true);
      return;
    }

    setState(() {
      _isActionBusy = true;
    });

    try {
      await FoodService.cancelPickup(token: widget.token, foodId: foodId);

      await _loadFoods();

      if (!mounted) return;

      _clearSelection();

      _showSnack('Pengambilan makanan dibatalkan.', isError: false);
    } catch (error) {
      debugPrint('CANCEL PICKUP ERROR: $error');

      if (!mounted) return;

      _showSnack('Gagal membatalkan pengambilan.', isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isActionBusy = false;
        });
      }
    }
  }

  void _clearSelection() {
    setState(() {
      _selectedFood = null;
      _selectedDestination = null;
      _routePoints = [];
      _claimQuantity = 1;
    });
  }

  void _openFoodDetail(Map<String, dynamic> food) {
    final String foodId = _stringValue(
      FoodMapper.valueOf(food, ['id', 'food_id', 'foodId']),
      fallback: 'unknown',
    );

    final String? imageUrl = _resolvePhotoUrl(
      FoodMapper.valueOf(food, [
        'photo_url',
        'photoUrl',
        'photo',
        'image',
        'image_url',
        'imageUrl',
      ]),
    );

    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _FoodDetailSheet(
          food: food,
          imageUrl: imageUrl,
          heroTag: 'food-photo-$foodId',
          distanceLabel: _distanceLabel(food),
          expiredAtLabel: _formatExpiredAt(
            FoodMapper.valueOf(food, [
              'expired_at',
              'expiredAt',
              'expires_at',
              'expiresAt',
            ]),
          ),
          isHalal: _isHalalFood(food),
          isOwnedByCurrentUser: _isOwnedByCurrentUser(food),
          isClaimedByCurrentUser: _isClaimedByCurrentUser(food),
          onChatTap: () => _showMockCommunication('Chat room'),
          onAudioCallTap: () => _showMockCommunication('Audio call'),
          onVideoCallTap: () => _showMockCommunication('Video call'),
          onShowRoute: (quantity) {
            _showRouteForFood(food, quantity);
          },
        );
      },
    );
  }

  void _showMockCommunication(String featureName) {
    _showSnack(
      '$featureName akan dihubungkan pada tahap fitur komunikasi in-app.',
      isError: false,
    );
  }

  void _showSnack(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: isError ? AppColors.danger : AppColors.textPrimary,
        content: Text(message),
      ),
    );
  }

  List<Map<String, dynamic>> get _visibleFoods {
    final List<Map<String, dynamic>> normalizedFoods = _foods
        .map(FoodMapper.mapOf)
        .where((food) => food.isNotEmpty)
        .toList();

    final String query = _searchQuery.trim().toLowerCase();

    if (query.isNotEmpty) {
      normalizedFoods.removeWhere((food) => !_matchesSearchQuery(food, query));
    }

    final double? radiusMeters = _activeRadiusMeters;

    if (radiusMeters != null) {
      normalizedFoods.removeWhere(
        (food) => _distanceInMeters(food) > radiusMeters,
      );
    }

    if (_activeFilter.categories.isNotEmpty) {
      normalizedFoods.removeWhere(
        (food) => !_matchesAnyCategory(food, _activeFilter.categories),
      );
    }

    if (_activeFilter.halalStatus != HalalStatusFilter.all) {
      normalizedFoods.removeWhere(
        (food) => !_matchesHalalStatus(food, _activeFilter.halalStatus),
      );
    }

    if (_activeFilter.conditions.isNotEmpty) {
      normalizedFoods.removeWhere(
        (food) => !_matchesAnyCondition(food, _activeFilter.conditions),
      );
    }

    normalizedFoods.sort(
      (a, b) => _distanceInMeters(a).compareTo(_distanceInMeters(b)),
    );

    return normalizedFoods;
  }

  bool _matchesSearchQuery(Map<String, dynamic> food, String query) {
    final String searchableText = [
      _stringValue(
        FoodMapper.valueOf(food, ['food_name', 'foodName', 'name', 'title']),
        fallback: '',
      ),
      _stringValue(
        FoodMapper.valueOf(food, ['description', 'desc', 'note']),
        fallback: '',
      ),
      _stringValue(
        FoodMapper.valueOf(food, ['address', 'location']),
        fallback: '',
      ),
      _stringValue(
        FoodMapper.valueOf(food, ['category', 'food_category', 'categoryName']),
        fallback: '',
      ),
    ].join(' ').toLowerCase();

    return searchableText.contains(query);
  }

  bool _matchesAnyCategory(
    Map<String, dynamic> food,
    Set<FoodCategoryFilter> categories,
  ) {
    return categories.any((category) => _matchesCategory(food, category));
  }

  bool _matchesCategory(
    Map<String, dynamic> food,
    FoodCategoryFilter category,
  ) {
    final String text = [
      _stringValue(
        FoodMapper.valueOf(food, ['category', 'food_category', 'categoryName']),
        fallback: '',
      ),
      _stringValue(
        FoodMapper.valueOf(food, ['food_name', 'foodName', 'name', 'title']),
        fallback: '',
      ),
      _stringValue(
        FoodMapper.valueOf(food, ['description', 'desc', 'note']),
        fallback: '',
      ),
    ].join(' ').toLowerCase();

    switch (category) {
      case FoodCategoryFilter.heavyMeal:
        return _containsAny(text, [
          'makanan berat',
          'nasi',
          'lauk',
          'meal',
          'rice',
          'ayam',
          'ikan',
          'sayur',
        ]);
      case FoodCategoryFilter.drink:
        return _containsAny(text, [
          'minuman',
          'drink',
          'beverage',
          'teh',
          'kopi',
          'susu',
          'jus',
          'juice',
        ]);
      case FoodCategoryFilter.grocery:
        return _containsAny(text, [
          'sembako',
          'grocery',
          'beras',
          'minyak',
          'mie',
          'gula',
          'tepung',
        ]);
      case FoodCategoryFilter.snack:
        return _containsAny(text, [
          'kue',
          'snack',
          'roti',
          'cake',
          'cemilan',
          'camilan',
          'biskuit',
        ]);
    }
  }

  bool _matchesHalalStatus(
    Map<String, dynamic> food,
    HalalStatusFilter halalStatus,
  ) {
    final bool isHalal = _isHalalFood(food);

    switch (halalStatus) {
      case HalalStatusFilter.all:
        return true;
      case HalalStatusFilter.halal:
        return isHalal;
      case HalalStatusFilter.nonHalal:
        return !isHalal;
    }
  }

  bool _matchesAnyCondition(
    Map<String, dynamic> food,
    Set<FoodConditionFilter> conditions,
  ) {
    return conditions.any((condition) => _matchesCondition(food, condition));
  }

  bool _matchesCondition(
    Map<String, dynamic> food,
    FoodConditionFilter condition,
  ) {
    final String text = [
      _stringValue(
        FoodMapper.valueOf(food, ['condition', 'food_condition', 'quality']),
        fallback: '',
      ),
      _stringValue(
        FoodMapper.valueOf(food, ['description', 'desc', 'note']),
        fallback: '',
      ),
      _stringValue(
        FoodMapper.valueOf(food, ['food_name', 'foodName', 'name', 'title']),
        fallback: '',
      ),
    ].join(' ').toLowerCase();

    switch (condition) {
      case FoodConditionFilter.fresh:
        return _containsAny(text, [
          'tahan lama',
          'segar',
          'fresh',
          'baru',
          'awet',
        ]);
      case FoodConditionFilter.consumeSoon:
        return _containsAny(text, [
          'segera',
          'cepat habis',
          'hari ini',
          'consume soon',
          'mendekati expired',
        ]);
      case FoodConditionFilter.compost:
        return _containsAny(text, [
          'basi',
          'pakan ternak',
          'kompos',
          'compost',
          'animal feed',
          'pakan',
        ]);
    }
  }

  bool _isHalalFood(Map<String, dynamic> food) {
    final Object? rawHalalValue = FoodMapper.valueOf(food, [
      'is_halal',
      'isHalal',
      'halal',
      'halal_status',
      'halalStatus',
    ]);

    if (rawHalalValue is bool) {
      return rawHalalValue;
    }

    final String text = [
      _stringValue(rawHalalValue, fallback: ''),
      _stringValue(
        FoodMapper.valueOf(food, ['food_name', 'foodName', 'name', 'title']),
        fallback: '',
      ),
      _stringValue(
        FoodMapper.valueOf(food, ['description', 'desc', 'note']),
        fallback: '',
      ),
    ].join(' ').toLowerCase();

    final bool hasNonHalal = _containsAny(text, [
      'non-halal',
      'non halal',
      'nonhalal',
      'tidak halal',
      'babi',
      'pork',
      'false',
      '0',
    ]);

    return !hasNonHalal;
  }

  bool _containsAny(String text, List<String> keywords) {
    return keywords.any(text.contains);
  }

  List<Marker> _buildUtilityMarkers() {
    final List<Marker> markers = [
      Marker(
        width: 54,
        height: 54,
        point: _currentLocation,
        child: const MapCurrentLocationMarker(),
      ),
    ];

    if (_selectedDestination != null) {
      markers.add(
        Marker(
          width: 72,
          height: 72,
          point: _selectedDestination!,
          child: const MapDestinationMarker(label: 'Tujuan'),
        ),
      );
    }

    return markers;
  }

  String _statusOf(Map<String, dynamic> food) {
    return _stringValue(
      FoodMapper.valueOf(food, ['status', 'food_status', 'foodStatus']),
      fallback: 'POSTED',
    ).toUpperCase();
  }

  String _statusLabel(Map<String, dynamic> food) {
    return FoodMapper.statusLabel(
      FoodMapper.valueOf(food, ['status', 'food_status', 'foodStatus']),
    );
  }

  bool _isOwnedByCurrentUser(Map<String, dynamic> food) {
    final int? ownerId = _toInt(
      FoodMapper.valueOf(food, ['user_id', 'userId', 'owner_id', 'ownerId']),
    );

    return ownerId != null && ownerId == _currentUserId;
  }

  bool _isClaimedByCurrentUser(Map<String, dynamic> food) {
    final int? claimedBy = _toInt(
      FoodMapper.valueOf(food, [
        'claimed_by',
        'claimedBy',
        'consumer_id',
        'consumerId',
      ]),
    );

    return claimedBy != null && claimedBy == _currentUserId;
  }

  double _distanceInMeters(Map<String, dynamic> food) {
    final double? latitude = _toDouble(
      FoodMapper.valueOf(food, ['latitude', 'lat']),
    );

    final double? longitude = _toDouble(
      FoodMapper.valueOf(food, ['longitude', 'lng', 'lon']),
    );

    if (latitude == null || longitude == null) {
      return double.infinity;
    }

    return Geolocator.distanceBetween(
      _currentLocation.latitude,
      _currentLocation.longitude,
      latitude,
      longitude,
    );
  }

  String _distanceLabel(Map<String, dynamic> food) {
    final double distance = _distanceInMeters(food);

    return FoodMapper.distanceLabelFromMeters(distance);
  }

  String _formatExpiredAt(Object? rawValue) {
    return FoodMapper.dateTimeLabel(rawValue, fallback: '-');
  }

  String? _resolvePhotoUrl(Object? rawValue) {
    return FoodMapper.nullablePhotoUrl(rawValue);
  }

  int? _toInt(Object? value) {
    return FoodMapper.nullableIntOf(value);
  }

  double? _toDouble(Object? value) {
    return FoodMapper.nullableDoubleOf(value);
  }

  String _stringValue(Object? value, {required String fallback}) {
    return FoodMapper.textOf(value, fallback: fallback);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const _HomeSkeletonPage();
    }

    final List<Map<String, dynamic>> visibleFoods = _visibleFoods;
    final double? activeRadiusMeters = _activeRadiusMeters;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          Positioned.fill(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _currentLocation,
                initialZoom: _locationAllowed ? 14 : 12,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.food_donation_app',
                ),
                if (_locationAllowed && activeRadiusMeters != null)
                  CircleLayer(
                    circles: [
                      CircleMarker(
                        point: _currentLocation,
                        radius: activeRadiusMeters,
                        useRadiusInMeter: true,
                        color: AppColors.primary.withValues(alpha: 0.08),
                        borderColor: AppColors.primary.withValues(alpha: 0.24),
                        borderStrokeWidth: 2,
                      ),
                    ],
                  ),
                if (_routePoints.isNotEmpty)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: _routePoints,
                        strokeWidth: 5,
                        color: AppColors.teal,
                      ),
                    ],
                  ),
                ClusteredFoodMarkerLayer(
                  foods: visibleFoods,
                  selectedFoodId: _selectedFood == null
                      ? null
                      : _toInt(
                          FoodMapper.valueOf(_selectedFood!, [
                            'id',
                            'food_id',
                            'foodId',
                          ]),
                        ),
                  currentUserId: _currentUserId,
                  onFoodTap: _openFoodDetail,
                ),
                MarkerLayer(markers: _buildUtilityMarkers()),
              ],
            ),
          ),
          Positioned(
            left: AppSpacing.x2,
            right: AppSpacing.x2,
            top: 0,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.only(top: AppSpacing.x2),
                child: _HomeHeader(
                  searchController: _searchController,
                  searchQuery: _searchQuery,
                  locationAllowed: _locationAllowed,
                  visibleFoodCount: visibleFoods.length,
                  totalFoodCount: _foods.length,
                  isRefreshing: _isRefreshing,
                  activeFilterCount: _activeFilter.activeCount,
                  hasActiveSearchOrFilter: _hasActiveSearchOrFilter,
                  onSearchChanged: _onSearchChanged,
                  onClearSearch: _clearSearch,
                  onOpenFilter: _openFilterSheet,
                  onRefresh: _refreshFoods,
                  onFocusLocation: _focusCurrentLocation,
                ),
              ),
            ),
          ),
          if (_selectedFood == null)
            Positioned(
              left: AppSpacing.x2,
              right: AppSpacing.x2,
              bottom: 76,
              child: _FoodCarousel(
                foods: visibleFoods,
                selectedFoodId: null,
                onTap: _openFoodDetail,
                imageUrlOf: (food) {
                  return _resolvePhotoUrl(
                    FoodMapper.valueOf(food, [
                      'photo_url',
                      'photoUrl',
                      'photo',
                      'image',
                      'image_url',
                      'imageUrl',
                    ]),
                  );
                },
                distanceLabelOf: _distanceLabel,
                statusOf: _statusOf,
                isHalalOf: _isHalalFood,
              ),
            ),
          if (_selectedFood != null)
            Positioned(
              left: AppSpacing.x2,
              right: AppSpacing.x2,
              bottom: 76,
              child: _PickupActionBar(
                food: _selectedFood!,
                quantity: _claimQuantity,
                isBusy: _isActionBusy,
                isOwnedByCurrentUser: _isOwnedByCurrentUser(_selectedFood!),
                isClaimedByCurrentUser: _isClaimedByCurrentUser(_selectedFood!),
                statusLabel: _statusLabel(_selectedFood!),
                onClose: _clearSelection,
                onPickNow: _claimSelectedFood,
                onCompletePickup: _openProofOfPickup,
                onCancel: _cancelPickup,
              ),
            ),
          if (!_locationAllowed)
            _LocationPermissionOverlay(onAllow: _requestLocationAgain),
        ],
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  final TextEditingController searchController;
  final String searchQuery;
  final bool locationAllowed;
  final int visibleFoodCount;
  final int totalFoodCount;
  final bool isRefreshing;
  final int activeFilterCount;
  final bool hasActiveSearchOrFilter;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClearSearch;
  final VoidCallback onOpenFilter;
  final VoidCallback onRefresh;
  final VoidCallback onFocusLocation;

  const _HomeHeader({
    required this.searchController,
    required this.searchQuery,
    required this.locationAllowed,
    required this.visibleFoodCount,
    required this.totalFoodCount,
    required this.isRefreshing,
    required this.activeFilterCount,
    required this.hasActiveSearchOrFilter,
    required this.onSearchChanged,
    required this.onClearSearch,
    required this.onOpenFilter,
    required this.onRefresh,
    required this.onFocusLocation,
  });

  @override
  Widget build(BuildContext context) {
    return _PremiumMapPanel(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
                child: const Icon(
                  Icons.volunteer_activism_rounded,
                  color: AppColors.primaryDark,
                  size: 22,
                ),
              ),
              const SizedBox(width: AppSpacing.x1),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Donasi Terdekat',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              _PremiumIconButton(
                tooltip: 'Refresh data',
                onTap: isRefreshing ? null : onRefresh,
                child: isRefreshing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh_rounded, size: 21),
              ),
              const SizedBox(width: 6),
              _PremiumIconButton(
                tooltip: 'Lokasi saya',
                onTap: onFocusLocation,
                child: const Icon(Icons.my_location_rounded, size: 21),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.x1),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: TextField(
                    controller: searchController,
                    textInputAction: TextInputAction.search,
                    onChanged: onSearchChanged,
                    style: Theme.of(context).textTheme.bodyMedium,
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.x1,
                        vertical: 0,
                      ),
                      hintText: 'Cari makanan...',
                      prefixIcon: const Icon(Icons.search_rounded, size: 20),
                      suffixIcon: searchQuery.trim().isEmpty
                          ? null
                          : IconButton(
                              tooltip: 'Hapus pencarian',
                              onPressed: onClearSearch,
                              icon: const Icon(Icons.close_rounded, size: 18),
                            ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.x1),
              _FilterButton(
                activeFilterCount: activeFilterCount,
                onTap: onOpenFilter,
              ),
            ],
          ),
        ],
      ),
    );
  }

  String get _subtitle {
    if (!locationAllowed) {
      return 'Izinkan lokasi untuk hasil akurat';
    }

    if (!hasActiveSearchOrFilter) {
      return '$totalFoodCount postingan makanan tersedia';
    }

    return '$visibleFoodCount hasil sesuai filter';
  }
}

class _PremiumMapPanel extends StatelessWidget {
  final Widget child;

  const _PremiumMapPanel({required this.child});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: Colors.white.withValues(alpha: 0.74)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 30,
            offset: const Offset(0, 16),
          ),
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.x1),
        child: child,
      ),
    );
  }
}

class _PremiumIconButton extends StatelessWidget {
  final String tooltip;
  final VoidCallback? onTap;
  final Widget child;

  const _PremiumIconButton({
    required this.tooltip,
    required this.onTap,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: SizedBox(
            width: 42,
            height: 42,
            child: Center(
              child: IconTheme(
                data: const IconThemeData(color: AppColors.textPrimary),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FilterButton extends StatelessWidget {
  final int activeFilterCount;
  final VoidCallback onTap;

  const _FilterButton({required this.activeFilterCount, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final bool isActive = activeFilterCount > 0;

    return Material(
      color: isActive ? AppColors.primary : AppColors.surfaceSoft,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: isActive
                  ? AppColors.primary
                  : AppColors.border.withValues(alpha: 0.82),
            ),
            boxShadow: isActive ? AppShadows.brand : const [],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(
                Icons.tune_rounded,
                color: isActive ? Colors.white : AppColors.primaryDark,
                size: 22,
              ),
              if (isActive)
                Positioned(
                  top: 7,
                  right: 7,
                  child: Container(
                    constraints: const BoxConstraints(
                      minWidth: 17,
                      minHeight: 17,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: const BoxDecoration(
                      color: AppColors.accent,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '$activeFilterCount',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          height: 1,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FoodCarousel extends StatelessWidget {
  final List<Map<String, dynamic>> foods;
  final int? selectedFoodId;
  final ValueChanged<Map<String, dynamic>> onTap;
  final String? Function(Map<String, dynamic> food) imageUrlOf;
  final String Function(Map<String, dynamic> food) distanceLabelOf;
  final String Function(Map<String, dynamic> food) statusOf;
  final bool Function(Map<String, dynamic> food) isHalalOf;

  const _FoodCarousel({
    required this.foods,
    required this.selectedFoodId,
    required this.onTap,
    required this.imageUrlOf,
    required this.distanceLabelOf,
    required this.statusOf,
    required this.isHalalOf,
  });

  @override
  Widget build(BuildContext context) {
    if (foods.isEmpty) {
      return AppSurfaceCard(
        padding: const EdgeInsets.all(AppSpacing.x2),
        borderRadius: AppRadius.lg,
        backgroundColor: AppColors.surface.withValues(alpha: 0.96),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: AppColors.surfaceSoft,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: const Icon(
                Icons.search_off_rounded,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: AppSpacing.x2),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tidak Ada Hasil',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Ubah pencarian atau filter makanan.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return SizedBox(
      height: 124,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: foods.length,
        separatorBuilder: (context, index) {
          return const SizedBox(width: AppSpacing.x1);
        },
        itemBuilder: (context, index) {
          final Map<String, dynamic> food = foods[index];
          final String foodId =
              (FoodMapper.valueOf(food, ['id', 'food_id', 'foodId']) ?? index)
                  .toString();

          return _FoodPreviewCard(
            food: food,
            imageUrl: imageUrlOf(food),
            heroTag: 'food-photo-$foodId',
            distanceLabel: distanceLabelOf(food),
            status: statusOf(food),
            isHalal: isHalalOf(food),
            isSelected: selectedFoodId?.toString() == foodId,
            onTap: () => onTap(food),
          );
        },
      ),
    );
  }
}

class _FoodPreviewCard extends StatelessWidget {
  final Map<String, dynamic> food;
  final String? imageUrl;
  final String heroTag;
  final String distanceLabel;
  final String status;
  final bool isHalal;
  final bool isSelected;
  final VoidCallback onTap;

  const _FoodPreviewCard({
    required this.food,
    required this.imageUrl,
    required this.heroTag,
    required this.distanceLabel,
    required this.status,
    required this.isHalal,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final FoodRecord foodRecord = FoodRecord(food);

    return AppSurfaceCard(
      width: 290,
      padding: const EdgeInsets.all(8),
      borderRadius: AppRadius.lg,
      backgroundColor: AppColors.surface.withValues(alpha: 0.98),
      borderColor: isSelected ? AppColors.primary : AppColors.border,
      onTap: onTap,
      child: Row(
        children: [
          AppNetworkImage.food(
            imageUrl: imageUrl,
            width: 88,
            height: double.infinity,
            borderRadius: AppRadius.md,
            heroTag: heroTag,
          ),
          const SizedBox(width: AppSpacing.x1),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  foodRecord.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 5,
                  runSpacing: 5,
                  children: [
                    HalalBadge(isHalal: isHalal, showBorder: false),
                    StatusPill.fromFoodStatus(status),
                  ],
                ),
                const SizedBox(height: 7),
                Row(
                  children: [
                    _CompactPill(
                      icon: Icons.location_on_outlined,
                      label: distanceLabel,
                      color: AppColors.primaryDark,
                    ),
                    const SizedBox(width: 5),
                    _CompactPill(
                      icon: Icons.inventory_2_outlined,
                      label: '${foodRecord.quantity}',
                      color: AppColors.teal,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FoodDetailSheet extends StatefulWidget {
  final Map<String, dynamic> food;
  final String? imageUrl;
  final String heroTag;
  final String distanceLabel;
  final String expiredAtLabel;
  final bool isHalal;
  final bool isOwnedByCurrentUser;
  final bool isClaimedByCurrentUser;
  final VoidCallback onChatTap;
  final VoidCallback onAudioCallTap;
  final VoidCallback onVideoCallTap;
  final ValueChanged<int> onShowRoute;

  const _FoodDetailSheet({
    required this.food,
    required this.imageUrl,
    required this.heroTag,
    required this.distanceLabel,
    required this.expiredAtLabel,
    required this.isHalal,
    required this.isOwnedByCurrentUser,
    required this.isClaimedByCurrentUser,
    required this.onChatTap,
    required this.onAudioCallTap,
    required this.onVideoCallTap,
    required this.onShowRoute,
  });

  @override
  State<_FoodDetailSheet> createState() => _FoodDetailSheetState();
}

class _FoodDetailSheetState extends State<_FoodDetailSheet> {
  late int _quantity;

  int get _maxQuantity {
    final FoodRecord foodRecord = FoodRecord(widget.food);
    return foodRecord.quantity < 1 ? 1 : foodRecord.quantity;
  }

  String get _status {
    return FoodRecord(widget.food).status;
  }

  bool get _canClaim {
    return (_status == 'POSTED' || _status == 'AVAILABLE') &&
        !widget.isOwnedByCurrentUser;
  }

  @override
  void initState() {
    super.initState();
    _quantity = 1;
  }

  void _decreaseQuantity() {
    if (_quantity <= 1) return;

    setState(() {
      _quantity--;
    });
  }

  void _increaseQuantity() {
    if (_quantity >= _maxQuantity) return;

    setState(() {
      _quantity++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final FoodRecord foodRecord = FoodRecord(widget.food);

    return SafeArea(
      top: false,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.88,
        ),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.xl),
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.x3,
            AppSpacing.x2,
            AppSpacing.x3,
            AppSpacing.x3,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 48,
                  height: 5,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.x2),
              AppNetworkImage.food(
                imageUrl: widget.imageUrl,
                width: double.infinity,
                height: 220,
                borderRadius: AppRadius.xl,
                heroTag: widget.heroTag,
              ),
              const SizedBox(height: AppSpacing.x3),
              Text(
                foodRecord.name,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: AppSpacing.x1),
              Wrap(
                spacing: AppSpacing.x1,
                runSpacing: AppSpacing.x1,
                children: [
                  HalalBadge(isHalal: widget.isHalal, isLarge: true),
                  StatusPill.fromFoodStatus(foodRecord.status, isLarge: true),
                  if (widget.isOwnedByCurrentUser)
                    const StatusPill(
                      label: 'Postingan Anda',
                      color: AppColors.teal,
                      icon: Icons.storefront_rounded,
                      isLarge: true,
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.x2),
              Text(
                foodRecord.description,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.x3),
              Wrap(
                spacing: AppSpacing.x1,
                runSpacing: AppSpacing.x1,
                children: [
                  _InfoChip(
                    icon: Icons.location_on_outlined,
                    label: widget.distanceLabel,
                  ),
                  _InfoChip(
                    icon: Icons.inventory_2_outlined,
                    label: '$_maxQuantity porsi',
                  ),
                  _InfoChip(
                    icon: Icons.schedule_rounded,
                    label: widget.expiredAtLabel,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.x3),
              AppInfoPanel.surface(
                icon: Icons.place_outlined,
                title: 'Lokasi Pengambilan',
                description: foodRecord.address,
              ),
              // const SizedBox(height: AppSpacing.x2),
              // _CommunicationActions(
              //   onChatTap: widget.onChatTap,
              //   onAudioCallTap: widget.onAudioCallTap,
              //   onVideoCallTap: widget.onVideoCallTap,
              // ),
              const SizedBox(height: AppSpacing.x3),
              if (widget.isOwnedByCurrentUser)
                const AppInfoPanel.info(
                  icon: Icons.manage_search_rounded,
                  title: 'Postingan milik Anda',
                  description:
                      'Manajemen edit dan hapus postingan tersedia melalui halaman Riwayat.',
                )
              else if (!_canClaim)
                AppInfoPanel.info(
                  title: 'Status makanan',
                  description: widget.isClaimedByCurrentUser
                      ? 'Anda sedang mengambil makanan ini. Tekan tombol Selesaikan Pesanan pada panel peta untuk mengunggah bukti foto.'
                      : 'Makanan ini sedang diproses oleh pengguna lain.',
                )
              else ...[
                Text(
                  'Jumlah yang ingin diklaim',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.x1),
                _QuantityStepper(
                  quantity: _quantity,
                  maxQuantity: _maxQuantity,
                  onDecrease: _decreaseQuantity,
                  onIncrease: _increaseQuantity,
                ),
                const SizedBox(height: AppSpacing.x3),
                SizedBox(
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      widget.onShowRoute(_quantity);
                    },
                    icon: const Icon(Icons.alt_route_rounded),
                    label: Text('Lihat Rute ($_quantity porsi)'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _PickupActionBar extends StatefulWidget {
  final Map<String, dynamic> food;
  final int quantity;
  final bool isBusy;
  final bool isOwnedByCurrentUser;
  final bool isClaimedByCurrentUser;
  final String statusLabel;
  final VoidCallback onClose;
  final VoidCallback onPickNow;
  final VoidCallback onCompletePickup;
  final VoidCallback onCancel;

  const _PickupActionBar({
    required this.food,
    required this.quantity,
    required this.isBusy,
    required this.isOwnedByCurrentUser,
    required this.isClaimedByCurrentUser,
    required this.statusLabel,
    required this.onClose,
    required this.onPickNow,
    required this.onCompletePickup,
    required this.onCancel,
  });

  @override
  State<_PickupActionBar> createState() => _PickupActionBarState();
}

class _PickupActionBarState extends State<_PickupActionBar> {
  Timer? _timer;
  Duration _remaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void didUpdateWidget(covariant _PickupActionBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.food['id'] != widget.food['id'] ||
        oldWidget.food['claimed_at'] != widget.food['claimed_at']) {
      _startTimer();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    final DateTime? claimedAt = FoodMapper.dateTimeOf(widget.food['claimed_at']);
    if (claimedAt == null) {
      _remaining = Duration.zero;
      return;
    }

    final DateTime targetTime = claimedAt.add(const Duration(minutes: 30));

    void updateRemaining() {
      final DateTime now = DateTime.now();
      final Duration diff = targetTime.difference(now);
      if (diff.isNegative) {
        _remaining = Duration.zero;
        _timer?.cancel();
      } else {
        _remaining = diff;
      }
      if (mounted) {
        setState(() {});
      }
    }

    updateRemaining();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      updateRemaining();
    });
  }

  String _formatDuration(Duration duration) {
    final int minutes = duration.inMinutes;
    final int seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String get _status {
    return FoodRecord(widget.food).status;
  }

  @override
  Widget build(BuildContext context) {
    final FoodRecord foodRecord = FoodRecord(widget.food);
    final bool canPick =
        (_status == 'POSTED' || _status == 'AVAILABLE') &&
        !widget.isOwnedByCurrentUser;

    final bool canManagePickup = true;

    print('STATUS BAR = $_status');
    print('CLAIMED USER = ${widget.isClaimedByCurrentUser}');
    print(widget.food);
    return AppSurfaceCard(
      padding: const EdgeInsets.all(AppSpacing.x2),
      borderRadius: AppRadius.xl,
      backgroundColor: AppColors.surface.withValues(alpha: 0.98),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: widget.isBusy ? null : widget.onClose,
                icon: const Icon(Icons.close_rounded),
              ),
              const SizedBox(width: AppSpacing.x1),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      foodRecord.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          '${widget.statusLabel} • ${widget.quantity} porsi',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        if (widget.isClaimedByCurrentUser && _remaining > Duration.zero) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.danger.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.timer_outlined,
                                  size: 14,
                                  color: AppColors.danger,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _formatDuration(_remaining),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.danger,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ] else if (widget.isClaimedByCurrentUser && FoodMapper.dateTimeOf(widget.food['claimed_at']) != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.danger.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'Waktu Habis',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppColors.danger,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.x2),
          if (canPick)
            SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                onPressed: widget.isBusy ? null : widget.onPickNow,
                icon: widget.isBusy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.shopping_bag_outlined),
                label: const Text('Ambil Sekarang'),
              ),
            )
          else if (canManagePickup)
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: widget.isBusy ? null : widget.onCompletePickup,
                      icon: const Icon(Icons.check),
                      label: const Text('Selesai'),
                    ),
                  ),
                ),

                const SizedBox(width: 8),

                Expanded(
                  child: SizedBox(
                    height: 52,
                    child: OutlinedButton.icon(
                      onPressed: widget.isBusy ? null : widget.onCancel,
                      icon: const Icon(Icons.close),
                      label: const Text('Batal'),
                    ),
                  ),
                ),
              ],
            )
          else
            const AppInfoPanel.info(
              icon: Icons.info_outline_rounded,
              title: 'Aksi tidak tersedia',
              description:
                  'Postingan milik sendiri atau makanan sedang diproses pengguna lain.',
            ),
        ],
      ),
    );
  }
}

class _LocationPermissionOverlay extends StatelessWidget {
  final VoidCallback onAllow;

  const _LocationPermissionOverlay({required this.onAllow});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: ColoredBox(
        color: Colors.black.withValues(alpha: 0.34),
        child: SafeArea(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.x2),
              child: AppSurfaceCard(
                padding: const EdgeInsets.all(AppSpacing.x3),
                borderRadius: AppRadius.xl,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: AppColors.primarySoft,
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                      ),
                      child: const Icon(
                        Icons.my_location_rounded,
                        color: AppColors.primaryDark,
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.x2),
                    Text(
                      'Aktifkan Lokasi',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: AppSpacing.x1),
                    Text(
                      'Lokasi digunakan untuk menghitung radius makanan terdekat dan menampilkan rute pengambilan.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: AppSpacing.x3),
                    SizedBox(
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: onAllow,
                        icon: const Icon(Icons.location_searching_rounded),
                        label: const Text('Izinkan Lokasi'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _QuantityStepper extends StatelessWidget {
  final int quantity;
  final int maxQuantity;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;

  const _QuantityStepper({
    required this.quantity,
    required this.maxQuantity,
    required this.onDecrease,
    required this.onIncrease,
  });

  @override
  Widget build(BuildContext context) {
    return AppSurfaceCard.soft(
      padding: const EdgeInsets.all(AppSpacing.x2),
      borderRadius: AppRadius.lg,
      child: Row(
        children: [
          IconButton(
            onPressed: quantity > 1 ? onDecrease : null,
            icon: const Icon(Icons.remove_circle_outline_rounded),
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  '$quantity',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                Text(
                  'dari $maxQuantity porsi',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: quantity < maxQuantity ? onIncrease : null,
            icon: const Icon(Icons.add_circle_outline_rounded),
          ),
        ],
      ),
    );
  }
}

// class _CommunicationActions extends StatelessWidget {
//   final VoidCallback onChatTap;
//   final VoidCallback onAudioCallTap;
//   final VoidCallback onVideoCallTap;

//   const _CommunicationActions({
//     required this.onChatTap,
//     required this.onAudioCallTap,
//     required this.onVideoCallTap,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Row(
//       children: [
//         Expanded(
//           child: OutlinedButton.icon(
//             onPressed: onChatTap,
//             icon: const Icon(Icons.chat_bubble_outline_rounded),
//             label: const Text('Chat'),
//           ),
//         ),
//         const SizedBox(width: AppSpacing.x1),
//         Expanded(
//           child: OutlinedButton.icon(
//             onPressed: onAudioCallTap,
//             icon: const Icon(Icons.call_outlined),
//             label: const Text('Audio'),
//           ),
//         ),
//         const SizedBox(width: AppSpacing.x1),
//         Expanded(
//           child: OutlinedButton.icon(
//             onPressed: onVideoCallTap,
//             icon: const Icon(Icons.videocam_outlined),
//             label: const Text('Video'),
//           ),
//         ),
//       ],
//     );
//   }
// }

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.x2,
        vertical: AppSpacing.x1,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.primaryDark, size: 16),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _CompactPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _CompactPill({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 12),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeSkeletonPage extends StatelessWidget {
  const _HomeSkeletonPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.x2),
          child: Column(
            children: [
              const ShimmerBox(height: 112, borderRadius: AppRadius.xl),
              const SizedBox(height: AppSpacing.x2),
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceSoft,
                    borderRadius: BorderRadius.circular(AppRadius.xl),
                  ),
                  child: const Center(
                    child: ShimmerBox(
                      width: 160,
                      height: 160,
                      borderRadius: AppRadius.xl,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.x2),
              const ShimmerBox(height: 112, borderRadius: AppRadius.xl),
            ],
          ),
        ),
      ),
    );
  }
}
