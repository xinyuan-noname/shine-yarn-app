import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shine/components/input.dart';
import 'package:shine/routes.dart';
import 'package:shine/theme.dart';

const dialogTitleStyle = TextStyle(
  fontSize: 20,
  fontFamily: 'SmileySans',
  fontWeight: FontWeight.w500,
);
const dialogContentStyle = TextStyle(
  fontSize: 16,
  fontFamily: 'SmileySans',
  color: bgColorLight60,
);
const dialogActionStyle = TextStyle(
  fontFamily: 'SmileySans',
  color: bgColorLight80,
);
final dialogButtonStyle = TextButton.styleFrom(
  backgroundColor: mainColorGreenBule60,
  foregroundColor: bgColorLight80,
  textStyle: dialogActionStyle,
);
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

void showAlertDialog({
  required BuildContext context,
  required String title,
  required String content,
  VoidCallback? onYes,
}) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return AlertDialog(
        backgroundColor: mainColorPurple,
        title: Text(title, style: dialogTitleStyle),
        content: Text(content, style: dialogContentStyle),
        actions: [
          TextButton(
            style: dialogButtonStyle,
            onPressed: onYes ?? () => Navigator.pop(context),
            child: const Text('确定'),
          ),
        ],
      );
    },
  );
}

Future<bool> showConfrimDialog({
  required BuildContext context,
  required String title,
  required String content,
}) {
  final completer = Completer<bool>();
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return AlertDialog(
        backgroundColor: mainColorPurple,
        title: Text(title, style: dialogTitleStyle),
        content: Text(content, style: dialogContentStyle),
        actions: [
          TextButton(
            style: dialogButtonStyle,
            onPressed: () {
              Navigator.pop(context);
              completer.complete(false);
            },
            child: const Text('取消'),
          ),
          TextButton(
            style: dialogButtonStyle,
            onPressed: () {
              Navigator.pop(context);
              completer.complete(true);
            },
            child: const Text('确定'),
          ),
        ],
      );
    },
  );
  return completer.future;
}

Future<String?> showPromptDialog({
  required BuildContext context,
  required String title,
  required String label,
  VoidCallback? onYes,
}) {
  final formKey = GlobalKey<FormState>();
  Map<String, dynamic> map = {};
  final completer = Completer<String?>();
  showDialog(
    barrierDismissible: false,
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        backgroundColor: mainColorPurple,
        title: Text(title, style: dialogTitleStyle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Form(
              key: formKey,
              child: Input(
                name: "prompt",
                label: label,
                onSavedMap: map,
                hintStyle: hintStyle,
                inputStyle: inputStyle,
                labelStyle: labelStyle,
                border: OutlineInputBorder(
                  borderSide: BorderSide(width: 1.0, color: Colors.grey),
                ),
                color: mainColorPurple90,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            style: dialogButtonStyle,
            onPressed: () {
              Navigator.pop(context);
              completer.complete(null);
            },
            child: const Text('取消'),
          ),
          TextButton(
            style: dialogButtonStyle,
            onPressed: () {
              formKey.currentState?.save();
              final String? result = map['prompt'];
              Navigator.pop(context);
              completer.complete(result);
            },
            child: const Text('确定'),
          ),
        ],
      );
    },
  );
  return completer.future;
}

Future gotoAdminDialog(BuildContext context) async {
  final result = await showConfrimDialog(
    context: context,
    title: '即将进入超级管理员界面!',
    content: '确定要进入吗？',
  );
  if (!result) return null;
  return await globalNavigatorKey.currentState?.pushNamed('/admin');
}
