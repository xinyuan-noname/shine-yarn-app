import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

class FileStorage {
  static Future<File> saveBytesToAppFolder({
    required String relativePath,
    required Uint8List data,
  }) async {
    final String fullPath = await FileStorage.getPath(relativePath);
    final File file = File(fullPath);
    await file.parent.create(recursive: true);
    return await file.writeAsBytes(data);
  }

  static Future<File> saveStringToAppFolder({
    required String relativePath,
    required String content,
    Encoding encoding = utf8,
  }) async {
    final String fullPath = await FileStorage.getPath(relativePath);
    final File file = File(fullPath);
    await file.parent.create(recursive: true);
    return await file.writeAsString(content, encoding: encoding);
  }

  static Future<String> getPath(String relativePath) async {
    final Directory appDocDir = await getApplicationDocumentsDirectory();
    final String fullPath = path.join(appDocDir.path, relativePath);
    return fullPath;
  }

  static Future<bool> existsFile(String relativePath) async {
    final String fullPath = await FileStorage.getPath(relativePath);
    final File file = File(fullPath);
    return file.exists();
  }

  static Future<Directory> getSubDirectory(String subDirName) async {
    final Directory baseDir = await getApplicationDocumentsDirectory();
    final String targetPath = path.join(baseDir.path, subDirName);
    final Directory targetDir = Directory(targetPath);
    if (!await targetDir.exists()) {
      await targetDir.create(recursive: true);
    }
    return targetDir;
  }

  static Future<void> deleteAllExcept({
    required List<String> keepFileNames,
    required String subDirName,
  }) async {
    final dir = await FileStorage.getSubDirectory(subDirName);
    final List<FileSystemEntity> entities = dir.listSync();
    for (final entity in entities) {
      if (entity is File) {
        final String fileName = entity.uri.pathSegments.last;
        if (!keepFileNames.contains(fileName)) {
          await entity.delete();
        }
      }
    }
  }
}
