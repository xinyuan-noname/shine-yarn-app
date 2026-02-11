import 'package:shine/services/api.dart';
import 'package:shine/services/dio.dart';
import 'package:shine/storage/token_storage.dart';

class ApiAuth {
  static login(input) async {
    final response = await dio.post("/auth/login", data: input);
    final Map<String, dynamic> data = response.data;
    final String? accessToken = data['accessToken'];
    final String? refreshToken = data['refreshToken'];
    if (accessToken != null && refreshToken != null) {
      ApiService.setAccessToken(accessToken);
      TokenStorage.setAccessToken(accessToken);
      TokenStorage.setRefreshToken(refreshToken);
      return true;
    }
    return false;
  }

  static refresh() async {
    final response = await dio.post("/auth/refresh", data: {"refreshToken"});
    final Map<String, dynamic> data = response.data;
    final String? accessToken = data['accessToken'];
    if (accessToken != null) {
      ApiService.setAccessToken(accessToken);
      return true;
    }
    return false;
  }
}
