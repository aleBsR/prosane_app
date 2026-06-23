# Entrega 2 — Antecedentes de salud del niño — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax.

**Goal:** Pantalla per-hijo para cargar los antecedentes de salud del niño (20 campos de `AntecedentePersonal`), offline-first con su propia tabla + syncer, su pendiente por hijo, y captura del id de paciente al sincronizar el hijo.

**Architecture:** Espeja el patrón `HijosRows`+`HijosSyncer`. Tabla Drift `AntecedentesNinoRows` (1 por hijo, upsert por `hijoLocalId`). `HijosSyncer` captura el `serverPacienteId` del `201`. `AntecedentesNinoSyncer` postea a `/tutores/<t>/hijos/<serverPacienteId>/antecedentes-personales/` cuando el hijo ya tiene id. Pendiente por hijo sin antecedentes (detección local reactiva).

**Tech Stack:** Flutter, Riverpod (StateNotifier + family), Drift (codegen + migraciones), dio, go_router, flutter_test.

**Spec:** `docs/superpowers/specs/2026-06-23-antecedentes-salud-nino-design.md`

**Backend:** depende del endpoint nuevo `…/tutores/<pk>/hijos/<paciente_id>/antecedentes-personales/` (handoff en el spec). El front funciona offline sin él; sincroniza cuando exista.

---

## File Structure

- `lib/core/database/tables/antecedentes_nino_table.dart` — **crear**: tabla `AntecedentesNinoRows`.
- `lib/core/database/tables/hijos_table.dart` — **modificar**: agregar `serverPacienteId`.
- `lib/core/database/app_database.dart` — **modificar**: registrar tabla, schemaVersion 6, migración, métodos.
- `lib/features/hijos/data/hijos_syncer.dart` — **modificar**: capturar `serverPacienteId`.
- `lib/features/hijos/data/antecedentes_nino_syncer.dart` — **crear**: syncer nuevo.
- `lib/core/providers.dart` — **modificar**: provider del syncer + agregarlo al `SyncEngine`.
- `lib/features/hijos/presentation/controllers/antecedentes_nino_controller.dart` — **crear**.
- `lib/features/hijos/presentation/screens/antecedentes_nino_screen.dart` — **crear**.
- `lib/core/router/app_router.dart` — **modificar**: ruta `/hijos/:hijoLocalId/antecedentes`.
- `lib/features/pendientes/pendientes_count_provider.dart` — **modificar**: pendiente por hijo sin antecedentes.
- Tests espejo en `test/...`.

---

### Task 1: Esquema Drift (tabla nueva + serverPacienteId + migración 5→6)

**Files:**
- Create: `lib/core/database/tables/antecedentes_nino_table.dart`
- Modify: `lib/core/database/tables/hijos_table.dart`
- Modify: `lib/core/database/app_database.dart`
- Test: `test/core/database/migration_test.dart`

- [ ] **Step 1: Crear la tabla nueva**

`lib/core/database/tables/antecedentes_nino_table.dart`:
```dart
import 'package:drift/drift.dart';
import '../sync_columns.dart';

/// Antecedentes de salud de un niño (Paciente), cargados por el tutor DESPUÉS
/// del alta. Offline-first: un borrador local por hijo (upsert por hijoLocalId)
/// que el AntecedentesNinoSyncer empuja al endpoint per-paciente cuando el hijo
/// ya tiene su id de servidor.
class AntecedentesNinoRows extends Table with SyncColumns {
  TextColumn get hijoLocalId => text()(); // id local del HijosRow
  TextColumn get payloadJson => text()();  // body del POST de antecedentes
}
```

- [ ] **Step 2: Agregar `serverPacienteId` a HijosRows**

En `lib/core/database/tables/hijos_table.dart`, agregar la columna al final de la clase:
```dart
  /// Id del Paciente que devolvió el backend en el 201 del alta. Lo necesita el
  /// AntecedentesNinoSyncer para postear los antecedentes de ese paciente.
  TextColumn get serverPacienteId => text().nullable()();
```

- [ ] **Step 3: Registrar tabla, bump schema y migración en app_database.dart**

En `lib/core/database/app_database.dart`:

1. Import nuevo (junto a los otros de `tables/`):
```dart
import 'tables/antecedentes_nino_table.dart';
```
2. Agregar la tabla al `@DriftDatabase`:
```dart
@DriftDatabase(tables: [SyncStateRows, CachedSessionRows, HijosRows, AntecedentesNinoRows])
```
3. Subir la versión:
```dart
  @override
  int get schemaVersion => 6;
```
4. En `onUpgrade`, agregar al final (dentro del cuerpo, después del bloque `if (from >= 2 && from < 5)`):
```dart
      if (from < 6) {
        // Tabla nueva (no existía antes de v6).
        await m.createTable(antecedentesNinoRows);
      }
      if (from >= 3 && from < 6) {
        // serverPacienteId: solo si HijosRows ya existía (creada en v3). Si from < 3,
        // la tabla se crea recién con m.createTable y ya incluye la columna.
        await m.addColumn(hijosRows, hijosRows.serverPacienteId);
      }
```

- [ ] **Step 4: Regenerar el código Drift**

Run: `dart run build_runner build --delete-conflicting-outputs`
Expected: regenera `app_database.g.dart` con `AntecedentesNinoRows`/`AntecedentesNinoRow`/`AntecedentesNinoRowsCompanion` y `serverPacienteId` en `HijosRow`. Sin errores.

- [ ] **Step 5: Volcar el esquema v6 y regenerar el verificador de migraciones**

Run (igual que se generaron los esquemas previos del proyecto):
```bash
dart run drift_dev schema dump lib/core/database/app_database.dart test/core/database/generated_migrations/
dart run drift_dev schema generate test/core/database/generated_migrations/ test/core/database/generated_migrations/
```
Expected: aparece `drift_schema_v6.json` + `schema_v6.dart` y `schema.dart` (GeneratedHelper) incluye v6. (Si los nombres/rutas difieren, replicar cómo está hecho v5 en ese directorio.)

- [ ] **Step 6: Escribir el test de migración 5→6**

