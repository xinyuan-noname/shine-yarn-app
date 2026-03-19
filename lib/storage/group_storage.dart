import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

enum GroupStorageKey {
  entire("entire", "group_entire_key"),
  male("male", "group_male_key"),
  female("female", "group_female_key"),
  admin("admin", "group_admin_key"),
  user("user", "group_user_key"),
  position("position", "group_position_key");

  const GroupStorageKey(this.name, this.value);
  final String value;
  final String name;
}

class GroupStorage {
  static Future<void> saveGroupUserList(GroupStorageKey key, List list) async {
    final prefs = await SharedPreferences.getInstance();
    final s = list.map((e) => jsonEncode(e)).toList();
    await prefs.setStringList(key.value, s);
  }

  static Future<List<Map<String, dynamic>>?> getGroupUserList(
    GroupStorageKey key,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(key.value);
    if (list == null) return null;
    return list
        .map((e) => jsonDecode(e))
        .whereType<Map<String, dynamic>>()
        .toList();
  }

  static Future delUserList(GroupStorageKey key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(key.value);
  }
}