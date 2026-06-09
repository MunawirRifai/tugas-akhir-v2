import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../core/config/api_config.dart';
import 'auth_service.dart';

class NotificationService {
  const NotificationService._();

  static const Duration _timeout = Duration(seconds: 25);

  static String get baseUrl => '${ApiConfig.baseUrl}/api/v1/notifications';

  static Future<List<Map<String, dynamic>>> getNotifications({
    required String token,
  }) async {
    final Map<String, dynamic> response = await _send(
      () => http.get(
        Uri.parse(baseUrl),
        headers: ApiConfig.jsonHeaders(token: token),
      ),
    );

    if (response['success'] == false) {
      throw Exception(
        response['message']?.toString() ?? 'Gagal memuat notifikasi.',
      );
    }

    return AuthService.listOf(response['data']);
  }

  static Future<void> markAsRead({
    required String token,
    required String notificationId,
  }) async {
    final Map<String, dynamic> response = await _send(
      () => http.put(
        Uri.parse('$baseUrl/$notificationId/read'),
        headers: ApiConfig.jsonHeaders(token: token),
      ),
    );

    if (response['success'] == false) {
      throw Exception(
        response['message']?.toString() ?? 'Gagal menandai notifikasi.',
      );
    }
  }

  static Future<void> markAllAsRead({required String token}) async {
    final Map<String, dynamic> response = await _send(
      () => http.put(
        Uri.parse('$baseUrl/read-all'),
        headers: ApiConfig.jsonHeaders(token: token),
      ),
    );

    if (response['success'] == false) {
      throw Exception(
        response['message']?.toString() ?? 'Gagal menandai notifikasi.',
      );
    }
  }

  static Future<Map<String, dynamic>> _send(
    Future<http.Response> Function() request,
  ) async {
    try {
      final http.Response response = await request().timeout(_timeout);

      debugPrint('NOTIFICATION SERVICE STATUS: ${response.statusCode}');
      debugPrint('NOTIFICATION SERVICE BODY: ${response.body}');

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
      return decoded.map((key, value) => MapEntry(key.toString(), value));
    }

    return {'data': decoded};
  }

  static Map<String, dynamic> _failure(String message) {
    return {'success': false, 'message': message};
  }
}
