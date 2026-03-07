import 'package:shine/database/database.dart';

final db = DatabaseProvider.instance;

class MessageStorageData {
  final int id;
  final DateTime? sentAt;
  final int level;
  final String from;
  final String content;
  const MessageStorageData({
    required this.id,
    required this.from,
    required this.content,
    this.level = 1,
    this.sentAt,
  });
}

class MessageStorage {
  static Future<List<MessageStorageData>> getAllRemindMessages() async {
    final result = await db.getAllRemindMessages();
    final list = <MessageStorageData>[];
    for (final messageData in result) {
      list.add(
        MessageStorageData(
          id: messageData.id,
          from: messageData.from,
          content: messageData.content,
          level: messageData.level,
          sentAt: messageData.sentAt,
        ),
      );
    }
    return list;
  }

  static Future<MessageStorageData?> getRemindMessage(int id) async {
    final result = await db.getRemindMessage(id);
    if (result == null) return null;
    return MessageStorageData(
      id: id,
      from: result.from,
      content: result.content,
      level: result.level,
      sentAt: result.sentAt,
    );
  }

  static Future<int> addRemindMessage({
    required String content,
    required int level,
    required String from,
    DateTime? sentAt,
  }) async {
    return await db.insertRemindMessage(
      content: content,
      level: level,
      from: from,
      sentAt: sentAt,
    );
  }

  static Future<void> removeRemindMessage(int id) async {
    return await db.deleteRemindMessage(id);
  }

  static Future<List<RemindMessageData>> getRemindMessagesByLevel(
    int level,
  ) async {
    return await db.getRemindMessagesByLevel(level);
  }

  static Future<List<RemindMessageData>> getRemindMessagesByFrom(
    String from,
  ) async {
    return await db.getRemindMessagesByFrom(from);
  }
}
