import 'package:week_of_year/date_week_extensions.dart';

DateTime getTodayStartMoment() {
  final now = DateTime.now().toLocal();
  return DateTime(now.year, now.month, now.day);
}

String getDayDifferenceString(DateTime d) {
  final dayDistance = DateTime(
    d.year,
    d.month,
    d.day,
  ).difference(getTodayStartMoment()).inDays;
  String result = "";
  if (dayDistance > 0) {
    result += "$dayDistance天后";
  } else if (dayDistance < 0) {
    result += "${-dayDistance}天前";
  } else {
    result += "今天";
  }
  return result;
}

String getLocalTimeString(DateTime time) {
  try {
    return time.toLocal().toString().split(".")[0];
  } catch (e) {
    return time.toString();
  }
}

String getLocalTimeYMDString(DateTime time, {String joinedString = '/'}) {
  final dd = time.toLocal();
  final y = dd.year % 100;
  final m = dd.month;
  final d = dd.day;
  final yS = y < 10 ? '0$y' : '$y';
  final mS = m < 10 ? '0$m' : '$m';
  final dS = d < 10 ? '0$d' : '$d';
  return [yS, mS, dS].join(joinedString);
}

List<DateTime> getWeekDates(DateTime date) {
  final weekday = date.weekday;

  final monday = date.subtract(Duration(days: weekday - 1));

  return List.generate(7, (i) {
    return DateTime(monday.year, monday.month, monday.day + i);
  });
}

bool isToday(DateTime date) {
  final now = DateTime.now();
  return now.year == date.year &&
      now.month == date.month &&
      now.day == date.day;
}

bool inCurrentWeek(DateTime date) {
  final now = DateTime.now();
  return date.year == now.year && date.weekOfYear == now.weekOfYear;
}

String getCnWeekDayName(DateTime date) {
  final weekday = date.weekday;
  switch (weekday) {
    case 1:
      return '一';
    case 2:
      return '二';
    case 3:
      return '三';
    case 4:
      return '四';
    case 5:
      return '五';
    case 6:
      return '六';
    case 7:
      return '日';
  }
  return '未知';
}

extension DateTimeExtension on DateTime {
  inSameWeek(DateTime date) {
    return year == date.year && weekOfYear == date.weekOfYear;
  }
}
