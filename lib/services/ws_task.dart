import 'dart:async';
import 'dart:convert';

import 'package:shine/services/event.dart';
import 'package:shine/services/ws.dart';
import 'package:shine/storage/message_storage.dart';
import 'package:shine/worker/worker.dart';
import 'package:uuid/uuid.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class WsTask {
  static final List<(String, Completer, String)> _taskRecordList = [];
  static WebSocketChannel? _channel;

  static int? _closeCode;
  static Timer? _reconnectTimer;
  static int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;
  static const Duration _reconnectDelay = Duration(seconds: 15);

  static bool get isConnected => _channel != null;

  static String get _wsUrl =>
      "${WebSocketServer.wsUrl}/task?token=${WebSocketServer.wsToken}";

  static Future<void> connect() async {
    if (_channel != null) return;
    try {
      _channel = WebSocketChannel.connect(Uri.parse(_wsUrl));
      _channel!.sink.done
          .then((_) {
            if (_channel?.closeCode == 1000 || _closeCode == 1000) return;
            WsTask.reconnect();
          })
          .catchError((error) {
            if (_channel?.closeCode == 1000 || _closeCode == 1000) return;
            WsTask.reconnect();
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
          if (_channel?.closeCode == 1000 || _closeCode == 1000) return;
          WsTask.reconnect();
        },
        onDone: () {
          if (_channel?.closeCode == 1000 || _closeCode == 1000) return;
          WsTask.reconnect();
        },
      );
      _reconnectAttempts = 0;
    } catch (e) {
      WsTask.reconnect();
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
    bool anonymous = false,
  }) {
    final wsi = Uuid().v4();
    final map = {
      "type": "remind",
      "targetList": targetList,
      "content": msg,
      "ts": DateTime.now().millisecondsSinceEpoch,
      "wsi": wsi,
      "level": level,
      if (anonymous) "anonymous": true,
    };
    WsTask.send(jsonEncode(map));
    return WsTask.recordAndWait(wsi: wsi, type: "remind");
  }

  static Future recordAndWait({required String wsi, required String type}) {
    final completer = Completer();
    _taskRecordList.add((wsi, completer, type));
    Future.delayed(Duration(seconds: 4)).then((_) {
      if (!completer.isCompleted) {
        completer.completeError(TimeoutException("发送超时"));
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

  static (String, Completer, String)? findRecord(String wsi) {
    for (final item in _taskRecordList) {
      if (item.$1 == wsi) return item;
    }
    return null;
  }

  static void _handlePing() {
    final map = {"type": "pong", "ts": DateTime.now().millisecondsSinceEpoch};
    WsTask.send(jsonEncode(map));
  }

  static void _handleAck(Map map) {
    final wsi = map['wsi'];
    final record = findRecord(wsi);
    if (record == null) return;
    switch (record.$3) {
      case "remind":
        removeRecordAndDoNext(record: record);
        break;
    }
  }

  static Future _handleRemind(Map map) async {
    final String content = map["content"] is String
        ? map["content"] as String
        : "";
    final int level = map["level"] is int ? map["level"] as int : 1;
    final int ts = map["ts"] is int
        ? map["ts"] as int
        : DateTime.now().millisecondsSinceEpoch;
    Map sourceMap = {};
    final rawSource = map["source"];
    if (rawSource is Map) {
      sourceMap = rawSource;
    } else if (rawSource is String) {
      try {
        final decoded = jsonDecode(rawSource);
        if (decoded is Map) sourceMap = decoded;
      } catch (e) {
        sourceMap = {};
      }
    }
    // 匿名消息不会保留发送者的任何身份信息
    final bool anonymous =
        map["anonymous"] == true || sourceMap["anonymous"] == true;
    final String source;
    final String sourceUsername;
    if (anonymous) {
      source = jsonEncode({
        "id": anonymousMessageSourceId,
        "username": anonymousMessageUsername,
        "anonymous": true,
      });
      sourceUsername = anonymousMessageUsername;
    } else {
      source = jsonEncode(sourceMap);
      sourceUsername = sourceMap['username'] is String
          ? sourceMap['username'] as String
          : "未知用户";
    }
    await MessageStorage.addRemindMessage(
      content: content,
      level: level,
      source: source,
      sentAt: DateTime.fromMillisecondsSinceEpoch(ts),
    );
    EventBus.publish(MessageEvent(sourceUser: sourceUsername));
  }

  static Future<void> start() async {
    await WebSocketServer.syncWsToken();
    await WsTask.connect();
  }

  static void reconnect() {
    WsTask.clear();

    if (_reconnectAttempts < _maxReconnectAttempts) {
      _reconnectAttempts++;
      _reconnectTimer?.cancel();
      _reconnectTimer = Timer(_reconnectDelay, () {
        Worker.startTaskWebSocket();
      });
    }
  }

  static Future<void> close({int code = 1000, String? reason}) async {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _closeCode = code;
    await _channel?.sink.close(code, reason);
    WsTask.clear();
  }

  static void clear() {
    _channel = null;
  }
}
