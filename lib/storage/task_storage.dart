import 'dart:convert';

import 'package:shine/database/database.dart';

final AppDatabase db = DatabaseProvider.firstInstance;

class TaskStorageData {
  final int id;
  final String title;
  final DateTime? createdAt;
  final bool personal;
  const TaskStorageData({
    required this.id,
    required this.title,
    required this.personal,
    this.createdAt,
  });
}

class CheckTaskStorageData extends TaskStorageData {
  final List finished;
  final List unfinished;
  const CheckTaskStorageData({
    required super.id,
    required super.title,
    super.personal = false,
    super.createdAt,
    required this.finished,
    required this.unfinished,
  });
}

class TaskStorage {
  static Future<void> addCheckTask({
    required String title,
    required List finished,
    required List unfinished,
    DateTime? createdAt,
  }) async {
    await db.insertTaskCheckItem(
      title: title,
      finished: jsonEncode(finished),
      unfinished: jsonEncode(unfinished),
    );
  }

  static Future<void> updateCheckTask({
    required int id,
    String? title,
    List? finished,
    List? unfinished,
  }) async {
    await db.updateTaskCheckContent(
      id: id,
      title: title,
      finished: finished == null ? null : jsonEncode(finished),
      unfinished: unfinished == null ? null : jsonEncode(unfinished),
    );
  }

  static Future<CheckTaskStorageData?> getCheckTask({required int id}) async {
    final data = await db.getTaskCheckItem(id);
    if (data == null) return null;
    final String title = data.title;
    final DateTime? createdAt = data.createdAt;
    final df = jsonDecode(data.finished);
    final du = jsonDecode(data.unfinished);
    final List finished = [];
    final List unfinished = [];
    if (df is List) finished.addAll(df);
    if (du is List) unfinished.addAll(du);
    return CheckTaskStorageData(
      id: id,
      title: title,
      finished: finished,
      unfinished: unfinished,
      createdAt: createdAt,
      personal: true,
    );
  }

  static Future<List<CheckTaskStorageData>> getAllCheckTask() async {
    final dataList = await db.getAllTaskCheckItems();
    return dataList.map((ele) {
      final df = jsonDecode(ele.finished);
      final du = jsonDecode(ele.unfinished);
      final List finished = [];
      final List unfinished = [];
      if (df is List) finished.addAll(df);
      if (du is List) unfinished.addAll(du);
      return CheckTaskStorageData(
        id: ele.id,
        title: ele.title,
        createdAt: ele.createdAt,
        finished: finished,
        unfinished: unfinished,
        personal: true,
      );
    }).toList();
  }

  static Future<void> delCheckTask({required int id}) async {
    await db.deleteTaskCheck(id);
  }

  static Future<List<TaskStorageData>> getAllTask() async {
    final List<TaskStorageData> result = [];
    result.addAll(await getAllCheckTask());
    return result;
  }
}
