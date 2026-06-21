import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prosane_app/core/database/app_database.dart';
import 'generated_migrations/schema.dart';

void main() {
  late SchemaVerifier verifier;
  setUpAll(() => verifier = SchemaVerifier(GeneratedHelper()));

  test('migración v2→v3 crea hijos_rows (offline-first)', () async {
    // 1. Obtener un db en memoria con el schema v2 ya creado.
    final schema = await verifier.schemaAt(2);

    // 2. Semilla en v2: insertar una fila en cached_session_rows para verificar
    //    que la migración no destruye datos existentes.
    schema.rawDatabase.execute(
      "INSERT INTO cached_session_rows (id, user_id, email, rol_name, rol_label, acciones_json, meta_version) "
      "VALUES ('me', 'u1', 'a@b.com', 'tutor', 'Tutor/a', '[]', 'v1')",
    );

    // 3. Abrir AppDatabase (schemaVersion 3) apuntando al MISMO rawDatabase.
    //    Drift detectará user_version=2 y ejecutará onUpgrade (from=2 → to=3).
    final db = AppDatabase(schema.newConnection());

    // 4. Correr la migración y validar que el schema resultante coincide con v3.
    await verifier.migrateAndValidate(db, 3);

    // 5. La tabla nueva existe y acepta una fila (insert no tira).
    //    updated_at es clientDefault en Drift (no DEFAULT SQL), así que lo proveemos.
    await db.customStatement(
      "INSERT INTO hijos_rows (id, updated_at, tutor_id, nombre_nna, apellido_nna, payload_json, sync_status) "
      "VALUES ('uuid-1', '2026-06-21T00:00:00.000Z', 'tutor-uuid', 'Juan', 'Pérez', '{\"dni\":\"12345678\"}', 0)",
    );
    final n = await db.customSelect('SELECT COUNT(*) AS c FROM hijos_rows').getSingle();
    expect(n.data['c'], 1);

    // 6. Los datos de cached_session sembrados en v2 sobrevivieron.
    final sess = await db.customSelect('SELECT COUNT(*) AS c FROM cached_session_rows').getSingle();
    expect(sess.data['c'], 1, reason: 'cached_session_rows debe sobrevivir la migración v2→v3');

    await db.close();
  });

  test('el esquema v1 abre y valida (harness de migración vivo)', () async {
    final connection = await verifier.startAt(1);
    final db = AppDatabase(connection);
    await verifier.migrateAndValidate(db, 1);
    await db.close();
  });

  test('migración v1→v2 crea cached_session y preserva sync_state (no destruye datos)',
      () async {
    // 1. Obtener un db en memoria con el schema v1 ya creado.
    final schema = await verifier.schemaAt(1);

    // 2. Semilla en v1: insertar una fila en sync_state_rows usando SQL directo
    //    sobre rawDatabase (sqlite3 Database). No usamos AppDatabase aquí porque
    //    AppDatabase ya es v2 y migra de inmediato.
    //    La fecha se guarda como texto ISO8601 porque build.yaml tiene
    //    store_date_time_values_as_text: true.
    schema.rawDatabase.execute(
      "INSERT INTO sync_state_rows (feature, last_synced_at) VALUES (?, ?)",
      ['permisos', '2026-06-10T00:00:00.000Z'],
    );

    // 3. Abrir AppDatabase (schemaVersion 2) apuntando al MISMO rawDatabase.
    //    Drift detectará user_version=1 y ejecutará onUpgrade (from=1 → to=2).
    final db = AppDatabase(schema.newConnection());

    // 4. Correr la migración y validar que el schema resultante coincide con v2.
    await verifier.migrateAndValidate(db, 2);

    // 5. Verificar que la fila sembrada en v1 sobrevivió la migración.
    final watermark = await db.getWatermark('permisos');
    expect(watermark, isNotNull, reason: 'la fila de sync_state sembrada en v1 debe sobrevivir la migración');
    final wm = watermark!.toUtc();
    expect(wm.year, 2026);
    expect(wm.month, 6);
    expect(wm.day, 10);

    // La tabla nueva existe y acepta una fila (insert no tira).
    await db.customStatement(
      "INSERT INTO cached_session_rows (id, user_id, email, rol_name, rol_label, acciones_json, meta_version) "
      "VALUES ('me', 'u1', 'a@b.com', 'medico', 'Médico/a', '[]', 'v1')",
    );
    final n = await db.customSelect('SELECT COUNT(*) AS c FROM cached_session_rows').getSingle();
    expect(n.data['c'], 1);

    await db.close();
  });
}
