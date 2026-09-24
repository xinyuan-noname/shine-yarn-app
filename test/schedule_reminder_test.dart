import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shine/models/course_data.dart';
import 'package:shine/models/schedule_reminder_data.dart';
import 'package:shine/services/schedule_reminder_service.dart';
import 'package:shine/storage/schedule_reminder_storage.dart';

/// 每天 5 节课，起始时间分别是 08:00 / 10:00 / 14:00 / 16:00 / 19:00
final List<List<TimeOfDay>> _phaseList = [
  [const TimeOfDay(hour: 8, minute: 0), const TimeOfDay(hour: 9, minute: 40)],
  [const TimeOfDay(hour: 10, minute: 0), const TimeOfDay(hour: 11, minute: 40)],
  [const TimeOfDay(hour: 14, minute: 0), const TimeOfDay(hour: 15, minute: 40)],
  [const TimeOfDay(hour: 16, minute: 0), const TimeOfDay(hour: 17, minute: 40)],
  [const TimeOfDay(hour: 19, minute: 0), const TimeOfDay(hour: 20, minute: 40)],
];

CourseData _course({
  String name = '数字信号处理',
  required List<CourseSchedule> schedule,
}) {
  return CourseData(
    basicInfo: CourseBasicInfo(
      subjectName: name,
      courseType: '专业必修课',
      teachers: const ['李老师'],
      credit: 3,
      semester: '2026春',
    ),
    schedule: schedule,
  );
}

