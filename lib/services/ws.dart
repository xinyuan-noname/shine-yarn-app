import 'package:dio/dio.dart';
import 'package:shine/services/api.dart';
import 'package:shine/services/dio.dart';
import 'package:shine/services/ws_task.dart';

class WebSocketServer {
  static String _token = '';
  static Future<String?> syncWsToken() async {
    try {
      final response = await dio.get("/ws/token");
      if (response.data is! Map) {
        return "获取WebSocket令牌失效";
      }
      if (response.data['token'] is! String) {
        return "获取WebSocket令牌失效";
      }
      _token = response.data['token'];
      return null;
    } on DioException catch (e) {
      return e.message ?? "获取WebSocket令牌失效";
    } catch (e) {
      return "获取WebSocket令牌失效";
    }
  }

  static String get wsUrl {
    try {
      final uri = Uri.parse(ApiService.url);
      final scheme = uri.scheme == 'https' ? 'wss' : 'ws';
      return "${uri.replace(scheme: scheme)}/ws";
    } catch (e) {
      throw ArgumentError('Invalid API URL: ${ApiService.url}');
    }
  }

  static String get wsToken {
    return _token;
  }

  static dispose() async {
    _token = '';
    await WsTask.close();
  }
}
