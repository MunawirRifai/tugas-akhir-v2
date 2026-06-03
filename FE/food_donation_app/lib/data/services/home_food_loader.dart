import 'package:latlong2/latlong.dart';

import '../../core/utils/food_mapper.dart';
import 'food_service.dart';

class HomeFoodLoadResult {
  final List<Map<String, dynamic>> foods;
  final DateTime fetchedAt;
  final int latencyMs;
  final String source;

  const HomeFoodLoadResult({
    required this.foods,
    required this.fetchedAt,
    required this.latencyMs,
    required this.source,
  });

  bool get isEmpty {
    return foods.isEmpty;
  }

  int get totalCount {
    return foods.length;
  }
}

class HomeFoodLoader {
  const HomeFoodLoader._();

  static Future<HomeFoodLoadResult> loadFoods({
    required String token,
    bool onlyValidCoordinate = true,
    bool onlyAvailable = false,
  }) async {
    final Stopwatch stopwatch = Stopwatch()..start();

    final List<dynamic> rawFoods = await FoodService.getFoods(token);

    stopwatch.stop();

    List<Map<String, dynamic>> foods = rawFoods
        .map(FoodMapper.mapOf)
        .where((food) => food.isNotEmpty)
        .toList();

    if (onlyValidCoordinate) {
      foods = foods.where(_hasValidCoordinate).toList();
    }

    if (onlyAvailable) {
      foods = foods.where(_isAvailableFood).toList();
    }

    return HomeFoodLoadResult(
      foods: foods,
      fetchedAt: DateTime.now(),
      latencyMs: stopwatch.elapsedMilliseconds,
      source: 'FoodService.getFoods',
    );
  }

  static Future<List<Map<String, dynamic>>> loadFoodList({
    required String token,
    bool onlyValidCoordinate = true,
    bool onlyAvailable = false,
  }) async {
    final HomeFoodLoadResult result = await loadFoods(
      token: token,
      onlyValidCoordinate: onlyValidCoordinate,
      onlyAvailable: onlyAvailable,
    );

    return result.foods;
  }

  static List<Map<String, dynamic>> sortByDistance({
    required List<Map<String, dynamic>> foods,
    required LatLng currentLocation,
  }) {
    final List<Map<String, dynamic>> sortedFoods =
        foods.map((food) => Map<String, dynamic>.from(food)).toList();

    sortedFoods.sort((a, b) {
      final double distanceA = distanceMetersOf(
        food: a,
        currentLocation: currentLocation,
      );

      final double distanceB = distanceMetersOf(
        food: b,
        currentLocation: currentLocation,
      );

      return distanceA.compareTo(distanceB);
    });

    return sortedFoods;
  }

  static List<Map<String, dynamic>> filterByRadius({
    required List<Map<String, dynamic>> foods,
    required LatLng currentLocation,
    required double radiusKm,
  }) {
    final double radiusMeters = radiusKm * 1000;

    return foods.where((food) {
      final double distanceMeters = distanceMetersOf(
        food: food,
        currentLocation: currentLocation,
      );

      return distanceMeters <= radiusMeters;
    }).toList();
  }

  static List<Map<String, dynamic>> searchFoods({
    required List<Map<String, dynamic>> foods,
    required String query,
  }) {
    final String normalizedQuery = query.trim().toLowerCase();

    if (normalizedQuery.isEmpty) {
      return foods;
    }

    return foods.where((food) {
      final String searchableText = [
        FoodMapper.textOf(
          FoodMapper.valueOf(
            food,
            [
              'food_name',
              'foodName',
              'name',
              'title',
            ],
          ),
          fallback: '',
        ),
        FoodMapper.textOf(
          FoodMapper.valueOf(
            food,
            [
              'description',
              'desc',
              'note',
              'notes',
            ],
          ),
          fallback: '',
        ),
        FoodMapper.textOf(
          FoodMapper.valueOf(
            food,
            [
              'category',
              'foodCategory',
              'food_category',
              'categoryName',
            ],
          ),
          fallback: '',
        ),
        FoodMapper.textOf(
          FoodMapper.valueOf(
            food,
            [
              'address',
              'location',
              'pickupAddress',
              'pickup_address',
            ],
          ),
          fallback: '',
        ),
      ].join(' ').toLowerCase();

      return searchableText.contains(normalizedQuery);
    }).toList();
  }

  static double distanceMetersOf({
    required Map<String, dynamic> food,
    required LatLng currentLocation,
  }) {
    final double? latitude = FoodMapper.nullableDoubleOf(
      FoodMapper.valueOf(
        food,
        [
          'latitude',
          'lat',
        ],
      ),
    );

    final double? longitude = FoodMapper.nullableDoubleOf(
      FoodMapper.valueOf(
        food,
        [
          'longitude',
          'lng',
          'lon',
        ],
      ),
    );

    if (latitude == null || longitude == null) {
      return double.infinity;
    }

    const Distance distance = Distance();

    return distance.as(
      LengthUnit.Meter,
      currentLocation,
      LatLng(latitude, longitude),
    );
  }

  static String distanceLabelOf({
    required Map<String, dynamic> food,
    required LatLng currentLocation,
  }) {
    final double distanceMeters = distanceMetersOf(
      food: food,
      currentLocation: currentLocation,
    );

    return FoodMapper.distanceLabelFromMeters(distanceMeters);
  }

  static bool _hasValidCoordinate(Map<String, dynamic> food) {
    final double? latitude = FoodMapper.nullableDoubleOf(
      FoodMapper.valueOf(
        food,
        [
          'latitude',
          'lat',
        ],
      ),
    );

    final double? longitude = FoodMapper.nullableDoubleOf(
      FoodMapper.valueOf(
        food,
        [
          'longitude',
          'lng',
          'lon',
        ],
      ),
    );

    if (latitude == null || longitude == null) {
      return false;
    }

    return latitude.isFinite &&
        longitude.isFinite &&
        latitude >= -90 &&
        latitude <= 90 &&
        longitude >= -180 &&
        longitude <= 180;
  }

  static bool _isAvailableFood(Map<String, dynamic> food) {
    final String status = FoodMapper.textOf(
      FoodMapper.valueOf(
        food,
        [
          'status',
          'food_status',
          'foodStatus',
        ],
      ),
      fallback: 'POSTED',
    ).toUpperCase();

    return status == 'POSTED' || status == 'AVAILABLE';
  }
}