import 'dart:math' as math;

import 'package:flutter/material.dart';

enum FoodCategory {
  heavyMeal,
  drink,
  grocery,
  snack,
  freshIngredient;

  String get label {
    switch (this) {
      case FoodCategory.heavyMeal:
        return 'Makanan Berat';
      case FoodCategory.drink:
        return 'Minuman';
      case FoodCategory.grocery:
        return 'Sembako';
      case FoodCategory.snack:
        return 'Kue/Snack';
      case FoodCategory.freshIngredient:
        return 'Bahan Segar';
    }
  }

  String get apiValue {
    switch (this) {
      case FoodCategory.heavyMeal:
        return 'makanan berat';
      case FoodCategory.drink:
        return 'minuman';
      case FoodCategory.grocery:
        return 'sembako';
      case FoodCategory.snack:
        return 'kue snack';
      case FoodCategory.freshIngredient:
        return 'bahan segar';
    }
  }

  IconData get markerIcon {
    switch (this) {
      case FoodCategory.heavyMeal:
        return Icons.restaurant;
      case FoodCategory.drink:
        return Icons.local_drink;
      case FoodCategory.grocery:
        return Icons.shopping_bag;
      case FoodCategory.snack:
        return Icons.cookie;
      case FoodCategory.freshIngredient:
        return Icons.eco;
    }
  }

  String get descriptionHint {
    switch (this) {
      case FoodCategory.heavyMeal:
        return 'Contoh: nasi goreng, ayam geprek, rendang, sate, mie ayam, dan hidangan siap santap lainnya.';
      case FoodCategory.drink:
        return 'Contoh: air mineral, teh, kopi, susu, jus, dan minuman siap konsumsi lainnya.';
      case FoodCategory.grocery:
        return 'Contoh: beras, gula, minyak goreng, tepung, garam, mie instan, dan kebutuhan pokok lainnya.';
      case FoodCategory.snack:
        return 'Contoh: roti, donat, biskuit, keripik, kue basah, dan camilan lainnya.';
      case FoodCategory.freshIngredient:
        return 'Contoh: sayur, buah, daging, ikan, telur, tahu, tempe, dan bahan makanan yang belum menjadi hidangan siap santap.';
    }
  }

  static FoodCategory fromText(Object? value) {
    final String text = value?.toString().trim().toLowerCase() ?? '';

    if (_containsAny(text, [
      'minuman',
      'drink',
      'beverage',
      'teh',
      'kopi',
      'susu',
      'jus',
      'juice',
      'air mineral',
    ])) {
      return FoodCategory.drink;
    }

    if (_containsAny(text, [
      'sembako',
      'grocery',
      'beras',
      'gula',
      'minyak',
      'minyak goreng',
      'tepung',
      'garam',
      'mie instan',
      'kebutuhan pokok',
    ])) {
      return FoodCategory.grocery;
    }

    if (_containsAny(text, [
      'kue',
      'snack',
      'roti',
      'donat',
      'biskuit',
      'keripik',
      'kue basah',
      'camilan',
      'cemilan',
      'cake',
    ])) {
      return FoodCategory.snack;
    }

    if (_containsAny(text, [
      'bahan segar',
      'fresh ingredient',
      'sayur',
      'sayuran',
      'buah',
      'buah-buahan',
      'daging',
      'ikan',
      'telur',
      'tahu',
      'tempe',
      'bahan makanan',
      'belum menjadi hidangan',
    ])) {
      return FoodCategory.freshIngredient;
    }

    return FoodCategory.heavyMeal;
  }
}

enum FoodReadinessCondition {
  fresh,
  consumeSoon,
  compost;

  String get label {
    switch (this) {
      case FoodReadinessCondition.fresh:
        return 'Hijau/Tahan Lama';
      case FoodReadinessCondition.consumeSoon:
        return 'Kuning/Segera Basi';
      case FoodReadinessCondition.compost:
        return 'Merah/Kompos';
    }
  }

  String get shortLabel {
    switch (this) {
      case FoodReadinessCondition.fresh:
        return 'Tahan Lama';
      case FoodReadinessCondition.consumeSoon:
        return 'Segera Basi';
      case FoodReadinessCondition.compost:
        return 'Kompos';
    }
  }

  String get apiValue {
    switch (this) {
      case FoodReadinessCondition.fresh:
        return 'tahan lama';
      case FoodReadinessCondition.consumeSoon:
        return 'segera basi';
      case FoodReadinessCondition.compost:
        return 'kompos';
    }
  }

