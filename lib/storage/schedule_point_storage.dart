import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:shine/models/schedule_point_data.dart';

class SchedulePointStorage {
  static const String _schedulePointDataKey = "schedule_point_data_key";

  /// 保存评分项数据
  static Future<void> saveSchedulePointData(SchedulePointData data) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonData = jsonEncode(data.toMap());
    await prefs.setString(_schedulePointDataKey, jsonData);
  }

  /// 获取评分项数据
  static Future<SchedulePointData?> getSchedulePointData() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonData = prefs.getString(_schedulePointDataKey);
    if (jsonData == null) return null;
    
    try {
      final map = jsonDecode(jsonData) as Map<String, dynamic>;
      return SchedulePointData.fromMap(map);
    } catch (e) {
      return null;
    }
  }

  /// 删除评分项数据
  static Future<void> delSchedulePointData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_schedulePointDataKey);
  }
}
