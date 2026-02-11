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

  static setBaseUrl(String url) {
    dio.options.baseUrl = url;
    print(url);
  }

  static setAccessToken(String accessToken) {
    dio.options.headers['Authorization'] = 'Bearer $accessToken';
    print(dio.options.headers);
  }

  static setDeviceInfo()async{
    final headers = await getDeviceHeadersForApi();
    print(headers);
    dio.options.headers.addAll(headers);
    print(dio.options.headers);
  }
}
