import 'package:dio/dio.dart';
import 'package:shine/services/dio.dart';

class ApiService {
  static getBaseUrl() async {
    final response = await Dio().get(
      "https://gitee.com/xinyuanwm/asset/raw/main/url.txt",
    );
    final url = response.data;
    return url;
  }

  static setBaseUrl(String url) {
    dio.options.baseUrl = url;
  }

  static setAccessToken(String accessToken) {
    dio.options.headers['Authorization'] = 'Bearer $accessToken';
  }
}
