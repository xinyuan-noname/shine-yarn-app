import 'package:flutter/material.dart';
import 'package:shine/components/message_card.dart';
import 'package:shine/storage/remind_storage.dart';
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
        itemCount: messageList.length,
        itemBuilder: (context, index) {
          final data = messageList[index];
          return MessageCard(
            messageData: data,
            deleteCallback: deleteCallback,
          );
        },
      ),
    );
  }
}