  int get baseScore {
    switch (this) {
      case FoodReadinessCondition.consumeSoon:
        return 100;
      case FoodReadinessCondition.fresh:
        return 60;
      case FoodReadinessCondition.compost:
        return 30;
    }
  }

  Color get markerColor {
    switch (this) {
      case FoodReadinessCondition.fresh:
        return const Color(0xFF10B981);
      case FoodReadinessCondition.consumeSoon:
        return const Color(0xFFF59E0B);
      case FoodReadinessCondition.compost:
        return const Color(0xFFEF4444);
    }
  }

  static FoodReadinessCondition fromText(Object? value) {
    final String text = value?.toString().trim().toLowerCase() ?? '';

    if (_containsAny(text, [
      'kompos',
      'compost',
      'basi',
      'pakan',
      'pakan ternak',
      'animal feed',
      'merah',
      'red',
    ])) {
      return FoodReadinessCondition.compost;
    }

    if (_containsAny(text, [
      'segera',
      'segera basi',
      'segera dihabiskan',
      'cepat habis',
      'mendekati expired',
      'hari ini',
      'consume soon',
      'kuning',
      'yellow',
    ])) {
      return FoodReadinessCondition.consumeSoon;
    }

    return FoodReadinessCondition.fresh;
  }
}

enum PickupTransportMode {
  walking,
  driving,
  transit;

  String get apiValue {
    switch (this) {
      case PickupTransportMode.walking:
        return 'walking';
      case PickupTransportMode.driving:
        return 'driving';
      case PickupTransportMode.transit:
        return 'transit';
    }
  }

  String get label {
    switch (this) {
      case PickupTransportMode.walking:
        return 'Jalan Kaki';
      case PickupTransportMode.driving:
        return 'Motor/Mobil';
      case PickupTransportMode.transit:
        return 'Transit';
    }
  }

  static PickupTransportMode fromApiValue(Object? value) {
    final String text = value?.toString().trim().toLowerCase() ?? '';

    switch (text) {
      case 'walking':
      case 'walk':
      case 'jalan kaki':
        return PickupTransportMode.walking;
      case 'transit':
      case 'bus':
      case 'angkutan umum':
        return PickupTransportMode.transit;
      case 'driving':
      case 'drive':
      case 'motor':
      case 'mobil':
      default:
        return PickupTransportMode.driving;
    }
  }
}

class SmartGeoPoint {
  final double latitude;
  final double longitude;

  const SmartGeoPoint({
    required this.latitude,
    required this.longitude,
  });

