import 'dart:convert';

import 'package:bot_toast/bot_toast.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shine/components/like_chip.dart';
import 'package:shine/services/api.dart';
import 'package:shine/services/dio.dart';

/// 伪造一个只有 payload 有意义的 JWT，供 ApiService.userId 解析
String fakeJwt(Map<String, dynamic> payload) {
  String encode(Map<String, dynamic> map) =>
      base64Url.encode(utf8.encode(jsonEncode(map))).replaceAll('=', '');
  return '${encode({"alg": "none", "typ": "JWT"})}.${encode(payload)}.signature';
}

const String myId = "2410210213";

/// 用拦截器伪造 /like 接口，避免测试真的发请求
Interceptor fakeLikeInterceptor({
  required Map<String, dynamic> response,
  required List<Map<String, dynamic>> requests,
}) {
  return InterceptorsWrapper(
    onRequest: (options, handler) {
      if (options.path == '/like') {
        requests.add(Map<String, dynamic>.from(options.data as Map));
        handler.resolve(
          Response(
            requestOptions: options,
            statusCode: 201,
            data: response,
          ),
        );
        return;
      }
      handler.next(options);
    },
  );
}

Future<void> pumpChip(
  WidgetTester tester, {
  required String userId,
  int? likeCount,
  bool likedToday = false,
  bool interactive = true,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      builder: BotToastInit(),
      home: Scaffold(
        body: LikeChip(
          userId: userId,
          likeCount: likeCount,
          likedToday: likedToday,
          interactive: interactive,
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
    // 让 ApiService.prepared 为 true，否则请求会被本地拦下
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

  group('获赞数展示', () {
    testWidgets('展示服务端返回的获赞数', (tester) async {
      await pumpChip(tester, userId: "2410210213", likeCount: 12);
      expect(find.text("12"), findsOneWidget);
      expect(find.byIcon(Icons.thumb_up_outlined), findsOneWidget);
      expect(find.byIcon(Icons.thumb_up), findsNothing);
    });

    testWidgets('没有获赞数时整个标记不展示', (tester) async {
      await pumpChip(tester, userId: "2410210213");
      expect(find.byType(Icon), findsNothing);
      expect(find.text("0"), findsNothing);
    });

    testWidgets('今天赞过时显示实心图标', (tester) async {
      await pumpChip(
        tester,
        userId: "2410210213",
        likeCount: 3,
        likedToday: true,
      );
      expect(find.byIcon(Icons.thumb_up), findsOneWidget);
      expect(find.byIcon(Icons.thumb_up_outlined), findsNothing);
    });

    testWidgets('只读场景不可点按', (tester) async {
      final requests = <Map<String, dynamic>>[];
      final interceptor = fakeLikeInterceptor(
        response: {"targetId": "2410230203", "likeCount": 4, "alreadyLiked": false},
        requests: requests,
      );
      added.add(interceptor);
      dio.interceptors.add(interceptor);

      await pumpChip(
        tester,
        userId: "2410230203",
        likeCount: 3,
        interactive: false,
      );
      expect(find.text("3"), findsOneWidget);
      await tester.tap(find.byType(LikeChip));
      await tester.pump(const Duration(milliseconds: 50));
      // 不可点时不会发出请求，数字也不会变
      expect(requests, isEmpty);
      expect(find.text("3"), findsOneWidget);
      await settleToast(tester);
    });
  });

  group('点赞交互', () {
    testWidgets('点击后获赞数增加并变成已赞', (tester) async {
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

      await pumpChip(tester, userId: "2410230203", likeCount: 5);
      expect(find.text("5"), findsOneWidget);

      await tester.tap(find.byType(LikeChip));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(requests.length, 1);
      expect(requests.single["targetId"], "2410230203");
      expect(find.text("6"), findsOneWidget);
      expect(find.byIcon(Icons.thumb_up), findsOneWidget);
      await settleToast(tester);
    });

    testWidgets('今天已经赞过时再点不会重复请求', (tester) async {
      final requests = <Map<String, dynamic>>[];
      final interceptor = fakeLikeInterceptor(
        response: {
          "targetId": "2410230203",
          "likeCount": 6,
          "alreadyLiked": true,
        },
        requests: requests,
      );
      added.add(interceptor);
      dio.interceptors.add(interceptor);

      await pumpChip(
        tester,
        userId: "2410230203",
        likeCount: 6,
        likedToday: true,
      );
      await tester.tap(find.byType(LikeChip));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // 已经赞过就直接提示，不再打服务端
      expect(requests, isEmpty);
      expect(find.text("6"), findsOneWidget);
      await settleToast(tester);
    });

    testWidgets('不能给自己点赞', (tester) async {
      final requests = <Map<String, dynamic>>[];
      final interceptor = fakeLikeInterceptor(
        response: {"targetId": myId, "likeCount": 1, "alreadyLiked": false},
        requests: requests,
      );
      added.add(interceptor);
      dio.interceptors.add(interceptor);

      await pumpChip(tester, userId: myId, likeCount: 4);
      expect(find.text("4"), findsOneWidget);
      await tester.tap(find.byType(LikeChip));
      await tester.pump();

      expect(requests, isEmpty);
      expect(find.text("4"), findsOneWidget);
      await settleToast(tester);
    });

    testWidgets('长按可以撤回今天的赞', (tester) async {
      final requests = <Map<String, dynamic>>[];
      final interceptor = InterceptorsWrapper(
        onRequest: (options, handler) {
          requests.add({"path": options.path, ...Map<String, dynamic>.from(options.data as Map)});
          handler.resolve(
            Response(
              requestOptions: options,
              statusCode: 200,
              data: {
                "targetId": "2410230203",
                "likeCount": 5,
                "canceled": true,
              },
            ),
          );
        },
      );
      added.add(interceptor);
      dio.interceptors.add(interceptor);

      await pumpChip(
        tester,
        userId: "2410230203",
        likeCount: 6,
        likedToday: true,
      );
      expect(find.byIcon(Icons.thumb_up), findsOneWidget);

      await tester.longPress(find.byType(LikeChip));
      await tester.pumpAndSettle();
      // 弹窗里确认撤回
      expect(find.text("撤回点赞"), findsOneWidget);
      await tester.tap(find.text("确定"));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(requests.single["path"], "/like/cancel");
      expect(find.text("5"), findsOneWidget);
      expect(find.byIcon(Icons.thumb_up_outlined), findsOneWidget);
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

      await pumpChip(tester, userId: "2410230203", likeCount: 2);
      await tester.tap(find.byType(LikeChip));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text("2"), findsOneWidget);
      expect(find.byIcon(Icons.thumb_up_outlined), findsOneWidget);
      await settleToast(tester);
    });
  });
}
