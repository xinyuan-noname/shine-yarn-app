import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:shine/models/holiday_data.dart';

/// 节假日数据源：holiday-cn（按国务院放假通知整理的公开 JSON，每年一个文件）。
///
/// 文件里的 `days` 数组既有放假的日子（isOffDay=true），也有调休上班的周末
/// （isOffDay=false），这里只取放假的日子并合并成连续区间。
class ApiHoliday {
  ApiHoliday._();

  /// 数据地址，按顺序尝试（jsDelivr 在国内一般可直连，失败再走 GitHub）
  static const List<String> urlTemplates = [
    'https://cdn.jsdelivr.net/gh/NateScarlet/holiday-cn@master/{year}.json',
    'https://raw.githubusercontent.com/NateScarlet/holiday-cn/master/{year}.json',
  ];

  /// 只用来拉节假日，不带应用自己的鉴权头
  static final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 8),
      receiveTimeout: const Duration(seconds: 8),
      headers: const {'Accept': 'application/json'},
    ),
  );

  /// 拉取某年的放假安排；两个源都失败时返回 null
  static Future<List<HolidayRange>?> fetchYear(int year) async {
    for (final template in urlTemplates) {
      final url = template.replaceAll('{year}', '$year');
      try {
        final response = await _dio.get<dynamic>(url);
        final data = response.data;
        if (data is Map && data['days'] is List) {
          final ranges = parseHolidayDays(data['days'] as List);
          if (ranges.isNotEmpty) return ranges;
        }
      } catch (e) {
        // 换下一个源继续试
      }
    }
    return null;
  }

  /// 同时拉取多年（跨年学期用），全部失败返回 null
  static Future<List<HolidayRange>?> fetchYears(List<int> years) async {
    final result = <HolidayRange>[];
    var succeeded = false;
    for (final year in years) {
      final ranges = await fetchYear(year);
      if (ranges == null) continue;
      succeeded = true;
      result.addAll(ranges);
    }
    if (!succeeded) return null;
    result.sort((a, b) => a.start.compareTo(b.start));
    return result;
  }

  /// 把 `days` 数组整理成放假区间：跳过调休上班日，同名的连续日期合并
  static List<HolidayRange> parseHolidayDays(List<dynamic> days) {
    final entries = <({DateTime date, String name})>[];
    for (final day in days) {
      if (day is! Map) continue;
      // 调休上班的周末不算放假
      if (day['isOffDay'] != true) continue;
      final date = DateTime.tryParse(day['date']?.toString() ?? '');
      if (date == null) continue;
      final name = day['name']?.toString().trim() ?? '';
      entries.add((
        date: DateUtils.dateOnly(date),
        name: name.isEmpty ? '假期' : name,
      ));
    }
    entries.sort((a, b) => a.date.compareTo(b.date));

    final ranges = <HolidayRange>[];
    for (final entry in entries) {
      final last = ranges.isEmpty ? null : ranges.last;
      final isNextDay =
          last != null && entry.date.difference(last.end).inDays == 1;
      if (last != null && isNextDay && last.name == entry.name) {
        ranges[ranges.length - 1] = HolidayRange(
          start: last.start,
          end: entry.date,
          name: last.name,
        );
      } else {
        ranges.add(HolidayRange.single(entry.date, entry.name));
      }
    }
    return ranges;
  }
}