  factory SmartGeoPoint.fromMap(Map<String, dynamic> map) {
    return SmartGeoPoint(
      latitude: _doubleOf(
            _valueOf(
              map,
              [
                'latitude',
                'lat',
              ],
            ),
          ) ??
          0,
      longitude: _doubleOf(
            _valueOf(
              map,
              [
                'longitude',
                'lng',
                'lon',
              ],
            ),
          ) ??
          0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  double distanceKmTo(SmartGeoPoint other) {
    const double earthRadiusKm = 6371.0;

    final double lat1 = _degreeToRadian(latitude);
    final double lat2 = _degreeToRadian(other.latitude);
    final double deltaLat = _degreeToRadian(other.latitude - latitude);
    final double deltaLng = _degreeToRadian(other.longitude - longitude);

    final double a = math.sin(deltaLat / 2) * math.sin(deltaLat / 2) +
        math.cos(lat1) *
            math.cos(lat2) *
            math.sin(deltaLng / 2) *
            math.sin(deltaLng / 2);

    final double c = 2 * math.atan2(
      math.sqrt(a),
      math.sqrt(1 - a),
    );

    return earthRadiusKm * c;
  }

  static double _degreeToRadian(double degree) {
    return degree * math.pi / 180;
  }
}

class SmartCartItem {
  final String id;
  final String foodId;
  final String foodName;
  final String donorName;
  final SmartGeoPoint donorLocation;
  final FoodCategory foodCategory;
  final FoodReadinessCondition foodCondition;
  final int quantity;
  final String? photoUrl;
  final String? address;
  final DateTime? expiredAt;
  final Map<String, dynamic> rawData;

  const SmartCartItem({
    required this.id,
    required this.foodId,
    required this.foodName,
    required this.donorName,
    required this.donorLocation,
    required this.foodCategory,
    required this.foodCondition,
    required this.quantity,
    this.photoUrl,
    this.address,
    this.expiredAt,
    this.rawData = const <String, dynamic>{},
  });

  FoodReadinessCondition get condition {
    return foodCondition;
  }

  FoodCategory get category {
    return foodCategory;
  }

  IconData get markerIcon {
    return foodCategory.markerIcon;
  }

  Color get markerColor {
    return foodCondition.markerColor;
  }

  int get baseScore {
    return foodCondition.baseScore;
  }

  double distanceKmFrom(SmartGeoPoint userLocation) {
    return userLocation.distanceKmTo(donorLocation);
  }

  double priorityScoreFrom(SmartGeoPoint userLocation) {
    final double distanceKm = distanceKmFrom(userLocation);
    return foodCondition.baseScore - (distanceKm * 10);
  }

  SmartCartItem copyWith({
    String? id,
    String? foodId,
    String? foodName,
    String? donorName,
    SmartGeoPoint? donorLocation,
    FoodCategory? foodCategory,
    FoodReadinessCondition? foodCondition,
    int? quantity,
    String? photoUrl,
    String? address,
    DateTime? expiredAt,
    Map<String, dynamic>? rawData,
  }) {
    return SmartCartItem(
      id: id ?? this.id,
      foodId: foodId ?? this.foodId,
      foodName: foodName ?? this.foodName,
      donorName: donorName ?? this.donorName,
      donorLocation: donorLocation ?? this.donorLocation,
      foodCategory: foodCategory ?? this.foodCategory,
      foodCondition: foodCondition ?? this.foodCondition,
      quantity: quantity ?? this.quantity,
      photoUrl: photoUrl ?? this.photoUrl,
      address: address ?? this.address,
      expiredAt: expiredAt ?? this.expiredAt,
      rawData: rawData ?? this.rawData,
    );
  }

  factory SmartCartItem.fromFoodMap(Map<String, dynamic> food) {
    final String parsedFoodId = _textOf(
      _valueOf(
        food,
        [
          'id',
          'food_id',
          'foodId',
        ],
      ),
      fallback: 'unknown-food',
    );

    final String parsedFoodName = _textOf(
      _valueOf(
        food,
        [
          'foodName',
          'food_name',
          'name',
          'title',
        ],
      ),
      fallback: 'Makanan',
    );

    final String parsedDescription = _textOf(
      _valueOf(
        food,
        [
          'description',
          'desc',
          'note',
        ],
      ),
      fallback: '',
    );

    final String parsedCategorySource = [
      _textOf(
        _valueOf(
          food,
          [
            'foodCategory',
            'food_category',
            'category',
            'categoryName',
            'category_name',
          ],
        ),
        fallback: '',
      ),
      parsedFoodName,
      parsedDescription,
    ].join(' ');

    final String parsedConditionSource = [
      _textOf(
        _valueOf(
          food,
          [
            'foodCondition',
            'food_condition',
            'condition',
            'readiness',
            'quality',
          ],
        ),
        fallback: '',
      ),
      parsedFoodName,
      parsedDescription,
    ].join(' ');

    return SmartCartItem(
      id: parsedFoodId,
      foodId: parsedFoodId,
      foodName: parsedFoodName,
      donorName: _textOf(
        _valueOf(
          food,
          [
            'donorName',
            'donor_name',
            'userName',
            'user_name',
            'ownerName',
            'owner_name',
            'nameDonor',
          ],
        ),
        fallback: 'Donatur',
      ),
      donorLocation: SmartGeoPoint(
        latitude: _doubleOf(
              _valueOf(
                food,
                [
                  'latitude',
                  'lat',
                ],
              ),
            ) ??
            0,
        longitude: _doubleOf(
              _valueOf(
                food,
                [
                  'longitude',
                  'lng',
                  'lon',
                ],
              ),
            ) ??
            0,
      ),
      foodCategory: FoodCategory.fromText(parsedCategorySource),
      foodCondition: FoodReadinessCondition.fromText(parsedConditionSource),
      quantity: _intOf(
            _valueOf(
              food,
              [
                'quantity',
                'qty',
                'stock',
              ],
            ),
          ) ??
          1,
      photoUrl: _nullableTextOf(
        _valueOf(
          food,
          [
            'photoUrl',
            'photo_url',
            'photo',
            'image',
            'imageUrl',
            'image_url',
          ],
        ),
      ),
      address: _nullableTextOf(
        _valueOf(
          food,
          [
            'address',
            'location',
            'pickupAddress',
            'pickup_address',
          ],
        ),
      ),
      expiredAt: _dateTimeOf(
        _valueOf(
          food,
          [
            'expiredAt',
            'expired_at',
            'expiresAt',
            'expires_at',
          ],
        ),
      ),
      rawData: Map<String, dynamic>.from(food),
    );
  }

  Map<String, dynamic> toBackendMap() {
    return {
      'id': id,
      'foodId': foodId,
      'foodName': foodName,
      'donorName': donorName,
      'donorLocation': donorLocation.toMap(),
      'foodCategory': foodCategory.apiValue,
      'foodCategoryLabel': foodCategory.label,
      'foodCondition': foodCondition.apiValue,
      'foodConditionLabel': foodCondition.label,
      'quantity': quantity,
      'photoUrl': photoUrl,
      'address': address,
      'expiredAt': expiredAt?.toIso8601String(),
    };
  }
}

class SmartCartMutationResult {
  final bool isSuccess;
  final String message;

  const SmartCartMutationResult({
    required this.isSuccess,
    required this.message,
  });

  const SmartCartMutationResult.success(this.message) : isSuccess = true;

  const SmartCartMutationResult.failure(this.message) : isSuccess = false;
}

class PriorityDonorData {
  final String foodId;
  final String foodName;
  final String donorName;
  final SmartGeoPoint location;
  final FoodCategory foodCategory;
  final FoodReadinessCondition foodCondition;
  final double score;

  const PriorityDonorData({
    required this.foodId,
    required this.foodName,
    required this.donorName,
    required this.location,
    required this.foodCategory,
    required this.foodCondition,
    required this.score,
  });

  FoodReadinessCondition get condition {
    return foodCondition;
  }

  factory PriorityDonorData.fromBackendMap(Map<String, dynamic> map) {
    final String categorySource = [
      _textOf(
        _valueOf(
          map,
          [
            'foodCategory',
            'food_category',
            'category',
          ],
        ),
        fallback: '',
      ),
      _textOf(
        _valueOf(
          map,
          [
            'foodName',
            'food_name',
            'name',
          ],
        ),
        fallback: '',
      ),
    ].join(' ');

    final String conditionSource = [
      _textOf(
        _valueOf(
          map,
          [
            'foodCondition',
            'food_condition',
            'condition',
            'readiness',
          ],
        ),
        fallback: '',
      ),
      _textOf(
        _valueOf(
          map,
          [
            'foodName',
            'food_name',
            'name',
          ],
        ),
        fallback: '',
      ),
    ].join(' ');

    return PriorityDonorData(
      foodId: _textOf(
        _valueOf(
          map,
          [
            'foodId',
            'food_id',
            'id',
          ],
        ),
        fallback: 'priority-food',
      ),
      foodName: _textOf(
        _valueOf(
          map,
          [
            'foodName',
            'food_name',
            'name',
            'title',
          ],
        ),
        fallback: 'Makanan Prioritas',
      ),
      donorName: _textOf(
        _valueOf(
          map,
          [
            'donorName',
            'donor_name',
            'userName',
            'user_name',
          ],
        ),
        fallback: 'Donatur Prioritas',
      ),
      location: SmartGeoPoint(
        latitude: _doubleOf(
              _valueOf(
                map,
                [
                  'latitude',
                  'lat',
                ],
              ),
            ) ??
            0,
        longitude: _doubleOf(
              _valueOf(
                map,
                [
                  'longitude',
                  'lng',
                  'lon',
                ],
              ),
            ) ??
            0,
      ),
      foodCategory: FoodCategory.fromText(categorySource),
      foodCondition: FoodReadinessCondition.fromText(conditionSource),
      score: _doubleOf(
            _valueOf(
              map,
              [
                'score',
                'priorityScore',
                'priority_score',
              ],
            ),
          ) ??
          0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'foodId': foodId,
      'foodName': foodName,
      'donorName': donorName,
      'latitude': location.latitude,
      'longitude': location.longitude,
      'foodCategory': foodCategory.apiValue,
      'foodCondition': foodCondition.apiValue,
      'score': score,
    };
  }
}

class DirectionsRouteData {
  final PriorityDonorData? priorityDonor;
  final List<SmartGeoPoint> points;
  final String distanceText;
  final String durationText;
  final int distanceMeters;
  final int durationSeconds;
  final PickupTransportMode mode;
  final int networkLatencyMs;
  final int responseBytes;

  const DirectionsRouteData({
    required this.priorityDonor,
    required this.points,
    required this.distanceText,
    required this.durationText,
    required this.distanceMeters,
    required this.durationSeconds,
    required this.mode,
    required this.networkLatencyMs,
    required this.responseBytes,
  });

  const DirectionsRouteData.empty({
    this.mode = PickupTransportMode.driving,
  })  : priorityDonor = null,
        points = const <SmartGeoPoint>[],
        distanceText = '-',
        durationText = '-',
        distanceMeters = 0,
        durationSeconds = 0,
        networkLatencyMs = 0,
        responseBytes = 0;

  bool get hasRoute {
    return points.isNotEmpty;
  }

  factory DirectionsRouteData.fromBackendMap(Map<String, dynamic> map) {
    final Map<String, dynamic> source = _mapOf(map['data']).isNotEmpty
        ? _mapOf(map['data'])
        : Map<String, dynamic>.from(map);

    final Map<String, dynamic> priorityDonorMap = _mapOf(
      _valueOf(
        source,
        [
          'priorityDonor',
          'priority_donor',
          'donor',
        ],
      ),
    );

    final List<SmartGeoPoint> parsedPoints = _pointsOf(
      _valueOf(
        source,
        [
          'polylinePoints',
          'polyline_points',
          'routePoints',
          'route_points',
          'points',
        ],
      ),
    );

    return DirectionsRouteData(
      priorityDonor: priorityDonorMap.isEmpty
          ? null
          : PriorityDonorData.fromBackendMap(priorityDonorMap),
      points: parsedPoints,
      distanceText: _textOf(
        _valueOf(
          source,
          [
            'distanceText',
            'distance_text',
          ],
        ),
        fallback: '-',
      ),
      durationText: _textOf(
        _valueOf(
          source,
          [
            'durationText',
            'duration_text',
          ],
        ),
        fallback: '-',
      ),
      distanceMeters: _intOf(
            _valueOf(
              source,
              [
                'distanceMeters',
                'distance_meters',
              ],
            ),
          ) ??
          0,
      durationSeconds: _intOf(
            _valueOf(
              source,
              [
                'durationSeconds',
                'duration_seconds',
              ],
            ),
          ) ??
          0,
      mode: PickupTransportMode.fromApiValue(
        _valueOf(
          source,
          [
            'mode',
            'transportMode',
            'transport_mode',
          ],
        ),
      ),
      networkLatencyMs: _intOf(
            _valueOf(
              source,
              [
                'networkLatencyMs',
                'network_latency_ms',
              ],
            ),
          ) ??
          0,
      responseBytes: _intOf(
            _valueOf(
              source,
              [
                'responseBytes',
                'response_bytes',
              ],
            ),
          ) ??
          0,
    );
  }
}

bool _containsAny(String text, List<String> keywords) {
  return keywords.any(text.contains);
}

Object? _valueOf(
  Map<String, dynamic> data,
  List<String> keys,
) {
  for (final String key in keys) {
    if (data.containsKey(key)) {
      return data[key];
    }
  }

  return null;
}

Map<String, dynamic> _mapOf(Object? value) {
  if (value is Map<String, dynamic>) {
    return value;
  }

  if (value is Map) {
    return value.map(
      (key, mapValue) => MapEntry(
        key.toString(),
        mapValue,
      ),
    );
  }

  return <String, dynamic>{};
}

List<SmartGeoPoint> _pointsOf(Object? value) {
  if (value is! List) {
    return <SmartGeoPoint>[];
  }

  return value
      .map((item) {
        if (item is SmartGeoPoint) {
          return item;
        }

        final Map<String, dynamic> map = _mapOf(item);

        if (map.isEmpty) {
          return null;
        }

        final double? latitude = _doubleOf(
          _valueOf(
            map,
            [
              'latitude',
              'lat',
            ],
          ),
        );

        final double? longitude = _doubleOf(
          _valueOf(
            map,
            [
              'longitude',
              'lng',
              'lon',
            ],
          ),
        );

        if (latitude == null || longitude == null) {
          return null;
        }

        return SmartGeoPoint(
          latitude: latitude,
          longitude: longitude,
        );
      })
      .whereType<SmartGeoPoint>()
      .toList();
}

String _textOf(
  Object? value, {
  required String fallback,
}) {
  final String text = value?.toString().trim() ?? '';

  if (text.isEmpty || text == 'null') {
    return fallback;
  }

  return text;
}

String? _nullableTextOf(Object? value) {
  final String text = value?.toString().trim() ?? '';

  if (text.isEmpty || text == 'null') {
    return null;
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

DateTime? _dateTimeOf(Object? value) {
  if (value == null) {
    return null;
  }

  if (value is DateTime) {
    return value;
  }

  return DateTime.tryParse(value.toString());
}