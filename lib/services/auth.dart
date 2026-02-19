import 'package:dio/dio.dart';
import 'package:shine/services/api.dart';
import 'package:shine/services/dio.dart';
import 'package:shine/storage/token_storage.dart';
import 'package:shine/worker/worker.dart';

class ApiAuth {
  static login(input) async {
    try {
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
    } on DioException catch (e) {
      Worker.scheduleRefreshNow();
      return e.message ?? "登陆失败";
    } catch (e) {
      return "登陆失败";
    }
  }

  static refresh() async {
    final refreshToken = await TokenStorage.getRefreshToken();
    try {
      final response = await dio.post(
        "/auth/refresh",
        data: {"refreshToken": refreshToken},
      );
      final Map<String, dynamic> data = response.data;
      final String? accessToken = data['accessToken'];
      if (accessToken != null) {
        ApiService.setAccessToken(accessToken);
        TokenStorage.setAccessToken(accessToken);
        return true;
      }
    } catch (e) {
      return false;
    }
  }

  static logout() async {
    final refreshToken = await TokenStorage.getRefreshToken();
    await TokenStorage.deleteAccessToken();
    await TokenStorage.deleteRefreshToken();
    await Worker.stopRefresh();
    try {
      await dio.post("/auth/logout", data: {"refreshToken": refreshToken});
    } on DioException catch (e) {
      Worker.scheduleRefreshNow();
      return e.message ?? "吊销令牌失败";
    } catch (e) {
      return "吊销令牌失败";
    }
  }
}
