import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../../core/config/api_config.dart';

class ImageOptimizationResult {
  final XFile source;
  final Uint8List bytes;
  final String fileName;
  final int originalBytes;
  final int estimatedUploadBytes;
  final double estimatedQuality;
  final bool isSimulation;

  const ImageOptimizationResult({
    required this.source,
    required this.bytes,
    required this.fileName,
    required this.originalBytes,
    required this.estimatedUploadBytes,
    required this.estimatedQuality,
    required this.isSimulation,
  });

  int get estimatedSavedBytes {
    return math.max(0, originalBytes - estimatedUploadBytes);
  }

  double get estimatedSavedPercent {
    if (originalBytes <= 0) return 0;
    return estimatedSavedBytes / originalBytes * 100;
  }

  String get originalSizeLabel {
    return FoodService.formatBytes(originalBytes);
  }

  String get estimatedUploadSizeLabel {
    return FoodService.formatBytes(estimatedUploadBytes);
  }

  String get estimatedSavedSizeLabel {
    return FoodService.formatBytes(estimatedSavedBytes);
  }
}

class ProofImageOptimizationResult {
  final XFile source;
  final Uint8List bytes;
  final String fileName;
  final int originalBytes;
  final int estimatedUploadBytes;
  final int targetMaxBytes;
  final double estimatedQuality;
  final bool isExtremeCompressionSimulation;

  const ProofImageOptimizationResult({
    required this.source,
    required this.bytes,
    required this.fileName,
    required this.originalBytes,
    required this.estimatedUploadBytes,
    required this.targetMaxBytes,
    required this.estimatedQuality,
    required this.isExtremeCompressionSimulation,
  });

  int get estimatedSavedBytes {
    return math.max(0, originalBytes - estimatedUploadBytes);
  }

  double get estimatedSavedPercent {
    if (originalBytes <= 0) return 0;
    return estimatedSavedBytes / originalBytes * 100;
  }

  double get compressionRatio {
    if (originalBytes <= 0) return 0;
    return estimatedUploadBytes / originalBytes;
  }

  String get originalSizeLabel {
    return FoodService.formatBytes(originalBytes);
  }

  String get estimatedUploadSizeLabel {
    return FoodService.formatBytes(estimatedUploadBytes);
  }

  String get targetMaxSizeLabel {
    return FoodService.formatBytes(targetMaxBytes);
  }

  String get estimatedSavedSizeLabel {
    return FoodService.formatBytes(estimatedSavedBytes);
  }
}

class FoodService {
  const FoodService._();

  static const Duration _timeout = Duration(seconds: 25);

  static String get baseUrl => ApiConfig.foodsUrl;

  static Future<ImageOptimizationResult> optimizeImageForUpload(
    XFile image,
  ) async {
    final Uint8List bytes = await image.readAsBytes();
    final int originalBytes = bytes.lengthInBytes;

    final int estimatedUploadBytes = _estimateCompressedImageSize(
      originalBytes,
    );

    final double estimatedQuality = _estimateImageQuality(originalBytes);

    return ImageOptimizationResult(
      source: image,
      bytes: bytes,
      fileName: _safeFileName(
        image.name,
        fallback: 'food_photo.jpg',
      ),
      originalBytes: originalBytes,
      estimatedUploadBytes: estimatedUploadBytes,
      estimatedQuality: estimatedQuality,
      isSimulation: true,
    );
  }

