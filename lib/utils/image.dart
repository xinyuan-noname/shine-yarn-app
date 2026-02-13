import 'dart:math';
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';

Future<Uint8List?> cropAvatar(XFile picked) async {
  // 1. 选择图片（返回 XFile，路径在 App 沙盒内，绝对安全）
  // 2. 读取为内存图像
  final inputBytes = await picked.readAsBytes();
  final image = img.decodeImage(inputBytes);
  if (image == null) return null;

  // 3. 居中裁剪为正方形
  final cropped = _cropSquare(image);

  // 4. 压缩为 JPEG（体积小、兼容好）
  final outputBytes = img.encodeJpg(cropped, quality: 90);
  return outputBytes;
}

// 居中裁剪工具函数
img.Image _cropSquare(img.Image src) {
  final size = min(src.width, src.height);
  final x = (src.width - size) ~/ 2;
  final y = (src.height - size) ~/ 2;
  return img.copyCrop(src, x: x, y: y, width: size, height: size);
}
