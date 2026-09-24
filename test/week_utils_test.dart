import 'package:flutter_test/flutter_test.dart';
import 'package:shine/utils/time_utils.dart';

void main() {
  group('周起始与自然天数', () {
    test('weekStartOf 返回所在周的周一', () {
      // 2026-09-09 是周三
      expect(weekStartOf(DateTime(2026, 9, 9)), DateTime(2026, 9, 7));
      // 周日归到同一周的周一
      expect(weekStartOf(DateTime(2026, 9, 13)), DateTime(2026, 9, 7));
      // 时间部分会被归零
      expect(weekStartOf(DateTime(2026, 9, 9, 23, 59)), DateTime(2026, 9, 7));
    });

    test('daysBetween 按自然日计算', () {
      expect(daysBetween(DateTime(2026, 9, 7), DateTime(2026, 9, 14)), 7);
      expect(daysBetween(DateTime(2026, 9, 7, 23), DateTime(2026, 9, 8, 1)), 1);
      // 跨年
      expect(daysBetween(DateTime(2026, 12, 28), DateTime(2027, 1, 4)), 7);
    });
  });

  group('学期周数', () {
    // 2026-09-07 是周一
    final startedAt = DateTime(2026, 9, 7);

    test('第 1 周从学期开始日期所在周的周一起算', () {
      expect(semesterWeekOf(DateTime(2026, 9, 7), startedAt), 1);
      expect(semesterWeekOf(DateTime(2026, 9, 13), startedAt), 1);
      expect(semesterWeekOf(DateTime(2026, 9, 14), startedAt), 2);
      expect(semesterWeekOf(DateTime(2026, 10, 5), startedAt), 5);
    });

    test('跨年时周数继续递增，不会变成负数', () {
      // 2026-12-28 是第 17 周（从 09-07 起 112 天 = 16 周）
      expect(semesterWeekOf(DateTime(2026, 12, 28), startedAt), 17);
      // 2027-01-04 是第 18 周：老实现用 ISO 周号会算成 1 - 37 + 1 = -35
      expect(semesterWeekOf(DateTime(2027, 1, 4), startedAt), 18);
      expect(semesterWeekOf(DateTime(2027, 1, 10), startedAt), 18);
      expect(semesterWeekOf(DateTime(2027, 1, 11), startedAt), 19);
      // 跨年附近不该出现 <= 0
      for (final date in [
        DateTime(2026, 12, 31),
        DateTime(2027, 1, 1),
        DateTime(2027, 2, 1),
      ]) {
        expect(
          semesterWeekOf(date, startedAt),
          greaterThan(0),
          reason: '$date',
        );
      }
    });

    test('学期开始日期不是周一时，先归到那一周的周一', () {
      // 2026-09-09 是周三，它所在的第 1 周从 09-07（周一）起
      final wednesdayStart = DateTime(2026, 9, 9);
      expect(semesterWeekOf(DateTime(2026, 9, 7), wednesdayStart), 1);
      expect(semesterWeekOf(DateTime(2026, 9, 13), wednesdayStart), 1);
      expect(semesterWeekOf(DateTime(2026, 9, 14), wednesdayStart), 2);
      // 跨年后依然正确
      expect(semesterWeekOf(DateTime(2027, 1, 4), wednesdayStart), 18);
    });

    test('早于学期开始返回 0 或负数，没有学期信息返回 0', () {
      expect(semesterWeekOf(DateTime(2026, 9, 1), startedAt), lessThan(1));
      expect(semesterWeekOf(DateTime(2026, 9, 7), null), 0);
    });
  });

  group('同周判断', () {
    test('inSameWeek 按周一划分', () {
      expect(DateTime(2026, 9, 9).inSameWeek(DateTime(2026, 9, 13)), isTrue);
      expect(DateTime(2026, 9, 13).inSameWeek(DateTime(2026, 9, 14)), isFalse);
    });

    test('跨年但属于同一周的两天算同一周', () {
      // 2026-12-31 是周四，2027-01-01 是周五，两者同属 2026 年第 53 周
      expect(DateTime(2027, 1, 1).inSameWeek(DateTime(2026, 12, 31)), isTrue);
      // 老实现用 year + weekOfYear 判断，这里会误判为不同周
      expect(DateTime(2027, 1, 4).inSameWeek(DateTime(2026, 12, 31)), isFalse);
    });

    test('getWeekDates 总是从周一到周日', () {
      for (final date in [
        DateTime(2026, 9, 7),
        DateTime(2026, 12, 31),
        DateTime(2027, 1, 1),
      ]) {
        final dates = getWeekDates(date);
        expect(dates.length, 7);
        expect(dates.first.weekday, DateTime.monday);
        expect(dates.last.weekday, DateTime.sunday);
        expect(dates.first.day, weekStartOf(date).day);
      }
    });
  });
}
