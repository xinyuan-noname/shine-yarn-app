import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// 专业任选课选课状态（纯本地数据，不会上传服务器）
///
/// 存储结构：`{ 学期名: { 科目名: 是否已选 } }`
/// 未记录的科目一律视为「已选」，这样服务端新增的专业任选课不会被意外隐藏，
/// 用户只需在设置中取消自己不选的课。
class ElectiveStorage {
  static const String _key = "major_elective_selection_key";

  /// 学期名为空时使用的占位 key
  static const String _unknownSemesterKey = "__unknown_semester__";

  static String _resolveSemesterKey(String? semester) {
    final name = semester?.trim() ?? '';
    return name.isEmpty ? _unknownSemesterKey : name;
  }

  static Future<Map<String, Map<String, bool>>> _readAll() async {
    final prefs = await SharedPreferences.getInstance();
    final result = prefs.getString(_key);
    if (result == null) return {};
    try {
      final infoJson = jsonDecode(result);
      if (infoJson is! Map) return {};
      final Map<String, Map<String, bool>> all = {};
      infoJson.forEach((semester, selection) {
        if (selection is! Map) return;
        final Map<String, bool> item = {};
        selection.forEach((subjectName, selected) {
          if (subjectName is! String || selected is! bool) return;
          item[subjectName] = selected;
        });
        all[semester.toString()] = item;
      });
      return all;
    } catch (e) {
      return {};
    }
  }

  static Future<void> _writeAll(Map<String, Map<String, bool>> all) async {
    final prefs = await SharedPreferences.getInstance();
    final filtered = all.entries
        .where((entry) => entry.value.isNotEmpty)
        .map((entry) => MapEntry(entry.key, entry.value));
    final data = Map.fromEntries(filtered);
    if (data.isEmpty) {
      await prefs.remove(_key);
      return;
    }
    await prefs.setString(_key, jsonEncode(data));
  }

  /// 读取某学期已保存的专业任选课选课状态（科目名 -> 是否已选）
  static Future<Map<String, bool>> getSelection(String? semester) async {
    final all = await _readAll();
    return Map<String, bool>.from(all[_resolveSemesterKey(semester)] ?? {});
  }

  /// 覆盖保存某学期的专业任选课选课状态
  static Future<void> saveSelection(
    String? semester,
    Map<String, bool> selection,
  ) async {
    final all = await _readAll();
    all[_resolveSemesterKey(semester)] = Map<String, bool>.from(selection);
    await _writeAll(all);
  }

  /// 设置单个科目的选课状态
  static Future<void> setSelected(
    String? semester,
    String subjectName,
    bool selected,
  ) async {
    final selection = await getSelection(semester);
    selection[subjectName] = selected;
    await saveSelection(semester, selection);
  }

  /// 清除某学期的选课状态（恢复默认：全部已选）
  static Future<void> clearSelection(String? semester) async {
    final all = await _readAll();
    all.remove(_resolveSemesterKey(semester));
    await _writeAll(all);
  }
}
