import 'package:flutter/material.dart';
import 'package:shine/models/course_data.dart';
import 'package:shine/models/schedule_reminder_data.dart';
import 'package:shine/services/notification.dart';
import 'package:shine/storage/schedule_reminder_storage.dart';

/// 日程提醒的排期：把「哪门课、提前多久提醒」变成系统的本地通知。
///
/// 每次课程 / 学期数据更新、或用户改了提醒设置时调用 [rescheduleAll]：
/// 先撤销上一批排期，再按当前设置重新排未来 [horizonDays] 天内的课次。
/// 采用滚动窗口而不是排满整个学期，既避开系统对同时排期数量的限制，
/// 也能在课表变动后自动纠正。
class ScheduleReminderService {
  /// 排期窗口：只排未来这么多天
  static const int horizonDays = 7;

  /// 单次最多排期的提醒条数
  static const int maxOccurrenceCount = 40;

  /// 按当前课表与提醒设置重排所有上课提醒，返回实际排期成功的条数
  static Future<int> rescheduleAll({
    required List<CourseData> courseList,
    required List<List<TimeOfDay>> phaseList,
    required DateTime? semesterStartedAt,
    DateTime? now,
  }) async {
    await _cancelScheduled();

    final settings = await ScheduleReminderStorage.getSettings();
    final occurrences = buildScheduleReminderOccurrences(
      courseList: courseList,
      settings: settings,
      phaseList: phaseList,
      semesterStartedAt: semesterStartedAt,
      now: now,
      horizonDays: horizonDays,
      maxCount: maxOccurrenceCount,
    );

    final scheduledIds = <int>[];
    for (var index = 0; index < occurrences.length; index++) {
      final occurrence = occurrences[index];
      final id = NotificationService.scheduleNotificationId(index);
      try {
        await NotificationService.zonedSchedule(
          id: id,
          scheduledDate: occurrence.remindAt,
          title: buildReminderTitle(occurrence),
          body: buildReminderBody(occurrence),
          payload: occurrence.subjectName,
        );
        scheduledIds.add(id);
      } catch (e) {
        // 单条排期失败不影响其它提醒
      }
    }
    await ScheduleReminderStorage.saveScheduledIds(scheduledIds);
    return scheduledIds.length;
  }

  /// 撤销之前排期的所有提醒
  static Future<void> _cancelScheduled() async {
    final previousIds = await ScheduleReminderStorage.getScheduledIds();
    for (final id in previousIds) {
      await NotificationService.cancelScheduled(id: id);
    }
    await ScheduleReminderStorage.saveScheduledIds(const []);
  }

  /// 通知标题
  static String buildReminderTitle(ScheduleReminderOccurrence occurrence) {
    return '上课提醒：${occurrence.displayName}';
  }

  /// 通知内容：第几节、几点开始、还有多久、在哪
  static String buildReminderBody(ScheduleReminderOccurrence occurrence) {
    final start = occurrence.classStart;
    final time =
        '${start.hour.toString().padLeft(2, '0')}:'
        '${start.minute.toString().padLeft(2, '0')}';
    final period = occurrence.startPeriod == occurrence.endPeriod
        ? '第 ${occurrence.startPeriod} 节'
        : '第 ${occurrence.startPeriod}-${occurrence.endPeriod} 节';
    final buffer = StringBuffer('$period $time 开始');
    if (occurrence.leadMinutes > 0) {
      buffer.write('，${_leadText(occurrence.leadMinutes)}后');
    }
    final location = occurrence.location;
    if (location != null && location.isNotEmpty) {
      buffer.write('，地点 $location');
    }
    return buffer.toString();
  }

  static String _leadText(int leadMinutes) {
    if (leadMinutes < 60) return '$leadMinutes 分钟';
    final hours = leadMinutes / 60;
    final text = hours == hours.roundToDouble()
        ? hours.round().toString()
        : hours.toStringAsFixed(1);
    return '$text 小时';
  }
}
