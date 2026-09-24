import 'package:shine/storage/message_storage.dart';

/// 消息按人物分类后的分组数据
class MessageGroupData {
  /// 分组键，通常为对方学号，匿名消息为 [anonymousMessageSourceId]
  final String sourceKey;
  final String sourceId;
  final String sourceUsername;
  final bool anonymous;

  /// 组内消息，按时间倒序(最新的在最前)
  final List<MessageStorageData> messageList;

  const MessageGroupData({
    required this.sourceKey,
    required this.sourceId,
    required this.sourceUsername,
    required this.messageList,
    this.anonymous = false,
  });

  int get messageCount => messageList.length;

  int get unreadCount => messageList.where((message) => !message.readed).length;

  bool get hasUnread => unreadCount > 0;

  /// 组内最新的一条消息
  MessageStorageData? get latestMessage =>
      messageList.isEmpty ? null : messageList.first;

  List<int> get messageIdList =>
      messageList.map((message) => message.id).toList();

  /// 界面展示用的昵称
  String get displayUsername =>
      anonymous ? anonymousMessageUsername : sourceUsername;

  /// 是否可以给该分组的主人发送消息(匿名消息没有可回复的对象)
  bool get canReply => !anonymous && sourceId.isNotEmpty;

  /// 按人物对消息列表进行分组，分组之间按最新消息时间倒序排列
  static List<MessageGroupData> fromMessageList(
    List<MessageStorageData> messageList,
  ) {
    final Map<String, List<MessageStorageData>> groupMap = {};
    for (final message in messageList) {
      groupMap.putIfAbsent(message.groupKey, () => []).add(message);
    }
    final groups = <MessageGroupData>[];
    groupMap.forEach((key, messages) {
      messages.sort((a, b) => _compareMessage(b, a));
      final latest = messages.first;
      groups.add(
        MessageGroupData(
          sourceKey: key,
          sourceId: latest.sourceId,
          sourceUsername: latest.sourceUsername,
          anonymous: latest.anonymous,
          messageList: messages,
        ),
      );
    });
    groups.sort((a, b) {
      final latestA = a.latestMessage;
      final latestB = b.latestMessage;
      if (latestA == null || latestB == null) return 0;
      return _compareMessage(latestB, latestA);
    });
    return groups;
  }

  static int _compareMessage(MessageStorageData a, MessageStorageData b) {
    final aTime = a.sentAt ?? DateTime.fromMillisecondsSinceEpoch(0);
    final bTime = b.sentAt ?? DateTime.fromMillisecondsSinceEpoch(0);
    final result = aTime.compareTo(bTime);
    if (result != 0) return result;
    return a.id.compareTo(b.id);
  }
}
