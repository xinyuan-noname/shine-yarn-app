import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shine/models/course_data.dart';
import 'package:shine/storage/elective_storage.dart';
import 'package:shine/theme.dart';
import 'package:shine/views/schedule_view.dart';

CourseData _course({
  required String name,
  required String type,
  required int weekday,
  List<int> weeks = const [1],
}) {
  return CourseData(
    basicInfo: CourseBasicInfo(
      subjectName: name,
      courseType: type,
      teachers: const ['测试老师'],
      credit: 2,
      semester: '2026春',
    ),
    schedule: [
      CourseSchedule(
        weekday: weekday,
        period: const [1, 2],
        weeks: weeks,
        location: 'A101',
      ),
    ],
  );
}

/// 判断某个课程格上是否显示着「上课提醒」铃铛角标
bool _hasReminderBadge(WidgetTester tester, String courseName) {
  final cell = find.ancestor(
    of: find.text(courseName),
    matching: find.byType(InkWell),
  );
  return find
      .descendant(of: cell, matching: find.byIcon(Icons.notifications_active))
      .evaluate()
      .isNotEmpty;
}

/// 判断某个课程格是否使用了指定底色
bool _hasBackgroundColor(WidgetTester tester, String courseName, Color color) {
  final containers = find.ancestor(
    of: find.text(courseName),
    matching: find.byType(Container),
  );
  for (final element in containers.evaluate()) {
    final decoration = (element.widget as Container).decoration;
    if (decoration is BoxDecoration && decoration.color == color) {
      return true;
    }
  }
  return false;
}

