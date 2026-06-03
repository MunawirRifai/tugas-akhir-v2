import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:provider/provider.dart';

import '../../../core/config/google_maps_config.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/services/directions_service.dart';
import '../../../domain/models/smart_cart_item.dart';
import '../controllers/smart_cart_controller.dart';
import '../widgets/proof_of_pickup_sheet.dart';

class SmartPickupMapPage extends StatefulWidget {
  final String token;
  final List<SmartCartItem> initialItems;
  final String googleMapsApiKey;

  const SmartPickupMapPage({
    super.key,
    required this.token,
    required this.initialItems,
    this.googleMapsApiKey = '',
  });

  @override
  State<SmartPickupMapPage> createState() => _SmartPickupMapPageState();
}

class _SmartPickupMapPageState extends State<SmartPickupMapPage> {
  late final SmartCartController _cartController;

  gmaps.GoogleMapController? _mapController;

  bool _isPreparingLocation = true;
  String? _locationError;

  String get _resolvedGoogleMapsApiKey {
    final String widgetKey = widget.googleMapsApiKey.trim();

    if (widgetKey.isNotEmpty) {
      return widgetKey;
    }

    return GoogleMapsConfig.directionsApiKey;
  }

  @override
  void initState() {
    super.initState();

    _cartController = SmartCartController(
      directionsService: DirectionsService(
        apiKey: _resolvedGoogleMapsApiKey,
      ),
    );

    _prepareLocationAndCart();
  }

  @override
  void dispose() {
    _mapController?.dispose();
    _cartController.dispose();
    super.dispose();
  }

