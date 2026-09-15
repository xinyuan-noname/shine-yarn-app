import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:shine/components/bottom_sheet.dart';
import 'package:shine/components/dialog.dart';
import 'package:shine/components/line.dart';
import 'package:shine/extensions/list.dart';
import 'package:shine/pages/home_page.dart';
import 'package:shine/storage/subject_storage.dart';
import 'package:shine/theme.dart';
import 'package:shine/models/course_data.dart';
import 'package:shine/utils/time_utils.dart';
import 'package:week_of_year/date_week_extensions.dart';

/// 基准尺寸，以 360 宽屏幕下的课表为基准，其它屏幕按比例自适应
const double _baseCellWidth = 35;
const double _baseCourseHeight = 60;

/// 单列最小宽度，避免屏幕过窄时单元格被压扁
const double _minCellWidth = 30;

/// 课表最小展示宽度，低于该宽度时提示用户
const double _minScreenWidth = 360;

/// 单节课的最小 / 最大高度（最大值会随文字缩放一起放大）
const double _minCourseHeight = _baseCourseHeight;
const double _maxCourseHeight = 120;

/// 文字最大放大倍数，避免大屏下单元格文字被拉得过大
const double _maxTextScale = 1.8;

/// 列数：节次列 + 7 天
const int _columnCount = 8;
const double _cardPadding = 20;

const _baseTitleTextStyle = TextStyle(fontFamily: "SmileySans", fontSize: 12);
const _baseDayTextStyle = TextStyle(
  fontFamily: "SmileySans",
  fontSize: 10,
  color: Colors.grey,
);
const _basePeriodTextStyle = TextStyle(fontFamily: "SmileySans", fontSize: 10);
const _baseTimeTextStyle = TextStyle(
  fontFamily: "SmileySans",
  fontSize: 8,
  color: Colors.grey,
);
const _baseCourseTextStyle = TextStyle(fontFamily: "SmileySans", fontSize: 10);
const _baseLocationTextStyle = TextStyle(
  fontFamily: "SmileySans",
  fontSize: 10,
  color: bgColorLight,
);

/// 依据可用宽度求单列宽度，保证 8 列刚好铺满可用宽度
double _resolveCellWidth(double availableWidth) {
  return max(_minCellWidth, availableWidth / _columnCount);
}

/// 依据可用高度与节次数求单节课高度：空间足够时铺满可视区域，不足时保持最小高度并滚动
double _resolveCourseHeight(
  double availableHeight,
  int phaseCount,
  double textScale,
) {
  if (phaseCount <= 0) return _baseCourseHeight;
  return (availableHeight / phaseCount)
      .clamp(_minCourseHeight, _maxCourseHeight * textScale)
      .toDouble();
}

/// 课表自适应布局参数：列宽、课程行高、文字缩放均由可用空间推导
class _ScheduleLayout {
  /// 单列（节次列 / 某一天）宽度
  final double cellWidth;

  /// 单节课（一个节次）的高度
  final double courseHeight;

  const _ScheduleLayout({required this.cellWidth, required this.courseHeight});

  /// 只依据可用宽度推导，用于表头等与行高无关的部分
  factory _ScheduleLayout.fromWidth(double availableWidth) => _ScheduleLayout(
    cellWidth: _resolveCellWidth(availableWidth),
    courseHeight: _minCourseHeight,
  );

  _ScheduleLayout withCourseHeight(double height) =>
      _ScheduleLayout(cellWidth: cellWidth, courseHeight: height);

  /// 文字 / 图标相对基准尺寸的缩放比例
  double get textScale =>
      (cellWidth / _baseCellWidth).clamp(1.0, _maxTextScale).toDouble();

  TextStyle _scaled(TextStyle style) =>
      style.copyWith(fontSize: (style.fontSize ?? 0) * textScale);

  TextStyle get titleTextStyle => _scaled(_baseTitleTextStyle);
  TextStyle get dayTextStyle => _scaled(_baseDayTextStyle);
  TextStyle get periodTextStyle => _scaled(_basePeriodTextStyle);
  TextStyle get timeTextStyle => _scaled(_baseTimeTextStyle);
  TextStyle get courseTextStyle => _scaled(_baseCourseTextStyle);
  TextStyle get locationTextStyle => _scaled(_baseLocationTextStyle);

  /// 课程格内部的小间距 / 图标尺寸
  double get cellPadding => 2 * textScale;
  double get cellTopPadding => 5 * textScale;
  double get labIconSize => 10 * textScale;
}

const List<Color> _courseColorList = [
  mainColorPurple50,
  mainColorPurple60,
  mainColorPurple70,
  mainColorPurple80,
  mainColorPurple90,
  mainColorPurple95,
  deepColorPurple90,
  darkColorPurple,
];