  static Future<ProofImageOptimizationResult> optimizePickupProofImage(
    XFile image,
  ) async {
    final Uint8List originalBytes = await image.readAsBytes();

    const int targetMaxBytes = 200 * 1024;

    final int estimatedUploadBytes = _estimateExtremeProofSize(
      originalBytes.lengthInBytes,
    );

    final double estimatedQuality = _estimateExtremeProofQuality(
      originalBytes.lengthInBytes,
    );

    /*
      MOCKUP LOGIC UNTUK ANALISIS BANDWIDTH:

      Bukti pengambilan dibuat lebih agresif daripada foto donasi.
      Target ukuran upload proof:
      - input kamera bisa 2MB - 5MB,
      - output ideal maksimal 150KB - 200KB,
      - strategi production:
        1. resize sisi terpanjang ke 640px - 800px,
        2. ubah JPEG quality ke 25 - 40,
        3. ulangi kompresi sampai ukuran <= 200KB,
        4. upload bytes hasil kompresi ke server.

      Saat ini bytes yang dikirim masih dari image_picker agar project
      tidak menambah dependency berat. Metadata simulasi tetap dikirim agar
      bisa dipakai untuk bahan analisis jaringan:
      - proofOriginalBytes
      - proofEstimatedUploadBytes
      - proofTargetMaxBytes
      - proofEstimatedQuality
      - proofCompressionRatio
      - proofCompressionMode = extreme_simulation_150kb_200kb
    */

    return ProofImageOptimizationResult(
      source: image,
      bytes: originalBytes,
      fileName: _safeFileName(
        'proof_${image.name}',
        fallback: 'proof_pickup_photo.jpg',
      ),
      originalBytes: originalBytes.lengthInBytes,
      estimatedUploadBytes: estimatedUploadBytes,
      targetMaxBytes: targetMaxBytes,
      estimatedQuality: estimatedQuality,
      isExtremeCompressionSimulation: true,
    );
  }

  static Future<Map<String, dynamic>> createFood({
    required String token,
    required String foodName,
    required String description,
    required int quantity,
    required double latitude,
    required double longitude,
    required String address,
    required String expiredAt,
    required XFile image,
    ImageOptimizationResult? optimizedImage,
    String? category,
    bool? isHalal,
    String? condition,
  }) async {
    try {
      final ImageOptimizationResult optimization =
          optimizedImage ?? await optimizeImageForUpload(image);

      final http.MultipartRequest request = http.MultipartRequest(
        'POST',
        Uri.parse(baseUrl),
      );

      request.headers.addAll(
        ApiConfig.authHeaders(token),
      );

      request.fields['foodName'] = foodName.trim();
      request.fields['food_name'] = foodName.trim();
      request.fields['description'] = description.trim();
      request.fields['quantity'] = quantity.toString();
      request.fields['latitude'] = latitude.toString();
      request.fields['longitude'] = longitude.toString();
      request.fields['address'] = address.trim();
      request.fields['expiredAt'] = expiredAt;
      request.fields['expired_at'] = expiredAt;

      if (category != null && category.trim().isNotEmpty) {
        request.fields['category'] = category.trim();
        request.fields['foodCategory'] = category.trim();
        request.fields['food_category'] = category.trim();
      }

      if (isHalal != null) {
        request.fields['isHalal'] = isHalal.toString();
        request.fields['is_halal'] = isHalal.toString();
        request.fields['halalStatus'] = isHalal ? 'halal' : 'non-halal';
        request.fields['halal_status'] = isHalal ? 'halal' : 'non-halal';
      }

      if (condition != null && condition.trim().isNotEmpty) {
        request.fields['condition'] = condition.trim();
        request.fields['foodCondition'] = condition.trim();
        request.fields['food_condition'] = condition.trim();
      }

      request.fields['imageOriginalBytes'] =
          optimization.originalBytes.toString();
      request.fields['image_original_bytes'] =
          optimization.originalBytes.toString();
      request.fields['imageEstimatedUploadBytes'] =
          optimization.estimatedUploadBytes.toString();
      request.fields['image_estimated_upload_bytes'] =
          optimization.estimatedUploadBytes.toString();
      request.fields['imageEstimatedQuality'] =
          optimization.estimatedQuality.toStringAsFixed(2);
      request.fields['image_estimated_quality'] =
          optimization.estimatedQuality.toStringAsFixed(2);
      request.fields['imageOptimizationMode'] = 'simulation';
      request.fields['image_optimization_mode'] = 'simulation';

      request.files.add(
        http.MultipartFile.fromBytes(
          'photo',
          optimization.bytes,
          filename: optimization.fileName,
        ),
      );

      final http.StreamedResponse streamedResponse =
          await request.send().timeout(_timeout);

      final http.Response response =
          await http.Response.fromStream(streamedResponse);

      debugPrint('CREATE FOOD STATUS: ${response.statusCode}');
      debugPrint('CREATE FOOD BODY: ${response.body}');

      return _normalizeResponse(response);
    } on TimeoutException {
      return _failure('Koneksi timeout saat membuat postingan makanan.');
    } catch (error) {
      return _failure('Tidak dapat membuat postingan makanan: $error');
    }
  }

