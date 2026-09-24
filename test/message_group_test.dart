import 'package:flutter_test/flutter_test.dart';
import 'package:shine/models/message_group_data.dart';
import 'package:shine/storage/message_storage.dart';

RemindMessageStorageData _message({
  required int id,
  required String sourceId,
  required String sourceUsername,
  required String content,
  required DateTime sentAt,
  bool anonymous = false,
  bool readed = false,
}) {
  return RemindMessageStorageData(
    id: id,
    sourceId: sourceId,
    sourceUsername: sourceUsername,
    content: content,
    sentAt: sentAt,
    anonymous: anonymous,
    readed: readed,
  );
}

void main() {
  group('MessageGroupData.fromMessageList', () {
    test('按照人物分类，组间与组内均按最新消息倒序', () {
      final groupList = MessageGroupData.fromMessageList([
        _message(
          id: 3,
          sourceId: "B",
          sourceUsername: "小王",
          content: "b2",
          sentAt: DateTime(2026, 1, 1, 10),
        ),
        _message(
          id: 2,
          sourceId: "A",
          sourceUsername: "小李",
          content: "a1",
          sentAt: DateTime(2026, 1, 1, 9),
        ),
        _message(
          id: 1,
          sourceId: "B",
          sourceUsername: "小王",
          content: "b1",
          sentAt: DateTime(2026, 1, 1, 8),
        ),
      ]);

      expect(groupList.length, 2);
      // 最新消息来自小王，因此小王的分组排在前面
      expect(groupList.first.sourceKey, "B");
      expect(groupList.first.displayUsername, "小王");
      expect(groupList.first.messageCount, 2);
      expect(groupList.first.latestMessage?.content, "b2");
      expect(groupList.first.messageIdList, [3, 1]);
      expect(groupList.first.canReply, true);
      expect(groupList.last.sourceId, "A");
      expect(groupList.last.messageCount, 1);
    });

    test('匿名消息使用 fffffffff 作为来源id并以随机昵称分组', () {
      final groupList = MessageGroupData.fromMessageList([
        _message(
          id: 6,
          sourceId: anonymousMessageSourceId,
          sourceUsername: "安静的海豚",
          content: "匿名消息3",
          sentAt: DateTime(2026, 1, 2, 13),
          anonymous: true,
        ),
        _message(
          id: 5,
          sourceId: anonymousMessageSourceId,
          sourceUsername: "安静的海豚",
          content: "匿名消息2",
          sentAt: DateTime(2026, 1, 2, 12),
          anonymous: true,
        ),
        _message(
          id: 4,
          sourceId: "A",
          sourceUsername: "小李",
          content: "普通消息",
          sentAt: DateTime(2026, 1, 2, 11),
        ),
        _message(
          id: 3,
          sourceId: anonymousMessageSourceId,
          sourceUsername: "迷路的小鹿",
          content: "匿名消息1",
          sentAt: DateTime(2026, 1, 2, 10),
          anonymous: true,
        ),
      ]);

      // 两个不同的随机昵称视为两个不同的分组
      expect(groupList.length, 3);
      final anonymousGroups = groupList.where((g) => g.anonymous).toList();
      expect(anonymousGroups.length, 2);
      final sameNameGroup = anonymousGroups.firstWhere(
        (g) => g.sourceUsername == "安静的海豚",
      );
      expect(sameNameGroup.messageCount, 2);
      expect(sameNameGroup.sourceId, anonymousMessageSourceId);
      expect(sameNameGroup.displayUsername, "安静的海豚");
      expect(sameNameGroup.messageIdList, [6, 5]);
      expect(sameNameGroup.sourceKey, "$anonymousMessageSourceId:安静的海豚");
      // 匿名消息不可回复
      expect(sameNameGroup.canReply, false);
      expect(
        anonymousGroups
            .firstWhere((g) => g.sourceUsername == "迷路的小鹿")
            .messageCount,
        1,
      );
    });

    test('未读数量与分组键回退逻辑', () {
      final groupList = MessageGroupData.fromMessageList([
        _message(
          id: 7,
          sourceId: "",
          sourceUsername: "神秘人",
          content: "第三条",
          sentAt: DateTime(2026, 1, 3, 10),
        ),
        _message(
          id: 6,
          sourceId: "",
          sourceUsername: "神秘人",
          content: "第二条",
          sentAt: DateTime(2026, 1, 3, 9),
          readed: true,
        ),
      ]);

      expect(groupList.length, 1);
      expect(groupList.first.sourceKey, "username:神秘人");
      expect(groupList.first.unreadCount, 1);
      expect(groupList.first.hasUnread, true);
      expect(groupList.first.canReply, false);
    });

    test('昵称为空时展示未知用户', () {
      final groupList = MessageGroupData.fromMessageList([
        _message(
          id: 8,
          sourceId: anonymousMessageSourceId,
          sourceUsername: "",
          content: "没有昵称的匿名消息",
          sentAt: DateTime(2026, 1, 4, 10),
          anonymous: true,
        ),
      ]);

      expect(groupList.length, 1);
      expect(groupList.first.displayUsername, "未知用户");
      expect(groupList.first.sourceKey, anonymousMessageSourceId);
    });

    test('空消息列表返回空分组', () {
      expect(MessageGroupData.fromMessageList([]), isEmpty);
    });
  });
}
