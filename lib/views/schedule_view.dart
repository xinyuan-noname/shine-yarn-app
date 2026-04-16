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

const _titleTextStyle = TextStyle(fontFamily: "SmileySans", fontSize: 12);
const _timeTextStyle = TextStyle(
  fontFamily: "SmileySans",
  fontSize: 8,
  color: Colors.grey,
);
const double _cellWidth = 35;
const double _courseHeight = 60;
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
      Size screenSize = MediaQuery.of(context).size;
      if (screenSize.width < 360) {
        return Container(
          alignment: Alignment.topCenter,
          child: Text(
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
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey,
                  spreadRadius: 1,
                  blurRadius: 5,
                  offset: Offset(0, 3),
                ),
              ],
              gradient: whiteLinearGradient,
            ),
            child: Column(
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
                          padding: EdgeInsets.only(
                            top: 1,
                            bottom: 1,
                            left: 20,
                            right: 18,
                          ),
                          margin: EdgeInsets.symmetric(vertical: 3),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: mainColorGreenBlue,
                            boxShadow: [
                              BoxShadow(
                                blurRadius: 10,
                                color: mainColorGrey20,
                                offset: Offset(0, 1),
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
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: bgColorLight,
                    borderRadius: BorderRadius.all(Radius.circular(5)),
                  ),
                  child: SizedBox(
                    width: 245,
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: _cellWidth,
                              child: Container(
                                alignment: Alignment.center,
                                child: Text(
                                  '${showDate.month}月',
                                  style: _titleTextStyle,
                                ),
                              ),
                            ),
                            ..._genTableTitleList(),
                          ],
                        ),
                        bottomLineSmall,
                        SizedBox(
                          height: min(
                            screenSize.height * 0.630136986301369,
                            460,
                          ),
                          child: RefreshIndicator(
                            onRefresh: onRefresh,
                            child: SingleChildScrollView(
                              padding: EdgeInsets.all(0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  _genPhaseList(),
                                  ..._genCourseColumn(context),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
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

  List<Widget> _genTableTitleList() {
    return getWeekDates(showDate)
        .map(
          (d) => Container(
            width: _cellWidth,
            color: isToday(d) ? mainColorGreenBlue : Colors.transparent,
            child: Column(
              children: [
                Text(getCnWeekDayName(d), style: _titleTextStyle),
                Text(
                  d.day.toString(),
                  style: const TextStyle(
                    color: Colors.grey,
                    fontFamily: "SmileySans",
                    fontSize: 10,
                  ),
                ),
              ],
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

  List<Widget> _genCourseColumn(BuildContext context) {
    final courseList = _getshowSubjectInfoList();
    final scheduleDataList = _getShowScheduleDataList();
    return getWeekDates(showDate).map((d) {
      return Container(
        decoration: isToday(d)
            ? BoxDecoration(boxShadow: [BoxShadow(color: mainColorGreenBlue)])
            : null,
        width: _cellWidth,
        child: Column(
          children: _genCourseRow(
            context: context,
            courseList: courseList,
            date: d,
            scheduleDataList: scheduleDataList,
          ),
        ),
      );
    }).toList();
  }

  Widget _genEmptyCourse(
    BuildContext context, {
    required int weekday,
    required int startPeriod,
  }) {
    return GestureDetector(
      child: Container(
        height: _courseHeight,
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: mainColorGrey20)),
        ),
      ),
      onLongPress: () async {
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
          _genEmptyCourse(context, weekday: date.weekday, startPeriod: i),
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
              height: _courseHeight * scheduleItem.$2.periodLength,
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
                        EdgeInsets.symmetric(horizontal: 2) +
                        EdgeInsets.only(top: 5),
                    child: Wrap(
                      children: [
                        Text(
                          courseName,
                          style: const TextStyle(
                            fontFamily: "SmileySans",
                            fontSize: 10,
                          ),
                        ),
                        Text(
                          location,
                          style: const TextStyle(
                            fontFamily: "SmileySans",
                            fontSize: 10,
                            color: bgColorLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_isLabClass(scheduleItem, mappedScheduleData))
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: mainColorRed,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.science,
                          size: 10,
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
        _genEmptyCourse(context, weekday: date.weekday, startPeriod: i),
      );
    }
    return children;
  }

  Widget _genPhaseList() {
    return SizedBox(
      width: _cellWidth,
      child: Column(
        children: List.generate(semesterPhaseList.length, (index) {
          final phase = semesterPhaseList[index];
          final start = phase[0];
          final end = phase[1];
          return SizedBox(
            height: _courseHeight,
            child: Column(
              children: [
                Text(
                  (index + 1).toString(),
                  style: const TextStyle(
                    fontFamily: "SmileySans",
                    fontSize: 10,
                  ),
                ),
                Text(
                  '${start.hour >= 10 ? start.hour : '0${start.hour}'}:${start.minute >= 10 ? start.minute : '0${start.minute}'}',
                  style: _timeTextStyle,
                ),
                Text(
                  '${end.hour >= 10 ? end.hour : '0${end.hour}'}:${end.minute >= 10 ? end.minute : '0${end.minute}'}',
                  style: _timeTextStyle,
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
