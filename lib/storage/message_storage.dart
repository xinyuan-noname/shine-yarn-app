import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:shine/database/database.dart';

final AppDatabase db = DatabaseProvider.firstInstance;

class MessageStorageData {
  final int id;
  final DateTime? sentAt;
  final int level;
  final String sourceId;
  final String sourceUsername;
  final String content;
  final bool readed;
  const MessageStorageData({
    required this.id,
    required this.sourceId,
    required this.sourceUsername,
    required this.content,
    this.level = 1,
    this.readed = false,
    this.sentAt,
  });
}

class RemindMessageStorageData extends MessageStorageData {
  const RemindMessageStorageData({
    required super.id,
    required super.sourceId,
    required super.sourceUsername,
    required super.content,
    super.readed,
    super.level,
    super.sentAt,
  });
}

class MessageStorage {
  static final String _remindMessageReadedKey = "remind_message_readed_key";

  static Future<void> addMessageReaded(int id) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> readedList =
        prefs.getStringList(_remindMessageReadedKey) ?? [];
    if (!readedList.contains(id.toString())) {
      readedList.add(id.toString());
      await prefs.setStringList(_remindMessageReadedKey, readedList);
    }
  }

  static Future<bool> judgeRemindMessageReaded(int id) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> readedList =
        prefs.getStringList(_remindMessageReadedKey) ?? [];
    return readedList.contains(id.toString());
  }

  static Future<void> removeReminderMessageReaded(int id) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> readedList =
        prefs.getStringList(_remindMessageReadedKey) ?? [];
    if (readedList.contains(id.toString())) {
      readedList.remove(id.toString());
      await prefs.setStringList(_remindMessageReadedKey, readedList);
    }
  }

  static Future<List<MessageStorageData>> getAllMessage() async {
    final List<MessageStorageData> result = [];
    result.addAll(await MessageStorage.getAllRemindMessages());
    return result;
  }

  static Future<List<RemindMessageStorageData>> getAllRemindMessages() async {
    final result = await db.getAllRemindMessages();
    final list = <RemindMessageStorageData>[];
    for (final messageData in result) {
      String sourceId = '';
      String sourceUsername = '';
      final sourceMap = jsonDecode(messageData.source);
      if (sourceMap is Map) {
        if (sourceMap['id'] is String) {
          sourceId = sourceMap['id'];
        }
        if (sourceMap['username'] is String) {
          sourceUsername = sourceMap['username'];
        }
      }
      final readed = await MessageStorage.judgeRemindMessageReaded(
        messageData.id,
      );
      list.add(
        RemindMessageStorageData(
          id: messageData.id,
          content: messageData.content,
          level: messageData.level,
          sentAt: messageData.sentAt,
          sourceId: sourceId,
          sourceUsername: sourceUsername,
          readed: readed,
        ),
      );
    }
    return list;
  }

  static Future<RemindMessageStorageData?> getRemindMessage(int id) async {
    final result = await db.getRemindMessage(id);
    if (result == null) return null;
    String sourceId = '';
    String sourceUsername = '';
    final sourceMap = jsonDecode(result.source);
    if (sourceMap is Map) {
      if (sourceMap['id'] is String) {
        sourceId = sourceMap['id'];
      }
      if (sourceMap['username'] is String) {
        sourceUsername = sourceMap['username'];
      }
    }
    return RemindMessageStorageData(
      id: id,
      sourceId: sourceId,
      sourceUsername: sourceUsername,
      content: result.content,
      level: result.level,
      sentAt: result.sentAt,
      readed: await MessageStorage.judgeRemindMessageReaded(id),
    );
  }

  static Future<int> addRemindMessage({
    required String content,
    required int level,
    required String source,
    DateTime? sentAt,
  }) async {
    return await db.insertRemindMessage(
      content: content,
      level: level,
      source: source,
      sentAt: sentAt,
    );
  }

  static Future<void> removeRemindMessage(int id) async {
    await MessageStorage.removeReminderMessageReaded(id);
    await db.deleteRemindMessage(id);
  }

  static Future<List<RemindMessageData>> getRemindMessagesByLevel(
    int level,
  ) async {
    return await db.getRemindMessagesByLevel(level);
  }

  static Future<List<RemindMessageData>> getRemindMessagesByFrom(
    String source,
  ) async {
    return await db.getRemindMessagesByFrom(source);
  }
}
