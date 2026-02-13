import 'package:shared_preferences/shared_preferences.dart';

class ProfileStorage {
  static final String _nameKey = 'name_key';
  static final String _idKey = 'id_key';
  static final String _avatarPathKey = 'avatar_path';
  static Future<void> saveName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_nameKey, name);
  }

  static Future<String?> getName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_nameKey);
  }

  static Future delName() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_nameKey);
  }

  static Future<void> saveId(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_idKey, id);
  }

  static Future<String?> getId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_idKey);
  }

  static Future delId() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_idKey);
  }

  static Future<void> saveAvatarPath(String saveAvatarPath) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_avatarPathKey, saveAvatarPath);
  }

  static Future<String?> getAvatarPath() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_avatarPathKey);
  }

  static Future delAvatarPath() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_avatarPathKey);
  }
}