Agregar al final de `void main()` en `test/core/database/migration_test.dart`:
```dart
  test('migración v5→v6 crea antecedentes_nino_rows y agrega server_paciente_id a hijos_rows', () async {
    final schema = await verifier.schemaAt(5);
    // Semilla en v5: un hijo, para verificar que sobrevive y acepta la columna nueva.
    schema.rawDatabase.execute(
      "INSERT INTO hijos_rows (id, updated_at, tutor_id, nombre_nna, apellido_nna, payload_json, sync_status) "
      "VALUES ('h1', '2026-06-23T00:00:00.000Z', 'tut-1', 'Juan', 'Pérez', '{\"persona\":{\"sexo\":\"M\"}}', 0)",
    );

    final db = AppDatabase(schema.newConnection());
    await verifier.migrateAndValidate(db, 6);

    // server_paciente_id existe y acepta valor.
    await db.customStatement("UPDATE hijos_rows SET server_paciente_id='pac-1' WHERE id='h1'");
    final hijo = await db.customSelect("SELECT server_paciente_id FROM hijos_rows WHERE id='h1'").getSingle();
    expect(hijo.data['server_paciente_id'], 'pac-1');

    // antecedentes_nino_rows existe y acepta una fila.
    await db.customStatement(
      "INSERT INTO antecedentes_nino_rows (id, updated_at, hijo_local_id, payload_json, sync_status) "
      "VALUES ('a1', '2026-06-23T00:00:00.000Z', 'h1', '{}', 0)",
    );
    final n = await db.customSelect('SELECT COUNT(*) AS c FROM antecedentes_nino_rows').getSingle();
    expect(n.data['c'], 1);

    // El hijo sembrado en v5 sobrevivió.
    final hijos = await db.customSelect('SELECT COUNT(*) AS c FROM hijos_rows').getSingle();
    expect(hijos.data['c'], 1, reason: 'hijos_rows debe sobrevivir la migración v5→v6');

    await db.close();
  });
```

- [ ] **Step 7: Correr el test de migración**

Run: `flutter test test/core/database/migration_test.dart`
Expected: PASS (incluye el nuevo v5→v6).

- [ ] **Step 8: Commit**
```bash
git add lib/core/database test/core/database
git commit -m "feat(db): tabla antecedentes_nino + serverPacienteId en hijos + migracion v6"
```

---

### Task 2: Métodos de base de datos

**Files:**
- Modify: `lib/core/database/app_database.dart`
- Test: `test/core/database/antecedentes_nino_db_test.dart`

- [ ] **Step 1: Escribir el test (debe fallar)**

`test/core/database/antecedentes_nino_db_test.dart`:
```dart
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prosane_app/core/database/app_database.dart';

void main() {
  late AppDatabase db;
  setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() => db.close());

  Future<void> seedHijo(String id, {String? serverPacienteId}) async {
    await db.insertHijoDraft(
      id: id, tutorId: 'tut-1', nombreNna: 'Juan', apellidoNna: 'Pérez',
      payloadJson: '{"persona":{"sexo":"F"}}',
    );
    if (serverPacienteId != null) {
      await db.guardarServerPacienteId(id, serverPacienteId);
    }
  }

  test('upsert: inserta y luego actualiza el MISMO registro por hijoLocalId', () async {
    await seedHijo('h1');
    await db.upsertAntecedenteNinoDraft(id: 'a1', hijoLocalId: 'h1', payloadJson: '{"diabetes":"no"}');
    var row = await db.antecedenteNinoPorHijo('h1');
    expect(row!.payloadJson, '{"diabetes":"no"}');

    await db.upsertAntecedenteNinoDraft(id: 'a2', hijoLocalId: 'h1', payloadJson: '{"diabetes":"si"}');
    final todos = await db.antecedentesNinoPendientes();
    expect(todos.length, 1, reason: 'upsert: no duplica por hijo');
    row = await db.antecedenteNinoPorHijo('h1');
    expect(row!.payloadJson, '{"diabetes":"si"}');
  });

  test('guardarServerPacienteId persiste el id y hijoPorId lo lee', () async {
    await seedHijo('h1', serverPacienteId: 'pac-99');
    final h = await db.hijoPorId('h1');
    expect(h!.serverPacienteId, 'pac-99');
  });

  test('watchHijosConAntecedentes marca tieneAntecedentes', () async {
    await seedHijo('h1');
    await seedHijo('h2');
    await db.upsertAntecedenteNinoDraft(id: 'a1', hijoLocalId: 'h1', payloadJson: '{}');
    final lista = await db.watchHijosConAntecedentes().first;
    final h1 = lista.firstWhere((e) => e.id == 'h1');
    final h2 = lista.firstWhere((e) => e.id == 'h2');
    expect(h1.tieneAntecedentes, isTrue);
    expect(h2.tieneAntecedentes, isFalse);
  });
}
```

- [ ] **Step 2: Correr y verificar que falla**

Run: `flutter test test/core/database/antecedentes_nino_db_test.dart`
Expected: FAIL (métodos inexistentes).

- [ ] **Step 3: Implementar los métodos**

En `lib/core/database/app_database.dart`, agregar antes del cierre de la clase:
```dart
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
```

- [ ] **Step 4: Correr y verificar que pasa**

Run: `flutter test test/core/database/antecedentes_nino_db_test.dart`
Expected: PASS (3 tests).

- [ ] **Step 5: Commit**
```bash
git add lib/core/database/app_database.dart test/core/database/antecedentes_nino_db_test.dart
git commit -m "feat(db): metodos upsert/query de antecedentes_nino + serverPacienteId + watch reactivo"
```

---

### Task 3: HijosSyncer captura el serverPacienteId

**Files:**
- Modify: `lib/features/hijos/data/hijos_syncer.dart`
- Test: `test/features/hijos/hijos_syncer_test.dart`

- [ ] **Step 1: Agregar el test de captura (debe fallar)**

