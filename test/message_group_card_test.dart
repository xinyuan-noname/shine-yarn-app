import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shine/components/message_group_card.dart';
import 'package:shine/models/message_group_data.dart';
import 'package:shine/storage/message_storage.dart';

MessageGroupData _anonymousGroup() {
  return MessageGroupData(
    sourceKey: anonymousMessageSourceId,
    sourceId: anonymousMessageSourceId,
    sourceUsername: anonymousMessageUsername,
    anonymous: true,
    messageList: [
      RemindMessageStorageData(
        id: 2,
        sourceId: anonymousMessageSourceId,
        sourceUsername: anonymousMessageUsername,
        content: "匿名消息内容",
        anonymous: true,
        sentAt: DateTime(2026, 1, 1, 10),
      ),
      RemindMessageStorageData(
        id: 1,
        sourceId: anonymousMessageSourceId,
        sourceUsername: anonymousMessageUsername,
        content: "更早的匿名消息",
        anonymous: true,
        readed: true,
        sentAt: DateTime(2026, 1, 1, 9),
      ),
    ],
  );
}

Widget _wrap(Widget child) {
  return MaterialApp(home: Scaffold(body: ListView(children: [child])));
}

void main() {
  testWidgets('分组卡片折叠时只展示最新消息预览', (tester) async {
    final group = _anonymousGroup();
    int readAllCount = 0;
    await tester.pumpWidget(
      _wrap(
        MessageGroupCard(
          group: group,
          onReadAll: () async {
            readAllCount++;
          },
          onClearAll: () async {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(anonymousMessageUsername), findsOneWidget);
    expect(find.text("匿名"), findsOneWidget);
    expect(find.text("共2条"), findsOneWidget);
    // 折叠状态下展示最新一条消息的预览
    expect(find.text("匿名消息内容"), findsOneWidget);
    // 更早的消息与操作按钮在展开后才出现
    expect(find.text("更早的匿名消息"), findsNothing);
    expect(find.text("清空"), findsNothing);
    expect(find.text("发消息"), findsNothing);
    expect(readAllCount, 0);
  });

  testWidgets('点击分组头部展开全部消息并标记已读', (tester) async {
    final group = _anonymousGroup();
    int readAllCount = 0;
    await tester.pumpWidget(
      _wrap(
        MessageGroupCard(
          group: group,
          onReadAll: () async {
            readAllCount++;
          },
          onClearAll: () async {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text(anonymousMessageUsername));
    await tester.pumpAndSettle();

    // 两条消息都以精简模式展示，且提供清空操作；匿名分组不提供回复入口
    expect(find.text("匿名消息内容"), findsNWidgets(2));
    expect(find.text("更早的匿名消息"), findsOneWidget);
    expect(find.text("清空"), findsOneWidget);
    expect(find.text("发消息"), findsNothing);
    expect(readAllCount, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('可回复的分组展示发消息入口', (tester) async {
    final group = MessageGroupData(
      sourceKey: "2023001",
      sourceId: "2023001",
      sourceUsername: "小王",
      messageList: [
        RemindMessageStorageData(
          id: 3,
          sourceId: "2023001",
          sourceUsername: "小王",
          content: "作业交一下",
          sentAt: DateTime(2026, 1, 1, 10),
        ),
      ],
    );
    int sendCount = 0;
    await tester.pumpWidget(
      _wrap(
        MessageGroupCard(
          group: group,
          initiallyExpanded: true,
          onSendMessage: () {
            sendCount++;
          },
          onClearAll: () async {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text("发消息"), findsOneWidget);
    await tester.tap(find.text("发消息"));
    await tester.pumpAndSettle();
    expect(sendCount, 1);
    expect(tester.takeException(), isNull);
  });
}
