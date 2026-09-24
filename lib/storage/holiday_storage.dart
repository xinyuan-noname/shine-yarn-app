import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:shine/models/holiday_data.dart';
import 'package:shine/services/api_holiday.dart';

/// 节假日本地缓存：数据联网自动获取，不提供手工设置。
///
/// 取数顺序：
/// 1. 缓存没过期（[cacheValidDuration] 内）→ 直接用缓存；
/// 2. 否则联网拉取当年与下一年的放假安排，成功就覆盖缓存；
/// 3. 拉取失败（断网）→ 继续用旧缓存；连缓存都没有才退回
///    [fallbackHolidayRanges]（只有法定固定日期）。
///
/// 失败后 [retryAfterFailure] 内不再重试，避免离线时每次进页面都卡在网络上。
class HolidayStorage {
  static const String _cacheKey = "holiday_cache_key";
  static const String _syncedAtKey = "holiday_cache_synced_at_key";
  static const String _attemptAtKey = "holiday_cache_attempt_at_key";

  /// 缓存有效期：过期后重新联网拉取
  static const Duration cacheValidDuration = Duration(days: 7);

  /// 拉取失败后的重试间隔
  static const Duration retryAfterFailure = Duration(minutes: 30);

  /// 正在进行中的刷新，避免多个页面同时触发拉取
  static Future<List<HolidayRange>>? _inflight;

  /// 取节假日（自动联网刷新）
  static Future<List<HolidayRange>> getHolidays({
    DateTime? now,
    bool forceRefresh = false,
  }) {
    final current = now ?? DateTime.now();
    final running = _inflight;
    if (running != null) return running;
    final future = _resolve(current: current, forceRefresh: forceRefresh);
    _inflight = future;
    // 后台记录一下结束时间，别让这个链上的错误变成未处理异常
    future.then((_) {}, onError: (Object _) {}).whenComplete(() {
      if (identical(_inflight, future)) _inflight = null;
    });
    return future;
  }

  /// 取数流程：任何异常都退回缓存或兜底数据，不会把错误抛给页面
  static Future<List<HolidayRange>> _resolve({
    required DateTime current,
    required bool forceRefresh,
  }) async {
    try {
      return await _resolveUnsafe(current: current, forceRefresh: forceRefresh);
    } catch (e) {
      return fallbackHolidayRanges(now: current);
    }
  }

  static Future<List<HolidayRange>> _resolveUnsafe({
    required DateTime current,
    required bool forceRefresh,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final cached = _decode(prefs.getString(_cacheKey));
    final syncedAt = _readTime(prefs.getString(_syncedAtKey));
    final attemptAt = _readTime(prefs.getString(_attemptAtKey));

    final cacheFresh =
        syncedAt != null &&
        current.difference(syncedAt) < cacheValidDuration &&
        cached.isNotEmpty;
    if (!forceRefresh && cacheFresh) return cached;

    // 刚失败过就先不试了，别让离线状态把页面卡住
    final recentlyTried =
        attemptAt != null && current.difference(attemptAt) < retryAfterFailure;
    if (recentlyTried) {
      return cached.isNotEmpty ? cached : fallbackHolidayRanges(now: current);
    }

    final fetched = await ApiHoliday.fetchYears([
      current.year,
      current.year + 1,
    ]);
    if (fetched != null && fetched.isNotEmpty) {
      await saveCache(fetched, syncedAt: current);
      return fetched;
    }

    // 拉取失败：记下这次尝试，避免频繁重试
    await prefs.setString(_attemptAtKey, current.toIso8601String());
    return cached.isNotEmpty ? cached : fallbackHolidayRanges(now: current);
  }

  /// 只读缓存，不触发联网
  static Future<List<HolidayRange>> getCachedHolidays() async {
    final prefs = await SharedPreferences.getInstance();
    return _decode(prefs.getString(_cacheKey));
  }

  static Future<DateTime?> getSyncedAt() async {
    final prefs = await SharedPreferences.getInstance();
    return _readTime(prefs.getString(_syncedAtKey));
  }

  static Future<void> saveCache(
    List<HolidayRange> holidays, {
    DateTime? syncedAt,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _cacheKey,
      jsonEncode(holidays.map((holiday) => holiday.toJson()).toList()),
    );
    if (syncedAt != null) {
      await prefs.setString(_syncedAtKey, syncedAt.toIso8601String());
    }
  }

  /// 清掉缓存与重试记时（下次访问会重新联网拉取）
  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cacheKey);
    await prefs.remove(_syncedAtKey);
    await prefs.remove(_attemptAtKey);
  }

  static DateTime? _readTime(String? value) {
    if (value == null) return null;
    return DateTime.tryParse(value);
  }

  /// 解析缓存内容：格式不对时按空列表处理
  static List<HolidayRange> _decode(String? raw) {
    if (raw == null) return [];
    try {
      final infoJson = jsonDecode(raw);
      if (infoJson is! List) return [];
      final result = infoJson
          .whereType<Map<String, dynamic>>()
          .map(HolidayRange.fromJson)
          .where((holiday) => holiday.start.year > 1970)
          .toList();
      result.sort((a, b) => a.start.compareTo(b.start));
      return result;
    } catch (e) {
      return [];
    }
  }
}
