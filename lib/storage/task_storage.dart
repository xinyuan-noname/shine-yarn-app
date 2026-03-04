import 'dart:convert';

import 'package:shine/database/database.dart';

final db = DatabaseProvider.instance;

class CheckTaskStorageData {
  final int id;
  final String title;
  final List finished;
  final List unfinished;
  final DateTime? createdAt;
  const CheckTaskStorageData(
    this.id,
    this.title,
    this.finished,
    this.unfinished,
    this.createdAt,
  );
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
    return CheckTaskStorageData(id, title, finished, unfinished, createdAt);
  }

  static Future<void> delCheckTask({required int id}) async {
    await db.deleteTaskCheck(id);
  }
}