  Future<void> _prepareLocationAndCart() async {
    setState(() {
      _isPreparingLocation = true;
      _locationError = null;
    });

    try {
      final Position position = await _getCurrentPosition();

      final SmartGeoPoint userLocation = SmartGeoPoint(
        latitude: position.latitude,
        longitude: position.longitude,
      );

      await _cartController.loadInitialItems(
        items: widget.initialItems,
        userLocation: userLocation,
      );

      if (!mounted) return;

      setState(() {
        _isPreparingLocation = false;
      });

      await _animateCameraToActiveRoute();
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isPreparingLocation = false;
        _locationError = error.toString();
      });
    }
  }

  Future<Position> _getCurrentPosition() async {
    final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      throw Exception('Location service belum aktif.');
    }

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw Exception('Izin lokasi belum diberikan.');
    }

    return Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.best,
    );
  }

  Future<void> _animateCameraToActiveRoute() async {
    final gmaps.GoogleMapController? mapController = _mapController;

    if (mapController == null) return;

    final List<SmartGeoPoint> routePoints = _cartController.routeData.points;

    if (routePoints.isNotEmpty) {
      final gmaps.LatLngBounds bounds = _boundsFromPoints(routePoints);

      await mapController.animateCamera(
        gmaps.CameraUpdate.newLatLngBounds(bounds, 72),
      );

      return;
    }

    final SmartCartItem? target = _cartController.activeTarget;

    if (target == null) {
      final SmartGeoPoint? userLocation = _cartController.userLocation;

      if (userLocation == null) return;

      await mapController.animateCamera(
        gmaps.CameraUpdate.newLatLngZoom(
          _toGoogleLatLng(userLocation),
          14,
        ),
      );

      return;
    }

    await mapController.animateCamera(
      gmaps.CameraUpdate.newLatLngZoom(
        _toGoogleLatLng(target.donorLocation),
        15,
      ),
    );
  }

  gmaps.LatLngBounds _boundsFromPoints(List<SmartGeoPoint> points) {
    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;

    for (final SmartGeoPoint point in points) {
      if (point.latitude < minLat) minLat = point.latitude;
      if (point.latitude > maxLat) maxLat = point.latitude;
      if (point.longitude < minLng) minLng = point.longitude;
      if (point.longitude > maxLng) maxLng = point.longitude;
    }

    if (minLat == maxLat) {
      minLat -= 0.0008;
      maxLat += 0.0008;
    }

    if (minLng == maxLng) {
      minLng -= 0.0008;
      maxLng += 0.0008;
    }

    return gmaps.LatLngBounds(
      southwest: gmaps.LatLng(minLat, minLng),
      northeast: gmaps.LatLng(maxLat, maxLng),
    );
  }

  gmaps.LatLng _toGoogleLatLng(SmartGeoPoint point) {
    return gmaps.LatLng(
      point.latitude,
      point.longitude,
    );
  }

  Future<void> _handleCompleteTopPickup() async {
    final SmartCartItem? target = _cartController.activeTarget;

    if (target == null) return;

    final bool? completed = await ProofOfPickupSheet.show(
      context: context,
      token: widget.token,
      foodId: int.tryParse(target.id) ?? 0,
      foodName: target.foodName,
    );

    if (completed != true || !mounted) return;

    await _cartController.completeByIdAndAdvance(target.id);

    if (!mounted) return;

    await _animateCameraToActiveRoute();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.textPrimary,
        content: Text(
          '${target.foodName} selesai diambil. Rute dialihkan ke prioritas berikutnya.',
        ),
      ),
    );
  }

  Future<void> _handleTransportModeChanged(PickupTransportMode mode) async {
    await _cartController.setTransportMode(mode);

    if (!mounted) return;

    await _animateCameraToActiveRoute();
  }

  Future<void> _removeItemAndRefresh(SmartCartItem item) async {
    await _cartController.removeItem(item.id);

    if (!mounted) return;

    await _animateCameraToActiveRoute();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<SmartCartController>.value(
      value: _cartController,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Builder(
            builder: (context) {
              if (_isPreparingLocation) {
                return const _SmartMapLoadingState();
              }

              if (_locationError != null) {
                return _SmartMapErrorState(
                  message: _locationError!,
                  onRetry: _prepareLocationAndCart,
                );
              }

              return Consumer<SmartCartController>(
                builder: (context, smartCartController, child) {
                  final SmartGeoPoint center =
                      smartCartController.userLocation ??
                          const SmartGeoPoint(
                            latitude: -6.9730,
                            longitude: 107.6300,
                          );

                  return Stack(
                    children: [
                      Positioned.fill(
                        child: gmaps.GoogleMap(
                          initialCameraPosition: gmaps.CameraPosition(
                            target: _toGoogleLatLng(center),
                            zoom: 14,
                          ),
                          onMapCreated: (googleMapController) {
                            _mapController = googleMapController;

                            scheduleMicrotask(() {
                              _animateCameraToActiveRoute();
                            });
                          },
                          trafficEnabled: true,
                          myLocationEnabled: true,
                          myLocationButtonEnabled: false,
                          compassEnabled: true,
                          zoomControlsEnabled: false,
                          mapToolbarEnabled: false,
                          markers: _buildMarkers(smartCartController),
                          polylines: _buildPolylines(smartCartController),
                        ),
                      ),
                      Positioned(
                        left: AppSpacing.x2,
                        right: AppSpacing.x2,
                        top: AppSpacing.x2,
                        child: _SmartRouteHeader(
                          controller: smartCartController,
                          onRefreshRoute: () async {
                            await smartCartController.refreshRouteForTop();

                            if (!mounted) return;

                            await _animateCameraToActiveRoute();
                          },
                        ),
                      ),
                      Positioned(
                        left: AppSpacing.x2,
                        right: AppSpacing.x2,
                        top: 146,
                        child: _TransportModeSelector(
                          selectedMode: smartCartController.transportMode,
                          onChanged: _handleTransportModeChanged,
                        ),
                      ),
                      Positioned(
                        right: AppSpacing.x2,
                        bottom: 304,
                        child: _MyLocationButton(
                          onTap: () async {
                            final SmartGeoPoint? userLocation =
                                smartCartController.userLocation;

                            if (userLocation == null ||
                                _mapController == null) {
                              return;
                            }

                            await _mapController!.animateCamera(
                              gmaps.CameraUpdate.newLatLngZoom(
                                _toGoogleLatLng(userLocation),
                                15,
                              ),
                            );
                          },
                        ),
                      ),
                      Positioned(
                        left: AppSpacing.x2,
                        right: AppSpacing.x2,
                        bottom: AppSpacing.x2,
                        child: _SmartCartBottomPanel(
                          controller: smartCartController,
                          onCompleteTopPickup: _handleCompleteTopPickup,
                          onRemoveItem: _removeItemAndRefresh,
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Set<gmaps.Marker> _buildMarkers(SmartCartController controller) {
    final Set<gmaps.Marker> markers = {};

    final SmartGeoPoint? userLocation = controller.userLocation;

    if (userLocation != null) {
      markers.add(
        gmaps.Marker(
          markerId: const gmaps.MarkerId('user-location'),
          position: _toGoogleLatLng(userLocation),
          icon: gmaps.BitmapDescriptor.defaultMarkerWithHue(
            gmaps.BitmapDescriptor.hueAzure,
          ),
          infoWindow: const gmaps.InfoWindow(
            title: 'Lokasi Anda',
          ),
        ),
      );
    }

    for (int index = 0; index < controller.items.length; index++) {
      final SmartCartItem item = controller.items[index];
      final bool isActive = index == 0;

      markers.add(
        gmaps.Marker(
          markerId: gmaps.MarkerId('donor-${item.id}'),
          position: _toGoogleLatLng(item.donorLocation),
          icon: gmaps.BitmapDescriptor.defaultMarkerWithHue(
            _markerHueForItem(
              item,
              isActive: isActive,
            ),
          ),
          infoWindow: gmaps.InfoWindow(
            title: isActive ? 'Prioritas #1: ${item.foodName}' : item.foodName,
            snippet:
                '${item.condition.label} • Skor ${controller.scoreOf(item).toStringAsFixed(1)}',
          ),
        ),
      );
    }

    return markers;
  }

  double _markerHueForItem(
    SmartCartItem item, {
    required bool isActive,
  }) {
    if (isActive) {
      return gmaps.BitmapDescriptor.hueOrange;
    }

    switch (item.condition) {
      case FoodReadinessCondition.fresh:
        return gmaps.BitmapDescriptor.hueGreen;
      case FoodReadinessCondition.consumeSoon:
        return gmaps.BitmapDescriptor.hueYellow;
      case FoodReadinessCondition.compost:
        return gmaps.BitmapDescriptor.hueRed;
    }
  }

  Set<gmaps.Polyline> _buildPolylines(SmartCartController controller) {
    final List<SmartGeoPoint> routePoints = controller.routeData.points;

    if (routePoints.isEmpty) {
      return <gmaps.Polyline>{};
    }

    return {
      gmaps.Polyline(
        polylineId: const gmaps.PolylineId('active-priority-route'),
        points: routePoints.map(_toGoogleLatLng).toList(),
        color: AppColors.primary,
        width: 6,
        geodesic: true,
      ),
    };
  }
}

class _SmartRouteHeader extends StatelessWidget {
  final SmartCartController controller;
  final Future<void> Function() onRefreshRoute;

  const _SmartRouteHeader({
    required this.controller,
    required this.onRefreshRoute,
  });

  @override
  Widget build(BuildContext context) {
    final SmartCartItem? activeTarget = controller.activeTarget;
    final PriorityDonorData? priorityDonor = controller.routeData.priorityDonor;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: AppShadows.card,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.x2),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              child: const Icon(
                Icons.route_rounded,
                color: AppColors.primaryDark,
              ),
            ),
            const SizedBox(width: AppSpacing.x2),
            Expanded(
              child: activeTarget == null
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Smart Cart Kosong',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          'Tambahkan makanan untuk mulai membuat rute.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          priorityDonor?.foodName ?? activeTarget.foodName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          controller.isRouteLoading
                              ? 'Memuat rute prioritas...'
                              : '${controller.routeData.durationText} • ${controller.routeData.distanceText}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
            ),
            IconButton(
              onPressed: controller.isRouteLoading ? null : onRefreshRoute,
              icon: controller.isRouteLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2.2),
                    )
                  : const Icon(Icons.refresh_rounded),
            ),
          ],
        ),
      ),
    );
  }
}

class _TransportModeSelector extends StatelessWidget {
  final PickupTransportMode selectedMode;
  final ValueChanged<PickupTransportMode> onChanged;

  const _TransportModeSelector({
    required this.selectedMode,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(999),
        boxShadow: AppShadows.card,
      ),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Row(
          children: PickupTransportMode.values.map((mode) {
            final bool selected = mode == selectedMode;

            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: ChoiceChip(
                  selected: selected,
                  showCheckmark: false,
                  selectedColor: AppColors.primary,
                  backgroundColor: Colors.transparent,
                  side: BorderSide(
                    color: selected ? AppColors.primary : Colors.transparent,
                  ),
                  label: Text(
                    mode.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  avatar: Icon(
                    _iconForMode(mode),
                    size: 16,
                    color: selected ? Colors.white : AppColors.primaryDark,
                  ),
                  labelStyle: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: selected ? Colors.white : AppColors.primaryDark,
                        fontWeight: FontWeight.w700,
                      ),
                  onSelected: (_) => onChanged(mode),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  IconData _iconForMode(PickupTransportMode mode) {
    switch (mode) {
      case PickupTransportMode.walking:
        return Icons.directions_walk_rounded;
      case PickupTransportMode.driving:
        return Icons.two_wheeler_rounded;
      case PickupTransportMode.transit:
        return Icons.directions_bus_rounded;
    }
  }
}

class _MyLocationButton extends StatelessWidget {
  final VoidCallback onTap;

  const _MyLocationButton({
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.card,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: const SizedBox(
            width: 52,
            height: 52,
            child: Icon(
              Icons.my_location_rounded,
              color: AppColors.primaryDark,
            ),
          ),
        ),
      ),
    );
  }
}

class _SmartCartBottomPanel extends StatelessWidget {
  final SmartCartController controller;
  final Future<void> Function() onCompleteTopPickup;
  final Future<void> Function(SmartCartItem item) onRemoveItem;

  const _SmartCartBottomPanel({
    required this.controller,
    required this.onCompleteTopPickup,
    required this.onRemoveItem,
  });

  @override
  Widget build(BuildContext context) {
    final SmartCartItem? activeTarget = controller.activeTarget;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: AppShadows.card,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.x2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _SmartCartSummaryRow(
              controller: controller,
            ),
            const SizedBox(height: AppSpacing.x2),
            if (controller.routeError != null)
              _RouteErrorCard(
                message: controller.routeError!,
              ),
            if (controller.routeError != null)
              const SizedBox(height: AppSpacing.x2),
            if (activeTarget == null)
              const _EmptyCartState()
            else ...[
              _ActiveTargetCard(
                item: activeTarget,
                score: controller.scoreOf(activeTarget),
                distanceKm: controller.distanceKmOf(activeTarget),
                priorityDonor: controller.routeData.priorityDonor,
              ),
              const SizedBox(height: AppSpacing.x2),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: controller.items.isEmpty
                          ? null
                          : () => onRemoveItem(activeTarget),
                      icon: const Icon(Icons.remove_circle_outline_rounded),
                      label: const Text('Hapus'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.x1),
                  Expanded(
                    flex: 2,
                    child: SizedBox(
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: onCompleteTopPickup,
                        icon: const Icon(Icons.fact_check_rounded),
                        label: const Text('Selesai & Upload Bukti'),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.x2),
              _QueuePreview(
                controller: controller,
                onRemoveItem: onRemoveItem,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SmartCartSummaryRow extends StatelessWidget {
  final SmartCartController controller;

  const _SmartCartSummaryRow({
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final String routeLatency = controller.routeData.networkLatencyMs == 0
        ? '-'
        : '${controller.routeData.networkLatencyMs} ms';

    final String responseSize = controller.routeData.responseBytes == 0
        ? '-'
        : '${(controller.routeData.responseBytes / 1024).toStringAsFixed(1)} KB';

    return Row(
      children: [
        Expanded(
          child: _SummaryTile(
            label: 'Keranjang',
            value: '${controller.totalCount}/3',
            icon: Icons.shopping_bag_outlined,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: AppSpacing.x1),
        Expanded(
          child: _SummaryTile(
            label: 'Kuning',
            value: '${controller.yellowCount}/1',
            icon: Icons.warning_amber_rounded,
            color: AppColors.accent,
          ),
        ),
        const SizedBox(width: AppSpacing.x1),
        Expanded(
          child: _SummaryTile(
            label: 'Mock API',
            value: routeLatency,
            subValue: responseSize,
            icon: Icons.network_check_rounded,
            color: AppColors.teal,
          ),
        ),
      ],
    );
  }
}

class _SummaryTile extends StatelessWidget {
  final String label;
  final String value;
  final String? subValue;
  final IconData icon;
  final Color color;

  const _SummaryTile({
    required this.label,
    required this.value,
    this.subValue,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.x1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: color.withValues(alpha: 0.18),
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 20,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: color,
                ),
          ),
          Text(
            subValue == null ? label : '$label • $subValue',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
        ],
      ),
    );
  }
}

class _ActiveTargetCard extends StatelessWidget {
  final SmartCartItem item;
  final double score;
  final double distanceKm;
  final PriorityDonorData? priorityDonor;

  const _ActiveTargetCard({
    required this.item,
    required this.score,
    required this.distanceKm,
    required this.priorityDonor,
  });

  @override
  Widget build(BuildContext context) {
    final String foodName = priorityDonor?.foodName ?? item.foodName;
    final String donorName = priorityDonor?.donorName ?? item.donorName;
    final double displayScore = priorityDonor?.score ?? score;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.x2),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: _conditionColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(
              _conditionIcon,
              color: _conditionColor,
            ),
          ),
          const SizedBox(width: AppSpacing.x2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Prioritas #1 • $donorName',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: AppColors.primaryDark,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  foodName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 2),
                Text(
                  '${item.condition.label} • ${distanceKm.toStringAsFixed(2)} km • Skor ${displayScore.toStringAsFixed(1)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color get _conditionColor {
    switch (item.condition) {
      case FoodReadinessCondition.fresh:
        return AppColors.primary;
      case FoodReadinessCondition.consumeSoon:
        return AppColors.accent;
      case FoodReadinessCondition.compost:
        return AppColors.danger;
    }
  }

  IconData get _conditionIcon {
    switch (item.condition) {
      case FoodReadinessCondition.fresh:
        return Icons.check_circle_rounded;
      case FoodReadinessCondition.consumeSoon:
        return Icons.schedule_rounded;
      case FoodReadinessCondition.compost:
        return Icons.recycling_rounded;
    }
  }
}

class _QueuePreview extends StatelessWidget {
  final SmartCartController controller;
  final Future<void> Function(SmartCartItem item) onRemoveItem;

  const _QueuePreview({
    required this.controller,
    required this.onRemoveItem,
  });

  @override
  Widget build(BuildContext context) {
    if (controller.items.length <= 1) {
      return const SizedBox.shrink();
    }

    final List<SmartCartItem> queue = controller.items.skip(1).toList();

    return SizedBox(
      height: 72,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: queue.length,
        separatorBuilder: (context, index) {
          return const SizedBox(width: AppSpacing.x1);
        },
        itemBuilder: (context, index) {
          final SmartCartItem item = queue[index];

          return _QueueMiniCard(
            item: item,
            score: controller.scoreOf(item),
            onRemove: () => onRemoveItem(item),
          );
        },
      ),
    );
  }
}

class _QueueMiniCard extends StatelessWidget {
  final SmartCartItem item;
  final double score;
  final VoidCallback onRemove;

  const _QueueMiniCard({
    required this.item,
    required this.score,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 196,
      padding: const EdgeInsets.all(AppSpacing.x1),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.foodName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(height: 2),
                Text(
                  'Skor ${score.toStringAsFixed(1)}',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onRemove,
            icon: const Icon(
              Icons.close_rounded,
              size: 18,
            ),
          ),
        ],
      ),
    );
  }
}

class _RouteErrorCard extends StatelessWidget {
  final String message;

  const _RouteErrorCard({
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.x2),
      decoration: BoxDecoration(
        color: AppColors.dangerSoft,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: AppColors.danger.withValues(alpha: 0.20),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: AppColors.danger,
          ),
          const SizedBox(width: AppSpacing.x1),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.danger,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyCartState extends StatelessWidget {
  const _EmptyCartState();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.x3),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.shopping_bag_outlined,
            color: AppColors.textSecondary,
            size: 34,
          ),
          const SizedBox(height: AppSpacing.x1),
          Text(
            'Belum Ada Pesanan',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            'Tambahkan maksimal 3 makanan ke Smart Cart.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _SmartMapLoadingState extends StatelessWidget {
  const _SmartMapLoadingState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(AppSpacing.x3),
        padding: const EdgeInsets.all(AppSpacing.x3),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          boxShadow: AppShadows.card,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(strokeWidth: 2.4),
            const SizedBox(width: AppSpacing.x2),
            Text(
              'Menyiapkan lokasi dan rute...',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _SmartMapErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _SmartMapErrorState({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.x3),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.xl),
            boxShadow: AppShadows.card,
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.x3),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.location_off_rounded,
                  color: AppColors.danger,
                  size: 48,
                ),
                const SizedBox(height: AppSpacing.x2),
                Text(
                  'Gagal Menyiapkan Lokasi',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: AppSpacing.x1),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.x3),
                SizedBox(
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Coba Lagi'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}