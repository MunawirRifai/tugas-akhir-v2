import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/common/app_bottom_sheet_handle.dart';
import '../../../shared/widgets/common/app_surface_card.dart';
import '../../../shared/widgets/maps/map_marker_shell.dart';

typedef FoodMarkerTap = void Function(Map<String, dynamic> food);

class ClusteredFoodMarkerLayer extends StatelessWidget {
  final List<Map<String, dynamic>> foods;
  final int? selectedFoodId;
  final int? currentUserId;
  final FoodMarkerTap onFoodTap;
  final double tightRadiusMeters;

  const ClusteredFoodMarkerLayer({
    super.key,
    required this.foods,
    required this.selectedFoodId,
    required this.currentUserId,
    required this.onFoodTap,
    this.tightRadiusMeters = 24,
  });

  @override
  Widget build(BuildContext context) {
    final List<Marker> markers = foods
        .map((food) {
          final LatLng? position = _positionOf(food);

          if (position == null) {
            return null;
          }

          final int? foodId = _intOf(
            _valueOf(food, ['id', 'food_id', 'foodId']),
          );

          final bool isSelected = foodId != null && foodId == selectedFoodId;
          final bool isOwnedByCurrentUser = _isOwnedByCurrentUser(food);

          final String categoryText = _categoryTextOf(food);
          final String conditionText = _conditionTextOf(food);

          return Marker(
            width: isSelected ? 72 : 64,
            height: isSelected ? 72 : 64,
            point: position,
            child: MapMarkerShell.foodCategory(
              category: categoryText,
              color: MapMarkerStyle.colorFromCondition(conditionText),
              size: MapMarkerShellSize.medium,
              isSelected: isSelected,
              isOwnedByCurrentUser: isOwnedByCurrentUser,
              tooltip: _foodNameOf(food),
              onTap: () => _handleFoodMarkerTap(
                context: context,
                tappedFood: food,
                tappedPosition: position,
              ),
            ),
          );
        })
        .whereType<Marker>()
        .toList();

    if (markers.isEmpty) {
      return const SizedBox.shrink();
    }

    return MarkerClusterLayerWidget(
      options: MarkerClusterLayerOptions(
        markers: markers,
        maxClusterRadius: 48,
        disableClusteringAtZoom: 17,
        maxZoom: 19,
        size: const Size(52, 52),
        alignment: Alignment.center,
        padding: const EdgeInsets.all(48),
        zoomToBoundsOnClick: true,
        centerMarkerOnClick: false,
        spiderfyCluster: true,
        spiderfyCircleRadius: 58,
        spiderfySpiralDistanceMultiplier: 2,
        circleSpiralSwitchover: 8,
        showPolygon: false,
        markerChildBehavior: true,
        animationsOptions: const AnimationsOptions(
          zoom: Duration(milliseconds: 360),
          fitBound: Duration(milliseconds: 360),
          spiderfy: Duration(milliseconds: 280),
          centerMarker: Duration(milliseconds: 280),
          fadeInCurve: Curves.easeOutCubic,
          fadeOutCurve: Curves.easeOutCubic,
          clusterExpandCurve: Curves.easeOutBack,
          clusterCollapseCurve: Curves.easeOutCubic,
          fitBoundCurves: Curves.easeOutCubic,
          centerMarkerCurves: Curves.easeOutCubic,
        ),
        computeSize: (clusterMarkers) {
          final int count = clusterMarkers.length;

          if (count >= 100) {
            return const Size(66, 66);
          }

          if (count >= 10) {
            return const Size(58, 58);
          }

          return const Size(52, 52);
        },
        builder: (context, clusterMarkers) {
          return MapClusterBubble(
            count: clusterMarkers.length,
            tooltip: '${clusterMarkers.length} makanan berdekatan',
          );
        },
      ),
    );
  }

  void _handleFoodMarkerTap({
    required BuildContext context,
    required Map<String, dynamic> tappedFood,
    required LatLng tappedPosition,
  }) {
    final List<Map<String, dynamic>> nearbyFoods = _nearbyFoods(tappedPosition);

    if (nearbyFoods.length > 1) {
      _showNearbyFoodsSheet(context: context, foods: nearbyFoods);
      return;
    }

    onFoodTap(tappedFood);
  }

  List<Map<String, dynamic>> _nearbyFoods(LatLng center) {
    const Distance distance = Distance();

    final List<Map<String, dynamic>> nearbyFoods = foods.where((food) {
      final LatLng? position = _positionOf(food);

      if (position == null) {
        return false;
      }

      final double meters = distance.as(LengthUnit.Meter, center, position);

      return meters <= tightRadiusMeters;
    }).toList();

    nearbyFoods.sort((a, b) {
      final LatLng? positionA = _positionOf(a);
      final LatLng? positionB = _positionOf(b);

      if (positionA == null || positionB == null) {
        return 0;
      }

      final double distanceA = distance.as(LengthUnit.Meter, center, positionA);

      final double distanceB = distance.as(LengthUnit.Meter, center, positionB);

      return distanceA.compareTo(distanceB);
    });

    return nearbyFoods;
  }

