import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'package:path_provider/path_provider.dart';
import 'package:shine/storage/profile_storage.dart';

part 'database.g.dart';

class TaskCheck extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text().withLength(min: 2, max: 32)();
  TextColumn get finished => text()();
  TextColumn get unfinished => text()();
  DateTimeColumn get createdAt => dateTime().nullable()();
}

class RemindMessage extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get content => text()();
  IntColumn get level => integer()();
  TextColumn get source => text()();
  DateTimeColumn get sentAt => dateTime()();
}

class ToDoMessage extends Table {
  TextColumn get id => text()();
  BoolColumn get finished => boolean()();
  DateTimeColumn get updatedAt => dateTime()();
}

@DriftDatabase(tables: [TaskCheck, RemindMessage, ToDoMessage])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);
  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) => m.createAll(),
    onUpgrade: (Migrator m, int from, int to) async {
      await m.createTable(remindMessage);
    },
  );

  @override
  int get schemaVersion => 2;
  Future<List<TaskCheckData>> getAllTaskCheckItems() async {
    return await select(taskCheck).get();
  }

  Future<TaskCheckData?> getTaskCheckItem(int id) async {
    final stmt = select(taskCheck)..where((t) => t.id.equals(id));
    return await stmt.getSingleOrNull();
  }

  Future<int> insertTaskCheckItem({
    required String title,
    String? finished,
    String? unfinished,
    DateTime? createdAt,
  }) async {
    return await into(taskCheck).insert(
      TaskCheckCompanion(
        title: Value(title),
        finished: Value(finished ?? ''),
        unfinished: Value(unfinished ?? ''),
        createdAt: Value(createdAt ?? DateTime.now()),
      ),
    );
  }

  Future<void> updateTaskCheckContent({
    required int id,
    String? title,
    String? finished,
    String? unfinished,
  }) async {
    final stmt = update(taskCheck)..where((tbl) => tbl.id.equals(id));

    stmt.write(
      TaskCheckCompanion(
        finished: finished != null ? Value(finished) : const Value.absent(),
        unfinished: unfinished != null
            ? Value(unfinished)
            : const Value.absent(),
        title: title != null ? Value(title) : const Value.absent(),
      ),
    );
  }

  Future<void> deleteTaskCheck(int id) async {
    final stmt = delete(taskCheck)..where((tbl) => tbl.id.equals(id));
    await stmt.go();
  }

  Future<List<RemindMessageData>> getAllRemindMessages() async {
    return await select(remindMessage).get();
  }

  Future<RemindMessageData?> getRemindMessage(int id) async {
    final stmt = select(remindMessage)..where((t) => t.id.equals(id));
    return await stmt.getSingleOrNull();
  }

  Future<int> insertRemindMessage({
    required String content,
    required int level,
    required String source,
    DateTime? sentAt,
  }) async {
    return await into(remindMessage).insert(
      RemindMessageCompanion(
        content: Value(content),
        level: Value(level),
        source: Value(source),
        sentAt: Value(sentAt ?? DateTime.now()),
      ),
    );
  }

  Future<void> deleteRemindMessage(int id) async {
    final stmt = delete(remindMessage)..where((tbl) => tbl.id.equals(id));
    await stmt.go();
  }

  Future<List<RemindMessageData>> getRemindMessagesByLevel(int level) async {
    return await (select(
      remindMessage,
    )..where((tbl) => tbl.level.equals(level))).get();
  }

  Future<List<RemindMessageData>> getRemindMessagesByFrom(String source) async {
    return await (select(
      remindMessage,
    )..where((tbl) => tbl.source.equals(source))).get();
  }

  // ToDoMessage 相关操作方法
  Future<List<ToDoMessageData>> getAllToDoMessages() async {
    return await select(toDoMessage).get();
  }

  Future<ToDoMessageData?> getToDoMessage(String id) async {
    final stmt = select(toDoMessage)..where((t) => t.id.equals(id));
    return await stmt.getSingleOrNull();
  }

  Future<List<ToDoMessageData>> getFinishedToDoMessages() async {
    return await (select(toDoMessage)..where((tbl) => tbl.finished.equals(true))).get();
  }

  Future<List<ToDoMessageData>> getUnfinishedToDoMessages() async {
    return await (select(toDoMessage)..where((tbl) => tbl.finished.equals(false))).get();
  }

  Future<void> insertToDoMessage({
    required String id,
    required bool finished,
    DateTime? updatedAt,
  }) async {
    await into(toDoMessage).insert(
      ToDoMessageCompanion(
        id: Value(id),
        finished: Value(finished),
        updatedAt: Value(updatedAt ?? DateTime.now()),
      ),
    );
  }

  Future<void> updateToDoMessage({
    required String id,
    bool? finished,
    DateTime? updatedAt,
  }) async {
    final stmt = update(toDoMessage)..where((tbl) => tbl.id.equals(id));

    stmt.write(
      ToDoMessageCompanion(
        finished: finished != null ? Value(finished) : const Value.absent(),
        updatedAt: updatedAt != null
            ? Value(updatedAt)
            : const Value.absent(),
      ),
    );
  }

  Future<void> deleteToDoMessage(String id) async {
    final stmt = delete(toDoMessage)..where((tbl) => tbl.id.equals(id));
    await stmt.go();
  }

  Future<void> clearAllToDoMessages() async {
    await delete(toDoMessage).go();
  }
}

class DatabaseProvider {
  static late AppDatabase _instance;
  static bool initialized = false;

  static AppDatabase get instance => _instance;

  static QueryExecutor _openConnection(String userId) {
    return driftDatabase(
      name: 'shine_yarn_db_$userId',
      native: const DriftNativeOptions(
        databaseDirectory: getApplicationDocumentsDirectory,
      ),
    );
  }

  static Future init() async {
    if (initialized) await _instance.close();
    final id = await ProfileStorage.getId();
    _instance = AppDatabase(_openConnection(id));
    initialized = true;
  }
}
