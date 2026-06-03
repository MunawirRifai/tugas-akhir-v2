import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../../core/config/api_config.dart';

class AuthService {
  const AuthService._();

  static const Duration _timeout = Duration(seconds: 25);

  static String get baseUrl => ApiConfig.authUrl;

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    return _send(
      () => http.post(
        Uri.parse('$baseUrl/login'),
        headers: ApiConfig.jsonHeaders(),
        body: jsonEncode({
          'email': email.trim(),
          'password': password,
        }),
      ),
    );
  }

  static Future<Map<String, dynamic>> register({
    required String fullName,
    required String email,
    required String phone,
    required String password,
  }) async {
    return _send(
      () => http.post(
        Uri.parse('$baseUrl/register'),
        headers: ApiConfig.jsonHeaders(),
        body: jsonEncode({
          'fullName': fullName.trim(),
          'full_name': fullName.trim(),
          'name': fullName.trim(),
          'email': email.trim(),
          'phone': phone.trim(),
          'phone_number': phone.trim(),
          'password': password,
        }),
      ),
    );
  }

  static Future<Map<String, dynamic>> verifyEmail({
    required String email,
    required String otp,
  }) async {
    return _send(
      () => http.post(
        Uri.parse('$baseUrl/verify'),
        headers: ApiConfig.jsonHeaders(),
        body: jsonEncode({
          'email': email.trim(),
          'otp': otp.trim(),
          'code': otp.trim(),
          'verificationCode': otp.trim(),
        }),
      ),
    );
  }

  static Future<Map<String, dynamic>> verifyOtp({
    required String email,
    required String otp,
  }) {
    return verifyEmail(
      email: email,
      otp: otp,
    );
  }

  static Future<Map<String, dynamic>> resendVerification({
    required String email,
  }) async {
    return _send(
      () => http.post(
        Uri.parse('$baseUrl/resend-verification'),
        headers: ApiConfig.jsonHeaders(),
        body: jsonEncode({
          'email': email.trim(),
        }),
      ),
    );
  }

  static Future<Map<String, dynamic>> forgotPassword({
    required String email,
  }) async {
    return _send(
      () => http.post(
        Uri.parse('$baseUrl/forgot-password'),
        headers: ApiConfig.jsonHeaders(),
        body: jsonEncode({
          'email': email.trim(),
        }),
      ),
    );
  }

  static Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    return _send(
      () => http.post(
        Uri.parse('$baseUrl/reset-password'),
        headers: ApiConfig.jsonHeaders(),
        body: jsonEncode({
          'email': email.trim(),
          'otp': otp.trim(),
          'code': otp.trim(),
          'password': newPassword,
          'newPassword': newPassword,
          'new_password': newPassword,
        }),
      ),
    );
  }

  static Future<Map<String, dynamic>> logout({
    required String token,
  }) async {
    return _send(
      () => http.post(
        Uri.parse('$baseUrl/logout'),
        headers: ApiConfig.jsonHeaders(token: token),
      ),
    );
  }

  static Future<Map<String, dynamic>> getProfile(String token) async {
    final Map<String, dynamic> authProfile = await _send(
      () => http.get(
        Uri.parse('$baseUrl/me'),
        headers: ApiConfig.jsonHeaders(token: token),
      ),
    );

    if (authProfile['success'] == true) {
      return authProfile;
    }

    final Map<String, dynamic> userProfile = await _send(
      () => http.get(
        Uri.parse('${ApiConfig.baseUrl}/users/profile'),
        headers: ApiConfig.jsonHeaders(token: token),
      ),
    );

    if (userProfile['success'] == true) {
      return userProfile;
    }

    return authProfile;
  }

  static Future<Map<String, dynamic>> updateProfile({
    required String token,
    required String fullName,
    required String email,
    required String phone,
  }) async {
    final Map<String, dynamic> payload = {
      'fullName': fullName.trim(),
      'full_name': fullName.trim(),
      'name': fullName.trim(),
      'email': email.trim(),
      'phone': phone.trim(),
      'phone_number': phone.trim(),
    };

    final Map<String, dynamic> authResponse = await _send(
      () => http.put(
        Uri.parse('$baseUrl/me'),
        headers: ApiConfig.jsonHeaders(token: token),
        body: jsonEncode(payload),
      ),
    );

    if (authResponse['success'] == true) {
      return authResponse;
    }

    final Map<String, dynamic> userResponse = await _send(
      () => http.put(
        Uri.parse('${ApiConfig.baseUrl}/users/profile'),
        headers: ApiConfig.jsonHeaders(token: token),
        body: jsonEncode(payload),
      ),
    );

    if (userResponse['success'] == true) {
      return userResponse;
    }

    return authResponse;
  }

  static Future<Map<String, dynamic>> uploadProfilePhoto({
    required String token,
    required XFile image,
  }) async {
    try {
      final http.MultipartRequest request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/me/photo'),
      );

      request.headers.addAll(
        ApiConfig.authHeaders(token),
      );

      final List<int> bytes = await image.readAsBytes();

      request.files.add(
        http.MultipartFile.fromBytes(
          'photo',
          bytes,
          filename: _safeFileName(image.name, fallback: 'profile_photo.jpg'),
        ),
      );

      final http.StreamedResponse streamedResponse =
          await request.send().timeout(_timeout);

      final http.Response response =
          await http.Response.fromStream(streamedResponse);

      final Map<String, dynamic> authResponse = _normalizeResponse(response);

      if (authResponse['success'] == true) {
        return authResponse;
      }

      // final http.MultipartRequest fallbackRequest = http.MultipartRequest(
      //   'POST',
      //   Uri.parse('${ApiConfig.baseUrl}/users/profile/photo'),
      // );

      // fallbackRequest.headers.addAll(
      //   ApiConfig.authHeaders(token),
      // );

      // fallbackRequest.files.add(
      //   http.MultipartFile.fromBytes(
      //     'photo',
      //     bytes,
      //     filename: _safeFileName(image.name, fallback: 'profile_photo.jpg'),
      //   ),
      // );

      // final http.StreamedResponse fallbackStreamedResponse =
      //     await fallbackRequest.send().timeout(_timeout);

      // final http.Response fallbackResponse =
      //     await http.Response.fromStream(fallbackStreamedResponse);

      // final Map<String, dynamic> fallbackNormalizedResponse =
      //     _normalizeResponse(fallbackResponse);

      // if (fallbackNormalizedResponse['success'] == true) {
      //   return fallbackNormalizedResponse;
      // }

      return authResponse;
    } on TimeoutException {
      return _failure('Koneksi timeout saat mengunggah foto profil.');
    } catch (error) {
      return _failure('Tidak dapat mengunggah foto profil: $error');
    }
  }

  static String? extractAccessToken(Map<String, dynamic> response) {
    final Object? tokenValue = _firstAvailableValue(
      response,
      [
        'access_token',
        'accessToken',
        'token',
        'jwt',
      ],
    );

    final String token = tokenValue?.toString().trim() ?? '';

    if (token.isNotEmpty && token != 'null') {
      return token;
    }

    final Map<String, dynamic> data = mapOf(response['data']);

    final Object? dataTokenValue = _firstAvailableValue(
      data,
      [
        'access_token',
        'accessToken',
        'token',
        'jwt',
      ],
    );

    final String dataToken = dataTokenValue?.toString().trim() ?? '';

    if (dataToken.isNotEmpty && dataToken != 'null') {
      return dataToken;
    }

    final Map<String, dynamic> user = mapOf(data['user']);

    final Object? userTokenValue = _firstAvailableValue(
      user,
      [
        'access_token',
        'accessToken',
        'token',
        'jwt',
      ],
    );

    final String userToken = userTokenValue?.toString().trim() ?? '';

    if (userToken.isNotEmpty && userToken != 'null') {
      return userToken;
    }

    return null;
  }

  static String messageOf(
    Map<String, dynamic> response, {
    required String fallback,
  }) {
    final Object? messageValue = _firstAvailableValue(
      response,
      [
        'message',
        'error',
        'detail',
      ],
    );

    final String message = messageValue?.toString().trim() ?? '';

    if (message.isNotEmpty && message != 'null') {
      return message;
    }

    final Map<String, dynamic> data = mapOf(response['data']);

    final Object? nestedMessageValue = _firstAvailableValue(
      data,
      [
        'message',
        'error',
        'detail',
      ],
    );

    final String nestedMessage =
        nestedMessageValue?.toString().trim() ?? '';

    if (nestedMessage.isNotEmpty && nestedMessage != 'null') {
      return nestedMessage;
    }

    return fallback;
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
        'users',
        'results',
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

  static Object? _firstAvailableValue(
    Map<String, dynamic> data,
    List<String> keys,
  ) {
    for (final String key in keys) {
      if (data.containsKey(key)) {
        return data[key];
      }
    }

    for (final Object? value in data.values) {
      if (value is Map) {
        final Map<String, dynamic> nestedMap = mapOf(value);

        for (final String key in keys) {
          if (nestedMap.containsKey(key)) {
            return nestedMap[key];
          }
        }
      }
    }

    return null;
  }

  static Future<Map<String, dynamic>> _send(
    Future<http.Response> Function() request,
  ) async {
    try {
      final http.Response response = await request().timeout(_timeout);

      debugPrint('AUTH SERVICE STATUS: ${response.statusCode}');
      debugPrint('AUTH SERVICE BODY: ${response.body}');

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
}