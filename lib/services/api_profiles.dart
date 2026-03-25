import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:shine/services/api.dart';
import 'package:shine/services/dio.dart';

class ApiProfiles {
  static Future<String?> uploadAvatar(Uint8List bytes) async {
    if (!ApiService.prepared) return "服务未就绪";
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


  static Future getMyProfile() async {
    if (!ApiService.prepared) return "服务未就绪";
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
    if (!ApiService.prepared) return "服务未就绪";
    try {
      config ??= {
        "gender": true,
        "userType": true,
        "username": true,
        "passwordRequired": true,
        "academy":true,
        
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
    if (!ApiService.prepared) return "服务未就绪";
    try {
      idList ??= "all";
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
