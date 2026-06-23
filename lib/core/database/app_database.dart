import 'dart:convert';
import 'package:drift/drift.dart';
import 'sync_columns.dart';
import 'tables/antecedentes_nino_table.dart';
import 'tables/cached_session_table.dart';
import 'tables/hijos_table.dart';
import 'tables/sync_state_table.dart';
import '../session/entities.dart';
import '../session/session_cache.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [SyncStateRows, CachedSessionRows, HijosRows, AntecedentesNinoRows])
class AppDatabase extends _$AppDatabase implements SessionCache {
  AppDatabase(super.e);

  /// Constructor para tests; acepta cualquier [QueryExecutor], típicamente
  /// `NativeDatabase.memory()`. Mismo cuerpo que el principal, nombrado por claridad.
  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 6;

  // INVARIANTE DE MIGRACIONES: al subir schemaVersion, escribir acá el step
  // versionado correspondiente Y su test en migration_test.dart. Nunca bumpear
  // schemaVersion sin migración + test.
  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.createTable(
          cachedSessionRows,
        ); // v1 -> v2: tabla nueva, no destruye nada
      }
      if (from < 3) {
        await m.createTable(
          hijosRows,
        ); // v2 -> v3: tabla offline-first para hijos
      }
      if (from >= 2 && from < 4) {
        // Solo agregar columnas si la tabla ya existía (creada en v2).
        // Si from < 2, la tabla se crea recién con m.createTable y ya incluye
        // las columnas del schema actual (Drift genera siempre el DDL actual).
        await m.addColumn(cachedSessionRows, cachedSessionRows.tutorId);
        await m.addColumn(cachedSessionRows, cachedSessionRows.nombrePila);
        await m.addColumn(cachedSessionRows, cachedSessionRows.apellido);
        await m.addColumn(cachedSessionRows, cachedSessionRows.tipoDni);
        await m.addColumn(cachedSessionRows, cachedSessionRows.dni);
      }
      if (from >= 2 && from < 5) {
        // Solo agregar columnas si la tabla ya existía (creada en v2).
        // Si from < 2, la tabla se crea recién con m.createTable y ya incluye
        // las columnas del schema actual (Drift genera siempre el DDL actual).
        await m.addColumn(cachedSessionRows, cachedSessionRows.consentimientoAceptado);
        await m.addColumn(cachedSessionRows, cachedSessionRows.antecedentesFamiliaresCompletos);
      }
      if (from < 6) {
        await m.createTable(antecedentesNinoRows);
      }
      if (from >= 3 && from < 6) {
        await m.addColumn(hijosRows, hijosRows.serverPacienteId);
      }
    },
  );

  Future<void> setWatermark(String feature, DateTime ts) =>
      into(syncStateRows).insertOnConflictUpdate(
        SyncStateRowsCompanion.insert(
          feature: feature,
          lastSyncedAt: Value(ts),
        ),
      );

  Future<DateTime?> getWatermark(String feature) async {
    final row = await (select(
      syncStateRows,
    )..where((t) => t.feature.equals(feature))).getSingleOrNull();
    return row?.lastSyncedAt;
  }

  static const _meKey = 'me';

  @override
  Future<void> guardarSesion(
    Sesion s, {
    required String email,
    required String version,
    required String syncedAtIso,
  }) {
    return into(cachedSessionRows).insertOnConflictUpdate(
      CachedSessionRowsCompanion.insert(
        id: _meKey,
        userId: s.usuario.id,
        email: email,
        nombre: Value(s.usuario.nombre),
        rolName: s.usuario.rolName,
        rolLabel: s.usuario.rolLabel,
        accionesJson: jsonEncode(s.acciones.map((a) => a.toJson()).toList()),
        metaVersion: version,
        tutorId: Value(s.usuario.tutorId),
        nombrePila: Value(s.usuario.nombrePila),
        apellido: Value(s.usuario.apellido),
        tipoDni: Value(s.usuario.tipoDni),
        dni: Value(s.usuario.dni),
        consentimientoAceptado: Value(s.usuario.consentimientoAceptado),
        antecedentesFamiliaresCompletos: Value(s.usuario.antecedentesFamiliaresCompletos),
        permissionsSyncedAt: Value(DateTime.tryParse(syncedAtIso)?.toUtc()),
      ),
    );
  }

  Future<CachedSessionRow?> _meRow() => (select(
    cachedSessionRows,
  )..where((t) => t.id.equals(_meKey))).getSingleOrNull();

  @override
  Future<Sesion?> leerSesion() async {
    final row = await _meRow();
    if (row == null) return null;
    final acciones = (jsonDecode(row.accionesJson) as List)
        .map((j) => Accion.fromJson((j as Map).cast<String, dynamic>()))
        .toList();
    return Sesion(
      usuario: Usuario(
        id: row.userId,
        nombre: row.nombre ?? row.email,
        rolName: row.rolName,
        rolLabel: row.rolLabel,
        tutorId: row.tutorId,
        nombrePila: row.nombrePila,
        apellido: row.apellido,
        tipoDni: row.tipoDni,
        dni: row.dni,
        consentimientoAceptado: row.consentimientoAceptado,
        antecedentesFamiliaresCompletos: row.antecedentesFamiliaresCompletos,
      ),
      acciones: acciones,
    );
  }

  Future<String?> versionCacheada() async => (await _meRow())?.metaVersion;

  @override
  Future<void> limpiarSesion() =>
      (delete(cachedSessionRows)..where((t) => t.id.equals(_meKey))).go();

  Future<void> insertHijoDraft({
    required String id,
    required String tutorId,
    required String nombreNna,
    required String apellidoNna,
    required String payloadJson,
  }) => into(hijosRows).insert(
    HijosRowsCompanion.insert(
      id: id,
      tutorId: tutorId,
      nombreNna: Value(nombreNna),
      apellidoNna: Value(apellidoNna),
      payloadJson: payloadJson,
    ),
  );

  Future<int> contarHijosPendientes() async {
    final q = selectOnly(hijosRows)
      ..addColumns([hijosRows.id.count()])
      ..where(hijosRows.syncStatus.equalsValue(SyncStatus.pendiente));
    final row = await q.getSingle();
    return row.read(hijosRows.id.count()) ?? 0;
  }

  Future<int> contarHijos() async {
    final q = selectOnly(hijosRows)
      ..addColumns([hijosRows.id.count()])
      ..where(hijosRows.deletedAt.isNull());
    final row = await q.getSingle();
    return row.read(hijosRows.id.count()) ?? 0;
  }

  Future<List<HijosRow>> hijosPendientes() => (select(
    hijosRows,
  )..where((t) => t.syncStatus.equalsValue(SyncStatus.pendiente))).get();

  /// Stream reactivo de los hijos vivos (no borrados). Emite en cada cambio de
  /// la tabla → el badge de Pendientes se actualiza solo (alta, sync, baja).
  Stream<List<HijosRow>> watchHijosVivos() =>
      (select(hijosRows)..where((t) => t.deletedAt.isNull())).watch();

  Future<void> marcarHijoSincronizado(String id) =>
      (update(hijosRows)..where((t) => t.id.equals(id))).write(
        const HijosRowsCompanion(syncStatus: Value(SyncStatus.sincronizado)),
      );

  // ── Hijos: id de paciente del servidor ──────────────────────────────────
  Future<void> guardarServerPacienteId(String hijoLocalId, String serverPacienteId) =>
      (update(hijosRows)..where((t) => t.id.equals(hijoLocalId))).write(
        HijosRowsCompanion(serverPacienteId: Value(serverPacienteId)),
      );

  Future<HijosRow?> hijoPorId(String id) =>
      (select(hijosRows)..where((t) => t.id.equals(id))).getSingleOrNull();

  // ── Antecedentes del niño (offline-first) ───────────────────────────────
  Future<AntecedentesNinoRow?> antecedenteNinoPorHijo(String hijoLocalId) =>
      (select(antecedentesNinoRows)
            ..where((t) => t.hijoLocalId.equals(hijoLocalId) & t.deletedAt.isNull()))
          .getSingleOrNull();

  Future<void> upsertAntecedenteNinoDraft({
    required String id,
    required String hijoLocalId,
    required String payloadJson,
  }) async {
    final existente = await antecedenteNinoPorHijo(hijoLocalId);
    if (existente == null) {
      await into(antecedentesNinoRows).insert(
        AntecedentesNinoRowsCompanion.insert(
          id: id,
          hijoLocalId: hijoLocalId,
          payloadJson: payloadJson,
        ),
      );
    } else {
      await (update(antecedentesNinoRows)..where((t) => t.id.equals(existente.id))).write(
        AntecedentesNinoRowsCompanion(
          payloadJson: Value(payloadJson),
          syncStatus: const Value(SyncStatus.pendiente),
          updatedAt: Value(DateTime.now().toUtc()),
        ),
      );
    }
  }

  Future<List<AntecedentesNinoRow>> antecedentesNinoPendientes() =>
      (select(antecedentesNinoRows)
            ..where((t) => t.syncStatus.equalsValue(SyncStatus.pendiente)))
          .get();

  Future<void> marcarAntecedenteNinoSincronizado(String id) =>
      (update(antecedentesNinoRows)..where((t) => t.id.equals(id))).write(
        const AntecedentesNinoRowsCompanion(syncStatus: Value(SyncStatus.sincronizado)),
      );

  /// Hijos vivos + si ya tienen antecedentes del niño cargados (reactivo).
  Stream<List<({String id, String nombre, bool tieneAntecedentes})>>
      watchHijosConAntecedentes() {
    final q = select(hijosRows).join([
      leftOuterJoin(
        antecedentesNinoRows,
        antecedentesNinoRows.hijoLocalId.equalsExp(hijosRows.id) &
            antecedentesNinoRows.deletedAt.isNull(),
      ),
    ])..where(hijosRows.deletedAt.isNull());
    return q.watch().map((rows) => rows.map((r) {
          final hijo = r.readTable(hijosRows);
          final ant = r.readTableOrNull(antecedentesNinoRows);
          return (id: hijo.id, nombre: hijo.nombreNna, tieneAntecedentes: ant != null);
        }).toList());
  }
}