Agregar este test dentro del `main()` de `test/features/hijos/hijos_syncer_test.dart` (reusa el estilo del archivo; usa `http_mock_adapter` como los demás tests del archivo — si la firma del helper difiere, adaptarla al patrón existente del archivo):
```dart
  test('pushLote captura el id del paciente del 201 (serverPacienteId)', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final dio = Dio(BaseOptions(baseUrl: 'http://x/api/v1'));
    final mock = DioAdapter(dio: dio);
    await db.insertHijoDraft(
      id: 'h1', tutorId: 'tut-1', nombreNna: 'Juan', apellidoNna: 'Pérez',
      payloadJson: '{"persona":{"dni":"1"}}',
    );
    mock.onPost('/tutores/tut-1/hijos/', (s) => s.reply(201, {'id': 'pac-1'}));

    final syncer = HijosSyncer(db, dio);
    final res = await syncer.pushLote(['h1']);

    expect(res.single.outcome, PushOutcome.ok);
    final hijo = await db.hijoPorId('h1');
    expect(hijo!.serverPacienteId, 'pac-1');
  });
```
(Asegurar los imports: `package:dio/dio.dart`, `package:http_mock_adapter/http_mock_adapter.dart`, `package:drift/native.dart`, `app_database.dart`, `feature_syncer.dart`, `hijos_syncer.dart`.)

- [ ] **Step 2: Correr y verificar que falla**

Run: `flutter test test/features/hijos/hijos_syncer_test.dart`
Expected: FAIL (`serverPacienteId` queda null).

- [ ] **Step 3: Capturar el id en `pushLote`**

En `lib/features/hijos/data/hijos_syncer.dart`, dentro del `try` de `pushLote`, reemplazar:
```dart
        await _dio.post('/tutores/${row.tutorId}/hijos/', data: body);
        results.add(PushItemResult(row.id, PushOutcome.ok));
```
por:
```dart
        final resp = await _dio.post('/tutores/${row.tutorId}/hijos/', data: body);
        final pacienteId = (resp.data is Map) ? (resp.data as Map)['id'] as String? : null;
        if (pacienteId != null && pacienteId.isNotEmpty) {
          await _db.guardarServerPacienteId(row.id, pacienteId);
        }
        results.add(PushItemResult(row.id, PushOutcome.ok));
```

- [ ] **Step 4: Correr y verificar que pasa**

Run: `flutter test test/features/hijos/hijos_syncer_test.dart`
Expected: PASS (incluye el nuevo y los previos).

- [ ] **Step 5: Commit**
```bash
git add lib/features/hijos/data/hijos_syncer.dart test/features/hijos/hijos_syncer_test.dart
git commit -m "feat(sync): HijosSyncer captura el id del paciente del 201"
```

---

### Task 4: AntecedentesNinoSyncer + wiring

**Files:**
- Create: `lib/features/hijos/data/antecedentes_nino_syncer.dart`
- Modify: `lib/core/providers.dart`
- Test: `test/features/hijos/antecedentes_nino_syncer_test.dart`

- [ ] **Step 1: Escribir el test (debe fallar)**

`test/features/hijos/antecedentes_nino_syncer_test.dart`:
```dart
import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:prosane_app/core/database/app_database.dart';
import 'package:prosane_app/core/sync/feature_syncer.dart';
import 'package:prosane_app/features/hijos/data/antecedentes_nino_syncer.dart';

void main() {
  late AppDatabase db;
  late Dio dio;
  late DioAdapter mock;
  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    dio = Dio(BaseOptions(baseUrl: 'http://x/api/v1'));
    mock = DioAdapter(dio: dio);
  });
  tearDown(() => db.close());

  Future<void> seedHijo(String id, {String? serverPacienteId}) => db
      .insertHijoDraft(id: id, tutorId: 'tut-1', nombreNna: 'J', apellidoNna: 'P', payloadJson: '{}')
      .then((_) => serverPacienteId == null
          ? Future.value()
          : db.guardarServerPacienteId(id, serverPacienteId));

  test('si el hijo no tiene serverPacienteId, queda transitorio (espera)', () async {
    await seedHijo('h1'); // sin id de servidor
    await db.upsertAntecedenteNinoDraft(id: 'a1', hijoLocalId: 'h1', payloadJson: '{"diabetes":"no"}');
    final res = await AntecedentesNinoSyncer(db, dio).pushLote(['a1']);
    expect(res.single.outcome, PushOutcome.transitorio);
  });

  test('si el hijo ya tiene serverPacienteId, postea al endpoint y queda ok', () async {
    await seedHijo('h1', serverPacienteId: 'pac-9');
    await db.upsertAntecedenteNinoDraft(id: 'a1', hijoLocalId: 'h1', payloadJson: '{"diabetes":"si"}');
    mock.onPost('/tutores/tut-1/hijos/pac-9/antecedentes-personales/', (s) => s.reply(200, {'ok': true}));
    final res = await AntecedentesNinoSyncer(db, dio).pushLote(['a1']);
    expect(res.single.outcome, PushOutcome.ok);
  });
}
```

- [ ] **Step 2: Correr y verificar que falla**

Run: `flutter test test/features/hijos/antecedentes_nino_syncer_test.dart`
Expected: FAIL (clase inexistente).

- [ ] **Step 3: Crear el syncer**

