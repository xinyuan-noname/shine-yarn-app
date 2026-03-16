import 'package:dio/dio.dart';
import 'package:shine/services/api.dart';
import 'package:shine/services/dio.dart';

class ApiTask {
  static Future createUploadTask({
    required String title,
    required DateTime startedAt,
    required DateTime endedAt,
    required String subjectName,
    required String mimetype,
    required String format,
    required String source,
  }) async {
    return ApiTask.createTask(
      title: title,
      startedAt: startedAt,
      endedAt: endedAt,
      subjectName: subjectName,
      mimetype: mimetype,
      taskType: "upload",
      format: format,
      notice: 1,
      source: source,
    );
  }

  static Future createTask({
    required String title,
    required DateTime startedAt,
    required DateTime endedAt,
    required String subjectName,
    required String mimetype,
    required String taskType,
    required String format,
    required int notice,
    required String source,
  }) async {
    try {
      final response = await dio.post(
        "/task/config/create",
        data: {
          "title": title,
          "startedAt": startedAt.millisecondsSinceEpoch,
          "endedAt": endedAt.millisecondsSinceEpoch,
          "subjectName": subjectName,
          "mimetype": mimetype,
          "taskType": taskType,
          "format": format,
          "notice": notice,
          "source": source,
        },
      );
      return response.data;
    } on DioException catch (e) {
      return e.message ?? "创建任务失败";
    } catch (e) {
      return "创建任务失败";
    }
  }

  static Future getAllTasks() async {
    try {
      final response = await dio.get("/task/config/all");
      final data = response.data;
      return data;
    } on DioException catch (e) {
      return e.message ?? "获取任务列表失败";
    } catch (e) {
      return "获取任务列表失败";
    }
  }

  static Future<String?> updateTask({
    required int taskId,
    String? title,
    DateTime? startedAt,
    DateTime? endedAt,
    String? subjectName,
    String? mimetype,
    String? taskType,
    String? format,
  }) async {
    try {
      final Map<String, dynamic> data = {};
      if (title != null) data["title"] = title;
      if (startedAt != null) {
        data["startedAt"] = startedAt.millisecondsSinceEpoch;
      }
      if (endedAt != null) {
        data["endedAt"] = endedAt.millisecondsSinceEpoch;
      }
      if (subjectName != null) data["subjectName"] = subjectName;
      if (mimetype != null) data["mimetype"] = mimetype;
      if (taskType != null) data["taskType"] = taskType;
      if (format != null) data["format"] = format;
      await dio.patch(
        "/task/config/update",
        data: {"taskId": taskId, "taskData": data},
      );
      return null;
    } on DioException catch (e) {
      return e.message ?? "更新任务失败";
    } catch (e) {
      return "更新任务失败";
    }
  }

  static Future<String> deleteTask({required int taskId}) async {
    if (!ApiService.prepared) return "服务未就绪";
    try {
      final response = await dio.delete(
        '/task/config/delete',
        data: {"taskId": taskId},
      );
      return response.data;
    } on DioException catch (e) {
      return e.message ?? "删除账户信息失败";
    } catch (e) {
      return "删除账户信息失败";
    }
  }
}
