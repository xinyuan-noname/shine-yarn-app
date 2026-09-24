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

/// 兜底用的节假日：只写「法定固定日期」，连休与调休以联网拉到的数据为准。
///
/// 只有在首次启动还没联网、又没有本地缓存时才会用到。
List<HolidayRange> fallbackHolidayRanges({DateTime? now}) {
  final year = (now ?? DateTime.now()).year;
  return [
    for (final y in [year, year + 1]) ...[
      HolidayRange.single(DateTime(y, 1, 1), '元旦'),
      HolidayRange.single(DateTime(y, 5, 1), '劳动节'),
      HolidayRange(
        start: DateTime(y, 10, 1),
        end: DateTime(y, 10, 3),
        name: '国庆节',
      ),
    ],
  ];
}