`lib/features/hijos/data/antecedentes_nino_syncer.dart`:
```dart
import 'dart:convert';
import 'package:dio/dio.dart';
import '../../../core/database/app_database.dart';
import '../../../core/sync/feature_syncer.dart';

/// Pushea borradores de antecedentes del niño. Espera a que el hijo tenga su
/// serverPacienteId (lo captura el HijosSyncer) y postea a:
/// `<host>/api/v1/tutores/<tutorId>/hijos/<serverPacienteId>/antecedentes-personales/`.
class AntecedentesNinoSyncer implements FeatureSyncer {
  AntecedentesNinoSyncer(this._db, this._dio);
  final AppDatabase _db;
  final Dio _dio;

  @override
  String get feature => 'antecedentes_nino';

  @override
  Future<List<String>> idsPendientes() async =>
      (await _db.antecedentesNinoPendientes()).map((r) => r.id).toList();

  @override
  Future<List<PushItemResult>> pushLote(List<String> ids) async {
    final pendientes = await _db.antecedentesNinoPendientes();
    final results = <PushItemResult>[];
    for (final row in pendientes.where((r) => ids.contains(r.id))) {
      final hijo = await _db.hijoPorId(row.hijoLocalId);
      // El hijo todavía no sincronizó (sin id de paciente): reintentar luego.
      if (hijo == null || hijo.serverPacienteId == null || hijo.serverPacienteId!.isEmpty) {
        results.add(PushItemResult(row.id, PushOutcome.transitorio));
        continue;
      }
      try {
        final body = jsonDecode(row.payloadJson) as Map<String, dynamic>;
        await _dio.post(
          '/tutores/${hijo.tutorId}/hijos/${hijo.serverPacienteId}/antecedentes-personales/',
          data: body,
        );
        results.add(PushItemResult(row.id, PushOutcome.ok));
      } on DioException catch (e) {
        final code = e.response?.statusCode ?? 0;
        results.add(PushItemResult(
          row.id,
          code >= 400 && code < 500 ? PushOutcome.permanente : PushOutcome.transitorio,
        ));
      }
    }
    return results;
  }

  @override
  Future<void> marcarSincronizado(String id) => _db.marcarAntecedenteNinoSincronizado(id);

  @override
  Future<DateTime?> getWatermark() => _db.getWatermark(feature);
  @override
  Future<void> setWatermark(DateTime ts) => _db.setWatermark(feature, ts);
  @override
  Future<void> pullDesdeYMergear(DateTime? since) async {} // v1: push-only
}
```

- [ ] **Step 4: Cablear en providers**

En `lib/core/providers.dart`:
1. Import: `import '../features/hijos/data/antecedentes_nino_syncer.dart';`
2. Después de `hijosSyncerProvider`:
```dart
final antecedentesNinoSyncerProvider = Provider<AntecedentesNinoSyncer>(
  (ref) => AntecedentesNinoSyncer(ref.watch(databaseProvider), ref.watch(dioV1Provider)),
);
```
3. Reemplazar `syncEngineProvider` por (hijos PRIMERO, así captura el id en el mismo ciclo):
```dart
final syncEngineProvider = Provider<SyncEngine>(
  (ref) => SyncEngine([
    ref.watch(hijosSyncerProvider),
    ref.watch(antecedentesNinoSyncerProvider),
  ]),
);
```

- [ ] **Step 5: Correr tests + analyze**

Run: `flutter test test/features/hijos/antecedentes_nino_syncer_test.dart && flutter analyze lib`
Expected: PASS (2 tests) y analyze sin issues.

- [ ] **Step 6: Commit**
```bash
git add lib/features/hijos/data/antecedentes_nino_syncer.dart lib/core/providers.dart test/features/hijos/antecedentes_nino_syncer_test.dart
git commit -m "feat(sync): AntecedentesNinoSyncer (espera el id del hijo) + wiring en el engine"
```

---

### Task 5: AntecedentesNinoController

**Files:**
- Create: `lib/features/hijos/presentation/controllers/antecedentes_nino_controller.dart`
- Test: `test/features/hijos/antecedentes_nino_controller_test.dart`

- [ ] **Step 1: Escribir el test (debe fallar)**

`test/features/hijos/antecedentes_nino_controller_test.dart`:
```dart
import 'dart:convert';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prosane_app/core/database/app_database.dart';
import 'package:prosane_app/features/hijos/presentation/controllers/antecedentes_nino_controller.dart';

void main() {
  Future<AppDatabase> dbConHijo({String sexo = 'F'}) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    await db.insertHijoDraft(
      id: 'h1', tutorId: 'tut-1', nombreNna: 'Ana', apellidoNna: 'Pérez',
      payloadJson: jsonEncode({'persona': {'sexo': sexo}}),
    );
    return db;
  }

  test('guardar arma el payload de los 20 campos y hace upsert', () async {
    final db = await dbConHijo();
    final ctrl = AntecedentesNinoController(db: db, hijoLocalId: 'h1', generarId: () => 'a1');
    await ctrl.listo; // espera la precarga inicial
    ctrl.setCampo('diabetes', 'si');
    ctrl.setPesoNacimiento('3.4');
    ctrl.setEdadMenstruacion('12');
    await ctrl.guardar();

    final row = await db.antecedenteNinoPorHijo('h1');
    final body = jsonDecode(row!.payloadJson) as Map<String, dynamic>;
    expect(body['diabetes'], 'si');
    expect(body['peso_nacimiento'], '3.4');
    expect(body['edad_primera_menstruacion'], 12);
    expect(body.containsKey('nacio_prematuro'), isTrue);
    expect(ctrl.state.exito, isTrue);
    await db.close();
  });

  test('precarga: lee el borrador existente', () async {
    final db = await dbConHijo();
    await db.upsertAntecedenteNinoDraft(
      id: 'a0', hijoLocalId: 'h1', payloadJson: jsonEncode({'diabetes': 'si', 'peso_nacimiento': '2.9'}),
    );
    final ctrl = AntecedentesNinoController(db: db, hijoLocalId: 'h1', generarId: () => 'a1');
    await ctrl.listo;
    expect(ctrl.state.respuestas['diabetes'], 'si');
    expect(ctrl.state.pesoNacimiento, '2.9');
    await db.close();
  });

  test('esFemenino refleja el sexo del hijo', () async {
    final db = await dbConHijo(sexo: 'M');
    final ctrl = AntecedentesNinoController(db: db, hijoLocalId: 'h1', generarId: () => 'a1');
    await ctrl.listo;
    expect(ctrl.state.esFemenino, isFalse);
    await db.close();
  });
}
```

- [ ] **Step 2: Correr y verificar que falla**

Run: `flutter test test/features/hijos/antecedentes_nino_controller_test.dart`
Expected: FAIL (clase inexistente).

- [ ] **Step 3: Implementar el controller**

