import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:prosane_app/core/database/app_database.dart';
import 'package:prosane_app/core/sync/feature_syncer.dart';
import 'package:prosane_app/features/hijos/data/hijos_syncer.dart';

void main() {
  test('pushea el draft al endpoint agregado y lo marca sincronizado', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    await db.insertHijoDraft(
      id: 'h1', tutorId: 'tut-1', nombreNna: 'Juana', apellidoNna: 'Pérez',
      payloadJson: '{"persona":{"dni":"7"}}',
    );
    final dio = Dio(BaseOptions(baseUrl: 'http://x/api/v1'));
    final adapter = DioAdapter(dio: dio);
    adapter.onPost('/tutores/tut-1/hijos/', (s) => s.reply(201, {'id': 'p1'}), data: Matchers.any);

    final syncer = HijosSyncer(db, dio);
    expect(await syncer.idsPendientes(), ['h1']);
    final res = await syncer.pushLote(['h1']);
    expect(res.single.outcome, PushOutcome.ok);
    await syncer.marcarSincronizado('h1');
    expect(await db.contarHijosPendientes(), 0);
    await db.close();
  });

  test('pushLote captura el id del paciente del 201 (serverPacienteId)', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final dio = Dio(BaseOptions(baseUrl: 'http://x/api/v1'));
    final mock = DioAdapter(dio: dio);
    await db.insertHijoDraft(
      id: 'h1', tutorId: 'tut-1', nombreNna: 'Juan', apellidoNna: 'Pérez',
      payloadJson: '{"persona":{"dni":"1"}}',
    );
    mock.onPost('/tutores/tut-1/hijos/', (s) => s.reply(201, {'id': 'pac-1'}), data: Matchers.any);

    final syncer = HijosSyncer(db, dio);
    final res = await syncer.pushLote(['h1']);

    expect(res.single.outcome, PushOutcome.ok);
    final hijo = await db.hijoPorId('h1');
    expect(hijo!.serverPacienteId, 'pac-1');
  });
}
