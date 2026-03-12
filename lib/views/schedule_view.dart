import 'package:flutter/material.dart';
import 'package:shine/components/line.dart';
import 'package:shine/extensions/list.dart';
import 'package:shine/theme.dart';
import 'package:shine/utils/course.dart';
import 'package:shine/utils/time.dart';
import 'package:week_of_year/date_week_extensions.dart';

const _titleTextStyle = TextStyle(fontFamily: "SmileySans", fontSize: 12);
const _timeTextStyle = TextStyle(
  fontFamily: "SmileySans",
  fontSize: 8,
  color: Colors.grey,
);
const double _cellWidth = 35;
const double _courseHeight = 60;

class ScheduleView extends StatelessWidget {
  final String? semesterName;
  final DateTime? semesterStartedAt;
  final List<List<TimeOfDay>> semesterPhaseList;
  final RefreshCallback onRefresh;
  final DateTime showDate;
  final List<CourseData>? subjectInfoList;
  const ScheduleView({
    super.key,
    this.semesterName,
    this.semesterStartedAt,
    required this.semesterPhaseList,
    required this.onRefresh,
    required this.showDate,
    this.subjectInfoList,
  });

  @override
  Widget build(BuildContext context) {
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(semesterName ?? "未知学期", style: labelStyle),
                  Text("当前周：第${_getCurrentWeek()}周", style: labelStyle),
                ],
              ),
              bottomLine,
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
                        height: 480,
                        child: RefreshIndicator(
                          onRefresh: onRefresh,
                          child: SingleChildScrollView(
                            padding: EdgeInsets.all(0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                _genPhaseList(),
                                ..._genCourseColumn(),
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
  }

  List<Widget> _genTableTitleList() {
    return getWeekDates(showDate)
        .map(
          (d) => Container(
            width: _cellWidth,
            color: isToday(d) ? mainColorGreenBule : Colors.transparent,
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
    if (subjectInfoList == null) return [];
    final List<(CourseBasicInfo, CourseSchedule)> result = [];
    for (final subject in subjectInfoList!) {
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

  List<Widget> _genCourseColumn() {
    final list = _getshowSubjectInfoList();
    return getWeekDates(showDate).map((d) {
      return SizedBox(
        width: _cellWidth,
        child: Column(children: _genCourseRow(list, d)),
      );
    }).toList();
  }

  List<Widget> _genCourseRow(
    List<(CourseBasicInfo, CourseSchedule)> list,
    DateTime date,
  ) {
    final List<Widget> children = [];
    for (int i = 1; i <= semesterPhaseList.length; i++) {
      final scheduleItem = list.safeElementAt(0);
      if (scheduleItem == null) {
        children.add(SizedBox(height: _courseHeight));
        continue;
      }
      if (scheduleItem.$2.weekday == date.weekday &&
          scheduleItem.$2.start == i) {
        children.add(
          Container(
            height: _courseHeight * scheduleItem.$2.periodLength,
            decoration: BoxDecoration(color: mainColorPurple),
            child: Wrap(
              children: [
                Text(
                  scheduleItem.$1.alias ?? scheduleItem.$1.subjectName,
                  style: const TextStyle(
                    fontFamily: "SmileySans",
                    fontSize: 12,
                  ),
                ),
                Text(
                  scheduleItem.$2.location,
                  style: const TextStyle(
                    fontFamily: "SmileySans",
                    fontSize: 12,
                    color: bgColorLight60,
                  ),
                ),
              ],
            ),
          ),
        );
        i = scheduleItem.$2.end;
        list.remove(scheduleItem);
        continue;
      }
      children.add(SizedBox(height: _courseHeight));
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
                Text(start.toString().substring(10, 15), style: _timeTextStyle),
                Text(end.toString().substring(10, 15), style: _timeTextStyle),
              ],
            ),
          );
        }),
      ),
    );
  }

  int _getCurrentWeek() {
    if (semesterStartedAt == null) return 0;
    final s = semesterStartedAt?.weekOfYear ?? 1;
    final e = DateTime.now().weekOfYear;
    return e - s + 1;
  }

  int _getShowTimeWeek() {
    if (semesterStartedAt == null) return 0;
    final s = semesterStartedAt?.weekOfYear ?? 1;
    final e = showDate.weekOfYear;
    return e - s + 1;
  }
}