`lib/features/hijos/presentation/controllers/antecedentes_nino_controller.dart`:
```dart
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/database/database_provider.dart';

/// Las 18 preguntas Sí/No/No sabe (clave = campo del backend).
const camposSiNoNoSabe = <String>[
  'nacio_prematuro',
  'convulsiones_epilepsia',
  'mareos_desmayos',
  'infecciones_urinarias',
  'asma_espasmos',
  'tuberculosis',
  'diabetes',
  'hipertension',
  'cardiopatia_congenita',
  'traumatismo_internacion',
  'diarrea_frecuente',
  'infecciones_oido',
  'rabia_tratamiento',
  'primera_menstruacion',
];

class AntecedentesNinoState {
  const AntecedentesNinoState({
    this.respuestas = const {},
    this.pesoNacimiento = '',
    this.causaHospitalizacion = '',
    this.descripcionTratamiento = '',
    this.ultimaConsultaMedica = '',
    this.otrosProblemasSalud = '',
    this.edadMenstruacion = '',
    this.esFemenino = false,
    this.cargando = true,
    this.guardando = false,
    this.exito = false,
    this.error,
  });

  final Map<String, String> respuestas; // campo Sí/No/No sabe -> 'si'|'no'|'no_sabe'
  final String pesoNacimiento, causaHospitalizacion, descripcionTratamiento,
      ultimaConsultaMedica, otrosProblemasSalud, edadMenstruacion;
  final bool esFemenino, cargando, guardando, exito;
  final String? error;

  String respuesta(String campo) => respuestas[campo] ?? '';
  bool get recibeTratamiento => respuesta('rabia_tratamiento') == 'si';
  bool get tuvoMenstruacion => respuesta('primera_menstruacion') == 'si';

  AntecedentesNinoState copyWith({
    Map<String, String>? respuestas,
    String? pesoNacimiento,
    String? causaHospitalizacion,
    String? descripcionTratamiento,
    String? ultimaConsultaMedica,
    String? otrosProblemasSalud,
    String? edadMenstruacion,
    bool? esFemenino,
    bool? cargando,
    bool? guardando,
    bool? exito,
    Object? error = _sentinel,
  }) =>
      AntecedentesNinoState(
        respuestas: respuestas ?? this.respuestas,
        pesoNacimiento: pesoNacimiento ?? this.pesoNacimiento,
        causaHospitalizacion: causaHospitalizacion ?? this.causaHospitalizacion,
        descripcionTratamiento: descripcionTratamiento ?? this.descripcionTratamiento,
        ultimaConsultaMedica: ultimaConsultaMedica ?? this.ultimaConsultaMedica,
        otrosProblemasSalud: otrosProblemasSalud ?? this.otrosProblemasSalud,
        edadMenstruacion: edadMenstruacion ?? this.edadMenstruacion,
        esFemenino: esFemenino ?? this.esFemenino,
        cargando: cargando ?? this.cargando,
        guardando: guardando ?? this.guardando,
        exito: exito ?? this.exito,
        error: identical(error, _sentinel) ? this.error : error as String?,
      );
}

const _sentinel = Object();

class AntecedentesNinoController extends StateNotifier<AntecedentesNinoState> {
  AntecedentesNinoController({
    required AppDatabase db,
    required this.hijoLocalId,
    String Function()? generarId,
  })  : _db = db,
        _generarId = generarId ?? (() => const Uuid().v4()),
        super(const AntecedentesNinoState()) {
    listo = _cargar();
  }

  final AppDatabase _db;
  final String hijoLocalId;
  final String Function() _generarId;

  /// Future de la precarga inicial (para tests).
  late final Future<void> listo;

  void setCampo(String campo, String valor) {
    if (!mounted) return;
    state = state.copyWith(respuestas: {...state.respuestas, campo: valor});
  }

  void setPesoNacimiento(String v) => state = state.copyWith(pesoNacimiento: v);
  void setCausaHospitalizacion(String v) => state = state.copyWith(causaHospitalizacion: v);
  void setDescripcionTratamiento(String v) => state = state.copyWith(descripcionTratamiento: v);
  void setUltimaConsultaMedica(String v) => state = state.copyWith(ultimaConsultaMedica: v);
  void setOtrosProblemasSalud(String v) => state = state.copyWith(otrosProblemasSalud: v);
  void setEdadMenstruacion(String v) => state = state.copyWith(edadMenstruacion: v);

  Future<void> _cargar() async {
    final hijo = await _db.hijoPorId(hijoLocalId);
    var esF = false;
    if (hijo != null) {
      final p = jsonDecode(hijo.payloadJson) as Map<String, dynamic>;
      esF = ((p['persona'] as Map?)?['sexo'] as String?) == 'F';
    }
    final draft = await _db.antecedenteNinoPorHijo(hijoLocalId);
    if (!mounted) return;
    if (draft == null) {
      state = state.copyWith(esFemenino: esF, cargando: false);
      return;
    }
    final body = jsonDecode(draft.payloadJson) as Map<String, dynamic>;
    final respuestas = <String, String>{
      for (final c in camposSiNoNoSabe)
        if (body[c] is String) c: body[c] as String,
    };
    state = state.copyWith(
      esFemenino: esF,
      respuestas: respuestas,
      pesoNacimiento: (body['peso_nacimiento'] as String?) ?? '',
      causaHospitalizacion: (body['causa_hospitalizacion'] as String?) ?? '',
      descripcionTratamiento: (body['descripcion_tratamiento'] as String?) ?? '',
      ultimaConsultaMedica: (body['ultima_consulta_medica'] as String?) ?? '',
      otrosProblemasSalud: (body['otros_problemas_salud'] as String?) ?? '',
      edadMenstruacion: (body['edad_primera_menstruacion'] is int)
          ? '${body['edad_primera_menstruacion']}'
          : '',
      cargando: false,
    );
  }

  Map<String, dynamic> _payload() {
    final s = state;
    String resp(String c) => s.respuesta(c).isEmpty ? 'no_sabe' : s.respuesta(c);
    return {
      for (final c in camposSiNoNoSabe) c: resp(c),
      'peso_nacimiento': s.pesoNacimiento,
      'causa_hospitalizacion': s.causaHospitalizacion,
      'descripcion_tratamiento': s.recibeTratamiento ? s.descripcionTratamiento : '',
      'ultima_consulta_medica': s.ultimaConsultaMedica,
      'otros_problemas_salud': s.otrosProblemasSalud,
      'edad_primera_menstruacion':
          (s.tuvoMenstruacion) ? (int.tryParse(s.edadMenstruacion) ?? 0) : 0,
    };
  }

  Future<void> guardar() async {
    state = state.copyWith(guardando: true, error: null);
    try {
      await _db.upsertAntecedenteNinoDraft(
        id: _generarId(),
        hijoLocalId: hijoLocalId,
        payloadJson: jsonEncode(_payload()),
      );
      if (!mounted) return;
      state = state.copyWith(guardando: false, exito: true);
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(guardando: false, error: 'No se pudieron guardar. Probá de nuevo.');
    }
  }
}

final antecedentesNinoControllerProvider = StateNotifierProvider.autoDispose
    .family<AntecedentesNinoController, AntecedentesNinoState, String>(
  (ref, hijoLocalId) =>
      AntecedentesNinoController(db: ref.watch(databaseProvider), hijoLocalId: hijoLocalId),
);
```

