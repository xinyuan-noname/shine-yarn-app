import 'dart:convert';
import 'dart:typed_data';

import 'package:crypton/crypton.dart';
import 'package:dio/dio.dart';
import 'package:shine/services/dio.dart';
import 'package:shine/storage/token_storage.dart';
import 'package:shine/utils/string.dart';

class ApiAdmin {
  static RSAPrivateKey? _rsaPrivateKey;
  static setRSASignature(String signature) {
    _rsaPrivateKey = RSAPrivateKey.fromPEM(signature);
  }

  static Map<String, dynamic>? sign(List wordList) {
    if (_rsaPrivateKey == null) return null;
    final createdAt = DateTime.now().toIso8601String();
    final linkedWords = [...wordList, createdAt].join("|");
    final signatureData = _rsaPrivateKey?.createSHA256Signature(
      Uint8List.fromList(linkedWords.codeUnits),
    );
    final signature = base64Encode(signatureData!.toList());
    return {"createdAt": createdAt, "signature": signature};
  }

  static Future<String?> checkSignatureByRSA() async {
    if (_rsaPrivateKey == null) return "签名出错";
    try {
      final word = nowBase64();
      final data = ApiAdmin.sign([word]);
      if (data == null) return "没有正确配置私钥";
      data.addAll({"word": word});
      await dio.post('/admin/check', data: data);
      return null;
    } on DioException catch (err) {
      return err.message ?? "签名出错";
    } catch (err) {
      return "签名出错";
    }
  }

  static Future<List<dynamic>?> getUserInfo() async {
    if (_rsaPrivateKey == null) return null;
    try {
      final word = nowBase64();
      final data = ApiAdmin.sign([word]);
      if (data == null) return null;
      // gender userType username passwordRequired position
      data.addAll({
        "word": word,
        "idList": "all",
        "config": {
          "gender": true,
          "userType": true,
          "username": true,
          "position": true,
          "passwordRequired": true,
        },
      });
      final response = await dio.post('/admin/search/user', data: data);
      return response.data;
    } catch (err) {
      return null;
    }
  }

  static Future issuePasswordKey(String id) async {
    if (_rsaPrivateKey == null) return null;
    try {
      final data = ApiAdmin.sign([id]);
      if (data == null) return null;
      data.addAll({"id": id});
      final response = await dio.post("/admin/issue/password_key", data: data);
      return response.data;
    } on DioException catch (err) {
      return err.message ?? "签发密码令牌出错";
    } catch (err) {
      return "签名密码令牌出错";
    }
  }

  static Future<String?> changeAdminStatus({
    required String id,
    required isAdmin,
  }) async {
    if (_rsaPrivateKey == null) return "签名出错";
    try {
      final data = ApiAdmin.sign([id, isAdmin]);
      if (data == null) return "没有正确配置私钥";
      data.addAll({"id": id, "isAdmin": isAdmin});
      await dio.patch("/admin/admin_status", data: data);
      return null;
    } on DioException catch (err) {
      return err.message ?? "删除用户出错";
    } catch (err) {
      return "删除用户出错";
    }
  }

  static Future<String?> changePosition({
    required String id,
    required String position,
  }) async {
    if (_rsaPrivateKey == null) return "签名出错";
    try {
      final data = ApiAdmin.sign([id]);
      if (data == null) return "没有正确配置私钥";
      data.addAll({"id": id, "position": position});
      await dio.patch("/admin/position", data: data);
      return null;
    } on DioException catch (err) {
      return err.message ?? "设置职务出错";
    } catch (err) {
      return "设置职务出错";
    }
  }

  static Future<String?> deleteUser(String id) async {
    if (_rsaPrivateKey == null) return "签名出错";
    try {
      final data = ApiAdmin.sign([id]);
      if (data == null) return "没有正确配置私钥";
      data.addAll({"id": id});
      await dio.delete("/admin/delete", data: data);
      return null;
    } on DioException catch (err) {
      return err.message ?? "删除用户出错";
    } catch (err) {
      return "删除用户出错";
    }
  }

  static Future deleteUserBatch(List<Map<String, dynamic>> userList) async {
    if (_rsaPrivateKey == null) return "签名出错";
    try {
      final data = userList;
      for (final user in userList) {
        if (user["id"] == null) continue;
        final id = user["id"];
        final signatureInfo = ApiAdmin.sign([id]);
        if (signatureInfo == null) return "没有正确配置私钥";
        user.addAll(signatureInfo);
      }
      final response = await dio.delete(
        "/admin/delete/batch",
        data: {"userList": data},
      );
      return response.data;
    } on DioException catch (err) {
      return err.message ?? "删除用户出错";
    } catch (err) {
      print(err);
      return "删除用户出错";
    }
  }

  static Future<String?> register(Map<String, dynamic> input) async {
    if (_rsaPrivateKey == null) return "签名出错";
    try {
      final String id = input["id"];
      final int isAdmin = input["isAdmin"] ? 1 : 0;
      final data = ApiAdmin.sign([id, isAdmin]);
      if (data == null) return "没有正确配置私钥";
      data.addAll(input);
      data.addAll({"isAdmin": isAdmin});
      await dio.post("/admin/register", data: data);
      return null;
    } on DioException catch (err) {
      return err.message ?? "注册用户失败";
    } catch (err) {
      return "注册用户失败";
    }
  }

  static Future registerFromExcel(Uint8List bytes) async {
    if (_rsaPrivateKey == null) return "签名出错";
    final word = nowBase64();
    final data = ApiAdmin.sign([word]);
    if (data == null) return "没有正确配置私钥";
    data.addAll({
      'register': MultipartFile.fromBytes(bytes, filename: 'register.xlsx'),
      'word': word,
    });
    final formData = FormData.fromMap(data);
    try {
      final response = await uploadDio.post(
        '/admin/register/excel',
        data: formData,
      );
      return response.data;
    } on DioException catch (e) {
      return e.message ?? "上传excel文件失败";
    } catch (e) {
      return "上传excel文件失败";
    }
  }

  static Future<String?> elevate() async {
    if (_rsaPrivateKey == null) return "签名出错";
    try {
      final word = nowBase64();
      final data = ApiAdmin.sign([word]);
      if (data == null) return "没有正确配置私钥";
      data.addAll({'word': word});
      final response = await dio.post("/admin/elevate", data: data);
      final String? accessToken = response.data['accessToken'];
      if (accessToken is String) {
        TokenStorage.setAccessToken(accessToken);
      }
      return null;
    } on DioException catch (err) {
      return err.message ?? "提权失败";
    } catch (err) {
      return "提权失败";
    }
  }
}
