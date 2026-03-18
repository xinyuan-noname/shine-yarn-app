import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:shine/components/avatar.dart';
import 'package:shine/components/line.dart';
import 'package:shine/pages/home_page.dart';
import 'package:shine/storage/message_storage.dart';
import 'package:shine/theme.dart';
import 'package:shine/utils/time.dart';

final List<Color> _levelColor = [
  Colors.grey,
  mainColorPurple,
  darkColorPurple,
  mainColorGreenBlue,
  deepColorBlue,
  mainColorRed,
  deepColorRed,
];

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
    final onDeleteMap = <Type, VoidCallback>{
      RemindMessageStorageData: () async {
        await MessageStorage.removeRemindMessage(messageData.id);
        HomePageRefreshNotifier.refreshMessage();
      },
    };
    final onPressMap = <Type, VoidCallback>{
      RemindMessageStorageData: () async {
        await MessageStorage.addMessageReaded(messageData.id);
        HomePageRefreshNotifier.refreshMessage();
      },
    };
    return Slidable(
      endActionPane: ActionPane(
        extentRatio: 0.25,
        motion: ScrollMotion(),
        children: [
          SlidableAction(
            onPressed: (BuildContext context) {
              final deleteAction =
                  deleteCallback ?? onDeleteMap[messageData.runtimeType];
              if (deleteAction != null) deleteAction();
            },
            icon: Icons.delete,
            backgroundColor: mainColorRed,
            spacing: 0,
            borderRadius: BorderRadius.circular(20),
          ),
        ],
      ),
      child: GestureDetector(
        onLongPress: onLongPress,
        onTap: onPress ?? onPressMap[messageData.runtimeType],
        child: Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          shadowColor:
              _levelColor.elementAtOrNull(messageData.level) ?? Colors.grey,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: whiteLinearGradient,
            ),
            child: Container(
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
                  bottomLine,
                  if (messageData.sentAt is DateTime) _buildTime(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    return Badge(
      textColor: bgColorLight,
      backgroundColor: mainColorRed,
      smallSize: 10,
      isLabelVisible: !messageData.readed,
      child: NetworkAvatar(id: messageData.sourceId),
    );
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
      style: TextStyle(
        fontFamily: 'SmileySans',
        fontSize: 19,
        color: _levelColor.elementAtOrNull(messageData.level) ?? Colors.grey,
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
