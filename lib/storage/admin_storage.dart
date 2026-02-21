import 'dart:convert';
import 'dart:typed_data';

class AdminStorage {
  static String? _signature;
  static Future<void> saveSignature(Uint8List data) async{
    String result = utf8.decode(data);
    _signature = result;
  }

  static Future<String?> getSignature() async{
    return _signature;
  }
}
