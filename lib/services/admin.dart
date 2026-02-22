import 'dart:convert';
import 'dart:typed_data';

import 'package:crypton/crypton.dart';
import 'package:dio/dio.dart';
import 'package:shine/services/dio.dart';
import 'package:shine/utils/string.dart';

class ApiAdmin {
  static RSAPrivateKey? _rsaPrivateKey;
  static setRSASignature(String signature) {
    _rsaPrivateKey = RSAPrivateKey.fromPEM(signature);
  }

  static Map<String, dynamic>? sign(List<String> wordList) {
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
      // gender userType username passwordRequired
      data.addAll({
        "word": word,
        "idList": "all",
        "config": {
          "gender": true,
          "userType": true,
          "username": true,
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
      // gender userType username passwordRequired
      data.addAll({"id": id});
      final response = await dio.post("/issue/password_key", data: data);
      return response.data;
    } on DioException catch (err) {
      return err.message ?? "签发密码令牌出错";
    } catch (err) {
      return "签名密码令牌出错";
    }
  }
}
