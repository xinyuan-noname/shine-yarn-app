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

/// 各分组的中文名称
const Map<GroupStorageKey, String> groupStorageKeyLabelMap = {
  GroupStorageKey.entire: "所有学生",
  GroupStorageKey.male: "所有男生",
  GroupStorageKey.female: "所有女生",
  GroupStorageKey.position: "所有班委",
  GroupStorageKey.user: "所有非班委",
  GroupStorageKey.admin: "所有管理员",
};

/// 各分组的中文名称，(分组, 名称) 列表形式
List<(GroupStorageKey, String)> get groupStorageKeyLabelList => [
  for (final entry in groupStorageKeyLabelMap.entries) (entry.key, entry.value),
];

class GroupStorage {
  /// 从分组成员列表中取出所有学号
  static List<String> getIdList(List<Map<String, dynamic>> userList) {
    return userList
        .map((user) => user['id'])
        .whereType<String>()
        .where((id) => id.isNotEmpty)
        .toList();
  }

  static Future<void> saveGroupUserList(
    GroupStorageKey key,
    List<Map<String, dynamic>> list,
  ) async {
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
