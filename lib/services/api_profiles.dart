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

  static Future getMyAvatar() async {
    try {
      final response = await dio.get(
        '/profiles/my/avatar',
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

  static Future getMyProfile() async {
    try {
      final response = await dio.get('/profiles/my');
      return response.data;
    } on DioException catch (e) {
      return e.message ?? "获取账户信息失败";
    } catch (e) {
      return "获取账户信息失败";
    }
  }

  static Future getUserInfoByList({required List idList, Map? config}) async {
    try {
      config ??= {
        "gender": true,
        "userType": true,
        "username": true,
        "passwordRequired": true,
      };
      final response = await dio.post(
        '/profiles/search/user',
        data: {"idList": idList, "config": config},
      );
      return response.data;
    } on DioException catch (e) {
      return e.message ?? "获取账户信息失败";
    } catch (e) {
      return "获取账户信息失败";
    }
  }

  static Future getUserInfo({String? idList, Map? config}) async {
    try {
      idList ??= "all";
      config ??= {
        "gender": true,
        "userType": true,
        "username": true,
        "passwordRequired": true,
        "position": true,
      };
      final response = await dio.post(
        '/profiles/search/user',
        data: {"idList": idList, "config": config},
      );
      return response.data;
    } on DioException catch (e) {
      return e.message ?? "获取账户信息失败";
    } catch (e) {
      return "获取账户信息失败";
    }
  }

}
