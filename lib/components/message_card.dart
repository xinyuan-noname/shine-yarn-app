import 'package:flutter/material.dart';
import 'package:shine/storage/remind_storage.dart';
import 'package:shine/theme.dart';

class MessageCard extends StatelessWidget {
  final MessageStorageData messageData;
  final VoidCallback? deleteCallback;
  final GestureLongPressCallback? onLongPress;
  final GestureTapCallback? onPress;
  const MessageCard({
    super.key,
    required this.messageData,
    this.deleteCallback,
    this.onLongPress,
    this.onPress,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: onLongPress,
      onTap: onPress,
      child: Card(
        elevation: 2,
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        shadowColor: mainColorGreenBule60,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: whiteLinearGradient,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [],
            ),
          ),
        ),
      ),
    );
  }
}