  void _showNearbyFoodsSheet({
    required BuildContext context,
    required List<Map<String, dynamic>> foods,
  }) {
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _NearbyFoodsSheet(
          foods: foods,
          onFoodTap: (food) {
            Navigator.of(context).pop();
            onFoodTap(food);
          },
        );
      },
    );
  }

  bool _isOwnedByCurrentUser(Map<String, dynamic> food) {
    final int? ownerId = _intOf(
      _valueOf(food, ['user_id', 'userId', 'owner_id', 'ownerId']),
    );

    return ownerId != null && ownerId == currentUserId;
  }

  LatLng? _positionOf(Map<String, dynamic> food) {
    final double? latitude = _doubleOf(_valueOf(food, ['latitude', 'lat']));

    final double? longitude = _doubleOf(
      _valueOf(food, ['longitude', 'lng', 'lon']),
    );

    if (latitude == null || longitude == null) {
      return null;
    }

    if (!latitude.isFinite || !longitude.isFinite) {
      return null;
    }

    if (latitude < -90 || latitude > 90) {
      return null;
    }

    if (longitude < -180 || longitude > 180) {
      return null;
    }

    return LatLng(latitude, longitude);
  }

  String _foodNameOf(Map<String, dynamic> food) {
    return _textOf(
      _valueOf(food, ['food_name', 'foodName', 'name', 'title']),
      fallback: 'Makanan',
    );
  }

  String _categoryTextOf(Map<String, dynamic> food) {
    return _textOf(
      _valueOf(food, [
        'category',
        'foodCategory',
        'food_category',
        'categoryName',
      ]),
      fallback: '',
    ).toLowerCase();
  }

  String _conditionTextOf(Map<String, dynamic> food) {
    return _textOf(
      _valueOf(food, [
        'condition',
        'foodCondition',
        'food_condition',
        'quality',
        'readiness',
      ]),
      fallback: '',
    ).toLowerCase();
  }

  Object? _valueOf(Map<String, dynamic> data, List<String> keys) {
    for (final String key in keys) {
      if (data.containsKey(key)) {
        return data[key];
      }
    }

    return null;
  }

  String _textOf(Object? value, {required String fallback}) {
    final String text = value?.toString().trim() ?? '';

    if (text.isEmpty || text == 'null') {
      return fallback;
    }

    return text;
  }

  int? _intOf(Object? value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();

    return int.tryParse(value.toString());
  }

  double? _doubleOf(Object? value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is num) return value.toDouble();

    return double.tryParse(value.toString());
  }
}

class _NearbyFoodsSheet extends StatelessWidget {
  final List<Map<String, dynamic>> foods;
  final FoodMarkerTap onFoodTap;

  const _NearbyFoodsSheet({required this.foods, required this.onFoodTap});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.72,
        ),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.xl),
          ),
        ),
        child: Column(
          children: [
            const AppBottomSheetHandle(),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.x3,
                0,
                AppSpacing.x3,
                AppSpacing.x1,
              ),
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
                      Icons.layers_rounded,
                      color: AppColors.primaryDark,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.x2),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Beberapa Makanan Berdekatan',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${foods.length} postingan berada pada radius sempit. Pilih salah satu.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.x3,
                  AppSpacing.x1,
                  AppSpacing.x3,
                  AppSpacing.x3,
                ),
                itemCount: foods.length,
                separatorBuilder: (context, index) {
                  return const SizedBox(height: AppSpacing.x1);
                },
                itemBuilder: (context, index) {
                  final Map<String, dynamic> food = foods[index];

                  return _NearbyFoodTile(
                    food: food,
                    onTap: () => onFoodTap(food),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NearbyFoodTile extends StatelessWidget {
  final Map<String, dynamic> food;
  final VoidCallback onTap;

  const _NearbyFoodTile({required this.food, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final String name = _textOf(
      _valueOf(food, ['food_name', 'foodName', 'name', 'title']),
      fallback: 'Makanan',
    );

    final String description = _textOf(
      _valueOf(food, ['description', 'desc', 'note']),
      fallback: 'Tidak ada deskripsi.',
    );

    final int quantity =
        _intOf(_valueOf(food, ['quantity', 'qty', 'stock'])) ?? 0;

    final String category = _textOf(
      _valueOf(food, ['category', 'foodCategory', 'food_category']),
      fallback: 'Kategori belum tersedia',
    );

    return AppSurfaceCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.x2),
      borderRadius: AppRadius.lg,
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(
              MapMarkerStyle.iconFromCategory(category),
              color: AppColors.primaryDark,
            ),
          ),
          const SizedBox(width: AppSpacing.x2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _SmallPill(
                      icon: Icons.inventory_2_outlined,
                      label: '$quantity porsi',
                      color: AppColors.teal,
                    ),
                    _SmallPill(
                      icon: Icons.category_outlined,
                      label: category,
                      color: AppColors.primaryDark,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.x1),
          const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
        ],
      ),
    );
  }

  Object? _valueOf(Map<String, dynamic> data, List<String> keys) {
    for (final String key in keys) {
      if (data.containsKey(key)) {
        return data[key];
      }
    }

    return null;
  }

  String _textOf(Object? value, {required String fallback}) {
    final String text = value?.toString().trim() ?? '';

    if (text.isEmpty || text == 'null') {
      return fallback;
    }

    return text;
  }

  int? _intOf(Object? value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();

    return int.tryParse(value.toString());
  }
}

class _SmallPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _SmallPill({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.x1,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
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
