import 'package:dio/dio.dart';
import 'package:shine/storage/url_storage.dart';

class ApiService {
  static String? baseUrl;
  static getBaseUrl() async {
    final response = await Dio().get(
      "https://gitee.com/xinyuanwm/asset/raw/main/url.txt",
      options: Options(
        headers: {
          'Cache-Control': 'no-cache, no-store, must-revalidate',
          'Pragma': 'no-cache',
          'Expires': '0',
        },
      ),
    );
    final url = response.data;
    URLStorage.setBaseUrl(url as String);
    baseUrl = url;
    print(response);
    print(response.headers);
  }
}
