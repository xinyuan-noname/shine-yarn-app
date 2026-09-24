import 'package:flutter/material.dart';
import 'package:shine/models/course_data.dart';
import 'package:shine/models/holiday_data.dart';
import 'package:shine/utils/time_utils.dart';

/// 日程提醒设置：是否开启 + 提前多少分钟提醒
class ScheduleReminderSetting {
  final bool enabled;

  /// 提前提醒的分钟数
  final int leadMinutes;

  const ScheduleReminderSetting({
    this.enabled = false,
    this.leadMinutes = defaultLeadMinutes,
  });

  /// 默认提前 30 分钟
  static const int defaultLeadMinutes = 30;

  /// 关闭状态的默认设置
  static const ScheduleReminderSetting disabled = ScheduleReminderSetting();

  /// 弹窗里的常用提前量
  static const List<int> leadMinuteOptions = [5, 10, 15, 30, 60, 120];

  factory ScheduleReminderSetting.fromJson(Map<String, dynamic> json) {
    final lead = json['leadMinutes'];
    return ScheduleReminderSetting(
      enabled: json['enabled'] == true,
      leadMinutes: lead is int && lead >= 0 ? lead : defaultLeadMinutes,
    );
  }

  Map<String, dynamic> toJson() => {
    'enabled': enabled,
    'leadMinutes': leadMinutes,
  };

  ScheduleReminderSetting copyWith({bool? enabled, int? leadMinutes}) {
    return ScheduleReminderSetting(
      enabled: enabled ?? this.enabled,
      leadMinutes: leadMinutes ?? this.leadMinutes,
    );
  }

  /// 提前量的文案：不足 1 小时显示分钟，超过 1 小时写成「x 小时 y 分」
  String get leadText {
    if (leadMinutes <= 0) return '上课时';
    return '提前 ${formatMinutesText(leadMinutes)}';
  }

  @override
  bool operator ==(Object other) {
    return other is ScheduleReminderSetting &&
        other.enabled == enabled &&
        other.leadMinutes == leadMinutes;
  }

  @override
  int get hashCode => Object.hash(enabled, leadMinutes);
}

/// 把分钟数写成中文时长：45 -> 45 分钟，60 -> 1 小时，90 -> 1 小时 30 分
String formatMinutesText(int minutes) {
  if (minutes <= 0) return '0 分钟';
  if (minutes < 60) return '$minutes 分钟';
  final hours = minutes ~/ 60;
  final rest = minutes % 60;
  if (rest == 0) return '$hours 小时';
  return '$hours 小时 $rest 分';
}

/// 一次即将到来的上课提醒
class ScheduleReminderOccurrence {
  final String subjectName;
  final String? alias;

  /// 星期几，1 表示周一
  final int weekday;
  final int startPeriod;
  final int endPeriod;
  final String? location;

  /// 上课时间
  final DateTime classStart;

  /// 该发提醒的时间（上课时间减去提前量）
  final DateTime remindAt;
  final int leadMinutes;

  const ScheduleReminderOccurrence({
    required this.subjectName,
    required this.weekday,
    required this.startPeriod,
    required this.endPeriod,
    required this.classStart,
    required this.remindAt,
    required this.leadMinutes,
    this.alias,
    this.location,
  });

  /// 课程显示名（优先别名）
  String get displayName => alias?.isNotEmpty == true ? alias! : subjectName;

  @override
  String toString() {
    return 'ScheduleReminderOccurrence(subject: $subjectName, classStart: $classStart, remindAt: $remindAt, leadMinutes: $leadMinutes)';
  }
}

/// 依据课表数据算出未来一段时间内需要提醒的课次。
///
/// - 只处理 [settings] 里开启了提醒的课程；
/// - 尊重每个时间段自己的周次（[CourseSchedule.weeks]）；
/// - 只保留「现在还来得及提醒」且落在 [horizonDays] 天内的课次；
/// - 结果按提醒时间升序，最多 [maxCount] 条（系统对同时排期的通知数量有限制）。
List<ScheduleReminderOccurrence> buildScheduleReminderOccurrences({
  required List<CourseData> courseList,
  required Map<String, ScheduleReminderSetting> settings,
  required List<List<TimeOfDay>> phaseList,
  required DateTime? semesterStartedAt,
  DateTime? now,
  int horizonDays = 7,
  int maxCount = 40,
  List<HolidayRange> holidays = const [],
}) {
  if (semesterStartedAt == null || phaseList.isEmpty) return const [];
  final current = now ?? DateTime.now();
  // 第 1 周周一：学期开始日期所在那一周的周一
  final weekOneMonday = weekStartOf(semesterStartedAt);
  final horizonEnd = DateUtils.dateOnly(
    current,
  ).add(Duration(days: horizonDays));

  final occurrences = <ScheduleReminderOccurrence>[];
  for (final course in courseList) {
    final setting = settings[course.subjectName];
    if (setting == null || !setting.enabled) continue;
    final leadMinutes = setting.leadMinutes.clamp(0, 24 * 60);
    for (final session in course.schedule) {
      if (session.weekday < 1 || session.weekday > 7) continue;
      final startPeriod = session.start;
      if (startPeriod < 1 || startPeriod > phaseList.length) continue;
      final startTime = phaseList[startPeriod - 1][0];
      for (final week in session.weeks) {
        if (week < 1) continue;
        // 用日历天相加，避免夏令时导致日期偏移
        final date = DateTime(
          weekOneMonday.year,
          weekOneMonday.month,
          weekOneMonday.day + (week - 1) * 7 + session.weekday - 1,
        );
        if (date.isAfter(horizonEnd)) continue;
        // 节假日不上课，不排提醒
        if (holidayNameOf(date, holidays) != null) continue;
        final classStart = DateTime(
          date.year,
          date.month,
          date.day,
          startTime.hour,
          startTime.minute,
        );
        final remindAt = classStart.subtract(Duration(minutes: leadMinutes));
        // 提醒时间已经过了就跳过，避免补发一堆历史提醒
        if (!remindAt.isAfter(current)) continue;
        occurrences.add(
          ScheduleReminderOccurrence(
            subjectName: course.subjectName,
            alias: course.alias,
            weekday: session.weekday,
            startPeriod: startPeriod,
            endPeriod: session.end,
            location: session.location.trim().isEmpty
                ? null
                : session.location.trim(),
            classStart: classStart,
            remindAt: remindAt,
            leadMinutes: leadMinutes,
          ),
        );
      }
    }
  }
  occurrences.sort((a, b) => a.remindAt.compareTo(b.remindAt));
  if (occurrences.length > maxCount) {
    return occurrences.sublist(0, maxCount);
  }
  return occurrences;
}
