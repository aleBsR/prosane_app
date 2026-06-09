// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $SyncStateRowsTable extends SyncStateRows
    with TableInfo<$SyncStateRowsTable, SyncStateRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncStateRowsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _featureMeta = const VerificationMeta(
    'feature',
  );
  @override
  late final GeneratedColumn<String> feature = GeneratedColumn<String>(
    'feature',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastSyncedAtMeta = const VerificationMeta(
    'lastSyncedAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastSyncedAt = GeneratedColumn<DateTime>(
    'last_synced_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [feature, lastSyncedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_state_rows';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncStateRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('feature')) {
      context.handle(
        _featureMeta,
        feature.isAcceptableOrUnknown(data['feature']!, _featureMeta),
      );
    } else if (isInserting) {
      context.missing(_featureMeta);
    }
    if (data.containsKey('last_synced_at')) {
      context.handle(
        _lastSyncedAtMeta,
        lastSyncedAt.isAcceptableOrUnknown(
          data['last_synced_at']!,
          _lastSyncedAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {feature};
  @override
  SyncStateRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncStateRow(
      feature: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}feature'],
      )!,
      lastSyncedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_synced_at'],
      ),
    );
  }

  @override
  $SyncStateRowsTable createAlias(String alias) {
    return $SyncStateRowsTable(attachedDatabase, alias);
  }
}

class SyncStateRow extends DataClass implements Insertable<SyncStateRow> {
  final String feature;
  final DateTime? lastSyncedAt;
  const SyncStateRow({required this.feature, this.lastSyncedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['feature'] = Variable<String>(feature);
    if (!nullToAbsent || lastSyncedAt != null) {
      map['last_synced_at'] = Variable<DateTime>(lastSyncedAt);
    }
    return map;
  }

  SyncStateRowsCompanion toCompanion(bool nullToAbsent) {
    return SyncStateRowsCompanion(
      feature: Value(feature),
      lastSyncedAt: lastSyncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSyncedAt),
    );
  }

  factory SyncStateRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncStateRow(
      feature: serializer.fromJson<String>(json['feature']),
      lastSyncedAt: serializer.fromJson<DateTime?>(json['lastSyncedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'feature': serializer.toJson<String>(feature),
      'lastSyncedAt': serializer.toJson<DateTime?>(lastSyncedAt),
    };
  }

  SyncStateRow copyWith({
    String? feature,
    Value<DateTime?> lastSyncedAt = const Value.absent(),
  }) => SyncStateRow(
    feature: feature ?? this.feature,
    lastSyncedAt: lastSyncedAt.present ? lastSyncedAt.value : this.lastSyncedAt,
  );
  SyncStateRow copyWithCompanion(SyncStateRowsCompanion data) {
    return SyncStateRow(
      feature: data.feature.present ? data.feature.value : this.feature,
      lastSyncedAt: data.lastSyncedAt.present
          ? data.lastSyncedAt.value
          : this.lastSyncedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncStateRow(')
          ..write('feature: $feature, ')
          ..write('lastSyncedAt: $lastSyncedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(feature, lastSyncedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncStateRow &&
          other.feature == this.feature &&
          other.lastSyncedAt == this.lastSyncedAt);
}

class SyncStateRowsCompanion extends UpdateCompanion<SyncStateRow> {
  final Value<String> feature;
  final Value<DateTime?> lastSyncedAt;
  final Value<int> rowid;
  const SyncStateRowsCompanion({
    this.feature = const Value.absent(),
    this.lastSyncedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncStateRowsCompanion.insert({
    required String feature,
    this.lastSyncedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : feature = Value(feature);
  static Insertable<SyncStateRow> custom({
    Expression<String>? feature,
    Expression<DateTime>? lastSyncedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (feature != null) 'feature': feature,
      if (lastSyncedAt != null) 'last_synced_at': lastSyncedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncStateRowsCompanion copyWith({
    Value<String>? feature,
    Value<DateTime?>? lastSyncedAt,
    Value<int>? rowid,
  }) {
    return SyncStateRowsCompanion(
      feature: feature ?? this.feature,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (feature.present) {
      map['feature'] = Variable<String>(feature.value);
    }
    if (lastSyncedAt.present) {
      map['last_synced_at'] = Variable<DateTime>(lastSyncedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncStateRowsCompanion(')
          ..write('feature: $feature, ')
          ..write('lastSyncedAt: $lastSyncedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $SyncStateRowsTable syncStateRows = $SyncStateRowsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [syncStateRows];
  @override
  DriftDatabaseOptions get options =>
      const DriftDatabaseOptions(storeDateTimeAsText: true);
}

typedef $$SyncStateRowsTableCreateCompanionBuilder =
    SyncStateRowsCompanion Function({
      required String feature,
      Value<DateTime?> lastSyncedAt,
      Value<int> rowid,
    });
typedef $$SyncStateRowsTableUpdateCompanionBuilder =
    SyncStateRowsCompanion Function({
      Value<String> feature,
      Value<DateTime?> lastSyncedAt,
      Value<int> rowid,
    });

class $$SyncStateRowsTableFilterComposer
    extends Composer<_$AppDatabase, $SyncStateRowsTable> {
  $$SyncStateRowsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get feature => $composableBuilder(
    column: $table.feature,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SyncStateRowsTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncStateRowsTable> {
  $$SyncStateRowsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get feature => $composableBuilder(
    column: $table.feature,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SyncStateRowsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncStateRowsTable> {
  $$SyncStateRowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get feature =>
      $composableBuilder(column: $table.feature, builder: (column) => column);

  GeneratedColumn<DateTime> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => column,
  );
}

class $$SyncStateRowsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SyncStateRowsTable,
          SyncStateRow,
          $$SyncStateRowsTableFilterComposer,
          $$SyncStateRowsTableOrderingComposer,
          $$SyncStateRowsTableAnnotationComposer,
          $$SyncStateRowsTableCreateCompanionBuilder,
          $$SyncStateRowsTableUpdateCompanionBuilder,
          (
            SyncStateRow,
            BaseReferences<_$AppDatabase, $SyncStateRowsTable, SyncStateRow>,
          ),
          SyncStateRow,
          PrefetchHooks Function()
        > {
  $$SyncStateRowsTableTableManager(_$AppDatabase db, $SyncStateRowsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncStateRowsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncStateRowsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncStateRowsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> feature = const Value.absent(),
                Value<DateTime?> lastSyncedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncStateRowsCompanion(
                feature: feature,
                lastSyncedAt: lastSyncedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String feature,
                Value<DateTime?> lastSyncedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncStateRowsCompanion.insert(
                feature: feature,
                lastSyncedAt: lastSyncedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncStateRowsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SyncStateRowsTable,
      SyncStateRow,
      $$SyncStateRowsTableFilterComposer,
      $$SyncStateRowsTableOrderingComposer,
      $$SyncStateRowsTableAnnotationComposer,
      $$SyncStateRowsTableCreateCompanionBuilder,
      $$SyncStateRowsTableUpdateCompanionBuilder,
      (
        SyncStateRow,
        BaseReferences<_$AppDatabase, $SyncStateRowsTable, SyncStateRow>,
      ),
      SyncStateRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$SyncStateRowsTableTableManager get syncStateRows =>
      $$SyncStateRowsTableTableManager(_db, _db.syncStateRows);
}
