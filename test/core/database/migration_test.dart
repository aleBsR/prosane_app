import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prosane_app/core/database/app_database.dart';
import 'generated_migrations/schema.dart';

void main() {
  late SchemaVerifier verifier;
  setUpAll(() => verifier = SchemaVerifier(GeneratedHelper()));

  test('migración v2→v5 crea hijos_rows y columnas de identidad del tutor (offline-first)', () async {
    // 1. Obtener un db en memoria con el schema v2 ya creado.
    final schema = await verifier.schemaAt(2);

    // 2. Semilla en v2: insertar una fila en cached_session_rows para verificar
    //    que la migración no destruye datos existentes.
    schema.rawDatabase.execute(
      "INSERT INTO cached_session_rows (id, user_id, email, rol_name, rol_label, acciones_json, meta_version) "
      "VALUES ('me', 'u1', 'a@b.com', 'tutor', 'Tutor/a', '[]', 'v1')",
    );

    // 3. Abrir AppDatabase (schemaVersion 5) apuntando al MISMO rawDatabase.
    //    Drift detectará user_version=2 y ejecutará onUpgrade (from=2 → to=5).
    final db = AppDatabase(schema.newConnection());

    // 4. Correr la migración y validar que el schema resultante coincide con v5.
    await verifier.migrateAndValidate(db, 5);

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
    expect(sess.data['c'], 1, reason: 'cached_session_rows debe sobrevivir la migración v2→v5');

    await db.close();
  });

  test('migración v3→v5 añade columnas de identidad del tutor (tutorId, nombrePila, apellido, tipoDni, dni)', () async {
    // 1. Obtener un db en memoria con el schema v3 ya creado.
    final schema = await verifier.schemaAt(3);

    // 2. Semilla en v3: insertar una fila en cached_session_rows para verificar
    //    que la migración no destruye datos existentes.
    schema.rawDatabase.execute(
      "INSERT INTO cached_session_rows (id, user_id, email, rol_name, rol_label, acciones_json, meta_version) "
      "VALUES ('me', 'u1', 'a@b.com', 'tutor', 'Tutor/a', '[]', 'v1')",
    );

    // 3. Abrir AppDatabase (schemaVersion 5) apuntando al MISMO rawDatabase.
    //    Drift detectará user_version=3 y ejecutará onUpgrade (from=3 → to=5).
    final db = AppDatabase(schema.newConnection());

    // 4. Correr la migración y validar que el schema resultante coincide con v5.
    await verifier.migrateAndValidate(db, 5);

    // 5. Las nuevas columnas existen y aceptan valores.
    await db.customStatement(
      "UPDATE cached_session_rows SET tutor_id='tut-1', nombre_pila='Juan', apellido='Arquipa', tipo_dni='DNI', dni='43949474' WHERE id='me'",
    );
    final row = await db.customSelect(
      "SELECT tutor_id, nombre_pila, apellido, tipo_dni, dni FROM cached_session_rows WHERE id='me'",
    ).getSingle();
    expect(row.data['tutor_id'], 'tut-1');
    expect(row.data['nombre_pila'], 'Juan');
    expect(row.data['apellido'], 'Arquipa');
    expect(row.data['tipo_dni'], 'DNI');
    expect(row.data['dni'], '43949474');

    // 6. Los datos de cached_session sembrados en v3 sobrevivieron.
    final sess = await db.customSelect('SELECT COUNT(*) AS c FROM cached_session_rows').getSingle();
    expect(sess.data['c'], 1, reason: 'cached_session_rows debe sobrevivir la migración v3→v5');

    await db.close();
  });

  test('el esquema v1 abre y valida (harness de migración vivo)', () async {
    final connection = await verifier.startAt(1);
    final db = AppDatabase(connection);
    await verifier.migrateAndValidate(db, 1);
    await db.close();
  });

  test('migración v1→v5 crea cached_session y preserva sync_state (no destruye datos)',
      () async {
    // 1. Obtener un db en memoria con el schema v1 ya creado.
    final schema = await verifier.schemaAt(1);

    // 2. Semilla en v1: insertar una fila en sync_state_rows usando SQL directo
    //    sobre rawDatabase (sqlite3 Database). No usamos AppDatabase aquí porque
    //    AppDatabase ya es v5 y migra de inmediato.
    //    La fecha se guarda como texto ISO8601 porque build.yaml tiene
    //    store_date_time_values_as_text: true.
    schema.rawDatabase.execute(
      "INSERT INTO sync_state_rows (feature, last_synced_at) VALUES (?, ?)",
      ['permisos', '2026-06-10T00:00:00.000Z'],
    );

    // 3. Abrir AppDatabase (schemaVersion 5) apuntando al MISMO rawDatabase.
    //    Drift detectará user_version=1 y ejecutará onUpgrade (from=1 → to=5).
    final db = AppDatabase(schema.newConnection());

    // 4. Correr la migración y validar que el schema resultante coincide con v5.
    await verifier.migrateAndValidate(db, 5);

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

  test('migración v4→v5 añade flags de consentimiento y antecedentes familiares', () async {
    // 1. Obtener un db en memoria con el schema v4 ya creado.
    final schema = await verifier.schemaAt(4);

    // 2. Semilla en v4: insertar una fila en cached_session_rows para verificar
    //    que la migración no destruye datos existentes.
    schema.rawDatabase.execute(
      "INSERT INTO cached_session_rows (id, user_id, email, rol_name, rol_label, acciones_json, meta_version) "
      "VALUES ('me', 'u1', 'a@b.com', 'tutor', 'Tutor/a', '[]', 'v1')",
    );

    // 3. Abrir AppDatabase (schemaVersion 5) apuntando al MISMO rawDatabase.
    //    Drift detectará user_version=4 y ejecutará onUpgrade (from=4 → to=5).
    final db = AppDatabase(schema.newConnection());

    // 4. Correr la migración y validar que el schema resultante coincide con v5.
    await verifier.migrateAndValidate(db, 5);

    // 5. Las nuevas columnas existen, aceptan valores y tienen el default correcto.
    final row = await db.customSelect(
      "SELECT consentimiento_aceptado, antecedentes_familiares_completos FROM cached_session_rows WHERE id='me'",
    ).getSingle();
    // DEFAULT 0 (false) para filas existentes antes de la migración.
    expect(row.data['consentimiento_aceptado'], 0);
    expect(row.data['antecedentes_familiares_completos'], 0);

    // Pueden actualizarse a true (1).
    await db.customStatement(
      "UPDATE cached_session_rows SET consentimiento_aceptado=1, antecedentes_familiares_completos=1 WHERE id='me'",
    );
    final updated = await db.customSelect(
      "SELECT consentimiento_aceptado, antecedentes_familiares_completos FROM cached_session_rows WHERE id='me'",
    ).getSingle();
    expect(updated.data['consentimiento_aceptado'], 1);
    expect(updated.data['antecedentes_familiares_completos'], 1);

    // 6. Los datos de cached_session sembrados en v4 sobrevivieron.
    final sess = await db.customSelect('SELECT COUNT(*) AS c FROM cached_session_rows').getSingle();
    expect(sess.data['c'], 1, reason: 'cached_session_rows debe sobrevivir la migración v4→v5');

    await db.close();
  });
}