/// 2026-03-02 是周一
final DateTime _semesterStartedAt = DateTime(2026, 3, 2);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('提醒设置模型', () {
    test('提前量文案', () {
      expect(
        const ScheduleReminderSetting(enabled: true, leadMinutes: 30).leadText,
        '提前 30 分钟',
      );
      expect(
        const ScheduleReminderSetting(enabled: true, leadMinutes: 60).leadText,
        '提前 1 小时',
      );
      expect(
        const ScheduleReminderSetting(enabled: true, leadMinutes: 90).leadText,
        '提前 1.5 小时',
      );
      expect(
        const ScheduleReminderSetting(enabled: true, leadMinutes: 0).leadText,
        '上课时',
      );
    });

    test('默认提前 30 分钟，且默认关闭', () {
      expect(ScheduleReminderSetting.disabled.enabled, isFalse);
      expect(
        ScheduleReminderSetting.disabled.leadMinutes,
        ScheduleReminderSetting.defaultLeadMinutes,
      );
    });

    test('json 往返与容错', () {
      const setting = ScheduleReminderSetting(enabled: true, leadMinutes: 15);
      expect(ScheduleReminderSetting.fromJson(setting.toJson()), setting);
      // 缺失 / 非法字段退化为默认值
      expect(
        ScheduleReminderSetting.fromJson({'enabled': true}).leadMinutes,
        ScheduleReminderSetting.defaultLeadMinutes,
      );
      expect(
        ScheduleReminderSetting.fromJson({'leadMinutes': -5}).leadMinutes,
        ScheduleReminderSetting.defaultLeadMinutes,
      );
      expect(ScheduleReminderSetting.fromJson(const {}).enabled, isFalse);
    });
  });

  group('提醒课次计算', () {
    final courseList = [
      _course(
        schedule: [
          // 周一 1-2 节，全学期
          CourseSchedule(
            weekday: 1,
            period: const [1, 2],
            weeks: List.generate(16, (index) => index + 1),
            location: 'A101',
          ),
          // 周三 3-4 节，全学期
          CourseSchedule(
            weekday: 3,
            period: const [3, 4],
            weeks: List.generate(16, (index) => index + 1),
            location: 'B202',
          ),
        ],
      ),
      _course(
        name: '高等数学',
        schedule: [
          CourseSchedule(
            weekday: 2,
            period: const [1, 2],
            weeks: List.generate(16, (index) => index + 1),
            location: 'C303',
          ),
        ],
      ),
    ];
    const enabled30 = {
      '数字信号处理': ScheduleReminderSetting(enabled: true, leadMinutes: 30),
    };

    List<ScheduleReminderOccurrence> build({
      Map<String, ScheduleReminderSetting> settings = enabled30,
      DateTime? now,
      int horizonDays = 7,
      int maxCount = 40,
      List<CourseData>? courses,
    }) {
      return buildScheduleReminderOccurrences(
        courseList: courses ?? courseList,
        settings: settings,
        phaseList: _phaseList,
        semesterStartedAt: _semesterStartedAt,
        now: now ?? DateTime(2026, 3, 2, 7, 0),
        horizonDays: horizonDays,
        maxCount: maxCount,
      );
    }

    test('按提前量算出提醒时间，并按时间排序', () {
      final occurrences = build();
      expect(occurrences.length, 3);
      // 周一 08:00 的课提前 30 分钟 -> 07:30
      expect(occurrences[0].classStart, DateTime(2026, 3, 2, 8, 0));
      expect(occurrences[0].remindAt, DateTime(2026, 3, 2, 7, 30));
      expect(occurrences[0].startPeriod, 1);
      expect(occurrences[0].endPeriod, 2);
      expect(occurrences[0].location, 'A101');
      // 周三 14:00 的课 -> 13:30
      expect(occurrences[1].remindAt, DateTime(2026, 3, 4, 13, 30));
      // 下周一 07:30（还在 7 天窗口内）
      expect(occurrences[2].remindAt, DateTime(2026, 3, 9, 7, 30));
    });

    test('没开启提醒的课程不排期', () {
      expect(build(settings: const {}), isEmpty);
      expect(
        build(
          settings: const {
            '数字信号处理': ScheduleReminderSetting(enabled: false, leadMinutes: 30),
          },
        ),
        isEmpty,
      );
    });

    test('已经过了提醒时间的课次会被跳过', () {
      // 周一 08:00 再提前 30 分钟 = 07:30，此刻已经 08:05
      final occurrences = build(now: DateTime(2026, 3, 2, 8, 5));
      expect(
        occurrences.every(
          (item) => item.remindAt.isAfter(DateTime(2026, 3, 2, 8, 5)),
        ),
        isTrue,
      );
      expect(occurrences.first.remindAt, DateTime(2026, 3, 4, 13, 30));
    });

    test('窗口之外的课次不排期', () {
      final occurrences = build(horizonDays: 1);
      expect(occurrences.length, 1);
      expect(occurrences.single.remindAt, DateTime(2026, 3, 2, 7, 30));
    });

    test('周次决定课次是否出现', () {
      final onlyOddWeeks = [
        _course(
          schedule: [
            CourseSchedule(
              weekday: 1,
              period: const [1, 2],
              weeks: const [2, 3],
              location: 'A101',
            ),
          ],
        ),
      ];
      final occurrences = build(courses: onlyOddWeeks);
      // 第 1 周没有这节课，第 2 周（03-09）才出现
      expect(occurrences.length, 1);
      expect(occurrences.single.remindAt, DateTime(2026, 3, 9, 7, 30));
    });

    test('自定义提前量（含提前 1.5 小时与不提前）', () {
      // now 设成 06:00，否则周一 08:00 的课提前 90 分钟（06:30）还没到提醒点
      final early = build(
        now: DateTime(2026, 3, 2, 6, 0),
        settings: const {
          '数字信号处理': ScheduleReminderSetting(enabled: true, leadMinutes: 90),
        },
      );
      expect(early.first.remindAt, DateTime(2026, 3, 2, 6, 30));
      final onTime = build(
        settings: const {
          '数字信号处理': ScheduleReminderSetting(enabled: true, leadMinutes: 0),
        },
      );
      expect(onTime.first.remindAt, DateTime(2026, 3, 2, 8, 0));
    });

    test('条数上限会被裁剪（保留最近的）', () {
      final occurrences = build(horizonDays: 30, maxCount: 2);
      expect(occurrences.length, 2);
      expect(occurrences.first.remindAt, DateTime(2026, 3, 2, 7, 30));
      expect(occurrences.last.remindAt, DateTime(2026, 3, 4, 13, 30));
    });

    test('学期开始日期不是周一时按所在周的周一计算', () {
      final occurrences = buildScheduleReminderOccurrences(
        courseList: courseList,
        settings: enabled30,
        phaseList: _phaseList,
        // 2026-03-04 是周三，属于 03-02 那一周
        semesterStartedAt: DateTime(2026, 3, 4),
        now: DateTime(2026, 3, 2, 7, 0),
      );
      expect(occurrences.first.remindAt, DateTime(2026, 3, 2, 7, 30));
    });

    test('缺少学期开始时间或节次表时不排期', () {
      expect(
        buildScheduleReminderOccurrences(
          courseList: courseList,
          settings: enabled30,
          phaseList: _phaseList,
          semesterStartedAt: null,
        ),
        isEmpty,
      );
      expect(
        buildScheduleReminderOccurrences(
          courseList: courseList,
          settings: enabled30,
          phaseList: const [],
          semesterStartedAt: _semesterStartedAt,
        ),
        isEmpty,
      );
    });
  });

  group('通知文案', () {
    test('标题带课程名，正文包含节次 / 时间 / 提前量 / 地点', () {
      final occurrence = ScheduleReminderOccurrence(
        subjectName: '数字信号处理',
        weekday: 1,
        startPeriod: 1,
        endPeriod: 2,
        location: 'A101',
        classStart: DateTime(2026, 3, 2, 8, 0),
        remindAt: DateTime(2026, 3, 2, 7, 30),
        leadMinutes: 30,
      );
      expect(
        ScheduleReminderService.buildReminderTitle(occurrence),
        '上课提醒：数字信号处理',
      );
      expect(
        ScheduleReminderService.buildReminderBody(occurrence),
        '第 1-2 节 08:00 开始，30 分钟后，地点 A101',
      );
    });

    test('单节次 / 不提前 / 无地点时的文案', () {
      final occurrence = ScheduleReminderOccurrence(
        subjectName: '高等数学',
        alias: '高数',
        weekday: 2,
        startPeriod: 3,
        endPeriod: 3,
        classStart: DateTime(2026, 3, 3, 14, 0),
        remindAt: DateTime(2026, 3, 3, 14, 0),
        leadMinutes: 0,
      );
      expect(ScheduleReminderService.buildReminderTitle(occurrence), '上课提醒：高数');
      expect(
        ScheduleReminderService.buildReminderBody(occurrence),
        '第 3 节 14:00 开始',
      );
    });
  });

  group('提醒设置本地存储', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('默认没有任何设置', () async {
      expect(await ScheduleReminderStorage.getSettings(), isEmpty);
      final setting = await ScheduleReminderStorage.getSetting('数字信号处理');
      expect(setting.enabled, isFalse);
      expect(setting.leadMinutes, ScheduleReminderSetting.defaultLeadMinutes);
    });

    test('保存后可读回，互不影响', () async {
      await ScheduleReminderStorage.setSetting(
        '数字信号处理',
        const ScheduleReminderSetting(enabled: true, leadMinutes: 15),
      );
      await ScheduleReminderStorage.setSetting(
        '高等数学',
        const ScheduleReminderSetting(enabled: true, leadMinutes: 60),
      );
      final settings = await ScheduleReminderStorage.getSettings();
      expect(settings.length, 2);
      expect(settings['数字信号处理']?.leadMinutes, 15);
      expect(settings['高等数学']?.leadMinutes, 60);
    });

    test('已排期的通知 id 可读写', () async {
      expect(await ScheduleReminderStorage.getScheduledIds(), isEmpty);
      await ScheduleReminderStorage.saveScheduledIds([200000, 200001]);
      expect(await ScheduleReminderStorage.getScheduledIds(), [200000, 200001]);
      await ScheduleReminderStorage.saveScheduledIds(const []);
      expect(await ScheduleReminderStorage.getScheduledIds(), isEmpty);
    });

    test('损坏的数据不会抛异常', () async {
      SharedPreferences.setMockInitialValues({
        'schedule_reminder_setting_key': 'not a json',
        'schedule_reminder_scheduled_ids_key': '[1, "x", 2]',
      });
      expect(await ScheduleReminderStorage.getSettings(), isEmpty);
      expect(await ScheduleReminderStorage.getScheduledIds(), [1, 2]);
    });

    test('clear 会清掉设置与排期记录', () async {
      await ScheduleReminderStorage.setSetting(
        '数字信号处理',
        const ScheduleReminderSetting(enabled: true, leadMinutes: 30),
      );
      await ScheduleReminderStorage.saveScheduledIds([200000]);
      await ScheduleReminderStorage.clear();
      expect(await ScheduleReminderStorage.getSettings(), isEmpty);
      expect(await ScheduleReminderStorage.getScheduledIds(), isEmpty);
    });
  });
}
