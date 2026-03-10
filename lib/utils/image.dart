import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
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

Future<Uint8List?> captureWidgetToPng({
    required GlobalKey globalKey,
    double pixelRatio = 2.0,
  }) async {
    try {
      final renderObject = globalKey.currentContext?.findRenderObject();
      if (renderObject == null) {
        debugPrint("❌ captureWidgetToPng: RenderObject is null");
        return null;
      }

      if (renderObject is! RenderRepaintBoundary) {
        debugPrint("❌ captureWidgetToPng: Widget must be wrapped with RepaintBoundary");
        return null;
      }

      final image = await renderObject.toImage(pixelRatio: pixelRatio);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e, stack) {
      debugPrint("❌ captureWidgetToPng failed: $e\n$stack");
      return null;
    }
  }

