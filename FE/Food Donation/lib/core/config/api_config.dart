import 'package:flutter/foundation.dart';

class ApiConfig {
  const ApiConfig._();

  /*
    Cara paling aman untuk mengatur base URL API:

    1. Chrome / Web:
       flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:8080

    2. Android Emulator:
       flutter run -d emulator-5554 --dart-define=API_BASE_URL=http://10.0.2.2:8080

    3. HP Android fisik:
       flutter run -d DEVICE_ID --dart-define=API_BASE_URL=http://IP_LAPTOP_ANDA:8080

    4. Build APK:
       flutter build apk --release --dart-define=API_BASE_URL=http://IP_BACKEND_ANDA:8080

    Jika API_BASE_URL tidak diisi, config akan memakai default development
    berdasarkan platform.
  */

  static const String _environmentBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  static String get baseUrl {
    final String trimmedEnvironmentUrl = _environmentBaseUrl.trim();

    if (trimmedEnvironmentUrl.isNotEmpty) {
      return _removeTrailingSlash(trimmedEnvironmentUrl);
    }

    return _defaultDevelopmentBaseUrl;
  }

  static String get authUrl {
    return '$baseUrl/api/v1/auth';
  }

  static String get foodsUrl {
    return '$baseUrl/api/v1/foods';
  }

  static String get adminUrl {
    return '$baseUrl/api/v1/admin';
  }

  static String get directionsUrl {
    return '$baseUrl/api/v1/directions';
  }

  static String resolveMediaUrl(Object? rawValue) {
    final String rawUrl = rawValue?.toString().trim() ?? '';

    if (rawUrl.isEmpty || rawUrl == 'null') {
      return '';
    }

    final Uri? parsedUrl = Uri.tryParse(rawUrl);

    if (parsedUrl != null && parsedUrl.hasScheme) {
      return rawUrl;
    }

    final Uri parsedBaseUrl = Uri.parse(baseUrl);
    final String port = parsedBaseUrl.hasPort ? ':${parsedBaseUrl.port}' : '';
    final String origin =
        '${parsedBaseUrl.scheme}://${parsedBaseUrl.host}$port';
    final String normalizedPath = rawUrl.startsWith('/') ? rawUrl : '/$rawUrl';

    return '$origin$normalizedPath';
  }

  static Map<String, String> jsonHeaders({String? token}) {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null && token.trim().isNotEmpty)
        'Authorization': 'Bearer ${token.trim()}',
    };
  }

  static Map<String, String> authHeaders(String token) {
    return {
      'Accept': 'application/json',
      'Authorization': 'Bearer ${token.trim()}',
    };
  }

  static String _removeTrailingSlash(String value) {
    if (value.endsWith('/')) {
      return value.substring(0, value.length - 1);
    }

    return value;
  }

  static String get _defaultDevelopmentBaseUrl {
    if (kIsWeb) {
      return 'http://103.67.78.39:8080';
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'http://103.67.78.39:8080';
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      case TargetPlatform.fuchsia:
        return 'http://103.67.78.39:8080';
    }
  }
}
