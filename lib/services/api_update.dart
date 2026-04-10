import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:shine/config/app_config.dart';

class ApiUpdate {
  static final String baseUrl =
      "${AppConfig.stableGithubOrProxy}/asset/master/";
  static String downloadUrl = '';
  static Future checkIsNewest() async {
    if (AppConfig.stableServerUrl.isEmpty) return '暂无可用的应用信息源';
    try {
      final url = getUpdateUrl("release.json");
      final response = await Dio(
        BaseOptions(
          receiveTimeout: const Duration(seconds: 3),
          connectTimeout: const Duration(seconds: 3),
        ),
      ).get(url);
      return jsonDecode(response.data);
    } on DioException catch (e) {
      return e.message ?? "获取应用信息失败";
    } catch (e) {
      return "获取应用信息失败";
    }
  }

  static String getUpdateUrl(String path) {
    return Uri.parse(baseUrl).resolve(path).toString();
  }
}
