import 'dart:async';

import 'package:shine/services/ws.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class WsTask {
  static WebSocketChannel? _channel;

  static bool get isConnected => _channel != null;
  static Timer? _heartbeatTimer;

  static String get _wsUrl =>
      "${WebSocketServer.wsUrl}/task?token=${WebSocketServer.wsToken}";

  static Future<void> connect() async {
    print(WsTask._wsUrl);
    if (_channel != null) return;
    try {
      _channel = WebSocketChannel.connect(Uri.parse(_wsUrl));
      _channel!.sink.done
          .then((_) {
            WsTask.clear();
          })
          .catchError((error) {
            WsTask.clear();
          });

      _channel!.stream.listen(
        (message) {
          print("ws连接成功");
        },
        onError: (error) {
          WsTask.clear();
        },
        onDone: () {
          WsTask.clear();
        },
      );
    } catch (e) {
      print('Failed to connect WebSocket: $e');
      WsTask.clear();
      rethrow;
    }
  }

  static void send(String message) {
    if (_channel == null) throw StateError('Not connected');
    _channel!.sink.add(message);
  }

  static Future<void> close([int? code, String? reason]) async {
    await _channel?.sink.close(code, reason);
    WsTask.clear();
  }

  static void clear() {
    _channel = null;
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  static void ping() {
    _heartbeatTimer?.cancel();
    if (_channel == null) return;
    _heartbeatTimer = Timer.periodic(Duration(seconds: 30), (_) {
      if (_channel != null) {
        _channel!.sink.add('ping');
      }
    });
  }

  static Future<void> start() async {
    await WsTask.connect();
    ping();
  }
}
