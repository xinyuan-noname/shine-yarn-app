import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:shine/components/toast.dart';
import 'package:shine/config/app_config.dart';
import 'package:shine/services/dio.dart';
import 'package:shine/services/ws.dart';
import 'package:shine/utils/device_info.dart';
import 'package:shine/utils/routes_utils.dart';
import 'package:shine/worker/worker.dart';

class ApiService {
  static String _accessToken = '';
  static bool _offlineMode = false;
  static final _errorInterceptor = InterceptorsWrapper(
    onError: (DioException err, handler) {
      final res = err.response;
      final code = res?.statusCode;
      final resBody = res?.data;
      if (code == 401) {
        if (resBody is Map) {
          if (resBody["code"] != null) {
            switch (resBody["code"]) {
              case "INVALID_ACCESS_TOKEN":
                err = DioException(
                  requestOptions: err.requestOptions,
                  message: '访问令牌出错',
                  type: DioExceptionType.badCertificate,
                );
                Worker.scheduleRefreshNow();
                break;
              case "INVALID_PASSWORD":
                err = DioException(
                  requestOptions: err.requestOptions,
                  message: '密码出错',
                  type: DioExceptionType.badCertificate,
                );
                break;
              case "INVALID_REFRESH_TOKEN":
                err = DioException(
                  requestOptions: err.requestOptions,
                  message: "登陆身份出错",
                  type: DioExceptionType.badCertificate,
                );
                delAccessToken();
                Worker.dispose();
                showToast(msg: "身份认证过期, 请重新登录").then((_) async {
                  await goToLoginGlobally();
                });
            }
          }
        } else {
          err = DioException(
            requestOptions: err.requestOptions,
            message: '身份验证失效',
            type: DioExceptionType.badCertificate,
          );
        }
      } else if (err.type == DioExceptionType.connectionError) {
        err = DioException(
          requestOptions: err.requestOptions,
          message: '网络连接出错',
          type: DioExceptionType.connectionError,
        );
      } else if (code == 429) {
        err = DioException(
          requestOptions: err.requestOptions,
          message: '请求次数太多咯',
          type: DioExceptionType.badResponse,
        );
      } else if (code != null && code >= 500) {
        if (code == 530) {
          err = DioException(
            requestOptions: err.requestOptions,
            message: '服务器网络波动',
            type: DioExceptionType.connectionError,
          );
        } else {
          err = DioException(
            requestOptions: err.requestOptions,
            message: '服务器开小差了哟',
            type: DioExceptionType.connectionError,
          );
        }
        Worker.scheduleUrlNow();
      } else {
        err = DioException(
          requestOptions: err.requestOptions,
          message: '请求出错',
          type: DioExceptionType.unknown,
        );
      }
      handler.next(err);
    },
  );

  static getBaseUrl() async {
    if (AppConfig.stableGithubOrProxy.isNotEmpty) {
      try {
        final response = await Dio(
          BaseOptions(
            receiveTimeout: const Duration(seconds: 3),
            connectTimeout: const Duration(seconds: 3),
          ),
        ).get(AppConfig.stableGithubOrProxy);
        return response.data;
      } catch (error) {
        AppConfig.stableGithubOrProxy = '';
      }
    }
    if (AppConfig.stableGithubOrProxy.isEmpty) {
      for (final url in AppConfig.serverUrlList) {
        try {
          final response = await Dio(
            BaseOptions(
              receiveTimeout: const Duration(seconds: 2),
              connectTimeout: const Duration(seconds: 2),
            ),
          ).get(url);
          AppConfig.setStableGithubOrProxy(response);
          return response.data;
        } catch (err) {
          continue;
        }
      }
      throw DioException(
        requestOptions: RequestOptions(path: 'github_urls'),
        type: DioExceptionType.unknown,
        error: Exception('所有 GitHub 链接都无法访问，请检查网络连接或服务器状态'),
      );
    }
  }

  static bool get isOffline {
    return _offlineMode;
  }

  static bool get isOk {
    return dio.options.baseUrl.isNotEmpty || _offlineMode;
  }

  static bool get prepared {
    return _accessToken.isNotEmpty && isOk;
  }

  static String get url {
    return dio.options.baseUrl;
  }

  static Map get headers {
    return dio.options.headers;
  }

  static String get userType {
    if (_accessToken.isEmpty) return "guest";
    final payload = JwtDecoder.decode(_accessToken);
    return payload["userType"] ?? "guest";
  }

  static String get userId {
    if (_accessToken.isEmpty) return "";
    final payload = JwtDecoder.decode(_accessToken);
    return payload["id"] ?? "";
  }

  static String? get position {
    if (_accessToken.isEmpty) return null;
    final payload = JwtDecoder.decode(_accessToken);
    return payload["position"];
  }

  static Map<String, dynamic> get accessTokenPayload {
    if (_accessToken.isEmpty) return {};
    final payload = JwtDecoder.decode(_accessToken);
    return payload;
  }

  static void setBaseUrl(String url) {
    dio.options.baseUrl = url;
    uploadDio.options.baseUrl = url;
  }

  static void setAccessToken(String accessToken) {
    _accessToken = accessToken;
    dio.options.headers['Authorization'] = 'Bearer $accessToken';
    uploadDio.options.headers['Authorization'] = 'Bearer $accessToken';
  }

  static void delAccessToken() {
    _accessToken = "";
    dio.options.headers['Authorization'] = '';
    uploadDio.options.headers['Authorization'] = '';
  }

  static setDeviceInfo() async {
    final headers = await getDeviceHeadersForApi();
    dio.options.headers.addAll(headers);
    uploadDio.options.headers.addAll(headers);
  }

  static void useJson() {
    dio.interceptors.add(
      InterceptorsWrapper(
        onResponse: (Response response, handler) {
          final contentType = response.headers.value('content-type');
          if (contentType != null && contentType.contains('application/json')) {
            if (response.data is String) {
              try {
                response.data = jsonDecode(response.data);
              } catch (e) {
                response.data = {};
              }
            }
          }
          return handler.next(response);
        },
      ),
    );
  }

  static useError() {
    dio.interceptors.add(ApiService._errorInterceptor);
    uploadDio.interceptors.add(ApiService._errorInterceptor);
  }

  static init() {
    ApiService.useJson();
    ApiService.useError();
    ApiService.setDeviceInfo();
    Worker.scheduleUrlNow();
  }

  static waitOk() async {
    await Future(() async {
      while (!ApiService.isOk) {
        await Future.delayed(Duration(milliseconds: 100));
      }
    });
  }

  static DioMediaType? parseContentType(String? mimeType) {
    if (mimeType == null) return null;
    try {
      return DioMediaType.parse(mimeType);
    } catch (e) {
      return DioMediaType('application', 'octet-stream');
    }
  }

  static openOfflineMode() {
    ApiService.setBaseUrl("");
    ApiService._offlineMode = true;
    Worker.dispose();
    WebSocketServer.dispose();
  }
}
