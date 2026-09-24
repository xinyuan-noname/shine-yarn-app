import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shine/models/holiday_data.dart';
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

    test('单日假期', () {
      final range = HolidayRange.single(DateTime(2026, 1, 1), '元旦');
      expect(range.contains(DateTime(2026, 1, 1)), isTrue);
      expect(range.contains(DateTime(2026, 1, 2)), isFalse);
    });

    test('展示文案', () {
      expect(
        HolidayRange(
          start: DateTime(2026, 10, 1),
          end: DateTime(2026, 10, 7),
          name: '国庆节',
        ).label,
        '10月1日-10月7日 国庆节',
      );
      expect(
        HolidayRange(
          start: DateTime(2026, 4, 29),
          end: DateTime(2026, 5, 3),
          name: '劳动节',
        ).label,
        '4月29日-5月3日 劳动节',
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
      final holidays = defaultHolidayRanges();
      expect(holidayNameOf(DateTime(2026, 10, 3), holidays), '国庆节');
      expect(holidayNameOf(DateTime(2026, 9, 26), holidays), '中秋节');
      expect(holidayNameOf(DateTime(2026, 3, 4), holidays), isNull);
      expect(holidayNameOf(DateTime(2026, 10, 3), const []), isNull);
    });
  });

  group('节假日本地存储', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('首次读取会写入预置节假日', () async {
      final holidays = await HolidayStorage.getHolidays();
      expect(holidays, isNotEmpty);
      expect(holidayNameOf(DateTime(2026, 10, 3), holidays), '国庆节');
      // 第二次读取拿到同一份，不会重复叠加
      expect((await HolidayStorage.getHolidays()).length, holidays.length);
    });

    test('清空后不会被预置数据填回来', () async {
      await HolidayStorage.saveHolidays(const []);
      expect(await HolidayStorage.getHolidays(), isEmpty);
    });

    test('保存后可读回，恢复预置能还原', () async {
      await HolidayStorage.saveHolidays([
        HolidayRange.single(DateTime(2026, 11, 1), '校庆'),
      ]);
      final saved = await HolidayStorage.getHolidays();
      expect(saved.single.name, '校庆');

      final defaults = await HolidayStorage.resetToDefault();
      expect(defaults.length, defaultHolidayRanges().length);
      expect((await HolidayStorage.getHolidays()).length, defaults.length);
    });

    test('损坏的数据不会抛异常', () async {
      SharedPreferences.setMockInitialValues({
        'holiday_range_list_key': 'not a json',
      });
      expect(await HolidayStorage.getHolidays(), isEmpty);
    });
  });
}
