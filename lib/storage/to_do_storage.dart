import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:shine/models/to_do_item_data.dart';

/// 事项表（公共待办事项）的本地缓存。
///
/// 服务端始终是唯一数据源，本地只做镜像：启动或断网时先展示上次同步到的内容，
/// 每次同步成功后整体覆盖；本地删除 / 修改也会同步到缓存，
/// 这样离线时不会继续显示已经删掉的事项。
class ToDoStorage {
  static const String _listKey = "public_to_do_list_cache_key";

  /// 整体覆盖缓存（同步成功后调用）
  static Future<void> saveToDoList(List<ToDoItemData> list) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _listKey,
      jsonEncode(list.map((item) => item.toMap()).toList()),
    );
  }

  /// 读取缓存，没有缓存或内容损坏时返回空列表
  static Future<List<ToDoItemData>> getToDoList() async {
    final prefs = await SharedPreferences.getInstance();
    return _decode(prefs.getString(_listKey));
  }

  /// 删除事项后同步缓存
  static Future<void> removeToDoItem(String itemId) async {
    final prefs = await SharedPreferences.getInstance();
    final list = _decode(prefs.getString(_listKey));
    final before = list.length;
    list.removeWhere((item) => item.itemId == itemId);
    if (list.length == before) return;
    await saveToDoList(list);
  }

  /// 修改事项后同步缓存
  static Future<void> updateToDoItem({
    required String itemId,
    required String title,
    required String content,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final list = _decode(prefs.getString(_listKey));
    final index = list.indexWhere((item) => item.itemId == itemId);
    if (index < 0) return;
    final old = list[index];
    list[index] = ToDoItemData(
      itemId: old.itemId,
      title: title,
      content: content,
      source: old.source,
      ts: old.ts,
    );
    await saveToDoList(list);
  }

  static Future<void> clearToDoList() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_listKey);
  }

  /// 解析缓存内容：格式不合法时按空列表处理，避免脏数据让事项表崩掉
  static List<ToDoItemData> _decode(String? raw) {
    if (raw == null) return [];
    try {
      final infoJson = jsonDecode(raw);
      if (infoJson is! List) return [];
      return infoJson
          .whereType<Map<String, dynamic>>()
          .map(ToDoItemData.fromMap)
          .toList();
    } catch (e) {
      return [];
    }
  }
}
