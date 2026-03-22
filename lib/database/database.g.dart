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
      minTextLength: 2,
      maxTextLength: 32,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _finishedMeta = const VerificationMeta(
    'finished',
  );
  @override
  late final GeneratedColumn<String> finished = GeneratedColumn<String>(
    'finished',
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
    finished,
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
    if (data.containsKey('finished')) {
      context.handle(
        _finishedMeta,
        finished.isAcceptableOrUnknown(data['finished']!, _finishedMeta),
      );
    } else if (isInserting) {
      context.missing(_finishedMeta);
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
      finished: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}finished'],
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
  final String finished;
  final String unfinished;
  final DateTime? createdAt;
  const TaskCheckData({
    required this.id,
    required this.title,
    required this.finished,
    required this.unfinished,
    this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['title'] = Variable<String>(title);
    map['finished'] = Variable<String>(finished);
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
      finished: Value(finished),
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
      finished: serializer.fromJson<String>(json['finished']),
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
      'finished': serializer.toJson<String>(finished),
      'unfinished': serializer.toJson<String>(unfinished),
      'createdAt': serializer.toJson<DateTime?>(createdAt),
    };
  }

  TaskCheckData copyWith({
    int? id,
    String? title,
    String? finished,
    String? unfinished,
    Value<DateTime?> createdAt = const Value.absent(),
  }) => TaskCheckData(
    id: id ?? this.id,
    title: title ?? this.title,
    finished: finished ?? this.finished,
    unfinished: unfinished ?? this.unfinished,
    createdAt: createdAt.present ? createdAt.value : this.createdAt,
  );
  TaskCheckData copyWithCompanion(TaskCheckCompanion data) {
    return TaskCheckData(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      finished: data.finished.present ? data.finished.value : this.finished,
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
          ..write('finished: $finished, ')
          ..write('unfinished: $unfinished, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, title, finished, unfinished, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TaskCheckData &&
          other.id == this.id &&
          other.title == this.title &&
          other.finished == this.finished &&
          other.unfinished == this.unfinished &&
          other.createdAt == this.createdAt);
}

class TaskCheckCompanion extends UpdateCompanion<TaskCheckData> {
  final Value<int> id;
  final Value<String> title;
  final Value<String> finished;
  final Value<String> unfinished;
  final Value<DateTime?> createdAt;
  const TaskCheckCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.finished = const Value.absent(),
    this.unfinished = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  TaskCheckCompanion.insert({
    this.id = const Value.absent(),
    required String title,
    required String finished,
    required String unfinished,
    this.createdAt = const Value.absent(),
  }) : title = Value(title),
       finished = Value(finished),
       unfinished = Value(unfinished);
  static Insertable<TaskCheckData> custom({
    Expression<int>? id,
    Expression<String>? title,
    Expression<String>? finished,
    Expression<String>? unfinished,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (finished != null) 'finished': finished,
      if (unfinished != null) 'unfinished': unfinished,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  TaskCheckCompanion copyWith({
    Value<int>? id,
    Value<String>? title,
    Value<String>? finished,
    Value<String>? unfinished,
    Value<DateTime?>? createdAt,
  }) {
    return TaskCheckCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      finished: finished ?? this.finished,
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
    if (finished.present) {
      map['finished'] = Variable<String>(finished.value);
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
          ..write('finished: $finished, ')
          ..write('unfinished: $unfinished, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $RemindMessageTable extends RemindMessage
    with TableInfo<$RemindMessageTable, RemindMessageData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RemindMessageTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _contentMeta = const VerificationMeta(
    'content',
  );
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
    'content',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _levelMeta = const VerificationMeta('level');
  @override
  late final GeneratedColumn<int> level = GeneratedColumn<int>(
    'level',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sentAtMeta = const VerificationMeta('sentAt');
  @override
  late final GeneratedColumn<DateTime> sentAt = GeneratedColumn<DateTime>(
    'sent_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, content, level, source, sentAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'remind_message';
  @override
  VerificationContext validateIntegrity(
    Insertable<RemindMessageData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('content')) {
      context.handle(
        _contentMeta,
        content.isAcceptableOrUnknown(data['content']!, _contentMeta),
      );
    } else if (isInserting) {
      context.missing(_contentMeta);
    }
    if (data.containsKey('level')) {
      context.handle(
        _levelMeta,
        level.isAcceptableOrUnknown(data['level']!, _levelMeta),
      );
    } else if (isInserting) {
      context.missing(_levelMeta);
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceMeta);
    }
    if (data.containsKey('sent_at')) {
      context.handle(
        _sentAtMeta,
        sentAt.isAcceptableOrUnknown(data['sent_at']!, _sentAtMeta),
      );
    } else if (isInserting) {
      context.missing(_sentAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RemindMessageData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RemindMessageData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      content: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content'],
      )!,
      level: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}level'],
      )!,
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      )!,
      sentAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}sent_at'],
      )!,
    );
  }

  @override
  $RemindMessageTable createAlias(String alias) {
    return $RemindMessageTable(attachedDatabase, alias);
  }
}

class RemindMessageData extends DataClass
    implements Insertable<RemindMessageData> {
  final int id;
  final String content;
  final int level;
  final String source;
  final DateTime sentAt;
  const RemindMessageData({
    required this.id,
    required this.content,
    required this.level,
    required this.source,
    required this.sentAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['content'] = Variable<String>(content);
    map['level'] = Variable<int>(level);
    map['source'] = Variable<String>(source);
    map['sent_at'] = Variable<DateTime>(sentAt);
    return map;
  }

  RemindMessageCompanion toCompanion(bool nullToAbsent) {
    return RemindMessageCompanion(
      id: Value(id),
      content: Value(content),
      level: Value(level),
      source: Value(source),
      sentAt: Value(sentAt),
    );
  }

  factory RemindMessageData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RemindMessageData(
      id: serializer.fromJson<int>(json['id']),
      content: serializer.fromJson<String>(json['content']),
      level: serializer.fromJson<int>(json['level']),
      source: serializer.fromJson<String>(json['source']),
      sentAt: serializer.fromJson<DateTime>(json['sentAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'content': serializer.toJson<String>(content),
      'level': serializer.toJson<int>(level),
      'source': serializer.toJson<String>(source),
      'sentAt': serializer.toJson<DateTime>(sentAt),
    };
  }

  RemindMessageData copyWith({
    int? id,
    String? content,
    int? level,
    String? source,
    DateTime? sentAt,
  }) => RemindMessageData(
    id: id ?? this.id,
    content: content ?? this.content,
    level: level ?? this.level,
    source: source ?? this.source,
    sentAt: sentAt ?? this.sentAt,
  );
  RemindMessageData copyWithCompanion(RemindMessageCompanion data) {
    return RemindMessageData(
      id: data.id.present ? data.id.value : this.id,
      content: data.content.present ? data.content.value : this.content,
      level: data.level.present ? data.level.value : this.level,
      source: data.source.present ? data.source.value : this.source,
      sentAt: data.sentAt.present ? data.sentAt.value : this.sentAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RemindMessageData(')
          ..write('id: $id, ')
          ..write('content: $content, ')
          ..write('level: $level, ')
          ..write('source: $source, ')
          ..write('sentAt: $sentAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, content, level, source, sentAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RemindMessageData &&
          other.id == this.id &&
          other.content == this.content &&
          other.level == this.level &&
          other.source == this.source &&
          other.sentAt == this.sentAt);
}

class RemindMessageCompanion extends UpdateCompanion<RemindMessageData> {
  final Value<int> id;
  final Value<String> content;
  final Value<int> level;
  final Value<String> source;
  final Value<DateTime> sentAt;
  const RemindMessageCompanion({
    this.id = const Value.absent(),
    this.content = const Value.absent(),
    this.level = const Value.absent(),
    this.source = const Value.absent(),
    this.sentAt = const Value.absent(),
  });
  RemindMessageCompanion.insert({
    this.id = const Value.absent(),
    required String content,
    required int level,
    required String source,
    required DateTime sentAt,
  }) : content = Value(content),
       level = Value(level),
       source = Value(source),
       sentAt = Value(sentAt);
  static Insertable<RemindMessageData> custom({
    Expression<int>? id,
    Expression<String>? content,
    Expression<int>? level,
    Expression<String>? source,
    Expression<DateTime>? sentAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (content != null) 'content': content,
      if (level != null) 'level': level,
      if (source != null) 'source': source,
      if (sentAt != null) 'sent_at': sentAt,
    });
  }

  RemindMessageCompanion copyWith({
    Value<int>? id,
    Value<String>? content,
    Value<int>? level,
    Value<String>? source,
    Value<DateTime>? sentAt,
  }) {
    return RemindMessageCompanion(
      id: id ?? this.id,
      content: content ?? this.content,
      level: level ?? this.level,
      source: source ?? this.source,
      sentAt: sentAt ?? this.sentAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (level.present) {
      map['level'] = Variable<int>(level.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (sentAt.present) {
      map['sent_at'] = Variable<DateTime>(sentAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RemindMessageCompanion(')
          ..write('id: $id, ')
          ..write('content: $content, ')
          ..write('level: $level, ')
          ..write('source: $source, ')
          ..write('sentAt: $sentAt')
          ..write(')'))
        .toString();
  }
}

class $ToDoMessageTable extends ToDoMessage
    with TableInfo<$ToDoMessageTable, ToDoMessageData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ToDoMessageTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _finishedMeta = const VerificationMeta(
    'finished',
  );
  @override
  late final GeneratedColumn<bool> finished = GeneratedColumn<bool>(
    'finished',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("finished" IN (0, 1))',
    ),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, finished, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'to_do_message';
  @override
  VerificationContext validateIntegrity(
    Insertable<ToDoMessageData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('finished')) {
      context.handle(
        _finishedMeta,
        finished.isAcceptableOrUnknown(data['finished']!, _finishedMeta),
      );
    } else if (isInserting) {
      context.missing(_finishedMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => const {};
  @override
  ToDoMessageData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ToDoMessageData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      finished: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}finished'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $ToDoMessageTable createAlias(String alias) {
    return $ToDoMessageTable(attachedDatabase, alias);
  }
}

class ToDoMessageData extends DataClass implements Insertable<ToDoMessageData> {
  final String id;
  final bool finished;
  final DateTime updatedAt;
  const ToDoMessageData({
    required this.id,
    required this.finished,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['finished'] = Variable<bool>(finished);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  ToDoMessageCompanion toCompanion(bool nullToAbsent) {
    return ToDoMessageCompanion(
      id: Value(id),
      finished: Value(finished),
      updatedAt: Value(updatedAt),
    );
  }

  factory ToDoMessageData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ToDoMessageData(
      id: serializer.fromJson<String>(json['id']),
      finished: serializer.fromJson<bool>(json['finished']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'finished': serializer.toJson<bool>(finished),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  ToDoMessageData copyWith({String? id, bool? finished, DateTime? updatedAt}) =>
      ToDoMessageData(
        id: id ?? this.id,
        finished: finished ?? this.finished,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  ToDoMessageData copyWithCompanion(ToDoMessageCompanion data) {
    return ToDoMessageData(
      id: data.id.present ? data.id.value : this.id,
      finished: data.finished.present ? data.finished.value : this.finished,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ToDoMessageData(')
          ..write('id: $id, ')
          ..write('finished: $finished, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, finished, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ToDoMessageData &&
          other.id == this.id &&
          other.finished == this.finished &&
          other.updatedAt == this.updatedAt);
}

class ToDoMessageCompanion extends UpdateCompanion<ToDoMessageData> {
  final Value<String> id;
  final Value<bool> finished;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const ToDoMessageCompanion({
    this.id = const Value.absent(),
    this.finished = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ToDoMessageCompanion.insert({
    required String id,
    required bool finished,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       finished = Value(finished),
       updatedAt = Value(updatedAt);
  static Insertable<ToDoMessageData> custom({
    Expression<String>? id,
    Expression<bool>? finished,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (finished != null) 'finished': finished,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ToDoMessageCompanion copyWith({
    Value<String>? id,
    Value<bool>? finished,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return ToDoMessageCompanion(
      id: id ?? this.id,
      finished: finished ?? this.finished,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (finished.present) {
      map['finished'] = Variable<bool>(finished.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ToDoMessageCompanion(')
          ..write('id: $id, ')
          ..write('finished: $finished, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $TaskCheckTable taskCheck = $TaskCheckTable(this);
  late final $RemindMessageTable remindMessage = $RemindMessageTable(this);
  late final $ToDoMessageTable toDoMessage = $ToDoMessageTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    taskCheck,
    remindMessage,
    toDoMessage,
  ];
}

typedef $$TaskCheckTableCreateCompanionBuilder =
    TaskCheckCompanion Function({
      Value<int> id,
      required String title,
      required String finished,
      required String unfinished,
      Value<DateTime?> createdAt,
    });
typedef $$TaskCheckTableUpdateCompanionBuilder =
    TaskCheckCompanion Function({
      Value<int> id,
      Value<String> title,
      Value<String> finished,
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

  ColumnFilters<String> get finished => $composableBuilder(
    column: $table.finished,
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

  ColumnOrderings<String> get finished => $composableBuilder(
    column: $table.finished,
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

  GeneratedColumn<String> get finished =>
      $composableBuilder(column: $table.finished, builder: (column) => column);

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
                Value<String> finished = const Value.absent(),
                Value<String> unfinished = const Value.absent(),
                Value<DateTime?> createdAt = const Value.absent(),
              }) => TaskCheckCompanion(
                id: id,
                title: title,
                finished: finished,
                unfinished: unfinished,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String title,
                required String finished,
                required String unfinished,
                Value<DateTime?> createdAt = const Value.absent(),
              }) => TaskCheckCompanion.insert(
                id: id,
                title: title,
                finished: finished,
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
typedef $$RemindMessageTableCreateCompanionBuilder =
    RemindMessageCompanion Function({
      Value<int> id,
      required String content,
      required int level,
      required String source,
      required DateTime sentAt,
    });
typedef $$RemindMessageTableUpdateCompanionBuilder =
    RemindMessageCompanion Function({
      Value<int> id,
      Value<String> content,
      Value<int> level,
      Value<String> source,
      Value<DateTime> sentAt,
    });

class $$RemindMessageTableFilterComposer
    extends Composer<_$AppDatabase, $RemindMessageTable> {
  $$RemindMessageTableFilterComposer({
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

  ColumnFilters<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get level => $composableBuilder(
    column: $table.level,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get sentAt => $composableBuilder(
    column: $table.sentAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$RemindMessageTableOrderingComposer
    extends Composer<_$AppDatabase, $RemindMessageTable> {
  $$RemindMessageTableOrderingComposer({
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

  ColumnOrderings<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get level => $composableBuilder(
    column: $table.level,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get sentAt => $composableBuilder(
    column: $table.sentAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$RemindMessageTableAnnotationComposer
    extends Composer<_$AppDatabase, $RemindMessageTable> {
  $$RemindMessageTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumn<int> get level =>
      $composableBuilder(column: $table.level, builder: (column) => column);

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<DateTime> get sentAt =>
      $composableBuilder(column: $table.sentAt, builder: (column) => column);
}

class $$RemindMessageTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RemindMessageTable,
          RemindMessageData,
          $$RemindMessageTableFilterComposer,
          $$RemindMessageTableOrderingComposer,
          $$RemindMessageTableAnnotationComposer,
          $$RemindMessageTableCreateCompanionBuilder,
          $$RemindMessageTableUpdateCompanionBuilder,
          (
            RemindMessageData,
            BaseReferences<
              _$AppDatabase,
              $RemindMessageTable,
              RemindMessageData
            >,
          ),
          RemindMessageData,
          PrefetchHooks Function()
        > {
  $$RemindMessageTableTableManager(_$AppDatabase db, $RemindMessageTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RemindMessageTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RemindMessageTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RemindMessageTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> content = const Value.absent(),
                Value<int> level = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<DateTime> sentAt = const Value.absent(),
              }) => RemindMessageCompanion(
                id: id,
                content: content,
                level: level,
                source: source,
                sentAt: sentAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String content,
                required int level,
                required String source,
                required DateTime sentAt,
              }) => RemindMessageCompanion.insert(
                id: id,
                content: content,
                level: level,
                source: source,
                sentAt: sentAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$RemindMessageTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RemindMessageTable,
      RemindMessageData,
      $$RemindMessageTableFilterComposer,
      $$RemindMessageTableOrderingComposer,
      $$RemindMessageTableAnnotationComposer,
      $$RemindMessageTableCreateCompanionBuilder,
      $$RemindMessageTableUpdateCompanionBuilder,
      (
        RemindMessageData,
        BaseReferences<_$AppDatabase, $RemindMessageTable, RemindMessageData>,
      ),
      RemindMessageData,
      PrefetchHooks Function()
    >;
typedef $$ToDoMessageTableCreateCompanionBuilder =
    ToDoMessageCompanion Function({
      required String id,
      required bool finished,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$ToDoMessageTableUpdateCompanionBuilder =
    ToDoMessageCompanion Function({
      Value<String> id,
      Value<bool> finished,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$ToDoMessageTableFilterComposer
    extends Composer<_$AppDatabase, $ToDoMessageTable> {
  $$ToDoMessageTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get finished => $composableBuilder(
    column: $table.finished,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ToDoMessageTableOrderingComposer
    extends Composer<_$AppDatabase, $ToDoMessageTable> {
  $$ToDoMessageTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get finished => $composableBuilder(
    column: $table.finished,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ToDoMessageTableAnnotationComposer
    extends Composer<_$AppDatabase, $ToDoMessageTable> {
  $$ToDoMessageTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<bool> get finished =>
      $composableBuilder(column: $table.finished, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$ToDoMessageTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ToDoMessageTable,
          ToDoMessageData,
          $$ToDoMessageTableFilterComposer,
          $$ToDoMessageTableOrderingComposer,
          $$ToDoMessageTableAnnotationComposer,
          $$ToDoMessageTableCreateCompanionBuilder,
          $$ToDoMessageTableUpdateCompanionBuilder,
          (
            ToDoMessageData,
            BaseReferences<_$AppDatabase, $ToDoMessageTable, ToDoMessageData>,
          ),
          ToDoMessageData,
          PrefetchHooks Function()
        > {
  $$ToDoMessageTableTableManager(_$AppDatabase db, $ToDoMessageTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ToDoMessageTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ToDoMessageTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ToDoMessageTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<bool> finished = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ToDoMessageCompanion(
                id: id,
                finished: finished,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required bool finished,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => ToDoMessageCompanion.insert(
                id: id,
                finished: finished,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ToDoMessageTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ToDoMessageTable,
      ToDoMessageData,
      $$ToDoMessageTableFilterComposer,
      $$ToDoMessageTableOrderingComposer,
      $$ToDoMessageTableAnnotationComposer,
      $$ToDoMessageTableCreateCompanionBuilder,
      $$ToDoMessageTableUpdateCompanionBuilder,
      (
        ToDoMessageData,
        BaseReferences<_$AppDatabase, $ToDoMessageTable, ToDoMessageData>,
      ),
      ToDoMessageData,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$TaskCheckTableTableManager get taskCheck =>
      $$TaskCheckTableTableManager(_db, _db.taskCheck);
  $$RemindMessageTableTableManager get remindMessage =>
      $$RemindMessageTableTableManager(_db, _db.remindMessage);
  $$ToDoMessageTableTableManager get toDoMessage =>
      $$ToDoMessageTableTableManager(_db, _db.toDoMessage);
}
