import '../config/api_config.dart';

class FoodMapper {
  const FoodMapper._();

  static Object? valueOf(
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

  static Map<String, dynamic> mapOf(Object? value) {
    if (value is Map<String, dynamic>) {
      return value;
    }

    if (value is Map) {
      return value.map(
        (key, mapValue) => MapEntry(key.toString(), mapValue),
      );
    }

    return <String, dynamic>{};
  }

  static List<Map<String, dynamic>> listOf(Object? value) {
    if (value is List) {
      return value
          .map(mapOf)
          .where((item) => item.isNotEmpty)
          .toList();
    }

    if (value is Map) {
      final Map<String, dynamic> mappedValue = mapOf(value);

      for (final String key in [
        'data',
        'items',
        'foods',
        'users',
        'myDonation',
        'myClaim',
        'donations',
        'claims',
      ]) {
        final Object? nestedValue = mappedValue[key];

        if (nestedValue is List) {
          return listOf(nestedValue);
        }
      }

      if (mappedValue.isNotEmpty) {
        return [mappedValue];
      }
    }

    return <Map<String, dynamic>>[];
  }

  static String textOf(
    Object? value, {
    required String fallback,
  }) {
    final String text = value?.toString().trim() ?? '';

    if (text.isEmpty || text == 'null') {
      return fallback;
    }

    return text;
  }

  static int intOf(
    Object? value, {
    required int fallback,
  }) {
    final int? parsedValue = nullableIntOf(value);

    if (parsedValue == null) {
      return fallback;
    }

    return parsedValue;
  }

  static int? nullableIntOf(Object? value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();

    return int.tryParse(value.toString());
  }

  static double doubleOf(
    Object? value, {
    required double fallback,
  }) {
    final double? parsedValue = nullableDoubleOf(value);

    if (parsedValue == null) {
      return fallback;
    }

    return parsedValue;
  }

  static double? nullableDoubleOf(Object? value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is num) return value.toDouble();

    return double.tryParse(value.toString());
  }

  static bool boolOf(
    Object? value, {
    required bool fallback,
  }) {
    if (value == null) return fallback;
    if (value is bool) return value;

    final String text = value.toString().trim().toLowerCase();

    if (text.isEmpty || text == 'null') {
      return fallback;
    }

    if ([
      'true',
      '1',
      'yes',
      'ya',
      'y',
      'halal',
      'active',
      'aktif',
    ].contains(text)) {
      return true;
    }

    if ([
      'false',
      '0',
      'no',
      'tidak',
      'n',
      'non-halal',
      'non halal',
      'inactive',
      'nonaktif',
    ].contains(text)) {
      return false;
    }

    return fallback;
  }

  static DateTime? dateTimeOf(Object? value) {
    final String rawValue = value?.toString().trim() ?? '';

    if (rawValue.isEmpty || rawValue == 'null') {
      return null;
    }

    DateTime? parsed = DateTime.tryParse(rawValue);
    if (parsed == null) return null;

    final bool hasOffset = rawValue.contains('Z') ||
        RegExp(r'[-+]\d{2}:?\d{2}$').hasMatch(rawValue);

    if (!hasOffset) {
      if (parsed.isUtc) {
        parsed = DateTime(
          parsed.year,
          parsed.month,
          parsed.day,
          parsed.hour,
          parsed.minute,
          parsed.second,
          parsed.millisecond,
          parsed.microsecond,
        );
      }
    } else {
      parsed = parsed.toLocal();
    }

    // Koreksi otomatis jika selisih waktu mendekati offset zona waktu lokal
    // Hal ini menangani inkonsistensi UTC/Lokal pada database
    final DateTime now = DateTime.now();
    final Duration localOffset = now.timeZoneOffset;
    if (localOffset.inMinutes > 0) {
      final Duration diff = now.difference(parsed);
      final int offsetMinutes = localOffset.inMinutes;
      if (diff.inMinutes >= offsetMinutes - 45 &&
          diff.inMinutes <= offsetMinutes + 45) {
        parsed = parsed.add(localOffset);
      }
    }

    return parsed;
  }

  static String dateTimeLabel(
    Object? value, {
    String fallback = '-',
  }) {
    final DateTime? dateTime = dateTimeOf(value);

    if (dateTime == null) {
      final String rawText = value?.toString().trim() ?? '';

      if (rawText.isEmpty || rawText == 'null') {
        return fallback;
      }

      return rawText;
    }

    return '${_twoDigits(dateTime.day)}/'
        '${_twoDigits(dateTime.month)}/'
        '${dateTime.year} '
        '${_twoDigits(dateTime.hour)}:'
        '${_twoDigits(dateTime.minute)}';
  }

