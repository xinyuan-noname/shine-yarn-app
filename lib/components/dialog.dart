import 'package:flutter/material.dart';
import 'package:shine/routes.dart';

void showMessageDialog(
  BuildContext context,
  ValueNotifier<String> message, {
  bool? barrierDissmissible,
}) {
  showDialog(
    context: context,
    barrierDismissible: barrierDissmissible ?? false,
    builder: (_) => ValueListenableBuilder<String>(
      valueListenable: message,
      builder: (_, text, __) => Dialog(
        child: Container(
          height: 72,
          alignment: Alignment.center,
          child: Text(text),
        ),
      ),
    ),
  );
}

void gotoAdminDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text(
          '即将进入超级管理员界面!',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
        ),
        content: Text('确定要进入吗？'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              globalNavigatorKey.currentState?.pushNamedAndRemoveUntil(
                '/admin',
                clearOldRouter,
              );
            },
            child: Text('确定'),
          ),
        ],
      );
    },
  );
}
