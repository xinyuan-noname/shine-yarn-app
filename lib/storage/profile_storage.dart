import 'package:shared_preferences/shared_preferences.dart';

class ProfileStorage {
  static String nameKey = 'name_key';
  static String idKey = 'id_key';
  static Future<void> saveName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(nameKey, name);
  }
  static Future<String?> getName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(nameKey);
  }
  static Future<void> saveId(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(idKey, id);
  }
  static Future<String?> getId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(idKey);
  }
}
