import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileStorage {
  static final String _nameKey = 'name_key';
  static final String _idKey = 'id_key';
  static final String _genderKey = 'gener_key';
  static final String _passwordRequiredKey = 'password_required_key';
  static final String _avatarTsKey = 'avatar_ts_key';
  static final String _adminListKey = 'admin_list_key';
  static final String _userListKey = 'user_list_key';
  static final String _majorKey = 'major_key';
  static final String _classKey = "class_key";
  static final String _academyKey = "academy_key";

  static Future<void> saveMajor(String major) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_majorKey, major);
  }

  static Future<String> getMajor() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_majorKey) ?? "";
  }

  static Future delMajor() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_majorKey);
  }

  static Future<void> saveClass(String className) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_classKey, className);
  }

  static Future<String> getClass() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_classKey) ?? "";
  }

  static Future delClass() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_classKey);
  }

  static Future<void> saveAcademy(String academy) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_academyKey, academy);
  }

  static Future<String> getAcademy() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_academyKey) ?? "";
  }

  static Future delAcademy() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_academyKey);
  }

  static Future<void> saveName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_nameKey, name);
  }

  static Future<String> getName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_nameKey) ?? "";
  }

  static Future delName() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_nameKey);
  }

  static Future<void> saveId(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_idKey, id);
  }

  static Future<String> getId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_idKey) ?? "";
  }

  static Future delId() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_idKey);
  }

  static Future<void> saveGender(String gender) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_genderKey, gender);
  }

  static Future<String> getGender() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_genderKey) ?? "?";
  }

  static Future delGender() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_genderKey);
  }

  static Future<void> savePasswordRequired(bool passwordRequired) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_passwordRequiredKey, passwordRequired);
  }

  static Future<bool> getPasswordRequired() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_passwordRequiredKey) ?? false;
  }

  static Future delPasswordRequired() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_passwordRequiredKey);
  }

  static Future<void> saveAvatarTs(int ts) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_avatarTsKey, ts);
  }

  static Future<int> getAvatarTs() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_avatarTsKey) ?? 0;
  }

  static Future delAvatarTs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_avatarTsKey);
  }

  static Future<void> saveAdminList(List list) async {
    final prefs = await SharedPreferences.getInstance();
    final s = list.map((e) => jsonEncode(e)).toList();
    await prefs.setStringList(_adminListKey, s);
  }

  static Future<List?> getAdminList() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_adminListKey);
    if (list == null) return null;
    return list.map((e) => jsonDecode(e)).toList();
  }

  static Future delAdminList() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_adminListKey);
  }

  static Future<void> saveUserList(List list) async {
    final prefs = await SharedPreferences.getInstance();
    final s = list.map((e) => jsonEncode(e)).toList();
    await prefs.setStringList(_userListKey, s);
  }

  static Future<List?> getUserList() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_userListKey);
    if (list == null) return null;
    return list.map((e) => jsonDecode(e)).toList();
  }

  static Future delUserList() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userListKey);
  }
}
