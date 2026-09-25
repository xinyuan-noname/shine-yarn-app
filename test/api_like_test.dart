import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shine/services/api.dart';
import 'package:shine/services/api_like.dart';
import 'package:shine/services/dio.dart';

/// 让点赞接口返回指定的错误，用来验证失败原因是否说清楚了
Interceptor errorInterceptor({
  int? statusCode,
  Object? data,
  DioExceptionType type = DioExceptionType.badResponse,
  String? message,
}) {
  return InterceptorsWrapper(
    onRequest: (options, handler) {
      handler.reject(
        DioException(
          requestOptions: options,
          type: type,
          message: message ?? '请求出错',
          response: statusCode == null
              ? null
              : Response(
                  requestOptions: options,
                  statusCode: statusCode,
                  data: data,
                ),
        ),
      );
    },
  );
}

Interceptor successInterceptor(Object data) {
  return InterceptorsWrapper(
    onRequest: (options, handler) {
      handler.resolve(
        Response(requestOptions: options, statusCode: 201, data: data),
      );
    },
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<Interceptor> added;

  setUp(() {
    added = [];
    ApiService.setBaseUrl("http://like.test");
    ApiService.setAccessToken("token");
  });

  tearDown(() {
    for (final interceptor in added) {
      dio.interceptors.remove(interceptor);
    }
    added.clear();
    ApiService.delAccessToken();
    ApiService.setBaseUrl("");
  });

  void use(Interceptor interceptor) {
    added.add(interceptor);
    dio.interceptors.add(interceptor);
  }

  group('点赞接口失败原因', () {
    test('成功时返回服务端数据', () async {
      use(successInterceptor({
        "targetId": "2410230203",
        "likeCount": 3,
        "alreadyLiked": false,
      }));
      final result = await ApiLike.likeUser("2410230203");
      expect(result, isA<Map>());
      expect(result["likeCount"], 3);
    });

    test('接口不存在(404)时提示更新并重启服务端', () async {
      use(errorInterceptor(statusCode: 404, data: {"error": "Not Found"}));
      final result = await ApiLike.likeUser("2410230203");
      expect(result, isA<String>());
      expect(result, contains("404"));
      expect(result, contains("重启服务端"));
    });

    test('服务端给出原因时原样展示', () async {
      use(errorInterceptor(
        statusCode: 409,
        data: {"error": "不能给自己点赞", "code": "CONFLICT"},
      ));
      final result = await ApiLike.likeUser("2410210213");
      expect(result, contains("不能给自己点赞"));
    });

    test('参数不合法(400)时展示服务端说明', () async {
      use(errorInterceptor(
        statusCode: 400,
        data: {"error": "Invalid target id", "code": "VALIDATION_ERROR"},
      ));
      final result = await ApiLike.likeUser("abc");
      expect(result, contains("Invalid target id"));
    });

    test('服务端没给说明时至少带上状态码', () async {
      use(errorInterceptor(statusCode: 403, data: "forbidden"));
      final result = await ApiLike.likeUser("2410230203");
      expect(result, contains("403"));
    });

    test('网络不通时不会说成接口出错', () async {
      use(errorInterceptor(
        type: DioExceptionType.connectionError,
        message: "网络连接出错",
      ));
      final result = await ApiLike.likeUser("2410230203");
      expect(result, isA<String>());
      expect(result, contains("点赞失败"));
      expect(result, isNot(contains("404")));
    });

    test('撤回失败时同样说明原因', () async {
      use(errorInterceptor(statusCode: 404, data: {"error": "Not Found"}));
      final result = await ApiLike.cancelLike("2410230203");
      expect(result, isA<String>());
      expect(result, contains("取消失败"));
      expect(result, contains("404"));
    });
  });
}
