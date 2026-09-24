import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:shine/database/database.dart';
import 'package:shine/storage/profile_storage.dart';

/// 匿名消息统一使用的来源id，不包含任何真实身份信息
const String anonymousMessageSourceId = "fffffffff";

class MessageStorageData {
  final int id;
  final DateTime? sentAt;
  final int level;
  final String sourceId;
  final String sourceUsername;
  final String content;
  final bool readed;
  final bool anonymous;
  const MessageStorageData({
    required this.id,
    required this.sourceId,
    required this.sourceUsername,
    required this.content,
    this.level = 1,
    this.readed = false,
    this.anonymous = false,
    this.sentAt,
  });

  /// 按人物分类时使用的分组键，匿名消息以随机昵称作为区分依据
  String get groupKey {
    if (anonymous) {
      return sourceUsername.isEmpty
          ? anonymousMessageSourceId
          : "$anonymousMessageSourceId:$sourceUsername";
    }
    if (sourceId.isNotEmpty) return sourceId;
    if (sourceUsername.isNotEmpty) return "username:$sourceUsername";
    return "unknown";
  }

  /// 用于界面展示的来源昵称
  String get displayUsername =>
      sourceUsername.isEmpty ? "未知用户" : sourceUsername;
}

class RemindMessageStorageData extends MessageStorageData {
  const RemindMessageStorageData({
    required super.id,
    required super.sourceId,
    required super.sourceUsername,
    required super.content,
    super.readed,
    super.level,
    super.anonymous,
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

  /// 批量标记消息为已读
  static Future<void> addMessagesReaded(List<int> idList) async {
    if (idList.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final userId = await ProfileStorage.getId();
    final key = '$_remindMessageReadedKeyPrefix$userId';
    List<String> readedList = prefs.getStringList(key) ?? [];
    bool changed = false;
    for (final id in idList) {
      if (!readedList.contains(id.toString())) {
        readedList.add(id.toString());
        changed = true;
      }
    }
    if (changed) await prefs.setStringList(key, readedList);
  }

  /// 解析消息来源，返回 (来源id, 来源昵称, 是否匿名)
  static (String, String, bool) _parseSource(String source) {
    String sourceId = '';
    String sourceUsername = '';
    bool anonymous = false;
    try {
      final sourceMap = jsonDecode(source);
      if (sourceMap is Map) {
        if (sourceMap['anonymous'] == true) anonymous = true;
        if (sourceMap['id'] is String) {
          sourceId = sourceMap['id'];
        }
        if (sourceMap['username'] is String) {
          sourceUsername = sourceMap['username'];
        }
      }
    } catch (e) {
      anonymous = false;
    }
    // 使用匿名来源id的消息一律视为匿名消息
    if (sourceId == anonymousMessageSourceId) anonymous = true;
    if (anonymous) sourceId = anonymousMessageSourceId;
    return (sourceId, sourceUsername, anonymous);
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
      final (sourceId, sourceUsername, anonymous) = MessageStorage._parseSource(
        messageData.source,
      );
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
          anonymous: anonymous,
          readed: readed,
        ),
      );
    }
    return list;
  }

  static Future<RemindMessageStorageData?> getRemindMessage(int id) async {
    final result = await _db.getRemindMessage(id);
    if (result == null) return null;
    final (sourceId, sourceUsername, anonymous) = MessageStorage._parseSource(
      result.source,
    );
    return RemindMessageStorageData(
      id: id,
      sourceId: sourceId,
      sourceUsername: sourceUsername,
      anonymous: anonymous,
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

  /// 批量删除提醒消息(按人物清空时使用)
  static Future<void> removeRemindMessages(List<int> idList) async {
    if (idList.isEmpty) return;
    for (final id in idList) {
      await MessageStorage.removeReminderMessageReaded(id);
    }
    await _db.deleteRemindMessages(idList);
  }

  // -- --
  static Future<List<String>> getFinishedToDoItemIdList() async {
    final list = await _db.getFinishedToDoMessages();
    return list.map((e) => e.id).toList();
  }

  static Future<void> changeFinishedStatus({
    required String itemId,
    required bool finished,
  }) async {
    final item = await _db.getToDoMessage(itemId);
    if (item == null) {
      await _db.insertToDoMessage(
        id: itemId,
        finished: finished,
        updatedAt: DateTime.now(),
      );
    } else {
      await _db.updateToDoMessage(
        id: itemId,
        finished: finished,
        updatedAt: DateTime.now(),
      );
    }
  }
}
