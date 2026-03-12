import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:shine/components/toast.dart';
import 'package:shine/config/app_config.dart';
import 'package:shine/services/dio.dart';
import 'package:shine/utils/device_info.dart';
import 'package:shine/utils/routes.dart';
import 'package:shine/worker/worker.dart';

class ApiService {
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
                if (isOnLoginPageGlobally()) {
                  showToast(msg: "身份认证过期, 请重新登录");
                  goToLoginGlobally();
                }
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
    final response = await Dio().get(AppConfig.assetUrl);
    final url = response.data;
    return url;
  }

  static bool get isOk {
    return dio.options.baseUrl.isNotEmpty;
  }

  static String get url {
    return dio.options.baseUrl;
  }

  static Map get headers {
    return dio.options.headers;
  }

  static void setBaseUrl(String url) {
    dio.options.baseUrl = url;
    uploadDio.options.baseUrl = url;
  }

  static void setAccessToken(String accessToken) {
    dio.options.headers['Authorization'] = 'Bearer $accessToken';
    uploadDio.options.headers['Authorization'] = 'Bearer $accessToken';
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
}
