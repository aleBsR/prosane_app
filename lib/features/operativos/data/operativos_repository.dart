import 'package:dio/dio.dart';

class OperativosRepository {
  final Dio _dio;

  OperativosRepository(this._dio);

  Future<List<Map<String, dynamic>>> listar() async {
    final resp = await _dio.get('/operativos/');
    return List<Map<String, dynamic>>.from(resp.data as List);
  }

  Future<Map<String, dynamic>> crear(Map<String, dynamic> datos) async {
    final resp = await _dio.post('/operativos/', data: datos);
    return resp.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> detalle(String operativoId) async {
    final resp = await _dio.get('/operativos/$operativoId/');
    return resp.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> confirmar(String operativoId) async {
    final resp = await _dio.post('/operativos/$operativoId/confirmar/');
    return resp.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> iniciar(String operativoId) async {
    final resp = await _dio.post('/operativos/$operativoId/iniciar/');
    return resp.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> finalizar(String operativoId) async {
    final resp = await _dio.post('/operativos/$operativoId/finalizar/');
    return resp.data as Map<String, dynamic>;
  }

  Future<void> cancelar(String operativoId) async {
    await _dio.delete('/operativos/$operativoId/');
  }

  Future<Map<String, dynamic>> asignarProfesional(
    String operativoId,
    String profesionalId,
    String rol,
  ) async {
    final resp = await _dio.post(
      '/operativos/$operativoId/profesionales/asignar/',
      data: {'profesional': profesionalId, 'rol_en_operativo': rol},
    );
    return resp.data as Map<String, dynamic>;
  }

  Future<List<Map<String, dynamic>>> profesionalesDisponibles() async {
    final resp = await _dio.get('/operativos/profesionales-disponibles/');
    return List<Map<String, dynamic>>.from(resp.data as List);
  }

  Future<Map<String, dynamic>> importarCsv(String operativoId, FormData formData) async {
    final resp = await _dio.post('/operativos/$operativoId/alumnos/importar-csv/', data: formData);
    return resp.data as Map<String, dynamic>;
  }
}
