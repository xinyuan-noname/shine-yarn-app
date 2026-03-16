import 'package:dio/dio.dart';
import 'package:shine/services/api.dart';
import 'package:shine/services/dio.dart';

class ApiSubjects {
  static Future getCurrentSubjects() async {
    if (!ApiService.prepared) return "服务未就绪";
    try {
      final response = await dio.get("/message/notice");
      final data = response.data;
      return data;
    } on DioException catch (e) {
      return e.message ?? "获取公告信息失败";
    } catch (e) {
      return "获取公告信息失败";
    }
  }
}