  static String dateLabel(
    Object? value, {
    String fallback = '-',
  }) {
    final DateTime? dateTime = dateTimeOf(value);

    if (dateTime == null) {
      final String rawText = value?.toString().trim() ?? '';

      if (rawText.isEmpty || rawText == 'null') {
        return fallback;
      }

      return rawText;
    }

    return '${_twoDigits(dateTime.day)}/'
        '${_twoDigits(dateTime.month)}/'
        '${dateTime.year}';
  }

  static String timeLabel(
    Object? value, {
    String fallback = '-',
  }) {
    final DateTime? dateTime = dateTimeOf(value);

    if (dateTime == null) {
      return fallback;
    }

    return '${_twoDigits(dateTime.hour)}:${_twoDigits(dateTime.minute)}';
  }

  static String resolvePhotoUrl(Object? rawValue) {
    final String rawUrl = rawValue?.toString().trim() ?? '';

    if (rawUrl.isEmpty || rawUrl == 'null') {
      return '';
    }

    final Uri? parsedUrl = Uri.tryParse(rawUrl);

    if (parsedUrl != null && parsedUrl.hasScheme) {
      return rawUrl;
    }

    return ApiConfig.resolveMediaUrl(rawUrl);
  }

  static String? nullablePhotoUrl(Object? rawValue) {
    final String resolvedUrl = resolvePhotoUrl(rawValue);

    if (resolvedUrl.isEmpty) {
      return null;
    }

    return resolvedUrl;
  }

  static String statusLabel(Object? statusValue) {
    final String status = textOf(
      statusValue,
      fallback: 'POSTED',
    ).toUpperCase();

    switch (status) {
      case 'AVAILABLE':
      case 'POSTED':
        return 'Tersedia';
      case 'ON_THE_WAY':
        return 'Sedang Diambil test';
      case 'PICKED_UP':
      case 'COMPLETED':
      case 'CLAIMED':
        return 'Selesai';
      case 'CANCELED':
      case 'CANCELLED':
        return 'Dibatalkan';
      case 'EXPIRED':
        return 'Kadaluarsa';
      default:
        return status
            .split('_')
            .where((word) => word.trim().isNotEmpty)
            .map((word) {
          final String lower = word.toLowerCase();

          return '${lower[0].toUpperCase()}${lower.substring(1)}';
        }).join(' ');
    }
  }

  static String coordinateLabel({
    required Object? latitude,
    required Object? longitude,
    String fallback = 'Koordinat belum tersedia',
  }) {
    final double? parsedLatitude = nullableDoubleOf(latitude);
    final double? parsedLongitude = nullableDoubleOf(longitude);

    if (parsedLatitude == null || parsedLongitude == null) {
      return fallback;
    }

    return '${parsedLatitude.toStringAsFixed(6)}, '
        '${parsedLongitude.toStringAsFixed(6)}';
  }

  static String distanceLabelFromMeters(
    double? distanceMeters, {
    String fallback = '-',
  }) {
    if (distanceMeters == null || !distanceMeters.isFinite) {
      return fallback;
    }

    if (distanceMeters >= 1000) {
      return '${(distanceMeters / 1000).toStringAsFixed(1)} km';
    }

    return '${distanceMeters.round()} m';
  }

  static String quantityLabel(
    Object? value, {
    String fallback = '0 porsi',
  }) {
    final int? quantity = nullableIntOf(value);

    if (quantity == null) {
      return fallback;
    }

    return '$quantity porsi';
  }

  static String _twoDigits(int value) {
    return value.toString().padLeft(2, '0');
  }
}

class FoodRecord {
  final Map<String, dynamic> data;

  const FoodRecord(this.data);

  int? get id {
    return FoodMapper.nullableIntOf(
      FoodMapper.valueOf(
        data,
        [
          'id',
          'food_id',
          'foodId',
        ],
      ),
    );
  }

  String get name {
    return FoodMapper.textOf(
      FoodMapper.valueOf(
        data,
        [
          'food_name',
          'foodName',
          'name',
          'title',
        ],
      ),
      fallback: 'Makanan',
    );
  }

  String get description {
    return FoodMapper.textOf(
      FoodMapper.valueOf(
        data,
        [
          'description',
          'desc',
          'note',
          'notes',
        ],
      ),
      fallback: 'Tidak ada deskripsi.',
    );
  }

