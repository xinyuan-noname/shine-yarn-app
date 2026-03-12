import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:shine/services/dio.dart';

class ApiSemesters {
  static Future<String?> createSemester({
    required String semesterName,
    required DateTime startedAt,
    required List<List<DateTime>> phaseList,
  }) async {
    try {
      final d = {
        "semesterName": semesterName,
        "startedAt": startedAt.toIso8601String(),
        "phaseList": phaseList
            .map((p) => p.map((t) => [t.hour, t.minute]).toList())
            .toList(),
      };
      await dio.post("/semesters/create", data: d);
      return null;
    } on DioException catch (e) {
      return e.message ?? "创建学期失败";
    } catch (e) {
      return "创建学期失败";
    }
  }

  static Future<ApiSemesterResult> getCurrentSemester() async {
    try {
      final response = await dio.get("/semesters/current");
      final data = response.data;
      if (data is Map) {
        final semesterName = data["semesterName"];
        final startedAt = data["startedAt"];
        final phaseList = data["phaseList"];
        if (semesterName is String &&
            startedAt is String &&
            phaseList is List) {
          final String resultSemesterName = semesterName;
          final DateTime resultStartedAt = DateTime.parse(startedAt);
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
          return ApiSemesterResult(
            null,
            startedAt: resultStartedAt,
            phaseList: resultPhaseList,
            semesterName: resultSemesterName,
          );
        }
        return ApiSemesterResult("获得学期失败");
      }
      return ApiSemesterResult("获取学期失败");
    } on DioException catch (e) {
      return ApiSemesterResult(e.message ?? "获取学期失败");
    } catch (e) {
      return ApiSemesterResult("获取学期失败");
    }
  }

  static Future<String?> deleteCurrentSemester({
    required String semesterName,
  }) async {
    try {
      final d = {"semesterName": semesterName};
      await dio.delete("/semesters/delete", data: d);
      return null;
    } on DioException catch (e) {
      return e.message ?? "删除学期失败";
    } catch (e) {
      return "删除学期失败";
    }
  }
}

class ApiSemesterResult {
  final String? message;
  final DateTime? startedAt;
  final String? semesterName;
  final List<List<TimeOfDay>>? phaseList;
  const ApiSemesterResult(
    this.message, {
    this.semesterName,
    this.startedAt,
    this.phaseList,
  });
}
