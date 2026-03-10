import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shine/components/input.dart';
import 'package:shine/routes.dart';
import 'package:shine/storage/group_storage.dart';
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
  fontSize: 15,
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

Future<void> showAlertDialog({
  required BuildContext context,
  required String title,
  required String content,
  VoidCallback? onYes,
  String confirmText = '确定',
}) async {
  await showDialog(
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
            onPressed: onYes ?? () => Navigator.of(context).pop(),
            child: Text(confirmText),
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
  String confirmText = '确定',
  String cancelText = '取消',
}) async {
  final result = await showDialog<bool?>(
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
              Navigator.pop(context, false);
            },
            child: Text(cancelText),
          ),
          TextButton(
            style: dialogButtonStyle,
            onPressed: () {
              Navigator.pop(context, true);
            },
            child: Text(confirmText),
          ),
        ],
      );
    },
  );
  return result ?? false;
}

Future<String?> showPromptDialog({
  required BuildContext context,
  required String title,
  required String label,
  String? initValue,
  String confirmText = '确定',
  String cancelText = '取消',
  int? min,
  int? max,
}) {
  final formKey = GlobalKey<FormState>();
  final controller = TextEditingController();
  final completer = Completer<String?>();
  final future = showDialog(
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
                autofocus: true,
                name: "prompt",
                label: label,
                minLength: min ?? 1,
                maxLength: max ?? 32,
                controller: controller,
                hintStyle: hintStyle,
                inputStyle: inputStyle,
                labelStyle: labelStyle,
                border: OutlineInputBorder(
                  borderSide: BorderSide(width: 1.0, color: Colors.grey),
                ),
                color: mainColorPurple90,
                inputFormatters: [
                  FilteringTextInputFormatter.deny(RegExp(r"\s")),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            style: dialogButtonStyle,
            onPressed: () {
              Navigator.of(context).pop();
              completer.complete(null);
            },
            child: Text(cancelText),
          ),
          TextButton(
            style: dialogButtonStyle,
            onPressed: () {
              final result = controller.text;
              if (formKey.currentState!.validate() && result.isNotEmpty) {
                Navigator.of(context).pop();
                completer.complete(result);
              }
            },
            child: Text(confirmText),
          ),
        ],
      );
    },
  );
  if (initValue is String) {
    controller.text = initValue;
  }
  future.then((_) {
    if (completer.isCompleted) return;
    completer.complete(null);
  });
  return completer.future;
}

Future<T?> showDropDownDialog<T>({
  required BuildContext context,
  required String title,
  required List<(T, String)> items,
  required T initialValue,
  String confirmText = '确定',
  String cancelText = '取消',
}) {
  final completer = Completer<T?>();
  T selectedValue = initialValue;

  final future = showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return AlertDialog(
        backgroundColor: mainColorPurple,
        title: Text(title, style: dialogTitleStyle),
        content: StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return DropdownButtonFormField<T>(
              initialValue: selectedValue,
              onChanged: (T? newValue) {
                if (newValue == null) return;
                selectedValue = newValue;
                setState(() {});
              },
              dropdownColor: mainColorPurple60,
              items: items.map((item) {
                return DropdownMenuItem<T>(
                  value: item.$1,
                  child: Text(item.$2, style: dialogContentStyle),
                );
              }).toList(),
              decoration: InputDecoration(
                hintStyle: hintStyle,
                border: OutlineInputBorder(
                  borderSide: BorderSide(width: 1.0, color: Colors.grey),
                ),
                filled: true,
                fillColor: mainColorPurple90,
              ),
            );
          },
        ),
        actions: [
          TextButton(
            style: dialogButtonStyle,
            onPressed: () {
              Navigator.of(context).pop();
              completer.complete(null);
            },
            child: Text(cancelText),
          ),
          TextButton(
            style: dialogButtonStyle,
            onPressed: () {
              Navigator.of(context).pop();
              completer.complete(selectedValue);
            },
            child: Text(confirmText),
          ),
        ],
      );
    },
  );
  future.then((_) {
    if (completer.isCompleted) return;
    completer.complete(null);
  });
  return completer.future;
}

Future<GroupStorageKey?> showGroupStorageKeySelectionDialog({
  required BuildContext context,
  required String title,
  GroupStorageKey initialValue = GroupStorageKey.entire,
}) {
  return showDropDownDialog<GroupStorageKey>(
    context: context,
    title: title,
    items: [
      (GroupStorageKey.entire, "所有学生"),
      (GroupStorageKey.male, "所有男生"),
      (GroupStorageKey.female, "所有女生"),
      (GroupStorageKey.position, "所有班委"),
      (GroupStorageKey.user, "所有非班委"),
      (GroupStorageKey.admin, "所有管理员"),
    ],
    initialValue: initialValue,
  );
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
Future<String?> showUnfinishedTaskSaveDialog({
  required BuildContext context,
  int min = 2,
  int max = 8,
}) {
  return showPromptDialog(
    context: context,
    title: "该任务暂未完成，是否保存？(名称在$min到$max个字符之间)",
    label: "任务名称",
    confirmText: "保存",
    cancelText: "退出",
    min: min,
    max: max,
    initValue: '',
  );
}