import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shine/components/dialog.dart';
import 'package:shine/pages/task_vote_detail_page.dart';
import 'package:shine/routes.dart';
import 'package:shine/services/api.dart';
import 'package:shine/services/event.dart';
import 'package:shine/services/ws.dart';
import 'package:shine/storage/message_storage.dart';
import 'package:shine/utils/anonymous_utils.dart';
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
              case "vote":
                _handleVote(map);
              case "vote_update":
                _handleVoteUpdate(map);
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
      // 匿名消息由客户端直接指定来源：id 为 fffffffff，昵称为随机名字
      if (anonymous) ...buildAnonymousPayloadFields(),
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
    // 匿名消息的来源id固定为 ffffffffff，昵称使用随机名字
    final bool anonymous = isAnonymousMessage(map, sourceMap);
    final String source;
    final String sourceUsername;
    if (anonymous) {
      final result = buildAnonymousSource(map, sourceMap);
      source = result.$1;
      sourceUsername = result.$2;
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

  /// 处理服务器推送的新投票, 弹窗邀请用户立即投票
  static Future<void> _handleVote(Map map) async {
    final taskId = map["taskId"];
    if (taskId is! int) return;
    final title = map["title"] is String ? map["title"] as String : "新的投票";
    VoteEventBus.publish(
      VoteEvent(kind: "created", taskId: taskId, title: title),
    );
    // 应用不在前台时不打扰用户, 用户回来后在投票列表里仍能看到
    if (WidgetsBinding.instance.lifecycleState != AppLifecycleState.resumed) {
      return;
    }
    final navigator = globalNavigatorKey.currentState;
    final context = navigator?.overlay?.context;
    if (navigator == null || context == null) return;
    final (creatorId, creatorName) = _parseVoteSource(map["source"]);
    // 自己发起的投票不需要再弹窗邀请自己
    if (creatorId.isNotEmpty && creatorId == ApiService.userId) return;
    final goVote = await showVoteInviteDialog(
      context: context,
      title: title,
      creatorName: creatorName,
    );
    if (goVote != true) return;
    await navigator.pushNamed(
      '/task/vote/detail',
      arguments: TaskVoteDetailPageArgs(taskId: taskId),
    );
  }

  /// 处理投票内容或进度变化, 通知正在查看该投票的页面刷新
  static void _handleVoteUpdate(Map map) {
    final taskId = map["taskId"];
    if (taskId is! int) return;
    VoteEventBus.publish(
      VoteEvent(
        kind: "updated",
        taskId: taskId,
        title: map["title"] is String ? map["title"] as String : null,
      ),
    );
  }

  /// 解析投票推送中的发起人信息, 返回 (发起人ID, 发起人昵称)
  static (String, String) _parseVoteSource(dynamic rawSource) {
    Map sourceMap = {};
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
    final id = sourceMap['id'] is String ? sourceMap['id'] as String : "";
    final username = sourceMap['username'] is String
        ? sourceMap['username'] as String
        : "老师";
    return (id, username);
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
