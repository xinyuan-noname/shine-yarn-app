import 'package:dio/dio.dart';
import 'package:shine/storage/url_storage.dart';

class ApiService {
  static late Dio dio;
  static String _baseUrl = '';
  static get baseUrl => _baseUrl;
  static set baseUrl(String url) {
    _baseUrl = url;
     _refreshDio();
  }

  static String _accessToken = '';
  static get accessToken => _accessToken;
  static set accessToken(String token) {
    _accessToken = token;
    _refreshDio();
  }

  static getBaseUrl() async {
    final response = await Dio().get(
      "https://gitee.com/xinyuanwm/asset/raw/main/url.txt",
    );
    final url = response.data;
    URLStorage.setBaseUrl(url as String);
    baseUrl = url;
    print(url);
  }
  static _refreshDio(){
    dio =  Dio(
      BaseOptions(
        baseUrl: _baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      ),
    );
  }
}
