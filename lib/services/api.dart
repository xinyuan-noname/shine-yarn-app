import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:shine/services/dio.dart';
import 'package:shine/utils/device_info.dart';
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
                {
                  Worker.scheduleRefreshNow();
                }
                break;
              case "INVALID_PASSWORD":
                {
                  err = DioException(
                    requestOptions: err.requestOptions,
                    message: '密码出错',
                    type: DioExceptionType.badCertificate,
                  );
                }
                break;
            }
          }
        }
      } else if (err.type == DioExceptionType.connectionError) {
        err = DioException(
          requestOptions: err.requestOptions,
          message: '网络连接出错',
          type: DioExceptionType.connectionTimeout,
        );
      } else if (code != null && code >= 500) {
        Worker.scheduleUrlNow();
      }
      handler.next(err);
    },
  );
  static getBaseUrl() async {
    final response = await Dio().get(
      "https://gitee.com/xinyuanwm/asset/raw/main/url.txt",
    );
    final url = response.data;
    return url;
  }

  static bool get isOk {
    return dio.options.baseUrl.isNotEmpty;
  }

  static String get url {
    return dio.options.baseUrl;
  }

  static setBaseUrl(String url) {
    dio.options.baseUrl = url;
    uploadDio.options.baseUrl = url;
  }

  static setAccessToken(String accessToken) {
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
                print('JSON decode failed: $e');
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

  static init() async {
    ApiService.useJson();
    ApiService.useError();
    ApiService.setDeviceInfo();
    await Worker.scheduleUrlNow();
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
