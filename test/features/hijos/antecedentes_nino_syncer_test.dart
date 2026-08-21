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
    mock.onPost(
      '/tutores/tut-1/hijos/pac-9/antecedentes-personales/',
      (s) => s.reply(200, {'ok': true}),
      data: Matchers.any,
    );
    final res = await AntecedentesNinoSyncer(db, dio).pushLote(['a1']);
    expect(res.single.outcome, PushOutcome.ok);
  });
}
