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

  test('insertHijoDraft crea fila pendiente y contarHijosPendientes la cuenta', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    await db.insertHijoDraft(
      id: 'h1', tutorId: 't1', nombreNna: 'Juana', apellidoNna: 'Pérez',
      payloadJson: '{}',
    );
    expect(await db.contarHijosPendientes(), 1);
    final pend = await db.hijosPendientes();
    expect(pend.single.id, 'h1');
    await db.marcarHijoSincronizado('h1');
    expect(await db.contarHijosPendientes(), 0);
    await db.close();
  });

  test('contarHijos devuelve total de hijos no borrados', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    expect(await db.contarHijos(), 0);
    await db.insertHijoDraft(
      id: 'h1', tutorId: 't1', nombreNna: 'Juana', apellidoNna: 'Pérez',
      payloadJson: '{}',
    );
    expect(await db.contarHijos(), 1);
    // Sincronizar no excluye del conteo total (sólo filtra pendientes)
    await db.marcarHijoSincronizado('h1');
    expect(await db.contarHijos(), 1);
    await db.close();
  });
}
