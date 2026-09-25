import 'dart:convert';

import 'package:bot_toast/bot_toast.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shine/components/user_info_card.dart';
import 'package:shine/services/api.dart';
import 'package:shine/services/dio.dart';

/// 伪造一个只有 payload 有意义的 JWT，供 ApiService.userId 解析
String fakeJwt(Map<String, dynamic> payload) {
  String encode(Map<String, dynamic> map) =>
      base64Url.encode(utf8.encode(jsonEncode(map))).replaceAll('=', '');
  return '${encode({"alg": "none", "typ": "JWT"})}.${encode(payload)}.signature';
}

const String myId = "2410210213";

/// 用拦截器伪造点赞接口，避免测试真的发请求
Interceptor fakeLikeInterceptor({
  required Map<String, dynamic> response,
  required List<Map<String, dynamic>> requests,
}) {
  return InterceptorsWrapper(
    onRequest: (options, handler) {
      if (options.path.startsWith('/like')) {
        requests.add({
          "path": options.path,
          ...Map<String, dynamic>.from(options.data as Map),
        });
        handler.resolve(
          Response(requestOptions: options, statusCode: 201, data: response),
        );
        return;
      }
      handler.next(options);
    },
  );
}

Map<String, dynamic> userInfo({
  String id = "2410230203",
  String username = "张浩",
  int? likeCount,
  bool likedToday = false,
  String userType = "user",
}) {
  return {
    "id": id,
    "username": username,
    "userType": userType,
    "likeCount": likeCount,
    "likedToday": likedToday,
  };
}

Future<void> pumpCard(
  WidgetTester tester, {
  required Map<String, dynamic> info,
  bool noOperation = false,
  GestureTapCallback? onSendMessage,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      builder: BotToastInit(),
      home: Scaffold(
        body: UserInfoCard(
          userInfo: info,
          noOperation: noOperation,
          onSendMessage: onSendMessage,
        ),
      ),
    ),
  );
  await tester.pump();
}

