import 'package:week_of_year/date_week_extensions.dart';

String getLocalTimeString(DateTime time) {
  try {
    return time.toLocal().toString();
  } catch (e) {
    return time.toString();
  }
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
