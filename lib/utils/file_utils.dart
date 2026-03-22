import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shine/pages/view_image_page.dart';
import 'package:shine/pages/view_pdf_page.dart';
import 'package:shine/routes.dart';
import 'package:shine/services/api.dart';
import 'package:path/path.dart' as path;
import 'package:shine/utils/uri_utils.dart';

Future<Directory?> getExternalDirectory() async {
  Directory? directory;
  if (Platform.isAndroid) {
    directory = await getExternalStorageDirectory();
  } else if (Platform.isIOS) {
    directory = await getApplicationDocumentsDirectory();
  }
  return directory;
}

const imageExtensions = {
  'jpg',
  'jpeg',
  'png',
  'gif',
  'bmp',
  'webp',
  'svg',
  'tiff',
  'tif',
};
bool isImageFile(String filePath) {
  final ext = path.extension(filePath).substring(1).toLowerCase();
  return imageExtensions.contains(ext);
}

const documentExtensions = {'xls', 'xlsx', 'doc', 'docx', 'ppt', 'pptx', 'pdf'};

bool isDocument(String filePath) {
  final ext = path.extension(filePath).substring(1).toLowerCase();
  return documentExtensions.contains(ext);
}

Future<PlatformFile?> pickFile({List<String>? exts}) async {
  FilePickerResult? result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowMultiple: false,
    withData: true,
    allowedExtensions: exts,
  );
  if (result != null) {
    final file = result.files.single;
    return file;
  }
  return null;
}

Future<PlatformFile?> pickFileAny() async {
  FilePickerResult? result = await FilePicker.platform.pickFiles(
    type: FileType.any,
    allowMultiple: false,
    withData: true,
  );
  if (result != null) {
    final file = result.files.single;
    return file;
  }
  return null;
}

List<String>? getExtensionListFromMimeType(String mimetype) {
  switch (mimetype) {
    case "application/vnd.openxmlformats-officedocument.wordprocessingml.document":
      return ["docx"];

    case "application/pdf":
      return ["pdf"];

    case "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet":
      return ["xlsx"];

    case "image/jpeg":
      return ["jpg"];

    case "image/png":
      return ["png"];

    case "video/mp4":
      return ["mp4"];

    case "application/zip":
      return ["zip"];

    default:
      return null;
  }
}

String formatBytes(int? bytes) {
  if (bytes == null) return "未知大小";
  if (bytes < 1000) {
    return '$bytes B';
  }
  if (bytes < 1000_000) {
    return '${(bytes / 1000).toStringAsFixed(2)} KB';
  }
  if (bytes < 1000_000_000) {
    return '${(bytes / (1000_000)).toStringAsFixed(2)} MB';
  }
  return '${(bytes / (1000_000_000)).toStringAsFixed(2)} GB';
}

Future gotoViewPdfFile(String filepath) async {
  await globalNavigatorKey.currentState?.pushNamed(
    "/view/pdf",
    arguments: ViewPdfPageArgs(filePath: filepath),
  );
}

Future gotoViewPdfUrl(
  String url, {
  bool downloadable = false,
  String? filename,
  String? downloadUrl
}) async {
  await globalNavigatorKey.currentState?.pushNamed(
    "/view/pdf",
    arguments: ViewPdfPageArgs(
      url: ensureUrl(url),
      downloadUrl: downloadUrl,
      downloadable: downloadable,
      filename: filename,
    ),
  );
}

Future gotoViewImageFile(String filepath) async {
  await globalNavigatorKey.currentState?.pushNamed(
    "/view/image",
    arguments: ViewImagePageArgs(filePath: filepath),
  );
}

Future gotoViewImageUrl(String url) async {
  await globalNavigatorKey.currentState?.pushNamed(
    "/view/image",
    arguments: ViewImagePageArgs(url: ensureUrl(url)),
  );
}
