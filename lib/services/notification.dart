import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

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
    if (Platform.isAndroid) {
      if (Platform.version.startsWith('Android 13') ||
          (Platform.isAndroid &&
              Platform.operatingSystemVersion.contains('13'))) {
        final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
            _notificationsPlugin
                .resolvePlatformSpecificImplementation<
                  AndroidFlutterLocalNotificationsPlugin
                >();
        await androidImplementation
            ?.requestNotificationsPermission();
      } else {
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
  ) {
  }

  static void onDidReceiveNotificationResponse(NotificationResponse response) {
  }
}