  static Future<Map<String, dynamic>> updateFood({
    required String token,
    required int foodId,
    required String foodName,
    required String description,
    required int quantity,
    required double latitude,
    required double longitude,
    required String address,
    required String expiredAt,
    XFile? image,
    ImageOptimizationResult? optimizedImage,
    String? category,
    bool? isHalal,
    String? condition,
  }) async {
    try {
      final http.MultipartRequest request = http.MultipartRequest(
        'PUT',
        Uri.parse('$baseUrl/$foodId'),
      );

      request.headers.addAll(
        ApiConfig.authHeaders(token),
      );

      request.fields['foodName'] = foodName.trim();
      request.fields['food_name'] = foodName.trim();
      request.fields['description'] = description.trim();
      request.fields['quantity'] = quantity.toString();
      request.fields['latitude'] = latitude.toString();
      request.fields['longitude'] = longitude.toString();
      request.fields['address'] = address.trim();
      request.fields['expiredAt'] = expiredAt;
      request.fields['expired_at'] = expiredAt;

      if (category != null && category.trim().isNotEmpty) {
        request.fields['category'] = category.trim();
        request.fields['foodCategory'] = category.trim();
        request.fields['food_category'] = category.trim();
      }

      if (isHalal != null) {
        request.fields['isHalal'] = isHalal.toString();
        request.fields['is_halal'] = isHalal.toString();
        request.fields['halalStatus'] = isHalal ? 'halal' : 'non-halal';
        request.fields['halal_status'] = isHalal ? 'halal' : 'non-halal';
      }

      if (condition != null && condition.trim().isNotEmpty) {
        request.fields['condition'] = condition.trim();
        request.fields['foodCondition'] = condition.trim();
        request.fields['food_condition'] = condition.trim();
      }

      if (image != null) {
        final ImageOptimizationResult optimization =
            optimizedImage ?? await optimizeImageForUpload(image);

        request.fields['imageOriginalBytes'] =
            optimization.originalBytes.toString();
        request.fields['image_original_bytes'] =
            optimization.originalBytes.toString();
        request.fields['imageEstimatedUploadBytes'] =
            optimization.estimatedUploadBytes.toString();
        request.fields['image_estimated_upload_bytes'] =
            optimization.estimatedUploadBytes.toString();
        request.fields['imageEstimatedQuality'] =
            optimization.estimatedQuality.toStringAsFixed(2);
        request.fields['image_estimated_quality'] =
            optimization.estimatedQuality.toStringAsFixed(2);
        request.fields['imageOptimizationMode'] = 'simulation';
        request.fields['image_optimization_mode'] = 'simulation';

        request.files.add(
          http.MultipartFile.fromBytes(
            'photo',
            optimization.bytes,
            filename: optimization.fileName,
          ),
        );
      }

      final http.StreamedResponse streamedResponse =
          await request.send().timeout(_timeout);

      final http.Response response =
          await http.Response.fromStream(streamedResponse);

      debugPrint('UPDATE FOOD STATUS: ${response.statusCode}');
      debugPrint('UPDATE FOOD BODY: ${response.body}');

      return _normalizeResponse(response);
    } on TimeoutException {
      return _failure('Koneksi timeout saat memperbarui postingan.');
    } catch (error) {
      return _failure('Tidak dapat memperbarui postingan: $error');
    }
  }

