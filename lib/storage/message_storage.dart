import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:shine/database/database.dart';
import 'package:shine/storage/profile_storage.dart';

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
  static AppDatabase get _db => DatabaseProvider.instance;
  static final String _remindMessageReadedKeyPrefix =
      "remind_message_readed_key_";

  static Future<void> addMessageReaded(int id) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = await ProfileStorage.getId();
    final key = '$_remindMessageReadedKeyPrefix$userId';
    List<String> readedList = prefs.getStringList(key) ?? [];
    if (!readedList.contains(id.toString())) {
      readedList.add(id.toString());
      await prefs.setStringList(key, readedList);
    }
  }

  static Future<bool> judgeRemindMessageReaded(int id) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = await ProfileStorage.getId();
    final key = '$_remindMessageReadedKeyPrefix$userId';
    List<String> readedList = prefs.getStringList(key) ?? [];
    return readedList.contains(id.toString());
  }

  static Future<void> removeReminderMessageReaded(int id) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = await ProfileStorage.getId();
    final key = '$_remindMessageReadedKeyPrefix$userId';
    List<String> readedList = prefs.getStringList(key) ?? [];
    if (readedList.contains(id.toString())) {
      readedList.remove(id.toString());
      await prefs.setStringList(key, readedList);
    }
  }

  static Future<List<MessageStorageData>> getAllMessage() async {
    final List<MessageStorageData> result = [];
    result.addAll(await MessageStorage.getAllRemindMessages());
    return result;
  }

  static Future<List<RemindMessageStorageData>> getAllRemindMessages() async {
    final result = await _db.getAllRemindMessages();
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
      final readed = await MessageStorage.judgeRemindMessageReaded(messageData.id);
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
    final result = await _db.getRemindMessage(id);
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
    return await _db.insertRemindMessage(
      content: content,
      level: level,
      source: source,
      sentAt: sentAt,
    );
  }

  static Future<void> removeRemindMessage(int id) async {
    await MessageStorage.removeReminderMessageReaded(id);
    await _db.deleteRemindMessage(id);
  }

}
