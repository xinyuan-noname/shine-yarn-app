import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

final storage = const FlutterSecureStorage(
  wOptions: WindowsOptions(useBackwardCompatibility: true),
);

class TokenStorage {
  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'fresh_token';
  static Future<String?> getAccessToken() async {
    return await storage.read(key: _accessTokenKey);
  }

  static Future<void> setAccessToken(String accessToken) async {
    storage.write(key: _accessTokenKey, value: accessToken);
  }

  static Future<void> deleteAccessToken() async {
    storage.delete(key: _accessTokenKey);
  }

  static Future<String?> getRefreshToken() async {
    return await storage.read(key: _refreshTokenKey);
  }

  static Future<void> setRefreshToken(String refreshToken) async {
    storage.write(key: _refreshTokenKey, value: refreshToken);
  }

  static Future<void> deleteRefreshToken() async {
    storage.delete(key: _refreshTokenKey);
  }

  static Future<String> getTokenUserType() async {
    final token = await TokenStorage.getAccessToken();
    if (token == null || token.isEmpty) return "guest";
    final payload = JwtDecoder.decode(token);
    return payload["userType"] ?? "guest";
  }

  static Future<void> clearAllToken() async {
    storage.delete(key: _accessTokenKey);
    storage.delete(key: _refreshTokenKey);
  }
}