  static Future<Map<String, dynamic>> completePickupWithProof({
    required String token,
    required int foodId,
    required XFile proofImage,
    ProofImageOptimizationResult? optimizedProof,
  }) async {
    try {
      final ProofImageOptimizationResult proofOptimization =
          optimizedProof ?? await optimizePickupProofImage(proofImage);

      final http.MultipartRequest request = http.MultipartRequest(
        'PUT',
        Uri.parse('$baseUrl/$foodId/confirm-proof'),
      );

      request.headers.addAll(
        ApiConfig.authHeaders(token),
      );

      request.fields['proofOriginalBytes'] =
          proofOptimization.originalBytes.toString();
      request.fields['proof_original_bytes'] =
          proofOptimization.originalBytes.toString();
      request.fields['proofEstimatedUploadBytes'] =
          proofOptimization.estimatedUploadBytes.toString();
      request.fields['proof_estimated_upload_bytes'] =
          proofOptimization.estimatedUploadBytes.toString();
      request.fields['proofTargetMaxBytes'] =
          proofOptimization.targetMaxBytes.toString();
      request.fields['proof_target_max_bytes'] =
          proofOptimization.targetMaxBytes.toString();
      request.fields['proofEstimatedQuality'] =
          proofOptimization.estimatedQuality.toStringAsFixed(2);
      request.fields['proof_estimated_quality'] =
          proofOptimization.estimatedQuality.toStringAsFixed(2);
      request.fields['proofCompressionRatio'] =
          proofOptimization.compressionRatio.toStringAsFixed(4);
      request.fields['proof_compression_ratio'] =
          proofOptimization.compressionRatio.toStringAsFixed(4);
      request.fields['proofCompressionMode'] =
          'extreme_simulation_150kb_200kb';
      request.fields['proof_compression_mode'] =
          'extreme_simulation_150kb_200kb';
      request.fields['proofPrivacyNote'] =
          'Tidak perlu foto wajah. Cukup foto makanan atau tangan saat menerima makanan.';
      request.fields['proof_privacy_note'] =
          'Tidak perlu foto wajah. Cukup foto makanan atau tangan saat menerima makanan.';

      request.files.add(
        http.MultipartFile.fromBytes(
          'proofPhoto',
          proofOptimization.bytes,
          filename: proofOptimization.fileName,
        ),
      );

      final http.StreamedResponse streamedResponse =
          await request.send().timeout(_timeout);

      final http.Response response =
          await http.Response.fromStream(streamedResponse);

      final Map<String, dynamic> proofResponse = _normalizeResponse(response);

      if (proofResponse['success'] == true) {
        return proofResponse;
      }

      /*
        Fallback untuk backend lama:
        Jika endpoint /confirm-proof belum ada, aplikasi tetap bisa menutup
        flow menggunakan endpoint lama /confirm. Metadata kompresi tetap ada
        di UI untuk kebutuhan analisis bandwidth.
      */
      final Map<String, dynamic> fallbackConfirm = await _send(
        () => http.put(
          Uri.parse('$baseUrl/$foodId/confirm'),
          headers: ApiConfig.authHeaders(token),
        ),
      );

      return {
        ...fallbackConfirm,
        'proofUploadMode': 'fallback_confirm_without_proof_endpoint',
        'proofOriginalBytes': proofOptimization.originalBytes,
        'proofEstimatedUploadBytes': proofOptimization.estimatedUploadBytes,
        'proofTargetMaxBytes': proofOptimization.targetMaxBytes,
      };
    } on TimeoutException {
      return _failure('Koneksi timeout saat mengunggah bukti pengambilan.');
    } catch (error) {
      return _failure('Tidak dapat mengunggah bukti pengambilan: $error');
    }
  }

  static Future<List<dynamic>> getFoods(String token) async {
    final Map<String, dynamic> response = await _send(
      () => http.get(
        Uri.parse(baseUrl),
        headers: ApiConfig.authHeaders(token),
      ),
    );

    if (response['success'] == false) {
      throw Exception(
        response['message']?.toString() ?? 'Gagal memuat data makanan.',
      );
    }

    final Object? data = response['data'];

    if (data is List) {
      return data;
    }

    if (data is Map && data['foods'] is List) {
      return data['foods'] as List;
    }

    if (response['foods'] is List) {
      return response['foods'] as List;
    }

    if (response['items'] is List) {
      return response['items'] as List;
    }

    return [];
  }

