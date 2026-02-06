import 'package:shared_preferences/shared_preferences.dart';

class TokenStorage {
  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'fresh_token';
  static Future<String?> getAccessToken() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_accessTokenKey);
  }

  static Future<void> setAccessToken(String accessToken) async {
    final p = await SharedPreferences.getInstance();
    p.setString(_accessTokenKey, accessToken);
  }

  static Future<void> deleteAccessToken() async {
    final p = await SharedPreferences.getInstance();
    p.remove(_accessTokenKey);
  }

  static Future<String?> getRefreshToken() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_refreshTokenKey);
  }

  static Future<void> setRefreshToken(String freshToken) async {
    final p = await SharedPreferences.getInstance();
    p.setString(_refreshTokenKey, freshToken);
  }

  static Future<void> deleteRefreshToken() async {
    final p = await SharedPreferences.getInstance();
    p.remove(_refreshTokenKey);
  }

  static Future<void> clearAllToken() async {
    final p = await SharedPreferences.getInstance();
    p.remove(_refreshTokenKey);
    p.remove(_accessTokenKey);
  }
}
