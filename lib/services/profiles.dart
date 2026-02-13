import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shine/services/api.dart';
import 'package:shine/services/dio.dart';
class ApiProfiles {
  static Future<void> uploadXFileWithDio(XFile xFile) async {
    final bytes = await xFile.readAsBytes();

    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(
        bytes,
        filename: xFile.name,
        contentType: ApiService.parseContentType(xFile.mimeType),
      ),
    });

    try {
      final response = await dio.post(
        '/profiles/avatar',
        data: formData,
        onSendProgress: (sent, total) {
          print('上传进度: ${sent / total * 100}%');
        },
      );
      print('成功: ${response.data}');
    } catch (e) {
      print('失败: $e');
    }
  }
}