typedef ChangeShowWeekCallback = void Function(DateTime d);

class ScheduleView extends StatelessWidget {
  final String? semesterName;
  final DateTime? semesterStartedAt;
  final List<List<TimeOfDay>> semesterPhaseList;
  final RefreshCallback onRefresh;
  final DateTime showDate;
  final List<CourseData> subjectInfoList;
  final List<ScheduleData> scheduleDataList;
  final ChangeShowWeekCallback onChangeShowDate;
  const ScheduleView({
    super.key,
    this.semesterName,
    this.semesterStartedAt,
    required this.semesterPhaseList,
    required this.scheduleDataList,
    required this.subjectInfoList,
    required this.onRefresh,
    required this.onChangeShowDate,
    required this.showDate,
  });

  @override
  Widget build(BuildContext context) {
    try {
      final Size screenSize = MediaQuery.of(context).size;
      if (screenSize.width < _minScreenWidth) {
        return Container(
          alignment: Alignment.topCenter,
          child: const Text(
            "宽度不足以展示课表！",
            style: viewEmptyTextStyle,
            textAlign: TextAlign.center,
          ),
        );
      }
      return SizedBox.expand(
        child: Container(
          padding: bodyPadding,
          child: Container(
            padding: const EdgeInsets.all(_cardPadding),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey,
                  spreadRadius: 1,
                  blurRadius: 5,
                  offset: const Offset(0, 3),
                ),
              ],
              gradient: whiteLinearGradient,
            ),
            // 按可用宽度推导列宽，使表格恰好铺满屏幕宽度
            child: LayoutBuilder(
              builder: (context, constraints) {
                final columnLayout = _ScheduleLayout.fromWidth(
                  constraints.maxWidth,
                );
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "${semesterName ?? "未知学期"}(第${_getCurrentWeek()}周)",
                      style: labelStyle,
                    ),
                    bottomLine,
                    SizedBox(
                      child: Row(
                        children: [
                          InkWell(
                            onTap: () async {
                              if (semesterStartedAt == null) return;
                              final result = await showWeekBottomSheet(
                                context,
                                startedAt: semesterStartedAt!,
                                selectedDate: showDate,
                              );
                              if (result != null) {
                                onChangeShowDate(result);
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.only(
                                top: 1,
                                bottom: 1,
                                left: 20,
                                right: 18,
                              ),
                              margin: const EdgeInsets.symmetric(vertical: 3),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                color: mainColorGreenBlue,
                                boxShadow: [
                                  BoxShadow(
                                    blurRadius: 10,
                                    color: mainColorGrey20,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                              child: Text(
                                '第${_getShowTimeWeek()}周▼',
                                style: const TextStyle(
                                  fontFamily: "SmileySans",
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // 表格区域占满剩余高度，随屏幕高度自适应
                    Expanded(
                      child: Container(
                        width: double.infinity,
                        decoration: const BoxDecoration(
                          color: bgColorLight,
                          borderRadius: BorderRadius.all(Radius.circular(5)),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                SizedBox(
                                  width: columnLayout.cellWidth,
                                  child: Container(
                                    alignment: Alignment.center,
                                    child: Text(
                                      '${showDate.month}月',
                                      style: columnLayout.titleTextStyle,
                                    ),
                                  ),
                                ),
                                ..._genTableTitleList(context, columnLayout),
                              ],
                            ),
                            bottomLineSmall,
                            // 依据剩余高度计算单节课高度，空间足够时无需滚动
                            Expanded(
                              child: LayoutBuilder(
                                builder: (context, bodyConstraints) {
                                  final layout = columnLayout.withCourseHeight(
                                    _resolveCourseHeight(
                                      bodyConstraints.maxHeight,
                                      semesterPhaseList.length,
                                      columnLayout.textScale,
                                    ),
                                  );
                                  return RefreshIndicator(
                                    onRefresh: onRefresh,
                                    child: SingleChildScrollView(
                                      physics:
                                          const AlwaysScrollableScrollPhysics(),
                                      padding: EdgeInsets.zero,
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        children: [
                                          _genPhaseList(layout),
                                          ..._genCourseColumn(context, layout),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      );
    } catch (e) {
      SubjectStorage.delCurrentDiySubjectInfo().then((_) {
        HomePageRefreshNotifier.refreshSchedule();
      });
      return const Text("数据出错", style: viewEmptyTextStyle);
    }
  }

  List<Widget> _genTableTitleList(
    BuildContext context,
    _ScheduleLayout layout,
  ) {
    return getWeekDates(showDate)
        .map(
          (d) => GestureDetector(
            onLongPress: () {
              showSchedulePointDialog(context: context);
            },
            onDoubleTap: () {
              showDailySchedulePointDialog(
                context: context,
                date: d,
                weekday: d.weekday,
              );
            },
            child: Container(
              width: layout.cellWidth,
              color: isToday(d) ? mainColorGreenBlue : Colors.transparent,
              child: Column(
                children: [
                  Text(getCnWeekDayName(d), style: layout.titleTextStyle),
                  Text(d.day.toString(), style: layout.dayTextStyle),
                ],
              ),
            ),
          ),
        )
        .toList();
  }

  List<(CourseBasicInfo, CourseSchedule)> _getshowSubjectInfoList() {
    final List<(CourseBasicInfo, CourseSchedule)> result = [];
    for (final subject in subjectInfoList) {
      final schedule = subject.findScheduleByWeek(_getShowTimeWeek());
      if (schedule == null) continue;
      for (final scheduleItem in schedule) {
        result.add((subject.basicInfo, scheduleItem));
      }
    }
    result.sort((a, b) {
      final r = a.$2.weekday.compareTo(b.$2.weekday);
      if (r == 0) return a.$2.period[0].compareTo(b.$2.period[0]);
      return r;
    });
    return result;
  }

  List<ScheduleData> _getShowScheduleDataList() {
    final result = scheduleDataList.where((element) {
      return element.week == _getShowTimeWeek();
    }).toList();
    result.sort((a, b) {
      final r = a.weekday.compareTo(b.weekday);
      if (r == 0) return a.periodStart.compareTo(b.periodStart);
      return r;
    });
    return result;
  }

  List<Widget> _genCourseColumn(BuildContext context, _ScheduleLayout layout) {
    final courseList = _getshowSubjectInfoList();
    final scheduleDataList = _getShowScheduleDataList();
    return getWeekDates(showDate).map((d) {
      return Container(
        decoration: isToday(d)
            ? BoxDecoration(boxShadow: [BoxShadow(color: mainColorGreenBlue)])
            : null,
        width: layout.cellWidth,
        child: Column(
          // 让课程格铺满整列宽度
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: _genCourseRow(
            context: context,
            courseList: courseList,
            date: d,
            scheduleDataList: scheduleDataList,
            layout: layout,
          ),
        ),
      );
    }).toList();
  }

  Widget _genEmptyCourse(
    BuildContext context, {
    required int weekday,
    required int startPeriod,
    required _ScheduleLayout layout,
  }) {
    return GestureDetector(
      child: Container(
        height: layout.courseHeight,
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: mainColorGrey20)),
        ),
      ),
      onTap: () async {
        final data = await showCourseDataEditDialog(
          context: context,
          courseData: CourseData(
            basicInfo: CourseBasicInfo(
              subjectName: '',
              courseType: '选修课',
              credit: 0.0,
              semester: semesterName,
            ),
            schedule: [
              CourseSchedule(
                weekday: weekday,
                period: [startPeriod, startPeriod + 1],
                weeks: [_getWeek(showDate)],
                location: '',
              ),
            ],
          ),
        );
        if (data != null) {
          await SubjectStorage.addCurrentDiySubjectInfo(data);
          HomePageRefreshNotifier.refreshSchedule();
        }
      },
    );
  }

  bool _isLabClass(
    (CourseBasicInfo, CourseSchedule) scheduleItem,
    ScheduleData? scheduleData,
  ) {
    return scheduleItem.$1.courseType == "实验" ||
        scheduleData?.isExperiment == true;
  }

  String _getLocation(
    (CourseBasicInfo, CourseSchedule) scheduleItem,
    ScheduleData? scheduleData,
  ) {
    final dataLocation = scheduleData?.location;
    if (dataLocation is String && dataLocation.isNotEmpty) {
      return dataLocation;
    }
    if (scheduleItem.$2.location.isNotEmpty) {
      return scheduleItem.$2.location;
    }
    return "暂无场地信息";
  }

  String _getCourseName(
    (CourseBasicInfo, CourseSchedule) scheduleItem,
    ScheduleData? scheduleData,
  ) {
    final aliasData = scheduleData?.alias;
    if (aliasData is String && aliasData.isNotEmpty) return aliasData;
    return scheduleItem.$1.alias ?? scheduleItem.$1.subjectName;
  }

  List<Widget> _genCourseRow({
    required List<(CourseBasicInfo, CourseSchedule)> courseList,
    required DateTime date,
    required List<ScheduleData> scheduleDataList,
    required BuildContext context,
    required _ScheduleLayout layout,
  }) {
    final List<Widget> children = [];
    final index = date.weekday - 1;
    for (int i = 1; i <= semesterPhaseList.length; i++) {
      ScheduleData? currentScheduleData = scheduleDataList.elementAtOrNull(0);
      final scheduleItem = courseList.elementAtOrNull(0);
      for (final item in courseList) {
        if (item == scheduleItem) continue;
        if (item.$2.weekday == date.weekday && item.$2.start == i) {
          courseList.remove(item);
        } else {
          break;
        }
      }
      if (scheduleItem == null) {
        children.add(
          _genEmptyCourse(
            context,
            weekday: date.weekday,
            startPeriod: i,
            layout: layout,
          ),
        );
        continue;
      }
      if (scheduleItem.$2.weekday == date.weekday &&
          scheduleItem.$2.start == i) {
        ScheduleData? mappedScheduleData;
        if (currentScheduleData?.weekday == date.weekday &&
            currentScheduleData?.periodStart == i) {
          mappedScheduleData = scheduleDataList.safeRemoveAt(0);
        }
        String courseName = _getCourseName(scheduleItem, mappedScheduleData);
        String location = _getLocation(scheduleItem, mappedScheduleData);
        CourseData courseData = subjectInfoList.firstWhere(
          (data) => data.subjectName == scheduleItem.$1.subjectName,
        );
        children.add(
          InkWell(
            onTap: () {
              showScheduleDialog(
                context: context,
                courseName: courseName,
                location: location,
                courseInfo: scheduleItem.$1,
                courseSchedule: scheduleItem.$2,
                scheduleData: mappedScheduleData,
                onJump: (name) {
                  HomePageRefreshNotifier.viewGoto(3);
                  HomePageRefreshNotifier.flagViewGoto(1);
                  HomePageRefreshNotifier.changeResource(name);
                },
                isDiy: SubjectStorage.diySubjectNameList.contains(
                  scheduleItem.$1.subjectName,
                ),
                courseData: courseData,
              );
            },
            onLongPress: () async {
              if (SubjectStorage.diySubjectNameList.contains(
                scheduleItem.$1.subjectName,
              )) {
                final data = await showCourseDataEditDialog(
                  context: context,
                  courseData: courseData,
                );
                if (data != null) {
                  await SubjectStorage.removeCurrentDiySubjectInfo(
                    scheduleItem.$1.subjectName,
                  );
                  await SubjectStorage.addCurrentDiySubjectInfo(data);
                  HomePageRefreshNotifier.refreshSchedule();
                }
              }
            },
            child: Container(
              height: layout.courseHeight * scheduleItem.$2.periodLength,
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: bgColorLight),
                  left: BorderSide(color: bgColorLight),
                ),
                color: _courseColorList.elementAt(index),
                borderRadius: BorderRadius.circular(5),
              ),
              child: Stack(
                children: [
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: layout.cellPadding) +
                        EdgeInsets.only(top: layout.cellTopPadding),
                    child: Wrap(
                      children: [
                        Text(courseName, style: layout.courseTextStyle),
                        Text(location, style: layout.locationTextStyle),
                      ],
                    ),
                  ),
                  if (_isLabClass(scheduleItem, mappedScheduleData))
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: EdgeInsets.all(layout.cellPadding),
                        decoration: BoxDecoration(
                          color: mainColorRed,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.science,
                          size: layout.labIconSize,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
        i = scheduleItem.$2.end;
        courseList.remove(scheduleItem);
        continue;
      }
      children.add(
        _genEmptyCourse(
          context,
          weekday: date.weekday,
          startPeriod: i,
          layout: layout,
        ),
      );
    }
    return children;
  }

  Widget _genPhaseList(_ScheduleLayout layout) {
    return SizedBox(
      width: layout.cellWidth,
      child: Column(
        children: List.generate(semesterPhaseList.length, (index) {
          final phase = semesterPhaseList[index];
          final start = phase[0];
          final end = phase[1];
          return SizedBox(
            height: layout.courseHeight,
            child: Column(
              children: [
                Text((index + 1).toString(), style: layout.periodTextStyle),
                Text(
                  '${start.hour >= 10 ? start.hour : '0${start.hour}'}:${start.minute >= 10 ? start.minute : '0${start.minute}'}',
                  style: layout.timeTextStyle,
                ),
                Text(
                  '${end.hour >= 10 ? end.hour : '0${end.hour}'}:${end.minute >= 10 ? end.minute : '0${end.minute}'}',
                  style: layout.timeTextStyle,
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  int _getCurrentWeek() {
    return _getWeek(DateTime.now());
  }

  int _getWeek(DateTime d) {
    if (semesterStartedAt == null) return 0;
    final s = semesterStartedAt?.weekOfYear ?? 1;
    final e = d.weekOfYear;
    return e - s + 1;
  }

  int _getShowTimeWeek() {
    return _getWeek(showDate);
  }
}
