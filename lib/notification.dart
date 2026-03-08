// lib/services/notification_service.dart
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    if (kIsWeb) return;

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('app_icon');
    await _notificationsPlugin.initialize(
      onDidReceiveNotificationResponse: onDidReceiveNotificationResponse,
      settings: InitializationSettings(android: androidSettings),
    );

    if (Platform.isAndroid) {
      await _requestAndroidPermission();
    }
  }

  static Future<void> _requestAndroidPermission() async {
    if (Platform.isAndroid) {
      if (Platform.version.startsWith('Android 13') ||
          (Platform.isAndroid &&
              Platform.operatingSystemVersion.contains('13'))) {
        final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
            _notificationsPlugin
                .resolvePlatformSpecificImplementation<
                  AndroidFlutterLocalNotificationsPlugin
                >();
        final bool? granted = await androidImplementation
            ?.requestNotificationsPermission();
        print('Android 通知权限授予: $granted');
      } else {
        print('Android 版本低于13，无需请求通知权限');
      }
    }
  }

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
      ),
      payload: 'message_payload',
    );
  }

  static void onDidReceiveLocalNotification(
    int id,
    String? title,
    String? body,
    String? payload,
  ) {
    print('前台收到通知: $title - $body');
  }

  static void onDidReceiveNotificationResponse(NotificationResponse response) {
    final payload = response.payload;
    print('用户点击了通知，payload: $payload');
  }
}
