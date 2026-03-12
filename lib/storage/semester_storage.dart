import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SemesterStorage {
  static const String _currentSemesterName = "current_semester_name_key";
  static const String _currentSemesterStartedAt =
      "current_semester_started_at_key";
  static const String _currentSemesterPhaseList =
      "current_semester_phase_list_key";

  // Create / Update 学期名称
  static Future<void> setCurrentSemesterName(String semesterName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currentSemesterName, semesterName);
  }

  // Read 学期名称
  static Future<String?> getCurrentSemesterName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_currentSemesterName);
  }

  // Delete 学期名称
  static Future<void> delCurrentSemesterName() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_currentSemesterName);
  }

  // Create / Update 学期开始时间
  static Future<void> setCurrentSemesterStartedAt(DateTime startedAt) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _currentSemesterStartedAt,
      startedAt.toIso8601String(),
    );
  }

  // Read 学期开始时间
  static Future<DateTime?> getCurrentSemesterStartedAt() async {
    final prefs = await SharedPreferences.getInstance();
    final startedAtStr = prefs.getString(_currentSemesterStartedAt);
    if (startedAtStr != null) {
      try {
        return DateTime.parse(startedAtStr);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  // Delete 学期开始时间
  static Future<void> delCurrentSemesterStartedAt() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_currentSemesterStartedAt);
  }

  // Create / Update 学期阶段列表
  static Future<void> setCurrentSemesterPhaseList(
    List<List<TimeOfDay>> phaseList,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final serializedPhaseList = phaseList
        .map((p) => p.map((t) => [t.hour, t.minute]).toList())
        .toList();

    await prefs.setString(
      _currentSemesterPhaseList,
      jsonEncode(serializedPhaseList),
    );
  }

  // Read 学期阶段列表
  static Future<List<List<TimeOfDay>>?> getCurrentSemesterPhaseList() async {
    final prefs = await SharedPreferences.getInstance();
    final phaseListStr = prefs.getString(_currentSemesterPhaseList);
    if (phaseListStr == null) return null;
    final phaseList = jsonDecode(phaseListStr);
    final List<List<TimeOfDay>> resultPhaseList = [];
    for (final phase in phaseList) {
      if (phase is! List) continue;
      final start = phase[0];
      final end = phase[1];
      if (start is! List || end is! List) continue;
      if (start[0] is! int ||
          start[1] is! int ||
          end[0] is! int ||
          end[1] is! int) {
        continue;
      }
      resultPhaseList.add([
        TimeOfDay(hour: start[0], minute: start[1]),
        TimeOfDay(hour: end[0], minute: end[1]),
      ]);
    }
    if (resultPhaseList.isNotEmpty) return resultPhaseList;
    return null;
  }

  // Delete 学期阶段列表
  static Future<void> delCurrentSemesterPhaseList() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_currentSemesterPhaseList);
  }

  // 获取完整的当前学期信息
  static Future<Map<String, dynamic>?> getCurrentSemesterInfo() async {
    final name = await getCurrentSemesterName();
    final startedAt = await getCurrentSemesterStartedAt();
    final phaseList = await getCurrentSemesterPhaseList();

    if (name != null || startedAt != null || phaseList != null) {
      return {
        'semesterName': name,
        'startedAt': startedAt,
        'phaseList': phaseList,
      };
    }
    return null;
  }

  // 删除完整学期信息
  static Future<void> deleteCurrentSemesterInfo() async {
    await delCurrentSemesterName();
    await delCurrentSemesterStartedAt();
    await delCurrentSemesterPhaseList();
  }
}
