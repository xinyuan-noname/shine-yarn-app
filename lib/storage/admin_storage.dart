import 'dart:io';
import 'dart:typed_data';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:shine/storage/file_storage.dart';

class AdminStorage {
  static const String _signatureRelativeFolderPath = "admin/signatures/";
  static const String _signatureNameKey = "signature_name_key";
  static Future<void> saveSignature({
    required Uint8List data,
    required String filename,
  }) async {
    final signatureRelativePath = '$_signatureRelativeFolderPath/$filename';
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_signatureNameKey, filename);
    await FileStorage.saveBytesToAppFolder(
      relativePath: signatureRelativePath,
      data: data,
    );
  }

  static Future<String> getSignatureName() async {
    final prefs = await SharedPreferences.getInstance();
    final filename = prefs.getString(_signatureNameKey);
    final signatureRelativePath = '$_signatureRelativeFolderPath/$filename';
    return FileStorage.getPath(signatureRelativePath);
  }

  static Future<String?> getSignature() async {
    final signaturePath = await AdminStorage.getSignatureName();
    final file = File(signaturePath);
    if (!(await file.exists())) return null;
    return await file.readAsString();
  }
}
