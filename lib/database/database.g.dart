// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $TaskCheckTable extends TaskCheck
    with TableInfo<$TaskCheckTable, TaskCheckData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TaskCheckTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 6,
      maxTextLength: 32,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _finishMeta = const VerificationMeta('finish');
  @override
  late final GeneratedColumn<String> finish = GeneratedColumn<String>(
    'finish',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _unfinishedMeta = const VerificationMeta(
    'unfinished',
  );
  @override
  late final GeneratedColumn<String> unfinished = GeneratedColumn<String>(
    'unfinished',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    title,
    finish,
    unfinished,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'task_check';
  @override
  VerificationContext validateIntegrity(
    Insertable<TaskCheckData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('finish')) {
      context.handle(
        _finishMeta,
        finish.isAcceptableOrUnknown(data['finish']!, _finishMeta),
      );
    } else if (isInserting) {
      context.missing(_finishMeta);
    }
    if (data.containsKey('unfinished')) {
      context.handle(
        _unfinishedMeta,
        unfinished.isAcceptableOrUnknown(data['unfinished']!, _unfinishedMeta),
      );
    } else if (isInserting) {
      context.missing(_unfinishedMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TaskCheckData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TaskCheckData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      finish: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}finish'],
      )!,
      unfinished: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}unfinished'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      ),
    );
  }

  @override
  $TaskCheckTable createAlias(String alias) {
    return $TaskCheckTable(attachedDatabase, alias);
  }
}

class TaskCheckData extends DataClass implements Insertable<TaskCheckData> {
  final int id;
  final String title;
  final String finish;
  final String unfinished;
  final DateTime? createdAt;
  const TaskCheckData({
    required this.id,
    required this.title,
    required this.finish,
    required this.unfinished,
    this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['title'] = Variable<String>(title);
    map['finish'] = Variable<String>(finish);
    map['unfinished'] = Variable<String>(unfinished);
    if (!nullToAbsent || createdAt != null) {
      map['created_at'] = Variable<DateTime>(createdAt);
    }
    return map;
  }

  TaskCheckCompanion toCompanion(bool nullToAbsent) {
    return TaskCheckCompanion(
      id: Value(id),
      title: Value(title),
      finish: Value(finish),
      unfinished: Value(unfinished),
      createdAt: createdAt == null && nullToAbsent
          ? const Value.absent()
          : Value(createdAt),
    );
  }

  factory TaskCheckData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TaskCheckData(
      id: serializer.fromJson<int>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      finish: serializer.fromJson<String>(json['finish']),
      unfinished: serializer.fromJson<String>(json['unfinished']),
      createdAt: serializer.fromJson<DateTime?>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'title': serializer.toJson<String>(title),
      'finish': serializer.toJson<String>(finish),
      'unfinished': serializer.toJson<String>(unfinished),
      'createdAt': serializer.toJson<DateTime?>(createdAt),
    };
  }

