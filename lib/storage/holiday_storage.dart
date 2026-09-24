import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:shine/models/holiday_data.dart';

/// 节假日本地存储。
///
/// 首次使用时用 [defaultHolidayRanges] 预置一份，之后完全由用户自己增删
/// （学校校历、调休安排各不相同，写死的日期不一定对）。
class HolidayStorage {
  static const String _key = "holiday_range_list_key";

  /// 读取节假日列表；第一次使用时写入预置数据
  static Future<List<HolidayRange>> getHolidays() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) {
      final defaults = defaultHolidayRanges();
      await saveHolidays(defaults);
      return defaults;
    }
    return _decode(raw);
  }

  static Future<void> saveHolidays(List<HolidayRange> holidays) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode(holidays.map((holiday) => holiday.toJson()).toList()),
    );
  }

  /// 恢复成预置的节假日
  static Future<List<HolidayRange>> resetToDefault() async {
    final defaults = defaultHolidayRanges();
    await saveHolidays(defaults);
    return defaults;
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }

  /// 解析缓存内容：格式不对时按空列表处理
  static List<HolidayRange> _decode(String raw) {
    try {
      final infoJson = jsonDecode(raw);
      if (infoJson is! List) return [];
      final result = infoJson
          .whereType<Map<String, dynamic>>()
          .map(HolidayRange.fromJson)
          .where((holiday) => holiday.start.year > 1970)
          .toList();
      result.sort((a, b) => a.start.compareTo(b.start));
      return result;
    } catch (e) {
      return [];
    }
  }
}
