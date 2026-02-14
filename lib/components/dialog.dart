import 'package:flutter/material.dart';

void showMessageDialog(BuildContext context, ValueNotifier<String> message) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => ValueListenableBuilder<String>(
      valueListenable: message,
      builder: (_, text, __) => Dialog(
        child: Container(
          height: 64,
          alignment: Alignment.center,
          child: Text(text),
        ),
      ),
    ),
  );
}
