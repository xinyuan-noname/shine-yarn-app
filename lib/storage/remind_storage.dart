import 'package:shine/database/database.dart';

final db = DatabaseProvider.instance;

class MessageStorage {
  static Future<List<RemindMessageData>> getAllRemindMessages() async {
    return await db.getAllRemindMessages();
  }

  static Future<RemindMessageData?> getRemindMessage(int id) async {
    return await db.getRemindMessage(id);
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
