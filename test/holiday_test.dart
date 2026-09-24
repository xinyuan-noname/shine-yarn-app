import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shine/models/holiday_data.dart';
import 'package:shine/services/api_holiday.dart';
import 'package:shine/storage/holiday_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('节假日区间', () {
    test('区间两端都算假期', () {
      final range = HolidayRange(
        start: DateTime(2026, 10, 1),
        end: DateTime(2026, 10, 7),
        name: '国庆节',
      );
      expect(range.contains(DateTime(2026, 9, 30)), isFalse);
      expect(range.contains(DateTime(2026, 10, 1)), isTrue);
      // 带时间的那天也算假期
      expect(range.contains(DateTime(2026, 10, 7, 23, 59)), isTrue);
      expect(range.contains(DateTime(2026, 10, 8)), isFalse);
    });

    test('单日假期与文案', () {
      final range = HolidayRange.single(DateTime(2026, 1, 1), '元旦');
      expect(range.contains(DateTime(2026, 1, 1)), isTrue);
      expect(range.contains(DateTime(2026, 1, 2)), isFalse);
      expect(
        HolidayRange(
          start: DateTime(2026, 10, 1),
          end: DateTime(2026, 10, 7),
          name: '国庆节',
        ).label,
        '10月1日-10月7日 国庆节',
      );
    });

    test('json 往返与容错', () {
      final range = HolidayRange(
        start: DateTime(2026, 9, 25),
        end: DateTime(2026, 9, 27),
        name: '中秋节',
      );
      final restored = HolidayRange.fromJson(range.toJson());
      expect(restored.label, range.label);
      expect(restored.contains(DateTime(2026, 9, 26)), isTrue);
      // 起止写反了会自动纠正
      final reversed = HolidayRange.fromJson({
        'start': '2026-10-07',
        'end': '2026-10-01',
        'name': '国庆节',
      });
      expect(reversed.start, DateTime(2026, 10, 1));
      // 坏数据不会命中任何一天
      expect(
        HolidayRange.fromJson({
          'start': 'oops',
        }).contains(DateTime(2026, 10, 1)),
        isFalse,
      );
    });

    test('查找某天的假日名', () {
      final holidays = [
        HolidayRange(
          start: DateTime(2026, 10, 1),
          end: DateTime(2026, 10, 7),
          name: '国庆节',
        ),
      ];
      expect(holidayNameOf(DateTime(2026, 10, 3), holidays), '国庆节');
      expect(holidayNameOf(DateTime(2026, 9, 26), holidays), isNull);
      expect(holidayNameOf(DateTime(2026, 10, 3), const []), isNull);
    });
  });

  group('联网数据的解析', () {
    test('只取放假的日子，同名的连续日期合并成一段', () {
      final ranges = ApiHoliday.parseHolidayDays([
        {'name': '国庆节', 'date': '2026-10-01', 'isOffDay': true},
        {'name': '国庆节', 'date': '2026-10-02', 'isOffDay': true},
        {'name': '国庆节', 'date': '2026-10-03', 'isOffDay': true},
        // 调休上班的周末不算放假
        {'name': '国庆节', 'date': '2026-09-27', 'isOffDay': false},
        {'name': '元旦', 'date': '2027-01-01', 'isOffDay': true},
      ]);
      expect(ranges.length, 2);
      expect(ranges.first.name, '国庆节');
      expect(ranges.first.start, DateTime(2026, 10, 1));
      expect(ranges.first.end, DateTime(2026, 10, 3));
      expect(ranges.last.name, '元旦');
      expect(ranges.last.start, ranges.last.end);
    });

    test('不同名字的假期不会并成一段', () {
      final ranges = ApiHoliday.parseHolidayDays([
        {'name': '中秋节', 'date': '2026-09-25', 'isOffDay': true},
        {'name': '国庆节', 'date': '2026-10-01', 'isOffDay': true},
      ]);
      expect(ranges.length, 2);
      expect(ranges.map((item) => item.name), ['中秋节', '国庆节']);
    });

    test('脏数据会被跳过', () {
      final ranges = ApiHoliday.parseHolidayDays([
        'not a map',
        {'name': '国庆节', 'date': 'oops', 'isOffDay': true},
        {'name': '国庆节', 'date': '2026-10-01', 'isOffDay': true},
      ]);
      expect(ranges.length, 1);
      expect(ranges.single.contains(DateTime(2026, 10, 1)), isTrue);
    });
  });

  group('节假日缓存', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('缓存没过期时直接读缓存', () async {
      await HolidayStorage.saveCache([
        HolidayRange(
          start: DateTime(2026, 10, 1),
          end: DateTime(2026, 10, 7),
          name: '国庆节',
        ),
      ], syncedAt: DateTime(2026, 9, 24));
      expect((await HolidayStorage.getCachedHolidays()).single.name, '国庆节');
      final holidays = await HolidayStorage.getHolidays(
        now: DateTime(2026, 9, 25),
      );
      expect(holidayNameOf(DateTime(2026, 10, 3), holidays), '国庆节');
      expect(await HolidayStorage.getSyncedAt(), DateTime(2026, 9, 24));
    });

    test('缓存过期后联网失败，仍然用旧缓存', () async {
      await HolidayStorage.saveCache([
        HolidayRange.single(DateTime(2026, 1, 1), '元旦'),
      ], syncedAt: DateTime(2026, 1, 1));
      // 测试环境发不出真实请求，会走「拉取失败」分支
      final holidays = await HolidayStorage.getHolidays(
        now: DateTime(2026, 6, 1),
      );
      expect(holidays.single.name, '元旦');
    });

    test('完全没有缓存时退回固定日期的兜底数据', () async {
      final holidays = await HolidayStorage.getHolidays(
        now: DateTime(2026, 6, 1),
      );
      expect(holidays, isNotEmpty);
      expect(holidayNameOf(DateTime(2026, 1, 1), holidays), '元旦');
      expect(holidayNameOf(DateTime(2026, 10, 2), holidays), '国庆节');
      expect(holidayNameOf(DateTime(2026, 3, 4), holidays), isNull);
    });

    test('拉取失败会记下时间，短时间内不再重试', () async {
      await HolidayStorage.getHolidays(now: DateTime(2026, 6, 1));
      final again = await HolidayStorage.getHolidays(
        now: DateTime(2026, 6, 1, 0, 5),
      );
      expect(again, isNotEmpty);
    });

    test('损坏的缓存不会抛异常', () async {
      SharedPreferences.setMockInitialValues({
        'holiday_cache_key': 'not a json',
      });
      expect(await HolidayStorage.getCachedHolidays(), isEmpty);
    });

    test('清掉缓存后可重新取数', () async {
      await HolidayStorage.saveCache([
        HolidayRange.single(DateTime(2026, 1, 1), '元旦'),
      ], syncedAt: DateTime(2026, 1, 1));
      await HolidayStorage.clear();
      expect(await HolidayStorage.getCachedHolidays(), isEmpty);
      expect(await HolidayStorage.getSyncedAt(), isNull);
    });
  });

  group('兜底节假日', () {
    test('只包含法定固定日期，不猜农历节日', () {
      final holidays = fallbackHolidayRanges(now: DateTime(2026, 6, 1));
      expect(holidayNameOf(DateTime(2026, 1, 1), holidays), '元旦');
      expect(holidayNameOf(DateTime(2026, 5, 1), holidays), '劳动节');
      expect(holidayNameOf(DateTime(2026, 10, 3), holidays), '国庆节');
      // 次年也带上，覆盖跨年学期
      expect(holidayNameOf(DateTime(2027, 1, 1), holidays), '元旦');
      // 中秋这类农历节日不写死
      expect(holidayNameOf(DateTime(2026, 9, 25), holidays), isNull);
    });
  });
}
