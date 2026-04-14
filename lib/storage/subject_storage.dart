import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:shine/models/course_data.dart';

class SubjectStorage {
  static final String _currentDiySubjectInfoListKey =
      "current_diy_subject_info_list_key";
  static final String _currentSubjectInfoListKey =
      "current_subject_info_list_key";
  static final String _currentScheduleInfoListKey =
      "current_schedule_info_list_key";
  // --- DIY科目信息 ---
  static Future<void> setCurrentDiySubjectInfo(String subjectList) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currentDiySubjectInfoListKey, subjectList);
  }

  static Future<void> addCurrentDiySubjectInfo(CourseData data) async {
    final prefs = await SharedPreferences.getInstance();
    final result = prefs.getString(_currentDiySubjectInfoListKey);
    var infoJson = result == null ? [] : jsonDecode(result);
    if (infoJson is List) {
      infoJson.add(data.toJson());
    } else {
      infoJson = [data.toJson()];
    }
    await prefs.setString(
      _currentDiySubjectInfoListKey,
      jsonEncode(infoJson),
    );
  }

  static Future<void> removeCurrentDiySubjectInfo(String subjectName) async {
    final prefs = await SharedPreferences.getInstance();
    final result = prefs.getString(_currentDiySubjectInfoListKey);
    if (result == null) return;
    
    final infoJson = jsonDecode(result);
    if (infoJson is List) {
      final filteredList = infoJson.whereType<Map<String, dynamic>>().where((e) {
        return e['subjectName'] != subjectName;
      }).toList();
      
      if (filteredList.isEmpty) {
        await prefs.remove(_currentDiySubjectInfoListKey);
      } else {
        await prefs.setString(
          _currentDiySubjectInfoListKey,
          jsonEncode(filteredList),
        );
      }
    }
  }

  static Future<List<CourseData>> getCurrentDiySubjectInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final result = prefs.getString(_currentDiySubjectInfoListKey);
    if (result == null) return [];
    final infoJson = jsonDecode(result);
    if (infoJson is List) {
      return infoJson.whereType<Map<String, dynamic>>().map((e) {
        return CourseData.fromJson(e);
      }).toList();
    }
    return [];
  }

  static Future<void> delCurrentDiySubjectInfo() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_currentDiySubjectInfoListKey);
  }

  static Future<List<String>> getCurrentDiySubjectName() async {
    final result = await SubjectStorage.getCurrentDiySubjectInfo();
    return result.map((info) => info.subjectName).toList();
  }

  // --- 日程信息 ---
  static Future<void> setCurrentScheduleInfo(String scheduleList) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currentScheduleInfoListKey, scheduleList);
  }

  static Future<List<ScheduleData>> getCurrentScheduleInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final result = prefs.getString(_currentScheduleInfoListKey);
    if (result == null) return [];
    final infoJson = jsonDecode(result);
    if (infoJson is List) {
      return infoJson.whereType<Map<String, dynamic>>().map((e) {
        return ScheduleData.fromJson(e);
      }).toList();
    }
    return [];
  }

  static Future<void> delCurrentScheduleInfo() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_currentScheduleInfoListKey);
  }

  // --- 科目信息 ----

  static Future<void> setCurrentSubjectInfo(String subjectList) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currentSubjectInfoListKey, subjectList);
  }

  static Future<List<CourseData>> getCurrentSubjectInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final result = prefs.getString(_currentSubjectInfoListKey);
    if (result == null) return [];
    final infoJson = jsonDecode(result);
    if (infoJson is List) {
      return infoJson.whereType<Map<String, dynamic>>().map((e) {
        return CourseData.fromJson(e);
      }).toList();
    }
    return [];
  }

  static Future<void> delCurrentSubjectInfo() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_currentSubjectInfoListKey);
  }

  static Future<List<String>> getCurrentSubjectName() async {
    final result = await SubjectStorage.getCurrentSubjectInfo();
    return result.map((info) => info.subjectName).toList();
  }
}
