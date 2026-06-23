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