- [ ] **Step 4: Correr y verificar que pasa**

Run: `flutter test test/features/hijos/antecedentes_nino_controller_test.dart`
Expected: PASS (3 tests).

- [ ] **Step 5: Commit**
```bash
git add lib/features/hijos/presentation/controllers/antecedentes_nino_controller.dart test/features/hijos/antecedentes_nino_controller_test.dart
git commit -m "feat(hijos): controller de antecedentes del nino (precarga + upsert offline)"
```

---

### Task 6: AntecedentesNinoScreen + ruta

**Files:**
- Create: `lib/features/hijos/presentation/screens/antecedentes_nino_screen.dart`
- Modify: `lib/core/router/app_router.dart`
- Test: `test/features/hijos/antecedentes_nino_screen_test.dart`

- [ ] **Step 1: Escribir el test (debe fallar)**

`test/features/hijos/antecedentes_nino_screen_test.dart`:
```dart
import 'dart:convert';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:prosane_app/core/database/app_database.dart';
import 'package:prosane_app/core/database/database_provider.dart';
import 'package:prosane_app/features/hijos/presentation/screens/antecedentes_nino_screen.dart';

Widget _app(AppDatabase db) {
  final router = GoRouter(initialLocation: '/hijos/h1/antecedentes', routes: [
    GoRoute(
      path: '/hijos/:hijoLocalId/antecedentes',
      builder: (c, s) => AntecedentesNinoScreen(hijoLocalId: s.pathParameters['hijoLocalId']!),
    ),
    GoRoute(path: '/inicio', builder: (c, s) => const Scaffold(body: Text('inicio'))),
  ]);
  return ProviderScope(
    overrides: [databaseProvider.overrideWithValue(db)],
    child: MaterialApp.router(routerConfig: router),
  );
}

void main() {
  testWidgets('muestra la pregunta de prematuro y oculta menstruación si es M', (t) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    await db.insertHijoDraft(
      id: 'h1', tutorId: 'tut-1', nombreNna: 'Juan', apellidoNna: 'P',
      payloadJson: jsonEncode({'persona': {'sexo': 'M'}}),
    );
    await t.pumpWidget(_app(db));
    await t.pumpAndSettle();
    expect(find.textContaining('prematuro', findRichText: true), findsOneWidget);
    expect(find.textContaining('menstruación', findRichText: true), findsNothing);
  });

  testWidgets('muestra menstruación si es F', (t) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    await db.insertHijoDraft(
      id: 'h1', tutorId: 'tut-1', nombreNna: 'Ana', apellidoNna: 'P',
      payloadJson: jsonEncode({'persona': {'sexo': 'F'}}),
    );
    await t.pumpWidget(_app(db));
    await t.pumpAndSettle();
    expect(find.textContaining('menstruación', findRichText: true), findsWidgets);
  });
}
```

- [ ] **Step 2: Correr y verificar que falla**

Run: `flutter test test/features/hijos/antecedentes_nino_screen_test.dart`
Expected: FAIL (clase inexistente).

- [ ] **Step 3: Crear la pantalla**

