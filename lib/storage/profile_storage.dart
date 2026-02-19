import 'dart:ffi';
import 'dart:typed_data';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:shine/storage/file_storage.dart';

class ProfileStorage {
  static final String _nameKey = 'name_key';
  static final String _idKey = 'id_key';
  static final String _genderKey = 'gener_key';
  static final String _passwordRequiredKey = 'password_required_key';
  static final String _avatarPathKey = 'avatar_path_key';
  static Future<void> saveName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_nameKey, name);
  }

  static Future<String> getName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_nameKey) ?? "???";
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
    return prefs.getString(_idKey) ?? "??????????";
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

  static Future<String> getPasswordRequired() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_passwordRequiredKey) ?? false ? "是" : "否";
  }

  static Future delPasswordRequired() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_passwordRequiredKey);
  }

  static Future<void> saveAvatar(Uint8List data) async {
    final prefs = await SharedPreferences.getInstance();
    final avatarRelativePath =
        'profiles/avatar-${DateTime.now().millisecondsSinceEpoch}.jpeg';
    await prefs.setString(_avatarPathKey, avatarRelativePath);
    await FileStorage.saveBytesToAppFolder(
      relativePath: avatarRelativePath,
      data: data,
    );
  }

  static Future<String?> getAvatarPath() async {
    final prefs = await SharedPreferences.getInstance();
    final avatarRelativePath = prefs.getString(_avatarPathKey);
    if (avatarRelativePath == null) return null;
    final fullpath = await FileStorage.getPath(avatarRelativePath);
    if (await FileStorage.existsFile(fullpath)) {
      return fullpath;
    }
    return null;
  }
}