  int get quantity {
    return FoodMapper.intOf(
      FoodMapper.valueOf(
        data,
        [
          'quantity',
          'qty',
          'stock',
          'portion',
          'portions',
        ],
      ),
      fallback: 0,
    );
  }

  String get status {
    return FoodMapper.textOf(
      FoodMapper.valueOf(
        data,
        [
          'status',
          'food_status',
          'foodStatus',
        ],
      ),
      fallback: 'POSTED',
    ).toUpperCase();
  }

  String get statusLabel {
    return FoodMapper.statusLabel(status);
  }

  String? get photoUrl {
    return FoodMapper.nullablePhotoUrl(
      FoodMapper.valueOf(
        data,
        [
          'photo_url',
          'photoUrl',
          'photo',
          'image',
          'image_url',
          'imageUrl',
          'thumbnail',
        ],
      ),
    );
  }

  String get address {
    return FoodMapper.textOf(
      FoodMapper.valueOf(
        data,
        [
          'address',
          'location',
          'pickup_address',
          'pickupAddress',
        ],
      ),
      fallback: 'Alamat belum tersedia.',
    );
  }

  double? get latitude {
    return FoodMapper.nullableDoubleOf(
      FoodMapper.valueOf(
        data,
        [
          'latitude',
          'lat',
        ],
      ),
    );
  }

  double? get longitude {
    return FoodMapper.nullableDoubleOf(
      FoodMapper.valueOf(
        data,
        [
          'longitude',
          'lng',
          'lon',
        ],
      ),
    );
  }

  String get coordinateLabel {
    return FoodMapper.coordinateLabel(
      latitude: latitude,
      longitude: longitude,
    );
  }

  String get expiredAtLabel {
    return FoodMapper.dateTimeLabel(
      FoodMapper.valueOf(
        data,
        [
          'expired_at',
          'expiredAt',
          'expires_at',
          'expiresAt',
          'expired',
        ],
      ),
      fallback: '-',
    );
  }

  DateTime? get expiredAt {
    return FoodMapper.dateTimeOf(
      FoodMapper.valueOf(
        data,
        [
          'expired_at',
          'expiredAt',
          'expires_at',
          'expiresAt',
          'expired',
        ],
      ),
    );
  }

  String get category {
    return FoodMapper.textOf(
      FoodMapper.valueOf(
        data,
        [
          'category',
          'foodCategory',
          'food_category',
          'categoryName',
        ],
      ),
      fallback: 'Kategori belum tersedia',
    );
  }

  bool get isHalal {
    return FoodMapper.boolOf(
      FoodMapper.valueOf(
        data,
        [
          'is_halal',
          'isHalal',
          'halal',
          'halalStatus',
          'halal_status',
        ],
      ),
      fallback: true,
    );
  }

  String get halalLabel {
    return isHalal ? 'Halal' : 'Non-Halal';
  }

  String get condition {
    return FoodMapper.textOf(
      FoodMapper.valueOf(
        data,
        [
          'condition',
          'foodCondition',
          'food_condition',
          'quality',
          'readiness',
        ],
      ),
      fallback: 'tahan lama segar',
    );
  }

  int? get userId {
    return FoodMapper.nullableIntOf(
      FoodMapper.valueOf(
        data,
        [
          'user_id',
          'userId',
          'owner_id',
          'ownerId',
        ],
      ),
    );
  }

  int? get claimedBy {
    return FoodMapper.nullableIntOf(
      FoodMapper.valueOf(
        data,
        [
          'claimed_by',
          'claimedBy',
          'consumer_id',
          'consumerId',
          'picked_by',
          'pickedBy',
        ],
      ),
    );
  }

  bool get isEditable {
    return status == 'POSTED' || status == 'AVAILABLE';
  }

  bool get isDeleteAllowed {
    return status == 'POSTED' ||
        status == 'AVAILABLE' ||
        status == 'CANCELED' ||
        status == 'CANCELLED' ||
        status == 'EXPIRED';
  }

  bool get isAvailable {
    return status == 'POSTED' || status == 'AVAILABLE';
  }

  bool get isOnTheWay {
    return status == 'ON_THE_WAY';
  }

  bool get isCompleted {
    return status == 'PICKED_UP' ||
        status == 'COMPLETED' ||
        status == 'CLAIMED';
  }

  bool get isCanceled {
    return status == 'CANCELED' || status == 'CANCELLED';
  }

  Map<String, dynamic> toMap() {
    return Map<String, dynamic>.from(data);
  }
}