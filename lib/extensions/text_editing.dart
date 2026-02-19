import 'dart:convert';
import 'package:flutter/material.dart';

extension TextEditingControllerMap on Map<String, TextEditingController> {
  void disposeAll() {
    for (final controller in values) {
      controller.dispose();
    }
  }

  Map<String, String> get asTextMap {
    final map = <String, String>{};
    for (final entry in entries) {
      final name = entry.key, controller = entry.value;
      map[name] = controller.text;
    }
    return map;
  }

  String get asTextJSON {
    final map = <String, String>{};
    for (final entry in entries) {
      final name = entry.key, controller = entry.value;
      map[name] = controller.text;
    }
    return jsonEncode(map);
  }
}