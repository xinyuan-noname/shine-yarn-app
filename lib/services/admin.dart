import 'dart:math';
import 'dart:typed_data';

import 'package:crypton/crypton.dart';
import 'package:dio/dio.dart';
import 'package:shine/services/dio.dart';

class ApiAdmin {
  static RSAPrivateKey? _rsaPrivateKey;
  static setRSASignature(String signature) {
    _rsaPrivateKey = RSAPrivateKey.fromPEM(signature);
  }

  static Map<String, String?> sign(List<String> wordList) {
    final createdAt = DateTime.now().toIso8601String();
    final linkedWords = [...wordList, createdAt].join("|");
    final data = Uint8List.fromList(linkedWords.codeUnits);
    return {
      "createdAt": createdAt,
      "signature": _rsaPrivateKey?.createSHA256Signature(data).toString(),
    };
  }

  static Future<String?> checkSignatureByRSA() async {
    if (_rsaPrivateKey == null) return "签名出错";
    try {
      final word = Random.secure().toString();
      final data = ApiAdmin.sign([word]);
      data.addAll({"word": word});
      await dio.post('/admin/check', data: data);
      return null;
    } on DioException catch (err) {
      return err.message ?? "签名出错";
    } catch (err) {
      return "签名出错";
    }
  }
}
