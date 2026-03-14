import 'dart:math';

import 'package:flutter/material.dart';
import 'package:shine/components/message_card.dart';
import 'package:shine/storage/message_storage.dart';
import 'package:shine/theme.dart';

class MessageView extends StatelessWidget {
  final RefreshCallback onRefresh;
  final List<MessageStorageData> messageList;

  final VoidCallback? deleteCallback;
  const MessageView({
    super.key,
    required this.onRefresh,
    required this.messageList,
    this.deleteCallback,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: mainColorPurple90,
      backgroundColor: bgColorLight,
      onRefresh: onRefresh,
      child: ListView.builder(
        padding: viewPadding,
        itemCount: max(messageList.length, 1),
        itemBuilder: (context, index) {
          if (messageList.isEmpty) {
            return Container(
              alignment: Alignment.center,
              child: Text("消息很干净哟", style: viewEmptyTextStyle),
            );
          }
          final data = messageList[index];
          return MessageCard(messageData: data, deleteCallback: deleteCallback);
        },
      ),
    );
  }
}
