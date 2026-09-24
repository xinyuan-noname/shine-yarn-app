import 'package:dio/dio.dart';
import 'package:shine/services/api.dart';
import 'package:shine/services/dio.dart';

class ApiDraw {
  /// 创建随机选人任务, 成功返回任务 ID
  static Future createDrawTask({
    required String title,
    required List<Map<String, dynamic>> rangeUserList,
    required bool reproducible,
    List<List<String>>? drawResult,
  }) async {
    if (!ApiService.prepared) return "服务未就绪";
    try {
      final response = await dio.post(
        '/task/draw/create',
        data: {
          "title": title,
          "rangeUserList": rangeUserList,
          "reproducible": reproducible,
          if (drawResult != null) "drawResult": drawResult,
        },
      );
      return response.data;
    } on DioException catch (e) {
      return e.message ?? "创建随机选人任务失败";
    } catch (e) {
      return "创建随机选人任务失败";
    }
  }

  /// 获取随机选人任务详情
  static Future getDrawTask(int taskId) async {
    if (!ApiService.prepared) return "服务未就绪";
    try {
      final response = await dio.get('/task/draw/$taskId');
      return response.data;
    } on DioException catch (e) {
      return e.message ?? "获取随机选人任务失败";
    } catch (e) {
      return "获取随机选人任务失败";
    }
  }

  /// 更新随机选人任务, 只提交传入的字段
  static Future updateDrawTask({
    required int taskId,
    String? title,
    List<Map<String, dynamic>>? rangeUserList,
    bool? reproducible,
    List<List<String>>? drawResult,
  }) async {
    if (!ApiService.prepared) return "服务未就绪";
    try {
      final Map<String, dynamic> taskData = {};
      if (title != null) taskData["title"] = title;
      if (rangeUserList != null) taskData["rangeUserList"] = rangeUserList;
      if (reproducible != null) taskData["reproducible"] = reproducible;
      if (drawResult != null) taskData["drawResult"] = drawResult;
      if (taskData.isEmpty) return null;
      final response = await dio.patch(
        '/task/draw/update',
        data: {"taskId": taskId, "taskData": taskData},
      );
      return response.data;
    } on DioException catch (e) {
      return e.message ?? "更新随机选人任务失败";
    } catch (e) {
      return "更新随机选人任务失败";
    }
  }
}
