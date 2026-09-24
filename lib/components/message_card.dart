import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:shine/components/avatar.dart';
import 'package:shine/components/line.dart';
import 'package:shine/pages/home_page.dart';
import 'package:shine/storage/message_storage.dart';
import 'package:shine/theme.dart';
import 'package:shine/utils/time_utils.dart';

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
  final bool hasController;

  /// 精简模式：不展示头像与昵称(按人物分类时，同一分组内共用分组头部信息)
  final bool compact;
  const MessageCard({
    super.key,
    required this.messageData,
    this.deleteCallback,
    this.onLongPress,
    this.onPress,
    this.hasController = true,
    this.compact = false,
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
        if (messageData.content.contains("待办事项")) {
          HomePageRefreshNotifier.flagViewGoto(0);
          HomePageRefreshNotifier.viewGoto(3);
        }
      },
    };
    return Slidable(
      endActionPane: hasController
          ? ActionPane(
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
            )
          : null,
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
                  if (compact)
                    _buildCompactRow()
                  else
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
      child: messageData.anonymous
          ? const AnonymousAvatar()
          : NetworkAvatar(id: messageData.sourceId),
    );
  }

  Widget _buildUsername() {
    final username = Text(
      messageData.displayUsername,
      style: const TextStyle(fontFamily: 'SmileySans', fontSize: 20),
    );
    if (!messageData.anonymous) return username;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        username,
        const SizedBox(width: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0.5),
          decoration: BoxDecoration(
            color: mainColorGreenBlue60,
            borderRadius: BorderRadius.all(Radius.circular(5)),
          ),
          child: const Text(
            "匿名",
            style: TextStyle(
              fontFamily: 'SmileySans',
              fontSize: 12,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContent() {
    return Text(
      messageData.content,
      style: TextStyle(
        fontFamily: 'SmileySans',
        fontSize: 14,
        color: _levelColor.elementAtOrNull(messageData.level) ?? Colors.grey,
      ),
      maxLines: 10,
    );
  }

  /// 精简模式下的内容行，未读时左侧显示小红点
  Widget _buildCompactRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!messageData.readed)
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(top: 6, right: 6),
            decoration: const BoxDecoration(
              color: mainColorRed,
              shape: BoxShape.circle,
            ),
          ),
        Expanded(child: _buildContent()),
      ],
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
