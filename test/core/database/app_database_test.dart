import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prosane_app/core/database/app_database.dart';

void main() {
  test('AppDatabase abre y persiste un watermark de sync', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    await db.setWatermark('apto_fisico', DateTime.utc(2026, 1, 1));
    expect(await db.getWatermark('apto_fisico'), DateTime.utc(2026, 1, 1));
    expect(await db.getWatermark('inexistente'), isNull);
    await db.close();
  });
}
