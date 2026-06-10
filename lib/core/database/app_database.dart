import 'package:drift/drift.dart';
import 'tables/cached_session_table.dart';
import 'tables/sync_state_table.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [SyncStateRows, CachedSessionRows])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  /// Constructor para tests; acepta cualquier [QueryExecutor], típicamente
  /// `NativeDatabase.memory()`. Mismo cuerpo que el principal, nombrado por claridad.
  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 2;

  // INVARIANTE DE MIGRACIONES: al subir schemaVersion, escribir acá el step
  // versionado correspondiente Y su test en migration_test.dart. Nunca bumpear
  // schemaVersion sin migración + test.
  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.createTable(cachedSessionRows); // v1 -> v2: tabla nueva, no destruye nada
          }
        },
      );

  Future<void> setWatermark(String feature, DateTime ts) =>
      into(syncStateRows).insertOnConflictUpdate(
        SyncStateRowsCompanion.insert(feature: feature, lastSyncedAt: Value(ts)),
      );

  Future<DateTime?> getWatermark(String feature) async {
    final row = await (select(syncStateRows)..where((t) => t.feature.equals(feature)))
        .getSingleOrNull();
    return row?.lastSyncedAt;
  }
}
