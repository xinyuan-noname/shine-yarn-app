import 'package:file_picker/file_picker.dart';

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
