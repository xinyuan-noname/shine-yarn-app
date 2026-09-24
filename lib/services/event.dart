import 'dart:async';

class EventBus {
  EventBus._();

  static final StreamController<MessageEvent> _controller =
      StreamController<MessageEvent>.broadcast();

  static Stream<MessageEvent> get stream => _controller.stream;

  static void publish(MessageEvent event) {
    _controller.add(event);
  }

  static void dispose() {
    _controller.close();
  }
}

class MessageEvent {
  final DateTime timestamp;
  final String? type;
  final String? sourceUser;

  MessageEvent({this.type, this.sourceUser, DateTime? timestamp})
    : timestamp = timestamp ?? DateTime.now();

  @override
  String toString() => 'MessageEvent(type: $type)';
}

/// 投票相关事件: 服务器推送新投票或投票进度变化时发布
class VoteEventBus {
  VoteEventBus._();

  static final StreamController<VoteEvent> _controller =
      StreamController<VoteEvent>.broadcast();

  static Stream<VoteEvent> get stream => _controller.stream;

  static void publish(VoteEvent event) {
    _controller.add(event);
  }

  static void dispose() {
    _controller.close();
  }
}

class VoteEvent {
  /// created: 收到新投票邀请, updated: 某个投票的内容或进度有变化
  final String kind;
  final int taskId;
  final String? title;

  VoteEvent({required this.kind, required this.taskId, this.title});

  @override
  String toString() => 'VoteEvent(kind: $kind, taskId: $taskId)';
}
