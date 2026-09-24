import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  /// 日程提醒用的通知渠道
  static const String scheduleChannelId = 'schedule_channel';
  static const String scheduleChannelName = '日程提醒';

  /// 日程提醒的通知 id 从这里开始分配（消息通知用 1000，不会冲突）
  static const int _scheduleNotificationIdBase = 200000;

  /// 用于 zonedSchedule 的时区是否已经初始化
  static bool _timeZoneReady = false;

  /// 给第 [index] 条日程提醒分配通知 id
  static int scheduleNotificationId(int index) =>
      _scheduleNotificationIdBase + index;

  static Future<void> init() async {
    if (kIsWeb) return;

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('ic_stat_format_paint');
    const WindowsInitializationSettings windowsInitializationSettings =
        WindowsInitializationSettings(
          appName: '闪纺',
          appUserModelId: 'com.example.shine',
          guid: '6548a3d3-236f-4651-8fe1-c1e537098058',
        );
    await _notificationsPlugin.initialize(
      onDidReceiveNotificationResponse: onDidReceiveNotificationResponse,
      settings: InitializationSettings(
        android: androidSettings,
        windows: windowsInitializationSettings,
      ),
    );

    if (Platform.isAndroid) {
      await _requestAndroidPermission();
    }
  }

  static Future<void> _requestAndroidPermission() async {
    // Android 13 起通知需要用户授权，低版本调用是空操作
    final androidImplementation = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await androidImplementation?.requestNotificationsPermission();
  }

  /// 申请发通知的权限（开启日程提醒时调用）。
  ///
  /// 返回是否拿到了通知权限，拿不到时排期仍会进行，只是用户看不到提醒。
  static Future<bool> requestPermission() async {
    if (kIsWeb) return false;
    try {
      if (Platform.isAndroid) {
        final androidImplementation = _notificationsPlugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();
        final granted = await androidImplementation
            ?.requestNotificationsPermission();
        // 精确闹钟权限被拒绝时排期会自动退回到不精确模式
        await requestExactAlarmPermission();
        return granted ?? false;
      }
      if (Platform.isIOS) {
        final iosImplementation = _notificationsPlugin
            .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin
            >();
        return await iosImplementation?.requestPermissions(
              alert: true,
              badge: true,
              sound: true,
            ) ??
            false;
      }
      if (Platform.isMacOS) {
        final macosImplementation = _notificationsPlugin
            .resolvePlatformSpecificImplementation<
              MacOSFlutterLocalNotificationsPlugin
            >();
        return await macosImplementation?.requestPermissions(
              alert: true,
              badge: true,
              sound: true,
            ) ??
            false;
      }
    } catch (e) {
      return false;
    }
    return false;
  }

  /// Android 上申请「精确闹钟」权限（Android 12+），其它平台直接返回 true
  static Future<bool> requestExactAlarmPermission() async {
    if (kIsWeb || !Platform.isAndroid) return true;
    try {
      final androidImplementation = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      if (await canScheduleExactNotifications()) return true;
      return await androidImplementation?.requestExactAlarmsPermission() ??
          false;
    } catch (e) {
      return false;
    }
  }

  /// 当前是否允许精确排期（Android 12+ 需要用户授权）
  static Future<bool> canScheduleExactNotifications() async {
    if (kIsWeb || !Platform.isAndroid) return true;
    try {
      final androidImplementation = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      return await androidImplementation?.canScheduleExactNotifications() ??
          false;
    } catch (e) {
      return false;
    }
  }

  /// 在指定时间弹一条本地通知（用于日程提醒）
  ///
  /// [scheduledDate] 按设备本地时间解释；Android 上拿不到精确闹钟权限时
  /// 会自动退回到不精确排期，避免设置成功却收不到提醒。
  static Future<void> zonedSchedule({
    required int id,
    required DateTime scheduledDate,
    required String title,
    required String body,
    String? payload,
  }) async {
    if (kIsWeb || Platform.isLinux) return;
    ensureTimeZone();
    final scheduledTzDate = tz.TZDateTime(
      tz.local,
      scheduledDate.year,
      scheduledDate.month,
      scheduledDate.day,
      scheduledDate.hour,
      scheduledDate.minute,
    );
    final exact = await canScheduleExactNotifications();
    try {
      await _notificationsPlugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: scheduledTzDate,
        notificationDetails: _scheduleNotificationDetails,
        androidScheduleMode: exact
            ? AndroidScheduleMode.exactAllowWhileIdle
            : AndroidScheduleMode.inexactAllowWhileIdle,
        payload: payload,
      );
    } catch (e) {
      // 精确闹钟被系统拒绝（PlatformException）时退回不精确排期
      await _notificationsPlugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: scheduledTzDate,
        notificationDetails: _scheduleNotificationDetails,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: payload,
      );
    }
  }

  /// 测试提醒用的固定通知 id
  static const int scheduleTestNotificationId = 299999;

  /// 系统通知权限是否可用（关掉时任何提醒都送不到用户手上）
  static Future<bool> areNotificationsEnabled() async {
    if (kIsWeb) return false;
    try {
      if (Platform.isAndroid) {
        final androidImplementation = _notificationsPlugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();
        return await androidImplementation?.areNotificationsEnabled() ?? true;
      }
    } catch (e) {
      return true;
    }
    return true;
  }

  /// 立刻弹一条日程提醒样式的通知。
  ///
  /// 用来确认通知权限与渠道是否正常：保存提醒设置后会立刻发一条，
  /// 用户当场就知道「设置生效了」还是「通知被系统拦了」。
  static Future<bool> showScheduleTestNotification({
    String? title,
    String? body,
  }) async {
    if (kIsWeb) return false;
    try {
      await _notificationsPlugin.show(
        id: scheduleTestNotificationId,
        title: title ?? '测试提醒：日程提醒已就绪',
        body: body ?? '看到这条通知说明提醒能正常送达，上课前会按你设置的提前量提醒你',
        notificationDetails: _scheduleNotificationDetails,
        payload: 'schedule_test',
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  /// 排一条 [delay] 之后的测试提醒，用来验证「定时投递」链路本身。
  ///
  /// 和真正的上课提醒走完全相同的 zonedSchedule → AlarmManager 路径，
  /// 所以「1 分钟后提醒」能弹出来，就说明定时提醒在这台机器上是可用的。
  static Future<bool> scheduleTestNotificationIn(Duration delay) async {
    if (kIsWeb) return false;
    try {
      await zonedSchedule(
        id: scheduleTestNotificationId,
        scheduledDate: DateTime.now().add(delay),
        title: '测试提醒：定时投递正常',
        body: '这条是定时提醒，能按约定时间弹出来说明排期链路可用',
        payload: 'schedule_test_delayed',
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  /// 撤销一条已排期的通知
  static Future<void> cancelScheduled({required int id}) async {
    if (kIsWeb) return;
    try {
      await _notificationsPlugin.cancel(id: id);
    } catch (e) {
      // 撤销失败不影响后续排期
    }
  }

  /// 初始化时区数据：优先中国时区，设备不在东八区时退回到与设备当前偏移一致的地区
  static void ensureTimeZone() {
    if (_timeZoneReady) return;
    try {
      tz_data.initializeTimeZones();
      final deviceOffset = DateTime.now().timeZoneOffset.inMinutes * 60000;
      final shanghai = tz.getLocation('Asia/Shanghai');
      if (shanghai.currentTimeZone.offset == deviceOffset) {
        tz.setLocalLocation(shanghai);
      } else {
        for (final location in tz.timeZoneDatabase.locations.values) {
          if (location.currentTimeZone.offset == deviceOffset) {
            tz.setLocalLocation(location);
            break;
          }
        }
      }
    } catch (e) {
      // 初始化失败时保持默认时区，排期仍按本地时间近似工作
    }
    _timeZoneReady = true;
  }

  static final NotificationDetails _scheduleNotificationDetails =
      NotificationDetails(
        android: AndroidNotificationDetails(
          scheduleChannelId,
          scheduleChannelName,
          channelDescription: '上课前的日程提醒',
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
          ticker: '日程提醒',
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
        macOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
        windows: WindowsNotificationDetails(),
      );

  static Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    int? badgeCount,
  }) async {
    if (kIsWeb) return;

    await _notificationsPlugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          'message_channel',
          '消息通知',
          channelDescription: '新消息提醒',
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
          ticker: '新消息',
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
        windows: WindowsNotificationDetails(),
      ),
      payload: 'message_payload',
    );
  }

  static void onDidReceiveLocalNotification(
    int id,
    String? title,
    String? body,
    String? payload,
  ) {}

  static void onDidReceiveNotificationResponse(NotificationResponse response) {}
}
