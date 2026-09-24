import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shine/components/avatar.dart';
import 'package:shine/components/dialog.dart';
import 'package:shine/components/toast.dart';
import 'package:shine/services/api.dart';
import 'package:shine/services/ws_task.dart';
import 'package:shine/theme.dart';
import 'package:shine/utils/message_utils.dart';

/// 发送消息时填写的内容
class SendMessageInput {
  final String content;
  final bool anonymous;
  const SendMessageInput({required this.content, required this.anonymous});
}

/// 给指定成员发送消息：填写内容 -> 选择是否匿名 -> 发送
///
/// 返回消息是否发送成功
Future<bool> showSendMessageDialog({
  required BuildContext context,
  required String targetId,
  String targetUsername = '',
  required ValueNotifier<String> message,
  String title = "发送消息",
  bool allowAnonymous = true,
}) async {
  if (targetId.isEmpty) {
    showToast(msg: "无法确定消息接收人");
    return false;
  }
  if (!ApiService.prepared) {
    showToast(msg: "服务未就绪，暂时无法发送消息");
    return false;
  }
  final input = await _showSendMessageInputDialog(
    context: context,
    targetId: targetId,
    targetUsername: targetUsername,
    title: title,
    allowAnonymous: allowAnonymous,
  );
  if (input == null) return false;
  if (!context.mounted) return false;
  return await _sendMessage(
    context: context,
    targetId: targetId,
    targetUsername: targetUsername,
    message: message,
    input: input,
  );
}

Future<SendMessageInput?> _showSendMessageInputDialog({
  required BuildContext context,
  required String targetId,
  required String targetUsername,
  required String title,
  required bool allowAnonymous,
}) {
  final controller = TextEditingController();
  final formKey = GlobalKey<FormState>();
  final completer = Completer<SendMessageInput?>();
  bool anonymous = false;

  final future = showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return AlertDialog(
            backgroundColor: mainColorPurple,
            title: Text(title, style: dialogTitleStyle),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTargetRow(
                      targetId: targetId,
                      targetUsername: targetUsername,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: controller,
                      autofocus: true,
                      minLines: 3,
                      maxLines: 5,
                      maxLength: 200,
                      keyboardType: TextInputType.multiline,
                      style: inputStyle,
                      decoration: InputDecoration(
                        hintText: "请输入消息内容",
                        hintStyle: hintStyle,
                        counterStyle: dialogContentSmallStyle,
                        filled: true,
                        fillColor: mainColorPurple90,
                        border: OutlineInputBorder(
                          borderSide: BorderSide(
                            width: 1.0,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                      validator: (value) {
                        final text = value?.trim() ?? "";
                        if (text.isEmpty) return "消息内容不能为空";
                        if (text.length > 200) return "消息内容不能超过200字";
                        return null;
                      },
                    ),
                    if (allowAnonymous)
                      SwitchListTile(
                        value: anonymous,
                        onChanged: (value) {
                          setState(() {
                            anonymous = value;
                          });
                        },
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        activeThumbColor: mainColorGreenBlue,
                        activeTrackColor: mainColorGreenBlue40,
                        title: Text(
                          "匿名发送",
                          style: dialogContentStyle.copyWith(
                            color: bgColorLight,
                          ),
                        ),
                        subtitle: Text(
                          anonymous
                              ? "对方只会看到一个随机名字，无法得知你的身份"
                              : "对方将看到你的头像与昵称",
                          style: dialogContentSmallStyle,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                style: dialogButtonStyle,
                onPressed: () {
                  Navigator.of(context).pop();
                  completer.complete(null);
                },
                child: Text("取消"),
              ),
              TextButton(
                style: dialogButtonStyle,
                onPressed: () {
                  if (formKey.currentState?.validate() != true) return;
                  final result = SendMessageInput(
                    content: controller.text.trim(),
                    anonymous: anonymous,
                  );
                  Navigator.of(context).pop();
                  completer.complete(result);
                },
                child: Text("发送"),
              ),
            ],
          );
        },
      );
    },
  );
  future.then((_) {
    if (!completer.isCompleted) completer.complete(null);
  });
  return completer.future;
}

Widget _buildTargetRow({
  required String targetId,
  required String targetUsername,
}) {
  final name = targetUsername.isEmpty ? targetId : targetUsername;
  return Row(
    children: [
      NetworkAvatar(id: targetId, radius: 20),
      const SizedBox(width: 10),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              name,
              style: const TextStyle(
                fontFamily: 'SmileySans',
                fontSize: 20,
                color: bgColorLight,
              ),
            ),
            Text("学号：$targetId", style: dialogContentSmallStyle),
          ],
        ),
      ),
    ],
  );
}

Future<bool> _sendMessage({
  required BuildContext context,
  required String targetId,
  required String targetUsername,
  required ValueNotifier<String> message,
  required SendMessageInput input,
}) async {
  final targetName = targetUsername.isEmpty ? targetId : targetUsername;
  message.value = "";
  final navigator = Navigator.of(context, rootNavigator: true);
  showMessageDialog(context, message);
  final success = await sendRequestAndChangeMessage(
    message,
    request: Future(() async {
      if (!WsTask.isConnected) return "消息服务未连接，请稍后重试";
      try {
        await WsTask.sendRemind(
          msg: input.content,
          targetList: [targetId],
          anonymous: input.anonymous,
        );
        return null;
      } on TimeoutException {
        return "发送超时，请检查网络后重试";
      } on StateError {
        return "消息服务未连接，请稍后重试";
      } catch (e) {
        return "发送失败：$e";
      }
    }),
    initMessageList: [],
    messageList: [
      "正在发送给$targetName.",
      "正在发送给$targetName..",
      "正在发送给$targetName...",
    ],
    successMessage: input.anonymous ? "匿名消息已发送" : "消息已发送",
    successMessageDuration: const Duration(milliseconds: 600),
    failMessageDuration: const Duration(milliseconds: 1200),
  );
  if (navigator.mounted) navigator.pop();
  return success;
}
