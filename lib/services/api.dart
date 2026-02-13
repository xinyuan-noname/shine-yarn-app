import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:shine/services/dio.dart';
import 'package:shine/utils/device_info.dart';

class ApiService {
  static getBaseUrl() async {
    final response = await Dio().get(
      "https://gitee.com/xinyuanwm/asset/raw/main/url.txt",
    );
    final url = response.data;
    return url;
  }
  static bool get isOk{
    return dio.options.baseUrl.isNotEmpty;
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

  static useJson() {
    dio.interceptors.add(
      InterceptorsWrapper(
        onResponse: (Response response, handler) {
          final contentType = response.headers.map['Content-Type'];
          if (contentType == 'application/json') {
            if (response.data is String) {
              try {
                response.data = jsonDecode(response.data);
              } catch (e) {
                // 解析失败保留原数据或抛出错误
                print('JSON decode failed: $e');
              }
            }
          }
          return handler.next(response); // 继续传递响应
        },
        onError: (DioException err, handler) {
          // 统一错误处理（比如 token 过期、网络错误等）
          print('Request error: ${err.message}');
          return handler.next(err);
        },
      ),
    );
  }

  static init() async {
    ApiService.useJson();
    ApiService.setDeviceInfo();
    final url = await getBaseUrl();
    ApiService.setBaseUrl(url);
  }

  static reinit() async {
    final url = await getBaseUrl();
    ApiService.setBaseUrl(url);
  }
}
