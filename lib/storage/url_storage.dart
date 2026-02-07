import 'package:shared_preferences/shared_preferences.dart';

class URLStorage {
  static const _baseUrlKey = "baseUrl";
  static Future<String?> getBaseUrl() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_baseUrlKey);
  }

  static Future<void> setBaseUrl(String url) async {
    final p = await SharedPreferences.getInstance();
    p.setString(_baseUrlKey, url);
  }

  static Future<void> deleteBaseUrl() async {
    final p = await SharedPreferences.getInstance();
    p.remove(_baseUrlKey);
  }
}
