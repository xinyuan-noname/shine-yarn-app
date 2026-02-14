import 'dart:math';
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';

Future<Uint8List?> cropAvatar(XFile picked) async {
  final inputBytes = await picked.readAsBytes();
  final image = img.decodeImage(inputBytes);
  if (image == null) return null;

  final cropped = _cropSquare(image);

  final outputBytes = img.encodeJpg(cropped, quality: 90);
  return outputBytes;
}

img.Image _cropSquare(img.Image src) {
  final size = min(src.width, src.height);
  final x = (src.width - size) ~/ 2;
  final y = (src.height - size) ~/ 2;
  return img.copyCrop(src, x: x, y: y, width: size, height: size);
}
