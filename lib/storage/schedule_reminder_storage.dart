import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:shine/models/schedule_reminder_data.dart';

/// 日程提醒的本地存储：每门课的提醒设置 + 已经排期出去的通知 id。
///
/// 通知 id 需要持久化，重排提醒时先把上一批撤掉，避免重复打扰。
class ScheduleReminderStorage {
  static const String _settingKey = "schedule_reminder_setting_key";
  static const String _scheduledIdsKey = "schedule_reminder_scheduled_ids_key";

  /// 读取全部课程的提醒设置（科目名 -> 设置）
  static Future<Map<String, ScheduleReminderSetting>> getSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_settingKey);
    if (raw == null) return {};
    try {
      final infoJson = jsonDecode(raw);
      if (infoJson is! Map) return {};
      final result = <String, ScheduleReminderSetting>{};
      infoJson.forEach((subjectName, setting) {
        if (subjectName is! String || setting is! Map) return;
        result[subjectName] = ScheduleReminderSetting.fromJson(
          Map<String, dynamic>.from(setting),
        );
      });
      return result;
    } catch (e) {
      return {};
    }
  }

  static Future<ScheduleReminderSetting> getSetting(String subjectName) async {
    final settings = await getSettings();
    return settings[subjectName] ?? ScheduleReminderSetting.disabled;
  }

  /// 保存某门课的提醒设置
  static Future<void> setSetting(
    String subjectName,
    ScheduleReminderSetting setting,
  ) async {
    final settings = await getSettings();
    settings[subjectName] = setting;
    await saveSettings(settings);
  }

  static Future<void> saveSettings(
    Map<String, ScheduleReminderSetting> settings,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _settingKey,
      jsonEncode(
        settings.map((subjectName, setting) {
          return MapEntry(subjectName, setting.toJson());
        }),
      ),
    );
  }

  static Future<List<int>> getScheduledIds() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_scheduledIdsKey);
    if (raw == null) return [];
    try {
      final infoJson = jsonDecode(raw);
      if (infoJson is! List) return [];
      return infoJson.whereType<int>().toList();
    } catch (e) {
      return [];
    }
  }

  static Future<void> saveScheduledIds(List<int> ids) async {
    final prefs = await SharedPreferences.getInstance();
    if (ids.isEmpty) {
      await prefs.remove(_scheduledIdsKey);
      return;
    }
    await prefs.setString(_scheduledIdsKey, jsonEncode(ids));
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_settingKey);
    await prefs.remove(_scheduledIdsKey);
  }
}
