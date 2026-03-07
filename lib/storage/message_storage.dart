import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:shine/database/database.dart';

final db = DatabaseProvider.instance;

class MessageStorageData {
  final int id;
  final DateTime? sentAt;
  final int level;
  final String sourceId;
  final String sourceUsername;
  final bool readed;
  final String content;
  const MessageStorageData({
    required this.id,
    required this.sourceId,
    required this.sourceUsername,
    required this.content,
    this.readed = false,
    this.level = 1,
    this.sentAt,
  });
}

class MessageStorage {
  static final String _messageReadedKey = "message_readed_key";

  static Future<void> saveMessageReaded(int id) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> readedList = prefs.getStringList(_messageReadedKey) ?? [];
    if (!readedList.contains(id.toString())) {
      readedList.add(id.toString());
      await prefs.setStringList(_messageReadedKey, readedList);
    }
  }

  static Future<bool> isMessageReaded(int id) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> readedList = prefs.getStringList(_messageReadedKey) ?? [];
    return readedList.contains(id.toString());
  }

  static Future<void> deleteMessageReaded(int id) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> readedList = prefs.getStringList(_messageReadedKey) ?? [];
    if (readedList.contains(id.toString())) {
      readedList.remove(id.toString());
      await prefs.setStringList(_messageReadedKey, readedList);
    }
  }

  static Future<List<MessageStorageData>> getAllMessage() async {
    final List<MessageStorageData> result = [];
    result.addAll(await MessageStorage.getAllRemindMessages());
    return result;
  }

  static Future<List<MessageStorageData>> getAllRemindMessages() async {
    final result = await db.getAllRemindMessages();
    final list = <MessageStorageData>[];
    for (final messageData in result) {
      String sourceId = '';
      String sourceUsername = '';
      final sourceMap = jsonDecode(messageData.source);
      print(sourceMap);
      if (sourceMap is Map) {
        if (sourceMap['id'] is String) {
          sourceId = sourceMap['id'];
        }
        if (sourceMap['username'] is String) {
          sourceUsername = sourceMap['username'];
        }
      }
      list.add(
        MessageStorageData(
          id: messageData.id,
          content: messageData.content,
          level: messageData.level,
          sentAt: messageData.sentAt,
          sourceId: sourceId,
          sourceUsername: sourceUsername,
        ),
      );
    }
    return list;
  }

  static Future<MessageStorageData?> getRemindMessage(int id) async {
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
    return MessageStorageData(
      id: id,
      sourceId: sourceId,
      sourceUsername: sourceUsername,
      content: result.content,
      level: result.level,
      sentAt: result.sentAt,
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
    return await db.deleteRemindMessage(id);
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
