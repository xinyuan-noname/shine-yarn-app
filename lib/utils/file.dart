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
