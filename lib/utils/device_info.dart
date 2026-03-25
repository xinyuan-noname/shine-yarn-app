import 'dart:io' show Platform;
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

bool get isNativePlatform => !kIsWeb && (Platform.isAndroid || Platform.isWindows);

Future<Map<String, String>> getDeviceHeadersForApi() async {
  if (!isNativePlatform) {
    return {};
  }

  final headers = <String, String>{};

  headers['X-Client-Type'] = 'flutter_app';
  try {
    String? deviceModel;
    if (Platform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      deviceModel = '${androidInfo.brand} ${androidInfo.model}'.trim();
    } else if (Platform.isWindows) {
      final windowsInfo = await DeviceInfoPlugin().windowsInfo;
      deviceModel =
          'Windows ${windowsInfo.majorVersion}.${windowsInfo.minorVersion}'
              .trim();
    }
    if (deviceModel != null && deviceModel.isNotEmpty) {
      headers['X-Device-Model'] = deviceModel;
    }

    final osVersion = Platform.operatingSystemVersion.trim();
    if (osVersion.isNotEmpty) {
      headers['X-OS-Version'] = osVersion;
    }

    headers['X-App-Version'] = await getVersionInfo();
  } finally {}
  return headers;
}

Future<String> getVersionInfo() async {
  final packageInfo = await PackageInfo.fromPlatform();
  final appVersion = '${packageInfo.version}+${packageInfo.buildNumber}';
  return appVersion;
}
