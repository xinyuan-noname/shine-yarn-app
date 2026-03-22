import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

enum HashDigestCoding { binary, hex, base64, base64Url }

enum HashAlgorithm { sha256, sha512, md5 }

String convertToHash(
  Uint8List data, {
  HashDigestCoding coding = HashDigestCoding.base64Url,
  HashAlgorithm algorithm = HashAlgorithm.sha256,
}) {
  final digest = _computeHash(data, algorithm);

  switch (coding) {
    case HashDigestCoding.binary:
      return digest.toString();
    case HashDigestCoding.hex:
      return digest.toString().substring(2); // 移除 '0x' 前缀
    case HashDigestCoding.base64:
      return base64Encode(digest.bytes);
    case HashDigestCoding.base64Url:
      return base64UrlEncode(digest.bytes);
  }
}

Digest _computeHash(Uint8List data, HashAlgorithm algorithm) {
  switch (algorithm) {
    case HashAlgorithm.sha256:
      return sha256.convert(data);
    case HashAlgorithm.sha512:
      return sha512.convert(data);
    case HashAlgorithm.md5:
      return md5.convert(data);
  }
}

String hashString(
  String input, {
  HashDigestCoding coding = HashDigestCoding.base64Url,
  HashAlgorithm algorithm = HashAlgorithm.sha256,
}) {
  final data = utf8.encode(input);
  return convertToHash(
    Uint8List.fromList(data),
    coding: coding,
    algorithm: algorithm,
  );
}
