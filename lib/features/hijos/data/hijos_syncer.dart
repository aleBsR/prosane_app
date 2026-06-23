import 'dart:convert';
import 'package:dio/dio.dart';
import '../../../core/database/app_database.dart';
import '../../../core/sync/feature_syncer.dart';

/// Pushea borradores de hijos pendientes al endpoint agregado del servidor.
///
/// URL de producción: `<host>/api/v1/tutores/<tutorId>/hijos/`
/// El Dio recibido debe tener su base en `.../api/v1` (sin sufijo `/auth`)
/// para que la ruta relativa `/tutores/<tutorId>/hijos/` resuelva correctamente.
class HijosSyncer implements FeatureSyncer {
  HijosSyncer(this._db, this._dio);
  final AppDatabase _db;
  final Dio _dio;

  @override
  String get feature => 'hijos';

  @override
  Future<List<String>> idsPendientes() async =>
      (await _db.hijosPendientes()).map((r) => r.id).toList();

  @override
  Future<List<PushItemResult>> pushLote(List<String> ids) async {
    final pendientes = await _db.hijosPendientes();
    final results = <PushItemResult>[];
    for (final row in pendientes.where((r) => ids.contains(r.id))) {
      try {
        final body = jsonDecode(row.payloadJson) as Map<String, dynamic>;
        // Base URL es `.../api/v1`; apuntamos directamente a
        // `/tutores/<tutorId>/hijos/` bajo esa base.
        final resp = await _dio.post('/tutores/${row.tutorId}/hijos/', data: body);
        final pacienteId = (resp.data is Map) ? (resp.data as Map)['id'] as String? : null;
        if (pacienteId != null && pacienteId.isNotEmpty) {
          await _db.guardarServerPacienteId(row.id, pacienteId);
        }
        results.add(PushItemResult(row.id, PushOutcome.ok));
      } on DioException catch (e) {
        final code = e.response?.statusCode ?? 0;
        results.add(PushItemResult(
          row.id,
          code >= 400 && code < 500
              ? PushOutcome.permanente
              : PushOutcome.transitorio,
        ));
      }
    }
    return results;
  }

  @override
  Future<void> marcarSincronizado(String id) => _db.marcarHijoSincronizado(id);

  @override
  Future<DateTime?> getWatermark() => _db.getWatermark(feature);

  @override
  Future<void> setWatermark(DateTime ts) => _db.setWatermark(feature, ts);

  @override
  Future<void> pullDesdeYMergear(DateTime? since) async {
    // v1: push-only; pull incremental no implementado (no-op).
  }
}
