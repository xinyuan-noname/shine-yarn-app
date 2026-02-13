import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:shine/services/dio.dart';

class ApiProfiles {
  static Future<void> uploadAvatar(Uint8List bytes) async {
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(
        bytes,
        filename: 'avatar.jpg',
        contentType: DioMediaType('image', 'jpeg'),
      ),
    });
    try {
      final response = await uploadDio.post('/profiles/avatar', data: formData);
      print('✅ 头像上传成功');
    } catch (e) {
      print('❌ 上传失败: $e');
      rethrow; // 让上层处理错误
    }
  }
}