/// 判断某个课程格是否使用了专业任选课的橙色底色
bool _hasOrangeBackground(WidgetTester tester, String courseName) {
  return _hasBackgroundColor(tester, courseName, deepColorOrange);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('专业任选课识别', () {
    test('课程类型包含「专业任选」即视为专业任选课', () {
      expect(isMajorElectiveCourseType('专业任选课'), isTrue);
      expect(isMajorElectiveCourseType('专业任选'), isTrue);
      expect(isMajorElectiveCourseType('专业任选（限选）'), isTrue);
    });

    test('其它课程类型不会被误判', () {
      expect(isMajorElectiveCourseType('专业必修课'), isFalse);
      expect(isMajorElectiveCourseType('公共选修课'), isFalse);
      expect(isMajorElectiveCourseType('实验'), isFalse);
      expect(isMajorElectiveCourseType(''), isFalse);
      expect(isMajorElectiveCourseType(null), isFalse);
    });

    test('CourseData 能从 json 推断专业任选课', () {
      final elective = CourseData.fromJson({
        'subjectName': '数字信号处理',
        'courseType': '专业任选课',
        'teachers': ['李老师'],
        'credit': 2.0,
        'schedule': [
          {
            'weekday': 2,
            'period': [1, 2],
            'weeks': [1],
            'location': 'A101',
          },
        ],
      });
      final required = CourseData.fromJson({
        'subjectName': '高等数学',
        'courseType': '专业必修课',
      });
      expect(elective.isMajorElective, isTrue);
      expect(required.isMajorElective, isFalse);
    });
  });

  group('实验课识别', () {
    test('课程类型为「实验」或科目名带实验后缀都算实验课', () {
      expect(isExperimentCourseType('实验', '随便什么课'), isTrue);
      expect(isExperimentCourseType('专业任选课', '数字信号处理实验'), isTrue);
      expect(isExperimentCourseType('专业必修课', '大学物理（实验）'), isTrue);
      expect(isExperimentCourseType('专业必修课', '大学物理(实验)'), isTrue);
      expect(isExperimentCourseType('专业任选课', '数字信号处理'), isFalse);
      // 名字里含「实验」但不是实验后缀，不算实验课
      expect(isExperimentCourseType('专业必修课', '实验心理学'), isFalse);
    });

    test('实验课能推出母课程名', () {
      expect(resolveExperimentBaseName('数字信号处理实验'), '数字信号处理');
      expect(resolveExperimentBaseName('大学物理（实验）'), '大学物理');
      expect(resolveExperimentBaseName('高等数学'), '高等数学');
    });

    test('CourseData 暴露实验课与母课程信息', () {
      final lab = CourseData.fromJson({
        'subjectName': '数字信号处理实验',
        'courseType': '专业任选课',
      });
      expect(lab.isExperiment, isTrue);
      expect(lab.experimentBaseName, '数字信号处理');
      expect(lab.isMajorElective, isTrue);
    });
  });

  group('ElectiveStorage 本地选课状态', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('默认没有任何记录，即全部视为已选', () async {
      expect(await ElectiveStorage.getSelection('2026春'), isEmpty);
    });

    test('保存后可按学期读回', () async {
      await ElectiveStorage.saveSelection('2026春', {
        '数字信号处理': true,
        '嵌入式系统': false,
      });
      expect(await ElectiveStorage.getSelection('2026春'), {
        '数字信号处理': true,
        '嵌入式系统': false,
      });
      // 其它学期互不影响
      expect(await ElectiveStorage.getSelection('2026秋'), isEmpty);
    });

    test('setSelected 只更新单个科目，clearSelection 恢复默认', () async {
      await ElectiveStorage.setSelected('2026春', '嵌入式系统', false);
      expect(await ElectiveStorage.getSelection('2026春'), {'嵌入式系统': false});
      await ElectiveStorage.setSelected('2026春', '嵌入式系统', true);
      expect(await ElectiveStorage.getSelection('2026春'), {'嵌入式系统': true});
      await ElectiveStorage.clearSelection('2026春');
      expect(await ElectiveStorage.getSelection('2026春'), isEmpty);
    });

    test('损坏的本地数据不会导致异常', () async {
      SharedPreferences.setMockInitialValues({
        'major_elective_selection_key': 'not a json',
      });
      expect(await ElectiveStorage.getSelection('2026春'), isEmpty);
    });
  });

  group('课表中的专业任选课展示', () {
    final semesterStartedAt = DateTime(2026, 3, 2);
    final showDate = DateTime(2026, 3, 4);
    final phaseList = List.generate(
      5,
      (index) => [
        TimeOfDay(hour: 8 + index, minute: 0),
        TimeOfDay(hour: 8 + index, minute: 45),
      ],
    );
    final subjectInfoList = [
      _course(name: '高等数学', type: '专业必修课', weekday: 1),
      _course(name: '数字信号处理', type: '专业任选课', weekday: 2),
      _course(name: '嵌入式系统', type: '专业任选课', weekday: 3),
      // 专业任选课「数字信号处理」的实验课，跟随母课程
      _course(name: '数字信号处理实验', type: '专业任选课', weekday: 4),
      // 非专业任选课的实验课，不受选课状态影响
      _course(name: '大学物理实验', type: '专业必修课', weekday: 5),
    ];

    Future<void> pumpSchedule(WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ScheduleView(
              semesterName: '2026春',
              semesterStartedAt: semesterStartedAt,
              semesterPhaseList: phaseList,
              subjectInfoList: subjectInfoList,
              scheduleDataList: const [],
              showDate: showDate,
              onRefresh: () async {},
              onChangeShowDate: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('已选的专业任选课使用橙色显示，普通课程不变', (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({
        'major_elective_selection_key': jsonEncode({
          '2026春': {'数字信号处理': true, '嵌入式系统': true},
        }),
      });
      await pumpSchedule(tester);
      expect(find.text('数字信号处理'), findsOneWidget);
      expect(_hasOrangeBackground(tester, '数字信号处理'), isTrue);
      expect(_hasOrangeBackground(tester, '高等数学'), isFalse);
      expect(find.text('选修课 2/2'), findsOneWidget);
    });

    testWidgets('未选的专业任选课不在课表中显示', (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({
        'major_elective_selection_key': jsonEncode({
          '2026春': {'数字信号处理': true, '嵌入式系统': false},
        }),
      });
      await pumpSchedule(tester);
      expect(find.text('数字信号处理'), findsOneWidget);
      expect(find.text('嵌入式系统'), findsNothing);
      expect(find.text('选修课 1/2'), findsOneWidget);
    });

    testWidgets('没有本地记录时全部专业任选课默认显示为橙色', (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      await pumpSchedule(tester);
      expect(_hasOrangeBackground(tester, '数字信号处理'), isTrue);
      expect(_hasOrangeBackground(tester, '嵌入式系统'), isTrue);
      expect(find.text('选修课 2/2'), findsOneWidget);
    });

    testWidgets('专业任选课的实验课跟随课程显示并带上实验下标', (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({
        'major_elective_selection_key': jsonEncode({
          '2026春': {'数字信号处理': true, '嵌入式系统': true},
        }),
      });
      await pumpSchedule(tester);
      expect(find.text('数字信号处理实验'), findsOneWidget);
      // 跟随母课程使用橙色
      expect(_hasOrangeBackground(tester, '数字信号处理实验'), isTrue);
      // 两门实验课都带实验下标（红色烧瓶图标）
      expect(find.byIcon(Icons.science), findsNWidgets(2));
      // 实验课不单独计入选课列表
      expect(find.text('选修课 2/2'), findsOneWidget);
    });

    testWidgets('专业任选课未选时其实验课一并隐藏', (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({
        'major_elective_selection_key': jsonEncode({
          '2026春': {'数字信号处理': false, '嵌入式系统': true},
        }),
      });
      await pumpSchedule(tester);
      expect(find.text('数字信号处理'), findsNothing);
      expect(find.text('数字信号处理实验'), findsNothing);
      // 非专业任选课的实验课不受影响，仍带实验下标
      expect(find.text('大学物理实验'), findsOneWidget);
      expect(_hasOrangeBackground(tester, '大学物理实验'), isFalse);
      expect(find.byIcon(Icons.science), findsOneWidget);
      expect(find.text('选修课 1/2'), findsOneWidget);
    });
    testWidgets('节假日的课程显示为灰色', (WidgetTester tester) async {
      // 2026-03-04（周三）放假；缓存未过期，不会触发联网
      SharedPreferences.setMockInitialValues({
        'holiday_cache_key': jsonEncode([
          {'start': '2026-03-04', 'end': '2026-03-04', 'name': '校庆'},
        ]),
        'holiday_cache_synced_at_key': DateTime.now().toIso8601String(),
      });
      await pumpSchedule(tester);
      // 周三那门课变灰
      expect(_hasBackgroundColor(tester, '嵌入式系统', mainColorHoliday), isTrue);
      // 其它天的课程不受影响
      expect(_hasOrangeBackground(tester, '数字信号处理'), isTrue);
    });

    testWidgets('节假日的课程不显示提醒铃铛角标', (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({
        // 2026-03-04（周三）放假；缓存未过期，不会触发联网
        'holiday_cache_key': jsonEncode([
          {'start': '2026-03-04', 'end': '2026-03-04', 'name': '校庆'},
        ]),
        'holiday_cache_synced_at_key': DateTime.now().toIso8601String(),
        // 周三、周二两门课都开了上课提醒
        'schedule_reminder_setting_key': jsonEncode({
          '嵌入式系统': {'enabled': true, 'leadMinutes': 30},
          '数字信号处理': {'enabled': true, 'leadMinutes': 30},
        }),
      });
      await pumpSchedule(tester);
      // 节假日那门课不会响，因此不显示铃铛
      expect(_hasReminderBadge(tester, '嵌入式系统'), isFalse);
      // 正常上课的那天仍然有铃铛
      expect(_hasReminderBadge(tester, '数字信号处理'), isTrue);
    });

    testWidgets('没有节假日时课程按原配色显示', (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      await pumpSchedule(tester);
      expect(_hasBackgroundColor(tester, '嵌入式系统', mainColorHoliday), isFalse);
      expect(_hasOrangeBackground(tester, '嵌入式系统'), isTrue);
    });
  });
}