  static Future<void> deleteFood({
    required String token,
    required int foodId,
  }) async {
    final Map<String, dynamic> response = await _send(
      () => http.delete(
        Uri.parse('$baseUrl/$foodId'),
        headers: ApiConfig.authHeaders(token),
      ),
    );

    if (response['success'] == false) {
      throw Exception(
        response['message']?.toString() ?? 'Gagal menghapus postingan.',
      );
    }
  }

  static Future<Map<String, dynamic>> getHistory(String token) async {
    final Map<String, dynamic> response = await _send(
      () => http.get(
        Uri.parse('$baseUrl/history'),
        headers: ApiConfig.jsonHeaders(token: token),
      ),
    );

    if (response['success'] == false) {
      throw Exception(
        response['message']?.toString() ?? 'Gagal memuat riwayat.',
      );
    }

    final Object? data = response['data'];

    if (data is Map<String, dynamic>) {
      return data;
    }

    if (data is Map) {
      return data.map(
        (key, value) => MapEntry(key.toString(), value),
      );
    }

    return {
      'myDonation': [],
      'myClaim': [],
    };
  }

  static Future<Map<String, dynamic>> pickFood({
    required String token,
    required int foodId,
    required int quantity,
  }) async {
    return _send(
      () => http.put(
        Uri.parse('$baseUrl/$foodId/pick?quantity=$quantity'),
        headers: ApiConfig.authHeaders(token),
      ),
    );
  }

  static Future<void> cancelDonation({
    required String token,
    required int foodId,
  }) async {
    final Map<String, dynamic> response = await _send(
      () => http.put(
        Uri.parse('$baseUrl/$foodId/cancel-donation'),
        headers: ApiConfig.authHeaders(token),
      ),
    );

    if (response['success'] == false) {
      throw Exception(
        response['message']?.toString() ?? 'Gagal membatalkan donasi.',
      );
    }
  }

  static Future<void> confirmPickup({
    required String token,
    required int foodId,
  }) async {
    final Map<String, dynamic> response = await _send(
      () => http.put(
        Uri.parse('$baseUrl/$foodId/confirm'),
        headers: ApiConfig.authHeaders(token),
      ),
    );

    if (response['success'] == false) {
      throw Exception(
        response['message']?.toString() ?? 'Gagal konfirmasi pengambilan.',
      );
    }
  }

  static Future<void> cancelPickup({
    required String token,
    required int foodId,
  }) async {
    final Map<String, dynamic> response = await _send(
      () => http.put(
        Uri.parse('$baseUrl/$foodId/cancel'),
        headers: ApiConfig.authHeaders(token),
      ),
    );

    if (response['success'] == false) {
      throw Exception(
        response['message']?.toString() ?? 'Gagal membatalkan pengambilan.',
      );
    }
  }

  static Future<Map<String, dynamic>> getFoodDetail({
    required String token,
    required int foodId,
  }) async {
    return _send(
      () => http.get(
        Uri.parse('$baseUrl/$foodId'),
        headers: ApiConfig.authHeaders(token),
      ),
    );
  }



  static String messageOf(
    Map<String, dynamic> response, {
    required String fallback,
  }) {
    final String message = response['message']?.toString().trim() ?? '';

    if (message.isNotEmpty && message != 'null') {
      return message;
    }

    final Object? data = response['data'];

    if (data is Map && data['message'] != null) {
      final String nestedMessage = data['message'].toString().trim();

      if (nestedMessage.isNotEmpty && nestedMessage != 'null') {
        return nestedMessage;
      }
    }

    return fallback;
  }

  static String formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';

    const int kb = 1024;
    const int mb = kb * 1024;

    if (bytes >= mb) {
      return '${(bytes / mb).toStringAsFixed(2)} MB';
    }