`lib/features/hijos/presentation/screens/antecedentes_nino_screen.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/design_system/app_button.dart';
import '../../../../core/design_system/app_card.dart';
import '../../../../core/design_system/app_dropdown_field.dart';
import '../../../../core/design_system/app_gradient_scaffold.dart';
import '../../../../core/design_system/app_text_field.dart';
import '../../../../core/notificaciones/notificacion_controller.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../controllers/antecedentes_nino_controller.dart';

const _siNoNoSabe = [
  (value: 'si', label: 'Sí'),
  (value: 'no', label: 'No'),
  (value: 'no_sabe', label: 'No sabe'),
];

/// Etiquetas de las preguntas Sí/No/No sabe (orden de la card "Antecedentes").
const _preguntas = <({String campo, String label})>[
  (campo: 'convulsiones_epilepsia', label: '¿Convulsiones a repetición o epilepsia?'),
  (campo: 'mareos_desmayos', label: '¿Mareos, desmayos, dolor de pecho o falta de aire con el ejercicio?'),
  (campo: 'infecciones_urinarias', label: '¿Infecciones urinarias a repetición?'),
  (campo: 'asma_espasmos', label: '¿Asma o espasmos bronquiales a repetición?'),
  (campo: 'tuberculosis', label: '¿Tuberculosis?'),
  (campo: 'diabetes', label: '¿Diabetes?'),
  (campo: 'hipertension', label: '¿Presión arterial alta?'),
  (campo: 'cardiopatia_congenita', label: '¿Cardiopatía congénita u otro problema del corazón?'),
  (campo: 'traumatismo_internacion', label: '¿Traumatismo/accidente que requirió internación?'),
  (campo: 'diarrea_frecuente', label: '¿Diarrea frecuente o a repetición?'),
  (campo: 'infecciones_oido', label: '¿Dolor o infecciones de oído frecuentes?'),
];

class AntecedentesNinoScreen extends ConsumerWidget {
  const AntecedentesNinoScreen({super.key, required this.hijoLocalId});
  final String hijoLocalId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prov = antecedentesNinoControllerProvider(hijoLocalId);
    ref.listen(prov, (prev, next) {
      if (next.exito && !(prev?.exito ?? false)) {
        ref.read(notificacionProvider.notifier).exito('¡Antecedentes guardados!');
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/inicio');
        }
      }
      if (next.error != null && next.error != prev?.error) {
        ref.read(notificacionProvider.notifier).error(next.error!);
      }
    });
    final state = ref.watch(prov);
    final ctrl = ref.read(prov.notifier);

    if (state.cargando) {
      return const AppGradientScaffold(child: Center(child: CircularProgressIndicator()));
    }

    AppDropdownField snns(String campo, String label) => AppDropdownField(
          label: label,
          value: state.respuesta(campo).isEmpty ? null : state.respuesta(campo),
          items: _siNoNoSabe,
          onChanged: (v) => ctrl.setCampo(campo, v),
        );

    return AppGradientScaffold(
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
          child: Row(children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, color: AppColors.blanco),
              onPressed: () => context.canPop() ? context.pop() : context.go('/inicio'),
            ),
            Expanded(
              child: Text('Antecedentes de salud',
                  style: AppTypography.titulo.copyWith(color: AppColors.blanco, fontSize: 22)),
            ),
          ]),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              AppCard(
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Text('Nacimiento', style: AppTypography.subtitulo),
                  const SizedBox(height: AppSpacing.sm),
                  snns('nacio_prematuro', '¿Nació prematuro?'),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    label: 'Peso de nacimiento (kg)',
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    onChanged: ctrl.setPesoNacimiento,
                  ),
                ]),
              ),
              const SizedBox(height: AppSpacing.md),
              AppCard(
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Text('Antecedentes', style: AppTypography.subtitulo),
                  for (final p in _preguntas) ...[
                    const SizedBox(height: AppSpacing.md),
                    snns(p.campo, p.label),
                  ],
                ]),
              ),
              const SizedBox(height: AppSpacing.md),
              AppCard(
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Text('Internación, tratamiento y otros', style: AppTypography.subtitulo),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                      label: 'Causa de internación (si alguna vez estuvo internado)',
                      onChanged: ctrl.setCausaHospitalizacion),
                  const SizedBox(height: AppSpacing.md),
                  snns('rabia_tratamiento', '¿Recibe algún tratamiento (médico, psicológico, fonoaudiológico…)?'),
                  if (state.recibeTratamiento) ...[
                    const SizedBox(height: AppSpacing.md),
                    AppTextField(label: '¿Cuál?', onChanged: ctrl.setDescripcionTratamiento),
                  ],
                  const SizedBox(height: AppSpacing.md),
                  AppDropdownField(
                    label: '¿Última vez que un médico lo pesó, midió y controló vacunas?',
                    value: state.ultimaConsultaMedica.isEmpty ? null : state.ultimaConsultaMedica,
                    items: const [
                      (value: 'menos_1_anio', label: 'Hace menos de 1 año'),
                      (value: 'mas_1_anio', label: 'Hace más de 1 año'),
                      (value: 'no_recuerda', label: 'No recuerda'),
                    ],
                    onChanged: ctrl.setUltimaConsultaMedica,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                      label: 'Otro problema de salud no detallado (¿cuál?)',
                      onChanged: ctrl.setOtrosProblemasSalud),
                ]),
              ),
              if (state.esFemenino) ...[
                const SizedBox(height: AppSpacing.md),
                AppCard(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    Text('Menstruación', style: AppTypography.subtitulo),
                    const SizedBox(height: AppSpacing.md),
                    snns('primera_menstruacion', '¿Tuvo la primera menstruación?'),
                    if (state.tuvoMenstruacion) ...[
                      const SizedBox(height: AppSpacing.md),
                      AppTextField(
                          label: 'Edad (años)',
                          keyboardType: TextInputType.number,
                          onChanged: ctrl.setEdadMenstruacion),
                    ],
                  ]),
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              AppCard(
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  if (state.error != null) ...[
                    Text(state.error!,
                        style: AppTypography.texto.copyWith(color: AppColors.error),
                        textAlign: TextAlign.center),
                    const SizedBox(height: AppSpacing.md),
                  ],
                  AppButton(
                    label: 'Guardar',
                    isLoading: state.guardando,
                    onPressed: state.guardando ? null : ctrl.guardar,
                  ),
                ]),
              ),
              const SizedBox(height: AppSpacing.lg),
            ]),
          ),
        ),
      ]),
    );
  }
}
```

- [ ] **Step 4: Registrar la ruta**

En `lib/core/router/app_router.dart`:
1. Import: `import '../../features/hijos/presentation/screens/antecedentes_nino_screen.dart';`
2. Agregar la ruta junto a las otras de `/hijos` (fuera del shell, como `/hijos/nuevo`):
```dart
      GoRoute(
        path: '/hijos/:hijoLocalId/antecedentes',
        builder: (c, s) => AntecedentesNinoScreen(hijoLocalId: s.pathParameters['hijoLocalId']!),
      ),
```

- [ ] **Step 5: Correr tests + analyze**

Run: `flutter test test/features/hijos/antecedentes_nino_screen_test.dart && flutter analyze lib`
Expected: PASS (2 tests) y analyze sin issues.

- [ ] **Step 6: Commit**
```bash
git add lib/features/hijos/presentation/screens/antecedentes_nino_screen.dart lib/core/router/app_router.dart test/features/hijos/antecedentes_nino_screen_test.dart
git commit -m "feat(hijos): pantalla de antecedentes de salud del nino + ruta per-hijo"
```

---

### Task 7: Pendiente por hijo (sin antecedentes)

**Files:**
- Modify: `lib/features/pendientes/pendientes_count_provider.dart`
- Test: `test/features/pendientes/pendientes_count_provider_test.dart` (y ajustar `pendientes_screen_test.dart` si rompe)

- [ ] **Step 1: Actualizar el test del provider (debe fallar)**

Reemplazar el contenido de `test/features/pendientes/pendientes_count_provider_test.dart` por (cubre la nueva firma):
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:prosane_app/features/pendientes/pendientes_count_provider.dart';

