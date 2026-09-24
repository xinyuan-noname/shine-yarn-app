import 'package:flutter/material.dart';

/// 节假日（放假不上课）的日期区间，[start]、[end] 两端都包含
class HolidayRange {
  final DateTime start;
  final DateTime end;
  final String name;

  const HolidayRange({
    required this.start,
    required this.end,
    required this.name,
  });

  /// 单日假期
  HolidayRange.single(DateTime date, this.name) : start = date, end = date;

  bool contains(DateTime date) {
    final day = DateUtils.dateOnly(date);
    return !day.isBefore(DateUtils.dateOnly(start)) &&
        !day.isAfter(DateUtils.dateOnly(end));
  }

  factory HolidayRange.fromJson(Map<String, dynamic> json) {
    final start = _parseDate(json['start']);
    final end = _parseDate(json['end']) ?? start;
    if (start == null || end == null) {
      // 数据损坏时退化成「空区间」，不会命中任何一天
      return HolidayRange(start: DateTime(1970), end: DateTime(1970), name: '');
    }
    return HolidayRange(
      start: start,
      end: end.isBefore(start) ? start : end,
      name: json['name']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'start': _formatDate(start),
    'end': _formatDate(end),
    'name': name,
  };

  /// 「10月1日-10月7日 国庆节」这样的展示文案
  String get label {
    final dateText = start.year == end.year && start.month == end.month
        ? '${start.month}月${start.day}日-${end.day}日'
        : '${start.month}月${start.day}日-${end.month}月${end.day}日';
    if (name.isEmpty) return dateText;
    return '$dateText $name';
  }

  static DateTime? _parseDate(Object? value) {
    if (value is! String || value.isEmpty) return null;
    return DateTime.tryParse(value);
  }

  static String _formatDate(DateTime date) {
    String two(int value) => value.toString().padLeft(2, '0');
    return '${date.year}-${two(date.month)}-${two(date.day)}';
  }

  @override
  String toString() => 'HolidayRange($label)';
}

/// 某天是不是假日，是的话返回假日名（不是假日返回 null）
String? holidayNameOf(DateTime date, List<HolidayRange> holidays) {
  for (final holiday in holidays) {
    if (holiday.contains(date)) {
      return holiday.name.isEmpty ? '假日' : holiday.name;
    }
  }
  return null;
}

/// 预置的节假日。
///
/// 只写「固定日期」的法定节假日（元旦 / 劳动节 / 国庆）与常见连休区间，
/// 按农历或每年调整的假期（春节、清明、端午、中秋）只预置近年，且都**可以自行增删**
/// —— 学校校历、调休安排请在「节假日设置」里改。
List<HolidayRange> defaultHolidayRanges() {
  return [
    for (final year in [2025, 2026, 2027]) ...[
      HolidayRange.single(DateTime(year, 1, 1), '元旦'),
      HolidayRange(
        start: DateTime(year, 5, 1),
        end: DateTime(year, 5, 5),
        name: '劳动节',
      ),
      HolidayRange(
        start: DateTime(year, 10, 1),
        end: DateTime(year, 10, 7),
        name: '国庆节',
      ),
    ],
    // 农历节日：这里预置 2026 年的常见连休区间，不对的话直接改
    HolidayRange(
      start: DateTime(2026, 4, 4),
      end: DateTime(2026, 4, 6),
      name: '清明节',
    ),
    HolidayRange(
      start: DateTime(2026, 6, 19),
      end: DateTime(2026, 6, 21),
      name: '端午节',
    ),
    HolidayRange(
      start: DateTime(2026, 9, 25),
      end: DateTime(2026, 9, 27),
      name: '中秋节',
    ),
  ];
}
