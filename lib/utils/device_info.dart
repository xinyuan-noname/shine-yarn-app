// lib/utils/device_info_helper.dart
import 'dart:io' show Platform;
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

bool get isNativePlatform => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

Future<Map<String, String>> getDeviceHeadersForApi() async {
  if (!isNativePlatform) {
    return {};
  }

  final headers = <String, String>{};

  try {
    headers['X-Client-Type'] = 'flutter_app';

    String? deviceModel;
    if (Platform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      deviceModel = '${androidInfo.brand} ${androidInfo.model}'.trim();
    } else if (Platform.isIOS) {
      final iosInfo = await DeviceInfoPlugin().iosInfo;
      deviceModel = iosInfo.model;
    }
    if (deviceModel != null && deviceModel.isNotEmpty) {
      headers['X-Device-Model'] = deviceModel;
    }

    final osVersion = Platform.operatingSystemVersion.trim();
    if (osVersion.isNotEmpty) {
      headers['X-OS-Version'] = osVersion;
    }

    headers['X-App-Version'] = await getVersionInfo();
  } catch (e) {
    // 安静失败：不阻塞请求
  }

  return headers;
}

Future<String> getVersionInfo() async {
  final packageInfo = await PackageInfo.fromPlatform();
  final appVersion = '${packageInfo.version}+${packageInfo.buildNumber}';
  return appVersion;
}
