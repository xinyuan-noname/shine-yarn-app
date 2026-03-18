import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:shine/services/api.dart';
import 'package:shine/services/dio.dart';

class ApiTaskUpload {
  static final myUploadsCache = [];
  static Future<String?> upload(
    Uint8List bytes, {
    required String filename,
    required int taskId,
  }) async {
    if (!ApiService.isOk) return "服务未就绪";
    final formData = FormData.fromMap({
      'upload': MultipartFile.fromBytes(bytes, filename: filename),
      'taskId': taskId,
      'uploadId': ApiService.userId,
      'uploadAt': DateTime.now().millisecondsSinceEpoch,
      'uploadFileName': filename,
    });
    try {
      await uploadDio.post('/task/upload/', data: formData);
      return null;
    } on DioException catch (e) {
      return e.message ?? "任务提交失败";
    } catch (e) {
      return "任务提交失败";
    }
  }

  static Future getUploadsByTaskId(int taskId) async {
    if (!ApiService.isOk) return "服务未就绪";
    try {
      final response = await dio.get('/task/upload/list/$taskId');
      return response.data;
    } on DioException catch (e) {
      return e.message ?? "获取上传列表失败";
    } catch (e) {
      return "获取上传列表失败";
    }
  }

  static Future getMyUploads() async {
    if (!ApiService.isOk) return "服务未就绪";
    try {
      final response = await dio.get('/task/upload/my');
      return response.data;
    } on DioException catch (e) {
      return e.message ?? "获取上传列表失败";
    } catch (e) {
      return "获取上传列表失败";
    }
  }
}
