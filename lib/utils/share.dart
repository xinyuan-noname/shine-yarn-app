import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

Future sharePswdKey({required String id, required String passwordKey}) async {
  final String pswdToken = "$id的密码令牌：$passwordKey，复制该段在app即可用";
  await SharePlus.instance.share(ShareParams(text: pswdToken));
}

Future shareImage({
  required Uint8List image,
  String name = "share.png",
  String mimeType = "image/png",
  String? title,
}) async {
  SharePlus.instance.share(
    ShareParams(
      text: title,
      files: [XFile.fromData(image, name: name, mimeType: mimeType)],
    ),
  );
}

Map<String, String>? extractIdAndPassword(String text) {
  final match = RegExp(r'^(\d+)的密码令牌：([\da-zA-Z-]+)').firstMatch(text);
  if (match == null) return null;
  return {'id': match.group(1)!, 'passwordKey': match.group(2)!};
}
