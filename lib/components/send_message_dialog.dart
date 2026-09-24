import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shine/components/avatar.dart';
import 'package:shine/components/dialog.dart';
import 'package:shine/components/toast.dart';
import 'package:shine/services/api.dart';
import 'package:shine/services/ws_task.dart';
import 'package:shine/storage/group_storage.dart';
import 'package:shine/theme.dart';
import 'package:shine/utils/message_utils.dart';
import 'package:shine/worker/worker.dart';

/// 广播消息的消息等级(影响消息配色)
const int broadcastMessageLevel = 5;

/// 发送消息时填写的内容
class SendMessageInput {
  final String content;
  final bool anonymous;
  const SendMessageInput({required this.content, required this.anonymous});
}

/// 广播消息填写的内容
class BroadcastMessageInput {
  final GroupStorageKey group;
  final String content;
  const BroadcastMessageInput({required this.group, required this.content});

  String get groupName => groupStorageKeyLabelMap[group] ?? group.name;
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

/// 向指定分组发送广播：选择分组 -> 填写内容 -> 发送
///
/// 返回广播是否发送成功
Future<bool> showBroadcastMessageDialog({
  required BuildContext context,
  required ValueNotifier<String> message,
  GroupStorageKey initialGroup = GroupStorageKey.entire,
}) async {
  if (!ApiService.prepared) {
    showToast(msg: "服务未就绪，暂时无法发送广播");
    return false;
  }
  if (ApiService.userType == "guest") {
    showToast(msg: "游客(无密码登录用户)暂不支持发送广播");
    return false;
  }
  final input = await showDialog<BroadcastMessageInput>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _BroadcastInputDialog(initialGroup: initialGroup),
  );
  if (input == null) return false;
  if (!context.mounted) return false;
  return await _sendBroadcast(
    context: context,
    message: message,
    input: input,
  );
}

Future<bool> _sendBroadcast({
  required BuildContext context,
  required ValueNotifier<String> message,
  required BroadcastMessageInput input,
}) async {
  final groupName = input.groupName;
  message.value = "";
  final navigator = Navigator.of(context, rootNavigator: true);
  showMessageDialog(context, message);
  final success = await sendRequestAndChangeMessage(
    message,
    request: Future(() async {
      if (!WsTask.isConnected) return "消息服务未连接，请稍后重试";
      final targetList = await _getGroupIdList(input.group);
      if (targetList.isEmpty) return "$groupName暂无成员，无法发送广播";
      try {
        await WsTask.sendRemind(
          msg: input.content,
          targetList: targetList,
          level: broadcastMessageLevel,
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
      "正在向$groupName发送广播.",
      "正在向$groupName发送广播..",
      "正在向$groupName发送广播...",
    ],
    successMessage: "广播已发送",
    successMessageDuration: const Duration(milliseconds: 600),
    failMessageDuration: const Duration(milliseconds: 1200),
  );
  if (navigator.mounted) navigator.pop();
  return success;
}

/// 取出分组内所有成员的学号
Future<List<String>> _getGroupIdList(GroupStorageKey group) async {
  final userList = await Worker.getUserListByGroup(group);
  return GroupStorage.getIdList(userList);
}

/// 广播内容填写弹窗，包含分组选择与成员人数提示
class _BroadcastInputDialog extends StatefulWidget {
  final GroupStorageKey initialGroup;
  const _BroadcastInputDialog({required this.initialGroup});

  @override
  State<_BroadcastInputDialog> createState() => _BroadcastInputDialogState();
}

class _BroadcastInputDialogState extends State<_BroadcastInputDialog> {
  final _formKey = GlobalKey<FormState>();
  final _contentController = TextEditingController();
  late GroupStorageKey _group;
  int? _memberCount;
  bool _counting = true;

  @override
  void initState() {
    super.initState();
    _group = widget.initialGroup;
    _updateMemberCount();
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _updateMemberCount() async {
    setState(() {
      _counting = true;
      _memberCount = null;
    });
    final idList = await _getGroupIdList(_group);
    if (!mounted) return;
    setState(() {
      _counting = false;
      _memberCount = idList.length;
    });
  }

  void _onChangeGroup(GroupStorageKey? group) {
    if (group == null || group == _group) return;
    setState(() {
      _group = group;
    });
    _updateMemberCount();
  }

  void _onConfirm() {
    if (_formKey.currentState?.validate() != true) return;
    Navigator.of(context).pop(
      BroadcastMessageInput(
        group: _group,
        content: _contentController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final noMember = !_counting && (_memberCount ?? 0) == 0;
    return AlertDialog(
      backgroundColor: mainColorPurple,
      title: Text("发送广播", style: dialogTitleStyle),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<GroupStorageKey>(
                initialValue: _group,
                onChanged: _onChangeGroup,
                dropdownColor: mainColorPurple60,
                items: groupStorageKeyLabelList.map((item) {
                  return DropdownMenuItem<GroupStorageKey>(
                    value: item.$1,
                    child: Text(item.$2, style: dialogContentStyle),
                  );
                }).toList(),
                decoration: InputDecoration(
                  labelText: "接收分组",
                  labelStyle: dialogContentSmallStyle,
                  hintStyle: hintStyle,
                  filled: true,
                  fillColor: mainColorPurple90,
                  border: OutlineInputBorder(
                    borderSide: BorderSide(width: 1.0, color: Colors.grey),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.groups_outlined,
                    size: 16,
                    color: noMember ? mainColorRed : bgColorLight80,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _counting
                        ? "正在统计成员..."
                        : noMember
                        ? "该分组暂无成员，无法发送"
                        : "该分组共$_memberCount名成员",
                    style: dialogContentSmallStyle.copyWith(
                      color: noMember ? mainColorRed : bgColorLight80,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _contentController,
                autofocus: true,
                minLines: 3,
                maxLines: 5,
                maxLength: 200,
                keyboardType: TextInputType.multiline,
                style: inputStyle,
                decoration: InputDecoration(
                  hintText: "请输入广播内容",
                  hintStyle: hintStyle,
                  counterStyle: dialogContentSmallStyle,
                  filled: true,
                  fillColor: mainColorPurple90,
                  border: OutlineInputBorder(
                    borderSide: BorderSide(width: 1.0, color: Colors.grey),
                  ),
                ),
                validator: (value) {
                  final text = value?.trim() ?? "";
                  if (text.isEmpty) return "广播内容不能为空";
                  if (text.length > 200) return "广播内容不能超过200字";
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          style: dialogButtonStyle,
          onPressed: () => Navigator.of(context).pop(),
          child: Text("取消"),
        ),
        TextButton(
          style: dialogButtonStyle,
          onPressed: _onConfirm,
          child: Text("发送"),
        ),
      ],
    );
  }
}
