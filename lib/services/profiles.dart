import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:shine/services/dio.dart';

class ApiProfiles {
  static Future<String?> uploadAvatar(
    Uint8List bytes, {
    String subMimeType = "jepg",
  }) async {
    final formData = FormData.fromMap({
      'avatar': MultipartFile.fromBytes(
        bytes,
        filename: 'avatar.jpg',
        contentType: DioMediaType('image', subMimeType),
      ),
    });
    try {
      await uploadDio.post('/profiles/avatar', data: formData);
    } on DioException catch (e) {
      return e.message ?? "头像上传失败";
    } catch (e) {
      return "头像上传失败";
    }
  }
}
