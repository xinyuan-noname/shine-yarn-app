import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:shine/services/dio.dart';
import 'package:shine/utils/device_info.dart';
import 'package:shine/worker/worker.dart';

class ApiService {
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
    print(url);
  }

  static setAccessToken(String accessToken) {
    dio.options.headers['Authorization'] = 'Bearer $accessToken';
    print(dio.options.headers);
  }

  static setDeviceInfo() async {
    final headers = await getDeviceHeadersForApi();
    dio.options.headers.addAll(headers);
    print(dio.options.headers);
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
    dio.interceptors.add(
      InterceptorsWrapper(
        onError: (DioException err, handler) {
          final res = err.response;
          final code = res?.statusCode;
          if (code == 401) {
            final Map<String, dynamic> data = jsonDecode(res?.data);
            if (data["error"] != null) {
              switch (data["error"]) {
                case "Invalid Access Token":
                  {
                    Worker.scheduleRefreshNow();
                  }
                  break;
              }
            }
          } else if (err.type == DioExceptionType.connectionError) {
            print('网络异常');
          } else if (code != null && code >= 500) {
            Worker.scheduleUrlNow();
          }
          handler.next(err);
        },
      ),
    );
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
