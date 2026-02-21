import 'dart:convert';

String nowBase64() => base64Encode(
  DateTime.now().millisecondsSinceEpoch.toRadixString(10).codeUnits,
);