/// 等提示浮层消失，避免测试结束时还有未完成的定时器
Future<void> settleToast(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 2));
  await tester.pump(const Duration(seconds: 2));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<Interceptor> added;

  setUp(() {
    added = [];
    ApiService.setBaseUrl("http://like.test");
    ApiService.setAccessToken(fakeJwt({"id": myId, "userType": "user"}));
  });

  tearDown(() {
    for (final interceptor in added) {
      dio.interceptors.remove(interceptor);
    }
    added.clear();
    ApiService.delAccessToken();
    ApiService.setBaseUrl("");
  });

  group('成员卡片上的获赞数', () {
    testWidgets('用户名旁边显示获赞数', (tester) async {
      await pumpCard(tester, info: userInfo(likeCount: 12));
      expect(find.text("12"), findsOneWidget);
      expect(find.byIcon(Icons.thumb_up_outlined), findsWidgets);
    });

    testWidgets('点赞按键始终存在', (tester) async {
      await pumpCard(tester, info: userInfo(likeCount: 3));
      expect(find.text("点赞 3"), findsOneWidget);
    });

    testWidgets('今天赞过时按键变成已赞', (tester) async {
      await pumpCard(
        tester,
        info: userInfo(likeCount: 3, likedToday: true),
      );
      expect(find.text("已赞 3"), findsOneWidget);
      expect(find.text("点赞 3"), findsNothing);
    });

    testWidgets('数据里没有获赞数时仍然有按键（只是不带数量）', (tester) async {
      await pumpCard(tester, info: userInfo());
      expect(find.text("点赞"), findsOneWidget);
      // 没有数量时不显示 0，避免误导
      expect(find.text("0"), findsNothing);
    });

    testWidgets('只读名单里不显示按键', (tester) async {
      await pumpCard(
        tester,
        info: userInfo(likeCount: 5),
        noOperation: true,
      );
      expect(find.text("点赞 5"), findsNothing);
      expect(find.text("已赞 5"), findsNothing);
      // 只读时仍能看到获赞数
      expect(find.text("5"), findsOneWidget);
    });
  });

  group('点赞交互', () {
    testWidgets('点击点赞后数量加一', (tester) async {
      final requests = <Map<String, dynamic>>[];
      final interceptor = fakeLikeInterceptor(
        response: {
          "targetId": "2410230203",
          "likeCount": 6,
          "alreadyLiked": false,
        },
        requests: requests,
      );
      added.add(interceptor);
      dio.interceptors.add(interceptor);

      await pumpCard(tester, info: userInfo(likeCount: 5));
      await tester.tap(find.text("点赞 5"));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(requests.single["path"], "/like");
      expect(requests.single["targetId"], "2410230203");
      expect(find.text("已赞 6"), findsOneWidget);
      expect(find.text("6"), findsOneWidget);
      await settleToast(tester);
    });

    testWidgets('今天已经赞过时再点不会重复请求', (tester) async {
      final requests = <Map<String, dynamic>>[];
      final interceptor = fakeLikeInterceptor(
        response: {"likeCount": 6, "alreadyLiked": true},
        requests: requests,
      );
      added.add(interceptor);
      dio.interceptors.add(interceptor);

      await pumpCard(
        tester,
        info: userInfo(likeCount: 6, likedToday: true),
      );
      await tester.tap(find.text("已赞 6"));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(requests, isEmpty);
      expect(find.text("已赞 6"), findsOneWidget);
      await settleToast(tester);
    });

    testWidgets('自己的名片不能点赞', (tester) async {
      final requests = <Map<String, dynamic>>[];
      final interceptor = fakeLikeInterceptor(
        response: {"likeCount": 9, "alreadyLiked": false},
        requests: requests,
      );
      added.add(interceptor);
      dio.interceptors.add(interceptor);

      await pumpCard(
        tester,
        info: userInfo(id: myId, username: "我自己", likeCount: 4),
      );
      expect(find.text("点赞 4"), findsOneWidget);
      await tester.tap(find.text("点赞 4"));
      await tester.pump(const Duration(milliseconds: 50));

      expect(requests, isEmpty);
      expect(find.text("点赞 4"), findsOneWidget);
      await settleToast(tester);
    });

    testWidgets('长按撤回今天的赞', (tester) async {
      final requests = <Map<String, dynamic>>[];
      final interceptor = fakeLikeInterceptor(
        response: {"likeCount": 5, "canceled": true},
        requests: requests,
      );
      added.add(interceptor);
      dio.interceptors.add(interceptor);

      await pumpCard(
        tester,
        info: userInfo(likeCount: 6, likedToday: true),
      );
      await tester.longPress(find.text("已赞 6"));
      await tester.pumpAndSettle();
      expect(find.text("撤回点赞"), findsOneWidget);
      await tester.tap(find.text("确定"));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(requests.single["path"], "/like/cancel");
      expect(find.text("点赞 5"), findsOneWidget);
      await settleToast(tester);
    });

    testWidgets('接口不存在时提示要更新服务端', (tester) async {
      final interceptor = InterceptorsWrapper(
        onRequest: (options, handler) {
          handler.reject(
            DioException(
              requestOptions: options,
              type: DioExceptionType.badResponse,
              message: '请求出错(404)',
              response: Response(
                requestOptions: options,
                statusCode: 404,
                data: {"error": "Not Found", "code": "NOT_FOUND"},
              ),
            ),
          );
        },
      );
      added.add(interceptor);
      dio.interceptors.add(interceptor);

      await pumpCard(tester, info: userInfo(likeCount: 2));
      await tester.tap(find.text("点赞 2"));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // 数字不变（失败提示由 ApiLike 负责说清楚，见 api_like_test.dart）
      expect(find.text("点赞 2"), findsOneWidget);
      await settleToast(tester);
    });

    testWidgets('服务端拒绝时保持原样', (tester) async {
      final interceptor = InterceptorsWrapper(
        onRequest: (options, handler) {
          handler.reject(
            DioException(
              requestOptions: options,
              type: DioExceptionType.badResponse,
              message: "不能给自己点赞",
              response: Response(
                requestOptions: options,
                statusCode: 409,
                data: {"error": "不能给自己点赞", "code": "CONFLICT"},
              ),
            ),
          );
        },
      );
      added.add(interceptor);
      dio.interceptors.add(interceptor);

      await pumpCard(tester, info: userInfo(likeCount: 2));
      await tester.tap(find.text("点赞 2"));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // 服务端说明了原因时直接展示出来
      expect(find.text("点赞 2"), findsOneWidget);
      await settleToast(tester);
    });

    testWidgets('点赞不会影响卡片上的其他操作', (tester) async {
      final requests = <Map<String, dynamic>>[];
      final interceptor = fakeLikeInterceptor(
        response: {"likeCount": 2, "alreadyLiked": false},
        requests: requests,
      );
      added.add(interceptor);
      dio.interceptors.add(interceptor);

      var messageTaps = 0;
      await pumpCard(
        tester,
        info: userInfo(likeCount: 1),
        onSendMessage: () => messageTaps++,
      );
      await tester.tap(find.text("发消息"));
      await tester.pump();
      expect(messageTaps, 1);

      await tester.tap(find.text("点赞 1"));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(messageTaps, 1);
      expect(requests.length, 1);
      await settleToast(tester);
    });
  });
}
