import 'package:carousel_slider/carousel_slider.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:shine/components/dialog.dart';
import 'package:shine/components/floating_action_button_widget.dart';
import 'package:shine/components/message_card.dart';
import 'package:shine/components/message_group_card.dart';
import 'package:shine/components/notice_card.dart';
import 'package:shine/components/send_message_dialog.dart';
import 'package:shine/models/message_group_data.dart';
import 'package:shine/pages/home_page.dart';
import 'package:shine/storage/message_storage.dart';
import 'package:shine/storage/task_storage.dart';
import 'package:shine/theme.dart';
import 'package:shine/utils/upload_utils.dart';

class MessageView extends StatefulWidget {
  final RefreshCallback onRefresh;
  final List<MessageStorageData> messageList;
  final List<TaskStorageData> taskNoticeList;
  final List<UploadData> uploadDataList;
  final VoidCallback? deleteCallback;

  /// 发送消息时展示进度用的消息通知器
  final ValueNotifier<String> message;
  const MessageView({
    super.key,
    this.deleteCallback,
    required this.onRefresh,
    required this.messageList,
    required this.taskNoticeList,
    required this.uploadDataList,
    required this.message,
  });

  @override
  State<MessageView> createState() => _MessageViewState();
}

class _MessageViewState extends State<MessageView> {
  /// 是否按人物分类展示消息
  bool _groupByUser = true;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Column(
          children: [
            _buildTypeSwitcher(),
            if (widget.taskNoticeList.isNotEmpty)
              CarouselSlider(
                items: widget.taskNoticeList
                    .map(
                      (taskData) => NoticeCard(
                        taskData: taskData,
                        uploadData: widget.uploadDataList.firstWhereOrNull(
                          (e) => e.taskId == taskData.id,
                        ),
                      ),
                    )
                    .toList(),
                options: CarouselOptions(
                  height: 160,
                  enlargeFactor: 0.15,
                  enlargeCenterPage: true,
                  autoPlay: true,
                  autoPlayInterval: Duration(seconds: 5),
                  autoPlayAnimationDuration: Duration(milliseconds: 800),
                  autoPlayCurve: Curves.fastOutSlowIn,
                  scrollDirection: Axis.horizontal,
                  enableInfiniteScroll: false,
                ),
              ),
            Expanded(
              child: RefreshIndicator(
                color: mainColorPurple90,
                backgroundColor: bgColorLight,
                onRefresh: widget.onRefresh,
                child: _buildMessageList(),
              ),
            ),
          ],
        ),
        Positioned(
          right: 0,
          bottom: 10,
          child: FloatingActionButtonWidget(
            onTap: () async {
              if (widget.messageList.isEmpty) return;
              for (final messageData in widget.messageList) {
                await MessageStorage.removeRemindMessage(messageData.id);
              }
              HomePageRefreshNotifier.refreshMessage();
            },
            child: Container(
              alignment: Alignment.center,
              padding: EdgeInsets.all(8),
              child: const Text(
                "清",
                style: TextStyle(
                  color: mainColorPurple,
                  fontFamily: "SmileySans",
                  fontSize: 36,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// 按人物分类 / 按时间排序的切换栏
  Widget _buildTypeSwitcher() {
    final groupCount = _groupByUser && widget.messageList.isNotEmpty
        ? MessageGroupData.fromMessageList(widget.messageList).length
        : 0;
    return Padding(
      padding: const EdgeInsets.only(top: 8, left: 16, right: 16),
      child: Row(
        children: [
          _buildTypeItem(
            label: "按人物",
            icon: Icons.people_outline,
            selected: _groupByUser,
            onTap: () {
              if (_groupByUser) return;
              setState(() {
                _groupByUser = true;
              });
            },
          ),
          const SizedBox(width: 8),
          _buildTypeItem(
            label: "按时间",
            icon: Icons.schedule,
            selected: !_groupByUser,
            onTap: () {
              if (!_groupByUser) return;
              setState(() {
                _groupByUser = false;
              });
            },
          ),
          const Spacer(),
          if (groupCount > 0)
            Text(
              "共$groupCount人",
              style: const TextStyle(
                fontFamily: 'SmileySans',
                fontSize: 13,
                color: Colors.grey,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTypeItem({
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: selected ? purpleLinearGradient : null,
          color: selected ? null : bgColorLight80,
          border: Border.all(color: mainColorPurple60),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: selected ? bgColorLight : deepColorPurple,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'SmileySans',
                fontSize: 15,
                color: selected ? bgColorLight : deepColorPurple,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageList() {
    if (widget.messageList.isEmpty) {
      return ListView(
        padding: viewPadding,
        children: [
          if (widget.taskNoticeList.isEmpty)
            Container(
              height: 200,
              alignment: Alignment.center,
              child: Text("消息很干净哟", style: viewEmptyTextStyle),
            ),
        ],
      );
    }
    if (_groupByUser) return _buildGroupedList();
    return _buildTimelineList();
  }

  /// 按人物分类的消息列表
  Widget _buildGroupedList() {
    final groupList = MessageGroupData.fromMessageList(widget.messageList);
    return ListView.builder(
      padding: viewPadding,
      itemCount: groupList.length,
      itemBuilder: (context, index) {
        final group = groupList[index];
        return MessageGroupCard(
          key: ValueKey(group.sourceKey),
          group: group,
          onReadAll: () => _markGroupReaded(group),
          onSendMessage: group.canReply ? () => _sendMessageTo(group) : null,
          onClearAll: () => _clearGroup(group),
          deleteCallback: widget.deleteCallback,
        );
      },
    );
  }

  /// 按时间排序的消息列表
  Widget _buildTimelineList() {
    return ListView.builder(
      padding: viewPadding,
      itemCount: widget.messageList.length,
      itemBuilder: (context, index) {
        final data = widget.messageList[index];
        return MessageCard(
          messageData: data,
          deleteCallback: widget.deleteCallback,
        );
      },
    );
  }

  /// 展开分组时将该成员的消息全部标记为已读
  Future<void> _markGroupReaded(MessageGroupData group) async {
    if (!group.hasUnread) return;
    await MessageStorage.addMessagesReaded(group.messageIdList);
    HomePageRefreshNotifier.refreshMessage();
  }

  /// 给该分组的成员发送消息(可匿名)
  Future<void> _sendMessageTo(MessageGroupData group) async {
    if (!mounted) return;
    await showSendMessageDialog(
      context: context,
      targetId: group.sourceId,
      targetUsername: group.sourceUsername,
      message: widget.message,
      title: "给${group.displayUsername}发送消息",
    );
  }

  /// 清空该成员的全部消息
  Future<void> _clearGroup(MessageGroupData group) async {
    final confirmed = await showConfirmDialog(
      context: context,
      title: "清空消息",
      content:
          "确定要清空与「${group.displayUsername}」的${group.messageCount}条消息记录吗？",
      confirmText: "清空",
    );
    if (!confirmed) return;
    await MessageStorage.removeRemindMessages(group.messageIdList);
    HomePageRefreshNotifier.refreshMessage();
  }
}
