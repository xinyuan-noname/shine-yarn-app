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

// 事件类保持不变
class MessageEvent {
  final DateTime timestamp;
  final String? type;

  MessageEvent({
    this.type,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  @override
  String toString() => 'MessageEvent(type: $type)';
}