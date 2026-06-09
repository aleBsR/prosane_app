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
  // Al subir a schemaVersion 2: dump v2, regenerar helpers, y agregar acá un
  // test v1→v2 que cargue datos en v1, migre, y verifique que NO se destruyen.
}
