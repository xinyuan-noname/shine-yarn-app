import 'package:flutter/material.dart';
import 'package:shine/storage/remind_storage.dart';

class MessageCard extends StatelessWidget {
  final MessageStorageData messageData;
  final VoidCallback? deleteCallback;
  const MessageCard({
    super.key,
    required this.messageData,
    this.deleteCallback,
  });

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
