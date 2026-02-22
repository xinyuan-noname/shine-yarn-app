import 'package:flutter/material.dart';
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

void showConfrimDialog({
  required BuildContext context,
  required String title,
  required String content,
  VoidCallback? onYes,
}) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        backgroundColor: mainColorPurple,
        title: Text(title, style: dialogTitleStyle),
        content: Text(content, style: dialogContentStyle),
        actions: [
          TextButton(
            style: dialogButtonStyle,
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
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

void gotoAdminDialog(BuildContext context) {
  showConfrimDialog(
    context: context,
    title: '即将进入超级管理员界面!',
    content: '确定要进入吗？',
    onYes: () {
      Navigator.pop(context);
      globalNavigatorKey.currentState?.pushNamedAndRemoveUntil(
        '/admin',
        clearOldRouter,
      );
    },
  );
}
