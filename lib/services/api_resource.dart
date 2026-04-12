import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:shine/config/app_config.dart';

class ApiResource {
  static String get baseUrl =>
      "${AppConfig.stableGithubOrProxy.isEmpty ? AppConfig.githubAndProxy[0] : AppConfig.stableGithubOrProxy}/resource/main";
  static String get direcotryUrl => "$baseUrl/directory.json";
  static Future getResourceDirecotry() async {
    try {
      final response = await Dio(
        BaseOptions(
          receiveTimeout: const Duration(seconds: 3),
          connectTimeout: const Duration(seconds: 3),
        ),
      ).get(direcotryUrl);
      final result = jsonDecode(response.data);
      if (result is Map) {
        final output = <String, List<String>>{};
        for (final entry in result.entries) {
          final key = entry.key;
          final value = entry.value;
          if (key is String && value is List) {
            output[key] = value.whereType<String>().toList();
          }
        }
        return output;
      } else {
        return "资源错误！";
      }
    } on DioException catch (e) {
      return e.message ?? "获取资源信息失败";
    } catch (e) {
      return "获取资源信息失败";
    }
  }
}
