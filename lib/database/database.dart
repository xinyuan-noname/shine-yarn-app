import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'package:path_provider/path_provider.dart';

part 'database.g.dart';

class TaskCheck extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text().withLength(min: 6, max: 32).unique()();
  TextColumn get finish => text()();
  TextColumn get unfinished => text()();
  DateTimeColumn get createdAt => dateTime().nullable()();
}

@DriftDatabase(tables: [TaskCheck])
class AppDatabase extends _$AppDatabase {
  AppDatabase._() : super(_openConnection());
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 1;

  Future<TaskCheckData> getTaskCheckItem(int id) async {
    final stmt = select(taskCheck)..where((t) => t.id.equals(id));
    return await stmt.getSingle();
  }

  Future<int> insertTaskCheckItem({
    required String title,
    String? finish,
    String? unfinished,
    DateTime? createdAt,
  }) async {
    return await into(taskCheck).insert(
      TaskCheckCompanion(
        title: Value(title),
        finish: Value(finish ?? ''),
        unfinished: Value(unfinished ?? ''),
        createdAt: Value(createdAt ?? DateTime.now()),
      ),
    );
  }

  Future<void> updateTaskCheckContent({
    required int id,
    String? finished,
    String? unfinished,
  }) async {
    final stmt = update(taskCheck)..where((tbl) => tbl.id.equals(id));

    stmt.write(
      TaskCheckCompanion(
        finish: finished != null ? Value(finished) : const Value.absent(),
        unfinished: unfinished != null
            ? Value(unfinished)
            : const Value.absent(),
      ),
    );
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
