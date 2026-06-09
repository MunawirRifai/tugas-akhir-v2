import 'package:shared_preferences/shared_preferences.dart';

class AuthStorage {
  static const String _tokenKey = 'auth_token';
  static const String _refreshTokenKey = 'refresh_token';

  /// Menyimpan token akses
  static Future<bool> saveToken(String token) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return await prefs.setString(_tokenKey, token);
  }

  /// Menyimpan token refresh
  static Future<bool> saveRefreshToken(String token) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return await prefs.setString(_refreshTokenKey, token);
  }

  /// Mengambil token akses (JWT) yang tersimpan
  static Future<String?> getToken() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  /// Mengambil token refresh yang tersimpan
  static Future<String?> getRefreshToken() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(_refreshTokenKey);
  }

  /// Menghapus seluruh token (untuk logout)
  static Future<bool> clearToken() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(_refreshTokenKey);
    return await prefs.remove(_tokenKey);
  }

  /// Mengecek apakah ada token akses yang tersimpan
  static Future<bool> hasToken() async {
    final String? token = await getToken();
    return token != null && token.trim().isNotEmpty;
  }
}