  TaskCheckData copyWith({
    int? id,
    String? title,
    String? finish,
    String? unfinished,
    Value<DateTime?> createdAt = const Value.absent(),
  }) => TaskCheckData(
    id: id ?? this.id,
    title: title ?? this.title,
    finish: finish ?? this.finish,
    unfinished: unfinished ?? this.unfinished,
    createdAt: createdAt.present ? createdAt.value : this.createdAt,
  );
  TaskCheckData copyWithCompanion(TaskCheckCompanion data) {
    return TaskCheckData(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      finish: data.finish.present ? data.finish.value : this.finish,
      unfinished: data.unfinished.present
          ? data.unfinished.value
          : this.unfinished,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TaskCheckData(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('finish: $finish, ')
          ..write('unfinished: $unfinished, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, title, finish, unfinished, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TaskCheckData &&
          other.id == this.id &&
          other.title == this.title &&
          other.finish == this.finish &&
          other.unfinished == this.unfinished &&
          other.createdAt == this.createdAt);
}

class TaskCheckCompanion extends UpdateCompanion<TaskCheckData> {
  final Value<int> id;
  final Value<String> title;
  final Value<String> finish;
  final Value<String> unfinished;
  final Value<DateTime?> createdAt;
  const TaskCheckCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.finish = const Value.absent(),
    this.unfinished = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  TaskCheckCompanion.insert({
    this.id = const Value.absent(),
    required String title,
    required String finish,
    required String unfinished,
    this.createdAt = const Value.absent(),
  }) : title = Value(title),
       finish = Value(finish),
       unfinished = Value(unfinished);
  static Insertable<TaskCheckData> custom({
    Expression<int>? id,
    Expression<String>? title,
    Expression<String>? finish,
    Expression<String>? unfinished,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (finish != null) 'finish': finish,
      if (unfinished != null) 'unfinished': unfinished,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  TaskCheckCompanion copyWith({
    Value<int>? id,
    Value<String>? title,
    Value<String>? finish,
    Value<String>? unfinished,
    Value<DateTime?>? createdAt,
  }) {
    return TaskCheckCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      finish: finish ?? this.finish,
      unfinished: unfinished ?? this.unfinished,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (finish.present) {
      map['finish'] = Variable<String>(finish.value);
    }
    if (unfinished.present) {
      map['unfinished'] = Variable<String>(unfinished.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TaskCheckCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('finish: $finish, ')
          ..write('unfinished: $unfinished, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $TaskCheckTable taskCheck = $TaskCheckTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [taskCheck];
}

typedef $$TaskCheckTableCreateCompanionBuilder =
    TaskCheckCompanion Function({
      Value<int> id,
      required String title,
      required String finish,
      required String unfinished,
      Value<DateTime?> createdAt,
    });
typedef $$TaskCheckTableUpdateCompanionBuilder =
    TaskCheckCompanion Function({
      Value<int> id,
      Value<String> title,
      Value<String> finish,
      Value<String> unfinished,
      Value<DateTime?> createdAt,
    });

class $$TaskCheckTableFilterComposer
    extends Composer<_$AppDatabase, $TaskCheckTable> {
  $$TaskCheckTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get finish => $composableBuilder(
    column: $table.finish,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get unfinished => $composableBuilder(
    column: $table.unfinished,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TaskCheckTableOrderingComposer
    extends Composer<_$AppDatabase, $TaskCheckTable> {
  $$TaskCheckTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get finish => $composableBuilder(
    column: $table.finish,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get unfinished => $composableBuilder(
    column: $table.unfinished,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TaskCheckTableAnnotationComposer
    extends Composer<_$AppDatabase, $TaskCheckTable> {
  $$TaskCheckTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get finish =>
      $composableBuilder(column: $table.finish, builder: (column) => column);

  GeneratedColumn<String> get unfinished => $composableBuilder(
    column: $table.unfinished,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$TaskCheckTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TaskCheckTable,
          TaskCheckData,
          $$TaskCheckTableFilterComposer,
          $$TaskCheckTableOrderingComposer,
          $$TaskCheckTableAnnotationComposer,
          $$TaskCheckTableCreateCompanionBuilder,
          $$TaskCheckTableUpdateCompanionBuilder,
          (
            TaskCheckData,
            BaseReferences<_$AppDatabase, $TaskCheckTable, TaskCheckData>,
          ),
          TaskCheckData,
          PrefetchHooks Function()
        > {
  $$TaskCheckTableTableManager(_$AppDatabase db, $TaskCheckTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TaskCheckTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TaskCheckTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TaskCheckTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> finish = const Value.absent(),
                Value<String> unfinished = const Value.absent(),
                Value<DateTime?> createdAt = const Value.absent(),
              }) => TaskCheckCompanion(
                id: id,
                title: title,
                finish: finish,
                unfinished: unfinished,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String title,
                required String finish,
                required String unfinished,
                Value<DateTime?> createdAt = const Value.absent(),
              }) => TaskCheckCompanion.insert(
                id: id,
                title: title,
                finish: finish,
                unfinished: unfinished,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TaskCheckTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TaskCheckTable,
      TaskCheckData,
      $$TaskCheckTableFilterComposer,
      $$TaskCheckTableOrderingComposer,
      $$TaskCheckTableAnnotationComposer,
      $$TaskCheckTableCreateCompanionBuilder,
      $$TaskCheckTableUpdateCompanionBuilder,
      (
        TaskCheckData,
        BaseReferences<_$AppDatabase, $TaskCheckTable, TaskCheckData>,
      ),
      TaskCheckData,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$TaskCheckTableTableManager get taskCheck =>
      $$TaskCheckTableTableManager(_db, _db.taskCheck);
}
