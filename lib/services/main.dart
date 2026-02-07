import 'package:dio/dio.dart';
import 'package:shine/storage/url_storage.dart';

class ApiService {
  static String? baseUrl;
  static getBaseUrl() async {
    final response = await Dio().get(
      "https://cdn.jsdelivr.net/gh/xinyuan-noname/asset@main/url.txt",
    );
    final url = response.data;
    URLStorage.setBaseUrl(url as String);
    baseUrl = url;
    print(url);
  }
}
