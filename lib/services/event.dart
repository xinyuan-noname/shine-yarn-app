import 'dart:async';

class EventBus {
  static final EventBus _instance = EventBus._internal();
  factory EventBus() => _instance;
  EventBus._internal();

  final StreamController<MessageEvent> _messageController = StreamController.broadcast();
  Stream<MessageEvent> get messageStream => _messageController.stream;

  void publish(MessageEvent event) {
    _messageController.add(event);
  }

  void dispose() {
    _messageController.close();
  }
}

// 事件数据类（可扩展）
class MessageEvent {
  final String content;
  final DateTime timestamp;
  final String? type;

  MessageEvent({
    required this.content,
    this.type,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  @override
  String toString() => 'MessageEvent(type: $type, content: $content)';
}