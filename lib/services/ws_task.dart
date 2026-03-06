import 'dart:async';
import 'dart:convert';

import 'package:shine/services/ws.dart';
import 'package:uuid/uuid.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class WsTask {
  static WebSocketChannel? _channel;

  static bool get isConnected => _channel != null;

  static String get _wsUrl =>
      "${WebSocketServer.wsUrl}/task?token=${WebSocketServer.wsToken}";

  static Future<void> connect() async {
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
          if (message is String) {
            final map = jsonDecode(message);
            switch (map["type"]) {
              case "ping":
                _handlePing();
            }
          }
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

  static void sendRemind({required String msg, required List<String> targetList}) {
    final map = {
      "type": "remind",
      "target": targetList,
      "ts": DateTime.now().toLocal().toString(),
      "wsi": Uuid().v4(),
    };
    WsTask.send(jsonEncode(map));
  }

  static Future<void> close([int? code, String? reason]) async {
    await _channel?.sink.close(code, reason);
    WsTask.clear();
  }

  static void clear() {
    _channel = null;
  }

  static void _handlePing() {
    final map = {"type": "pong", "ts": DateTime.now().toLocal().toString()};
    WsTask.send(jsonEncode(map));
  }

  static Future<void> start() async {
    await WsTask.connect();
  }
}