    if (bytes >= kb) {
      return '${(bytes / kb).toStringAsFixed(1)} KB';
    }

    return '$bytes B';
  }

  static Future<Map<String, dynamic>> _send(
    Future<http.Response> Function() request,
  ) async {
    try {
      final http.Response response = await request().timeout(_timeout);

      debugPrint('FOOD SERVICE STATUS: ${response.statusCode}');
      debugPrint('FOOD SERVICE BODY: ${response.body}');

      return _normalizeResponse(response);
    } on TimeoutException {
      return _failure('Koneksi timeout. Periksa jaringan lalu coba lagi.');
    } on FormatException {
      return _failure('Format respons server tidak valid.');
    } catch (error) {
      return _failure('Tidak dapat terhubung ke backend: $error');
    }
  }

  static Map<String, dynamic> _normalizeResponse(http.Response response) {
    final Map<String, dynamic> body = _decodeJsonMap(response.body);
    final bool statusSuccess =
        response.statusCode >= 200 && response.statusCode < 300;

    final Map<String, dynamic> normalized = {
      ...body,
      'statusCode': response.statusCode,
    };

    normalized.putIfAbsent('success', () => statusSuccess);

    if (statusSuccess) {
      normalized.putIfAbsent('message', () => 'OK');
      return normalized;
    }

    normalized['success'] = false;
    normalized.putIfAbsent(
      'message',
      () => 'Server error (${response.statusCode}).',
    );

    return normalized;
  }

  static Map<String, dynamic> _decodeJsonMap(String rawBody) {
    final String body = rawBody.trim();

    if (body.isEmpty) {
      return <String, dynamic>{};
    }

    final Object? decoded = jsonDecode(body);

    if (decoded is Map<String, dynamic>) {
      return decoded;
    }

    if (decoded is Map) {
      return decoded.map(
        (key, value) => MapEntry(key.toString(), value),
      );
    }

    return {
      'data': decoded,
    };
  }

  static Map<String, dynamic> _failure(String message) {
    return {
      'success': false,
      'message': message,
    };
  }

  static String _safeFileName(
    String rawName, {
    required String fallback,
  }) {
    final String trimmedName = rawName.trim();

    if (trimmedName.isEmpty || trimmedName == 'null') {
      return fallback;
    }

    return trimmedName.replaceAll(RegExp(r'\s+'), '_');
  }

  static int _estimateCompressedImageSize(int originalBytes) {
    const int kb = 1024;
    const int mb = kb * 1024;

    if (originalBytes <= 350 * kb) {
      return originalBytes;
    }

    if (originalBytes <= 1 * mb) {
      return (originalBytes * 0.72).round();
    }

    if (originalBytes <= 3 * mb) {
      return (originalBytes * 0.55).round();
    }

    return (originalBytes * 0.42).round();
  }

  static double _estimateImageQuality(int originalBytes) {
    const int kb = 1024;
    const int mb = kb * 1024;

    if (originalBytes <= 350 * kb) {
      return 1.00;
    }

    if (originalBytes <= 1 * mb) {
      return 0.82;
    }

    if (originalBytes <= 3 * mb) {
      return 0.72;
    }

    return 0.62;
  }

  static int _estimateExtremeProofSize(int originalBytes) {
    const int kb = 1024;
    const int targetMin = 150 * kb;
    const int targetMax = 200 * kb;

    if (originalBytes <= targetMax) {
      return originalBytes;
    }

    if (originalBytes <= 1 * 1024 * kb) {
      return math.max(targetMin, (originalBytes * 0.22).round());
    }

    if (originalBytes <= 5 * 1024 * kb) {
      return 180 * kb;
    }

    return targetMax;
  }

  static double _estimateExtremeProofQuality(int originalBytes) {
    const int kb = 1024;
    const int mb = kb * 1024;

    if (originalBytes <= 200 * kb) {
      return 1.00;
    }

    if (originalBytes <= 1 * mb) {
      return 0.42;
    }

    if (originalBytes <= 5 * mb) {
      return 0.30;
    }

    return 0.24;
  }
}