import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:shine/services/api.dart';
import 'package:shine/services/dio.dart';

class ApiAsset {
  static Future uploadDocumentConvertToPdf({
    required Uint8List data,
    required String filename,
  }) async {
    if (!ApiService.isOk) return "服务未就绪";
    final formData = FormData.fromMap({
      'document': MultipartFile.fromBytes(data, filename: filename),
    });
    try {
      final response = await uploadDio.post(
        '/asset/pdf/convert/document',
        data: formData,
      );
      return response.data;
    } on DioException catch (e) {
      return e.message ?? "转化失败";
    } catch (e) {
      return "转化失败";
    }
  }

  static Future<String?> checkPdfExist({required String address}) async {
    if (!ApiService.isOk) return "服务未就绪";
    try {
      await uploadDio.head('/asset/pdf/$address');
      return null;
    } on DioException catch (e) {
      return e.message ?? "文件不存在";
    } catch (e) {
      return "文件不存在";
    }
  }

  static Future checkIsNewest() async {
    if (!ApiService.isOk) return "服务未就绪";
    try {
      await Dio().get(
        "https://loquacious-muffin-b1eed0.netlify.app/release.json",
      );
      return null;
    } on DioException catch (e) {
      return e.message ?? "获取应用信息失败";
    } catch (e) {
      return "获取应用信息失败";
    }
  }
}
