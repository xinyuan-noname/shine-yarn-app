import 'dart:convert';
import 'dart:typed_data';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:shine/storage/file_storage.dart';

class ProfileStorage {
  static final String _nameKey = 'name_key';
  static final String _idKey = 'id_key';
  static final String _genderKey = 'gener_key';
  static final String _passwordRequiredKey = 'password_required_key';
  static final String _avatarNameKey = 'avatar_name_key';
  static final String _adminListKey = 'admin_list_key';
  static final String _userListKey = 'user_list_key';
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

  static Future<void> saveAvatar(Uint8List data) async {
    final prefs = await SharedPreferences.getInstance();
    final avatarName = "${DateTime.now().millisecondsSinceEpoch}.jpeg";
    final avatarRelativePath = 'profiles/avatars/$avatarName';
    await prefs.setString(_avatarNameKey, avatarName);
    await FileStorage.saveBytesToAppFolder(
      relativePath: avatarRelativePath,
      data: data,
    );
  }

  static Future<String?> getAvatarPath() async {
    final prefs = await SharedPreferences.getInstance();
    final avatarName = prefs.getString(_avatarNameKey);
    if (avatarName == null) return null;
    final avatarRelativePath = "profiles/avatars/$avatarName";
    final fullpath = await FileStorage.getPath(avatarRelativePath);
    if (await FileStorage.existsFile(fullpath)) {
      return fullpath;
    }
    return null;
  }

  static Future<void> delOutdatedAvatar() async {
    final prefs = await SharedPreferences.getInstance();
    final avatarName = prefs.getString(_avatarNameKey);
    FileStorage.deleteAllExcept(
      keepFileNames: avatarName == null ? [] : [avatarName],
      subDirName: 'profiles/avatars',
    );
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
