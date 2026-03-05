import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'package:path_provider/path_provider.dart';

part 'database.g.dart';

class TaskCheck extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text().withLength(min: 2, max: 32)();
  TextColumn get finished => text()();
  TextColumn get unfinished => text()();
  DateTimeColumn get createdAt => dateTime().nullable()();
}

@DriftDatabase(tables: [TaskCheck])
class AppDatabase extends _$AppDatabase {
  AppDatabase._() : super(_openConnection());
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 1;
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

  static QueryExecutor _openConnection() {
    return driftDatabase(
      name: 'shine_yarn',
      native: const DriftNativeOptions(
        databaseDirectory: getApplicationDocumentsDirectory,
      ),
    );
  }
}

class DatabaseProvider {
  static final AppDatabase _instance = AppDatabase._();

  static AppDatabase get instance => _instance;
}
