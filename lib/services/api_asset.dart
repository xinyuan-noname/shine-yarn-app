import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:shine/services/api.dart';
import 'package:shine/services/dio.dart';

class ApiAsset {
  static Future uploadDocumentConvertToPdf({
    required Uint8List data,
    required String filename,
  }) async {
    if (!ApiService.prepared) return "服务未就绪";
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
    if (!ApiService.prepared) return "服务未就绪";
    try {
      await uploadDio.head('/asset/pdf/$address');
      return null;
    } on DioException catch (e) {
      return e.message ?? "文件不存在";
    } catch (e) {
      return "文件不存在";
    }
  }

  /// 根据文件名推断图片类型, 部分机型上 XFile.mimeType 为空
  static DioMediaType _imageContentType(String filename) {
    final ext = filename.contains('.')
        ? filename.split('.').last.toLowerCase()
        : '';
    switch (ext) {
      case 'png':
        return DioMediaType('image', 'png');
      case 'gif':
        return DioMediaType('image', 'gif');
      case 'webp':
        return DioMediaType('image', 'webp');
      case 'bmp':
        return DioMediaType('image', 'bmp');
      default:
        return DioMediaType('image', 'jpeg');
    }
  }

  /// 上传事项里引用的图片, 成功返回 {name}, name 用于 %img[name]% 标记
  static Future uploadToDoImage({
    required Uint8List data,
    required String filename,
    String? mimeType,
  }) async {
    if (!ApiService.prepared) return "服务未就绪";
    final formData = FormData.fromMap({
      'image': MultipartFile.fromBytes(
        data,
        filename: filename,
        contentType:
            ApiService.parseContentType(mimeType) ?? _imageContentType(filename),
      ),
    });
    try {
      final response = await uploadDio.post('/asset/image', data: formData);
      return response.data;
    } on DioException catch (e) {
      return e.message ?? "图片上传失败";
    } catch (e) {
      return "图片上传失败";
    }
  }
}
