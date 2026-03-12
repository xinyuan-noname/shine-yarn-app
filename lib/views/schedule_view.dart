import 'package:flutter/material.dart';
import 'package:shine/components/line.dart';
import 'package:shine/theme.dart';
import 'package:shine/utils/time.dart';
import 'package:week_of_year/date_week_extensions.dart';

const _titleTextStyle = TextStyle(fontFamily: "SmileySans", fontSize: 12);
const _timeTextStyle = TextStyle(
  fontFamily: "SmileySans",
  fontSize: 8,
  color: Colors.grey,
);
const double _cellWidth = 35;

class ScheduleView extends StatelessWidget {
  final String? semesterName;
  final DateTime? semesterStartedAt;
  final List<List<TimeOfDay>> semesterPhaseList;
  final RefreshCallback onRefresh;
  final DateTime showDate;
  const ScheduleView({
    super.key,
    this.semesterName,
    this.semesterStartedAt,
    required this.semesterPhaseList,
    required this.onRefresh,
    required this.showDate,
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
                        height: 475,
                        child: SingleChildScrollView(
                          padding: EdgeInsets.only(top: 10),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [_genPhaseList()],
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

  Widget _genPhaseList() {
    return SizedBox(
      width: _cellWidth,
      child: Column(
        children: List.generate(semesterPhaseList.length, (index) {
          final phase = semesterPhaseList[index];
          final start = phase[0];
          final end = phase[1];
          return SizedBox(
            height: 60,
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
}
