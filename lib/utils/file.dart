import 'package:file_picker/file_picker.dart';

Future<PlatformFile?> pickFile({List<String>? ext}) async {
  FilePickerResult? result = await FilePicker.platform.pickFiles(
    type: FileType.any,
    allowMultiple: false,
    withData: true,
  );
  if (result != null) {
    final file = result.files.single;
    if (ext != null && ext.contains(file.extension)) {
      return file;
    }
  }
  return null;
}
