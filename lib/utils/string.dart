import 'dart:convert';

String nonce() => base64Encode(
  DateTime.now().millisecondsSinceEpoch.toRadixString(10).codeUnits,
);