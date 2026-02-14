import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:shine/services/dio.dart';

class ApiProfiles {
  static Future<bool> uploadAvatar(
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
      final response = await uploadDio.post('/profiles/avatar', data: formData);
      return true;
    } catch (e) {
      return false;
    }
  }
}
