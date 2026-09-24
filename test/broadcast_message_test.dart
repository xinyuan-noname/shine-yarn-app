import 'dart:convert';

import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shine/components/send_message_dialog.dart';
import 'package:shine/services/api.dart';
import 'package:shine/storage/group_storage.dart';

/// 构造一个只用于解析的假 JWT(不做签名校验)
String _fakeJwt(Map<String, dynamic> payload) {
  String encode(Map<String, dynamic> map) =>
      base64Url.encode(utf8.encode(jsonEncode(map))).replaceAll('=', '');
  return '${encode({"alg": "none", "typ": "JWT"})}.${encode(payload)}.sig';
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    // 所有学生分组缓存了 2 名成员，避免测试中发起网络请求
    SharedPreferences.setMockInitialValues({
      GroupStorageKey.entire.value: [
        jsonEncode({"id": "2023001", "username": "小李"}),
        jsonEncode({"id": "2023002", "username": "小王"}),
      ],
    });
    ApiService.setBaseUrl("http://127.0.0.1:1");
    ApiService.setAccessToken(
      _fakeJwt({
        "id": "2023001",
        "userType": "user",
        "exp": DateTime.now().add(const Duration(days: 1)).millisecondsSinceEpoch ~/ 1000,
      }),
    );
  });

  group('分组数据', () {
    test('分组名称映射包含全部分组', () {
      expect(groupStorageKeyLabelMap.length, GroupStorageKey.values.length);
      expect(groupStorageKeyLabelMap[GroupStorageKey.entire], "所有学生");
      expect(groupStorageKeyLabelList.length, GroupStorageKey.values.length);
      expect(groupStorageKeyLabelList.first.$1, GroupStorageKey.entire);
    });

    test('从成员列表取出有效学号', () {
      expect(
        GroupStorage.getIdList([
          {"id": "2023001", "username": "小李"},
          {"id": "", "username": "空学号"},
          {"username": "没有学号"},
          {"id": "2023002"},
        ]),
        ["2023001", "2023002"],
      );
      expect(GroupStorage.getIdList([]), isEmpty);
    });

    test('广播分组名称', () {
      const input = BroadcastMessageInput(
        group: GroupStorageKey.male,
        content: "内容",
      );
      expect(input.groupName, "所有男生");
    });
  });

  group('广播弹窗', () {
    Future<void> openDialog(WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          builder: BotToastInit(),
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () {
                  showBroadcastMessageDialog(
                    context: context,
                    message: ValueNotifier(""),
                  );
                },
                child: const Text("广播"),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text("广播"));
      await tester.pumpAndSettle();
    }

    testWidgets('展示分组选择与成员人数', (tester) async {
      await openDialog(tester);

      expect(find.text("发送广播"), findsOneWidget);
      expect(find.text("接收分组"), findsOneWidget);
      expect(find.text("所有学生"), findsOneWidget);
      expect(find.text("该分组共2名成员"), findsOneWidget);
      expect(find.text("请输入广播内容"), findsOneWidget);
    });

    testWidgets('广播内容不能为空', (tester) async {
      await openDialog(tester);

      await tester.tap(find.text("发送"));
      await tester.pumpAndSettle();

      expect(find.text("广播内容不能为空"), findsOneWidget);
      // 弹窗仍然打开
      expect(find.text("发送广播"), findsOneWidget);
    });

    testWidgets('取消后关闭弹窗', (tester) async {
      await openDialog(tester);

      await tester.tap(find.text("取消"));
      await tester.pumpAndSettle();

      expect(find.text("发送广播"), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });
}