void main() {
  test('no tutor → sin pendientes', () {
    expect(
      armarPendientes(esTutor: false, consentimientoAceptado: true, antecedentesCompletos: true, hijos: const []),
      isEmpty,
    );
  });

  test('hijo sin antecedentes → card de antecedentes del niño con ruta per-hijo', () {
    final items = armarPendientes(
      esTutor: true, consentimientoAceptado: true, antecedentesCompletos: true,
      hijos: const [(id: 'h1', nombre: 'Ana', tieneAntecedentes: false)],
    );
    expect(items.length, 1);
    expect(items.single.ruta, '/hijos/h1/antecedentes');
    expect(items.single.titulo, contains('Ana'));
  });

  test('hijo con antecedentes cargados → no aparece', () {
    final items = armarPendientes(
      esTutor: true, consentimientoAceptado: true, antecedentesCompletos: true,
      hijos: const [(id: 'h1', nombre: 'Ana', tieneAntecedentes: true)],
    );
    expect(items, isEmpty);
  });

  test('consentimiento pendiente sigue apareciendo primero', () {
    final items = armarPendientes(
      esTutor: true, consentimientoAceptado: false, antecedentesCompletos: true,
      hijos: const [],
    );
    expect(items.single.ruta, '/consentimiento');
  });
}
```

- [ ] **Step 2: Correr y verificar que falla**

Run: `flutter test test/features/pendientes/pendientes_count_provider_test.dart`
Expected: FAIL (firma de `armarPendientes` cambió).

- [ ] **Step 3: Actualizar `armarPendientes` y el provider**

En `lib/features/pendientes/pendientes_count_provider.dart`, reemplazar la firma/loop de hijos y el provider:

```dart
List<ItemPendiente> armarPendientes({
  required bool esTutor,
  required bool consentimientoAceptado,
  required bool antecedentesCompletos,
  required List<({String id, String nombre, bool tieneAntecedentes})> hijos,
}) {
  if (!esTutor) return const [];
  return [
    if (!consentimientoAceptado)
      const ItemPendiente(
        titulo: 'Consentimiento',
        subtitulo: 'Aceptá los términos para poder registrar a tus hijos',
        ruta: '/consentimiento',
        icono: Icons.assignment_turned_in_outlined,
      ),
    if (!antecedentesCompletos)
      const ItemPendiente(
        titulo: 'Antecedentes familiares',
        subtitulo: 'Completá los antecedentes de salud de la familia',
        ruta: '/antecedentes-familiares',
        icono: Icons.family_restroom_outlined,
      ),
    for (final h in hijos)
      if (!h.tieneAntecedentes)
        ItemPendiente(
          titulo: 'Antecedentes de ${h.nombre.isEmpty ? 'tu hijo/a' : h.nombre}',
          subtitulo: 'Completá los antecedentes de salud del niño/a',
          ruta: '/hijos/${h.id}/antecedentes',
          icono: Icons.medical_information_outlined,
        ),
  ];
}

final pendientesItemsProvider = StreamProvider<List<ItemPendiente>>((ref) {
  final db = ref.watch(databaseProvider);
  final s = ref.watch(sessionControllerProvider);
  final esTutor = s is SesionAutenticada && s.sesion.usuario.rolName == 'tutor';
  final consent = s is SesionAutenticada && s.sesion.usuario.consentimientoAceptado;
  final antec = s is SesionAutenticada && s.sesion.usuario.antecedentesFamiliaresCompletos;
  return db.watchHijosConAntecedentes().map((hijos) => armarPendientes(
        esTutor: esTutor,
        consentimientoAceptado: consent,
        antecedentesCompletos: antec,
        hijos: hijos,
      ));
});
```
(El `pendientesCountProvider` no cambia.)

- [ ] **Step 4: Correr y arreglar el screen test si rompe**

Run: `flutter test test/features/pendientes/`
Expected: el provider test PASA. Si `pendientes_screen_test.dart` falla porque esperaba la card "Evaluación", actualizar esos asserts para que siembren un hijo (`insertHijoDraft`) y esperen la card "Antecedentes de …" con ruta `/hijos/<id>/antecedentes` (la card de hijo ahora aparece solo si NO tiene antecedentes). Mantener los casos de consentimiento/antecedentes familiares.

- [ ] **Step 5: Analyze + suite completa**

Run: `flutter analyze lib test && flutter test`
Expected: "No issues found!" y todos los tests verdes.

- [ ] **Step 6: Commit**
```bash
git add lib/features/pendientes test/features/pendientes
git commit -m "feat(pendientes): pendiente por hijo sin antecedentes (ruta per-hijo)"
```

---

## Self-Review (autor del plan)

**1. Cobertura del spec:**
- Tabla propia offline → Task 1 + 2. ✅
- Captura serverPacienteId → Task 1 (columna) + Task 3 (HijosSyncer). ✅
- Syncer nuevo (espera el id, postea al endpoint) → Task 4. ✅
- Controller (precarga + upsert, 20 campos, sexo del hijo) → Task 5. ✅
- Pantalla (cards, condicionales menstruación/tratamiento, notificación) → Task 6. ✅
- Pendiente por hijo (detección local reactiva, ruta per-hijo) → Task 7. ✅
- Migración 5→6 + test → Task 1. ✅

**2. Placeholders:** ninguno; todo el código está completo. La única instrucción condicional (Task 7 Step 4) es para adaptar asserts de un test existente, con la guía exacta.

**3. Consistencia de tipos:** `watchHijosConAntecedentes` devuelve `List<({String id, String nombre, bool tieneAntecedentes})>`, mismo shape que consume `armarPendientes` (Task 7) y el test de Task 2. El syncer usa `hijoPorId`/`antecedentesNinoPendientes`/`marcarAntecedenteNinoSincronizado` (Task 2). El controller usa `antecedenteNinoPorHijo`/`upsertAntecedenteNinoDraft`/`hijoPorId` (Task 2). Los campos Sí/No/No sabe (`camposSiNoNoSabe`) y las claves del payload coinciden entre controller (Task 5) y los nombres del modelo backend.

**4. Orden de ejecución:** Task 1 (genera clases Drift) antes que 2–7. Task 3 (captura id) antes/junto con Task 4 (syncer que lo usa). Task 5 (controller) antes que 6 (pantalla). Task 2 (métodos) habilita 4/5/7.
