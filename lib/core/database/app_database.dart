import 'dart:convert';
import 'package:drift/drift.dart';
import 'sync_columns.dart';
import 'tables/cached_session_table.dart';
import 'tables/hijos_table.dart';
import 'tables/sync_state_table.dart';
import '../session/entities.dart';
import '../session/session_cache.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [SyncStateRows, CachedSessionRows, HijosRows])
class AppDatabase extends _$AppDatabase implements SessionCache {
  AppDatabase(super.e);

  /// Constructor para tests; acepta cualquier [QueryExecutor], típicamente
  /// `NativeDatabase.memory()`. Mismo cuerpo que el principal, nombrado por claridad.
  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 3;

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
          if (from < 3) {
            await m.createTable(hijosRows); // v2 -> v3: tabla offline-first para hijos
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

  static const _meKey = 'me';

  @override
  Future<void> guardarSesion(Sesion s, {required String email, required String version, required String syncedAtIso}) {
    return into(cachedSessionRows).insertOnConflictUpdate(CachedSessionRowsCompanion.insert(
      id: _meKey,
      userId: s.usuario.id,
      email: email,
      nombre: Value(s.usuario.nombre),
      rolName: s.usuario.rolName,
      rolLabel: s.usuario.rolLabel,
      accionesJson: jsonEncode(s.acciones.map((a) => a.toJson()).toList()),
      metaVersion: version,
      permissionsSyncedAt: Value(DateTime.tryParse(syncedAtIso)?.toUtc()),
    ));
  }

  Future<CachedSessionRow?> _meRow() =>
      (select(cachedSessionRows)..where((t) => t.id.equals(_meKey))).getSingleOrNull();

  @override
  Future<Sesion?> leerSesion() async {
    final row = await _meRow();
    if (row == null) return null;
    final acciones = (jsonDecode(row.accionesJson) as List)
        .map((j) => Accion.fromJson((j as Map).cast<String, dynamic>()))
        .toList();
    return Sesion(
      usuario: Usuario(id: row.userId, nombre: row.nombre ?? row.email, rolName: row.rolName, rolLabel: row.rolLabel),
      acciones: acciones,
    );
  }

  Future<String?> versionCacheada() async => (await _meRow())?.metaVersion;

  @override
  Future<void> limpiarSesion() => (delete(cachedSessionRows)..where((t) => t.id.equals(_meKey))).go();
}
