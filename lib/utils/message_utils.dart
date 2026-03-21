import 'package:flutter/material.dart';
import 'package:shine/storage/message_storage.dart';

Future<int> countMessageBadge() async {
  final messageList = await MessageStorage.getAllMessage();
  return messageList.where((m) => !m.readed).length;
}


Future<bool> sendRequestAndChangeMessage(
  ValueNotifier<String> message, {
  required Future<String?> request,
  required List<String> initMessageList,
  required List<String> messageList,
  required String successMessage,
  Duration? messageChangeDuration,
  Duration? successMessageDuration,
  Duration? failMessageDuration,
}) async {
  bool animate = true;
  messageChangeDuration ??= Duration(milliseconds: 500);
  String? result;
  result = await Future.any([
    request,
    Future(() async {
      for (final msg in initMessageList) {
        message.value = msg;
        await Future.delayed(messageChangeDuration!);
        if (result != null) return null;
      }
      while (animate) {
        for (final msg in messageList) {
          message.value = msg;
          await Future.delayed(messageChangeDuration!);
          if (!animate) return null;
        }
      }
      return null;
    }),
  ]);
  animate = false;
  if (result == null) {
    message.value = successMessage;
    await Future.delayed(successMessageDuration ?? Duration(milliseconds: 300));
    return true;
  } else {
    message.value = result;
    await Future.delayed(failMessageDuration ?? Duration(milliseconds: 500));
    return false;
  }
}
