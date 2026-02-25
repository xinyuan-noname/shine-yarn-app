import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:shine/services/dio.dart';

class ApiProfiles {
  static Future<String?> uploadAvatar(Uint8List bytes) async {
    final formData = FormData.fromMap({
      'avatar': MultipartFile.fromBytes(bytes, filename: 'avatar.jpg'),
    });
    try {
      await uploadDio.post('/profiles/avatar', data: formData);
      return null;
    } on DioException catch (e) {
      return e.message ?? "头像上传失败";
    } catch (e) {
      return "头像上传失败";
    }
  }

  static Future getAvatar(String id) async {
    try {
      final response = await dio.get(
        '/profiles/avatar/$id',
        options: Options(
          headers: {'Accept': 'image/*'},
          responseType: ResponseType.bytes,
        ),
      );
      return response.data;
    } catch (e) {
      return null;
    }
  }
}
