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

/// 某天所在周的周一（本地日期，时间部分归零）。
///
/// 所有周相关的计算都以这个函数为基准：ISO 周号在跨年处会回绕
/// （2026 年第 52 周之后是 2027 年第 1 周），直接相减会算出负数。
DateTime weekStartOf(DateTime date) {
  final day = DateTime(date.year, date.month, date.day);
  return day.subtract(Duration(days: date.weekday - 1));
}

/// 两个日期相差的自然天数（用 UTC 归一化，避免夏令时把天数算错一天）
int daysBetween(DateTime from, DateTime to) {
  final start = DateTime.utc(from.year, from.month, from.day);
  final end = DateTime.utc(to.year, to.month, to.day);
  return end.difference(start).inDays;
}

/// 某天是学期的第几周（第 1 周从学期开始日期所在周的周一起算）。
///
/// 跨年不会算错；早于学期开始返回 0 或负数；没有学期开始时间返回 0。
int semesterWeekOf(DateTime date, DateTime? semesterStartedAt) {
  if (semesterStartedAt == null) return 0;
  return daysBetween(weekStartOf(semesterStartedAt), weekStartOf(date)) ~/ 7 +
      1;
}

List<DateTime> getWeekDates(DateTime date) {
  final monday = weekStartOf(date);
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

/// 是否和今天在同一周（同 ISO 周但跨年的情况也能正确判断）
bool inCurrentWeek(DateTime date) {
  return weekStartOf(date) == weekStartOf(DateTime.now());
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
  /// 是否和 [date] 在同一周（按周一划分，跨年也对）
  bool inSameWeek(DateTime date) => weekStartOf(this) == weekStartOf(date);
}
