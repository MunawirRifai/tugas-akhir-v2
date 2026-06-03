class GoogleMapsConfig {
  const GoogleMapsConfig._();

  /*
    API key Google Maps jangan di-hardcode langsung di source code.

    Untuk development:
    flutter run -d chrome --dart-define=GOOGLE_MAPS_API_KEY=ISI_API_KEY_ANDA

    Untuk Android:
    flutter run -d DEVICE_ID --dart-define=GOOGLE_MAPS_API_KEY=ISI_API_KEY_ANDA

    Untuk build APK:
    flutter build apk --release --dart-define=GOOGLE_MAPS_API_KEY=ISI_API_KEY_ANDA

    Catatan penting:
    - Key ini dipakai oleh service Directions API di sisi Flutter.
    - Jika nanti Directions API dipindahkan penuh ke Back-End, maka FE tidak
      wajib membawa Google Maps Directions API key lagi.
    - Untuk widget GoogleMap di Android/iOS/Web, konfigurasi key platform
      tetap perlu disiapkan pada file native/platform masing-masing.
  */

  static const String _environmentApiKey = String.fromEnvironment(
    'GOOGLE_MAPS_API_KEY',
    defaultValue: '',
  );

  static String get directionsApiKey {
    return _environmentApiKey.trim();
  }

  static bool get hasDirectionsApiKey {
    return directionsApiKey.isNotEmpty;
  }

  static String get missingApiKeyMessage {
    return 'Google Maps Directions API key belum tersedia. '
        'Gunakan --dart-define=GOOGLE_MAPS_API_KEY=ISI_API_KEY_ANDA '
        'atau gunakan endpoint Directions dari Back-End.';
  }
}