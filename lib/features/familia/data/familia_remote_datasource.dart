import 'package:dio/dio.dart';

/// Endpoints de "familia" (consentimiento + antecedentes), base /api/v1.
class FamiliaRemoteDataSource {
  FamiliaRemoteDataSource(this._dio);
  final Dio _dio;

  /// POST `/tutores/<id>/consentimiento/` — acepta el consentimiento general (idempotente).
  Future<void> aceptarConsentimiento(String tutorId) =>
      _dio.post('/tutores/$tutorId/consentimiento/', data: const {});

  /// GET `/tutores/<id>/antecedentes-familiares/` — el backend hace get_or_create (siempre 200).
  Future<Map<String, dynamic>> getAntecedentes(String tutorId) async {
    final r = await _dio.get('/tutores/$tutorId/antecedentes-familiares/');
    return (r.data as Map).cast<String, dynamic>();
  }

  /// POST `/tutores/<id>/antecedentes-familiares/` — upsert.
  Future<void> guardarAntecedentes(String tutorId, Map<String, dynamic> body) =>
      _dio.post('/tutores/$tutorId/antecedentes-familiares/', data: body);
}
