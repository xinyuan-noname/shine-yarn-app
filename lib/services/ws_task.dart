import 'dart:async';
import 'dart:convert';

import 'package:shine/services/ws.dart';
import 'package:shine/storage/remind_storage.dart';
import 'package:uuid/uuid.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class WsTask {
  static final List<(String, Completer, String)> _taskRecordList = [];
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
              case "ack":
                _handleAck(map);
              case "remind":
                _handleRemind(map);
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

  static Future sendRemind({
    required String msg,
    required List<String> targetList,
    int level = 1,
  }) {
    final wsi = Uuid().v4();
    final map = {
      "type": "remind",
      "targetList": targetList,
      "content": msg,
      "ts": DateTime.now().millisecondsSinceEpoch,
      "wsi": wsi,
      "level": level,
    };
    WsTask.send(jsonEncode(map));
    return WsTask.recordAndWait(wsi: wsi, type: "remind");
  }

  static Future recordAndWait({required String wsi, required String type}) {
    final completer = Completer();
    _taskRecordList.add((wsi, completer, type));
    Future.delayed(Duration(seconds: 10)).then((_) {
      if (!completer.isCompleted) {
        completer.completeError(
          TimeoutException("Request timed out after 10 seconds"),
        );
      }
    });
    return completer.future;
  }

  static void removeRecordAndDoNext({
    required (String, Completer, String) record,
    dynamic result,
  }) {
    if (!record.$2.isCompleted) record.$2.complete(result);
    _taskRecordList.remove(record);
  }

  static (String, Completer, String) findRecord(String wsi) {
    return _taskRecordList.firstWhere((ele) => ele.$1 == wsi);
  }

  static void _handlePing() {
    final map = {"type": "pong", "ts": DateTime.now().millisecondsSinceEpoch};
    WsTask.send(jsonEncode(map));
  }

  static void _handleAck(Map map) {
    final wsi = map['wsi'];
    final record = findRecord(wsi);
    switch (record.$3) {
      case "remind":
        removeRecordAndDoNext(record: record);
        break;
    }
  }

  static void _handleRemind(Map map) {
    final String content = map["content"];
    final String from = map["from"];
    final int ts = map["ts"];
    final int level = map["level"];
    MessageStorage.addRemindMessage(
      content: content,
      level: level,
      from: from,
      sentAt: DateTime.fromMillisecondsSinceEpoch(ts),
    );
  }

  static Future<void> start() async {
    await WsTask.connect();
  }

  static Future<void> close([int? code, String? reason]) async {
    await _channel?.sink.close(code, reason);
    WsTask.clear();
  }

  static void clear() {
    _channel = null;
  }
}
