import 'package:dio/dio.dart';
import 'package:shine/services/api.dart';
import 'package:shine/services/dio.dart';

class ApiMessage {
  static Future getAllNotice() async {
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

  static Future getPublicToDoList() async {
    if (!ApiService.prepared) return "服务未就绪";
    try {
      final response = await dio.get("/message/to_do/public/list");
      final data = response.data;
      return data;
    } on DioException catch (e) {
      return e.message ?? "获取待办事项失败";
    } catch (e) {
      return "获取待办事项失败";
    }
  }

  /// 发布事项。
  ///
  /// [source] 是发布者昵称：事项改为所有人都能发布后，来源统一写昵称，
  /// 由服务端原样存回列表的 source 字段（不传时保持服务端原有取值）。
  static Future<String?> addPublicToDoItem({
    required String title,
    required String content,
    String? source,
  }) async {
    if (!ApiService.prepared) return "服务未就绪";
    try {
      await dio.post(
        "/message/to_do/public/create",
        data: {
          "title": title,
          "content": content,
          "ts": DateTime.now().millisecondsSinceEpoch,
          if (source != null && source.trim().isNotEmpty) "source": source.trim(),
        },
      );
      return null;
    } on DioException catch (e) {
      return e.message ?? "添加待办事项失败";
    } catch (e) {
      return "添加待办事项失败";
    }
  }

  /// 修改事项。
  ///
  /// [source] 传原事项的来源，避免服务端把作者改写成当前操作人。
  static Future<String?> updatePublicToDoItem({
    required String itemId,
    required String title,
    required String content,
    String? source,
  }) async {
    if (!ApiService.prepared) return "服务未就绪";
    try {
      await dio.patch(
        "/message/to_do/public/update",
        data: {
          "itemId": itemId,
          "title": title,
          "content": content,
          if (source != null && source.trim().isNotEmpty) "source": source.trim(),
        },
      );
      return null;
    } on DioException catch (e) {
      return "更新待办事项失败：${e.message ?? "未知错误"}";
    } catch (e) {
      return "更新待办事项失败：未知错误";
    }
  }

  static Future<String?> deletePublicToDoItem(String itemId) async {
    if (!ApiService.prepared) return "服务未就绪";
    try {
      await dio.delete("/message/to_do/public/delete", data: {"itemId": itemId});
      return null;
    } on DioException catch (e) {
      return e.message ?? "删除待办事项失败";
    } catch (e) {
      return "删除待办事项失败";
    }
  }
}
