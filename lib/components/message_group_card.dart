import 'package:flutter/material.dart';
import 'package:shine/components/avatar.dart';
import 'package:shine/components/line.dart';
import 'package:shine/components/message_card.dart';
import 'package:shine/models/message_group_data.dart';
import 'package:shine/theme.dart';
import 'package:shine/utils/time_utils.dart';

/// 消息按人物分类后的分组卡片，点击头部展开该成员的全部消息
class MessageGroupCard extends StatefulWidget {
  final MessageGroupData group;
  final bool initiallyExpanded;

  /// 展开分组时调用，用于把该成员的消息标记为已读
  final Future<void> Function()? onReadAll;

  /// 给该成员发送消息
  final VoidCallback? onSendMessage;

  /// 清空该成员的全部消息
  final Future<void> Function()? onClearAll;

  /// 单条消息的删除回调
  final VoidCallback? deleteCallback;
  const MessageGroupCard({
    super.key,
    required this.group,
    this.initiallyExpanded = false,
    this.onReadAll,
    this.onSendMessage,
    this.onClearAll,
    this.deleteCallback,
  });

  @override
  State<MessageGroupCard> createState() => _MessageGroupCardState();
}

class _MessageGroupCardState extends State<MessageGroupCard> {
  late bool _expanded;

  @override
  void initState() {
    super.initState();
    _expanded = widget.initiallyExpanded;
    if (_expanded) widget.onReadAll?.call();
  }

  void _toggleExpanded() {
    setState(() {
      _expanded = !_expanded;
    });
    if (_expanded) widget.onReadAll?.call();
  }

  @override
  Widget build(BuildContext context) {
    final group = widget.group;
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      shadowColor: group.hasUnread ? mainColorRed : mainColorPurple,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: whiteLinearGradient,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _toggleExpanded,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                child: _buildHeader(),
              ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              alignment: Alignment.topCenter,
              child: _expanded ? _buildContent() : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final group = widget.group;
    final latest = group.latestMessage;
    return Row(
      children: [
        Badge.count(
          count: group.unreadCount,
          isLabelVisible: group.hasUnread,
          backgroundColor: mainColorRed,
          textColor: bgColorLight,
          child: group.anonymous
              ? const AnonymousAvatar(radius: 24)
              : NetworkAvatar(id: group.sourceId, radius: 24),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: _buildUsername()),
                  if (group.messageCount > 1) ...[
                    const SizedBox(width: 6),
                    Text(
                      "共${group.messageCount}条",
                      style: const TextStyle(
                        fontFamily: 'SmileySans',
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                  const SizedBox(width: 6),
                  if (latest?.sentAt is DateTime)
                    Text(
                      getLocalTimeString(latest!.sentAt!),
                      style: const TextStyle(
                        fontFamily: 'SmileySans',
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                latest?.content ?? "",
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'SmileySans',
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 4),
        Icon(
          _expanded ? Icons.expand_less : Icons.expand_more,
          color: mainColorPurple,
        ),
      ],
    );
  }

  Widget _buildUsername() {
    final group = widget.group;
    final username = Text(
      group.displayUsername.isEmpty ? "未知用户" : group.displayUsername,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(fontFamily: 'SmileySans', fontSize: 20),
    );
    if (!group.anonymous) return username;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(child: username),
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
    final group = widget.group;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        bottomLine,
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
          child: Column(
            children: group.messageList
                .map(
                  (messageData) => MessageCard(
                    messageData: messageData,
                    compact: true,
                    deleteCallback: widget.deleteCallback,
                  ),
                )
                .toList(),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 6, bottom: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (widget.onSendMessage != null)
                _buildActionButton(
                  icon: Icons.message_outlined,
                  label: "发消息",
                  onTap: widget.onSendMessage,
                ),
              if (widget.onClearAll != null)
                _buildActionButton(
                  icon: Icons.clear_all,
                  label: "清空",
                  color: mainColorRed,
                  onTap: () {
                    widget.onClearAll?.call();
                  },
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback? onTap,
    Color color = deepColorBlue,
  }) {
    return TextButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16, color: color),
      label: Text(label),
      style: TextButton.styleFrom(
        foregroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        minimumSize: const Size(0, 32),
        textStyle: const TextStyle(fontFamily: 'SmileySans', fontSize: 14),
      ),
    );
  }
}
