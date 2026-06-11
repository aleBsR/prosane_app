import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prosane_app/core/database/app_database.dart';
import 'generated_migrations/schema.dart';

void main() {
  late SchemaVerifier verifier;
  setUpAll(() => verifier = SchemaVerifier(GeneratedHelper()));

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
