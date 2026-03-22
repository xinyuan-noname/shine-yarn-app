import 'dart:io';

import 'package:dio/dio.dart';
import 'package:shine/config/app_config.dart';

class UpdateInfo {
  final String version;
  final String url;
  const UpdateInfo({required this.url, required this.version});
}

Future<UpdateInfo?> getUpdateInfo() async {
  final response = await Dio().get(AppConfig.appInfoUrl);
  final data = response.data;
  if (data is Map<String, dynamic>) {
    String? url;
    if (data['apkUrl'] && Platform.isAndroid) {
      url = data['apkUrl'];
    } else if (data['exeUrl'] && Platform.isWindows) {
      url = data['exeUrl'];
    }
    if (url == null) return null;
    return UpdateInfo(url: url, version: data['version']);
  }
  return null;
}
