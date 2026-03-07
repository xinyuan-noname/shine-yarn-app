import 'package:flutter/material.dart';
import 'package:shine/components/avatar.dart';
import 'package:shine/components/line.dart';
import 'package:shine/storage/message_storage.dart';
import 'package:shine/theme.dart';
import 'package:shine/utils/time.dart';

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
              children: [
                Row(
                  children: [
                    _buildAvatar(),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [_buildUsername(), _buildContent()],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 1),
                bottomLine,
                if (messageData.sentAt is DateTime) _buildTime(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    return NetworkAvatar(id: messageData.sourceId);
  }

  Widget _buildUsername() {
    return Text(
      messageData.sourceUsername,
      style: const TextStyle(fontFamily: 'SmileySans', fontSize: 22),
    );
  }

  Widget _buildContent() {
    return Text(
      messageData.content,
      style: const TextStyle(
        fontFamily: 'SmileySans',
        fontSize: 19,
        color: Colors.grey,
      ),
    );
  }

  Widget _buildTime() {
    final sentAt = messageData.sentAt;
    return Row(
      children: [
        Text(
          "发送于：",
          style: const TextStyle(
            fontFamily: 'SmileySans',
            fontSize: 12,
            color: bgColorLight,
            shadows: [Shadow(color: darkColorPurple, blurRadius: 0.8)],
          ),
          softWrap: true,
        ),
        Text(
          sentAt is DateTime ? getLocalTimeString(sentAt) : "未知时间",
          style: const TextStyle(
            fontFamily: 'SmileySans',
            fontSize: 12,
            color: bgColorLight,
            shadows: [Shadow(color: darkColorPurple, blurRadius: 0.8)],
          ),
          softWrap: true,
        ),
      ],
    );
  }
}
