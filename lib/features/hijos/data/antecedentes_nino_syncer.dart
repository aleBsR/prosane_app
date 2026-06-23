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
