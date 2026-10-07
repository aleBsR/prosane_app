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

  Future<Map<String, dynamic>> actualizar(
      String operativoId, Map<String, dynamic> datos) async {
    final resp =
        await _dio.patch('/operativos/$operativoId/', data: datos);
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
    String profesionalId, [
    String? rol,
  ]) async {
    // Si se omite el rol, el backend lo deriva del rol real del profesional.
    final data = <String, dynamic>{'profesional': profesionalId};
    if (rol != null) data['rol_en_operativo'] = rol;
    final resp = await _dio.post(
      '/operativos/$operativoId/profesionales/asignar/',
      data: data,
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

  Future<List<Map<String, dynamic>>> listarAlumnos(String operativoId) async {
    final resp = await _dio.get('/operativos/$operativoId/alumnos/');
    return List<Map<String, dynamic>>.from(resp.data as List);
  }

  Future<Map<String, dynamic>> getEvaluacionMedica(String opId, String alumnoId) async {
    final resp = await _dio.get('/operativos/$opId/alumnos/$alumnoId/evaluacion-medica/');
    return resp.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> putEvaluacionMedica(
    String opId,
    String alumnoId,
    Map<String, dynamic> data,
  ) async {
    final resp = await _dio.put(
      '/operativos/$opId/alumnos/$alumnoId/evaluacion-medica/',
      data: data,
    );
    return resp.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getEvaluacionOdontologica(String opId, String alumnoId) async {
    final resp = await _dio.get('/operativos/$opId/alumnos/$alumnoId/evaluacion-odontologica/');
    return resp.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> putEvaluacionOdontologica(
    String opId,
    String alumnoId,
    Map<String, dynamic> data,
  ) async {
    final resp = await _dio.put(
      '/operativos/$opId/alumnos/$alumnoId/evaluacion-odontologica/',
      data: data,
    );
    return resp.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> patchSeccionEscuela(
    String opId,
    String alumnoId,
    Map<String, dynamic> data,
  ) async {
    final resp = await _dio.patch(
      '/operativos/$opId/alumnos/$alumnoId/seccion-escuela/',
      data: data,
    );
    return resp.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getCompletitud(String operativoId) async {
    final resp = await _dio.get('/operativos/$operativoId/completitud/');
    return resp.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getDerivaciones(String operativoId, {String? especialidad}) async {
    final resp = await _dio.get(
      '/operativos/$operativoId/derivaciones/',
      queryParameters: {if (especialidad != null && especialidad.isNotEmpty) 'especialidad': especialidad},
    );
    return resp.data as Map<String, dynamic>;
  }

  Future<List<int>> getConstanciaPdf(String opId, String alumnoId) async {
    final resp = await _dio.get(
      '/operativos/$opId/alumnos/$alumnoId/constancia/',
      options: Options(responseType: ResponseType.bytes),
    );
    return (resp.data as List<int>);
  }

  Future<List<int>> getPlanillaPdf(String opId, String alumnoId) async {
    final resp = await _dio.get(
      '/operativos/$opId/alumnos/$alumnoId/planilla/',
      options: Options(responseType: ResponseType.bytes),
    );
    return (resp.data as List<int>);
  }

  Future<List<int>> exportOperativo(String opId, String formato) async {
    final resp = await _dio.get(
      '/operativos/$opId/export/',
      queryParameters: {'formato': formato},
      options: Options(responseType: ResponseType.bytes),
    );
    return (resp.data as List<int>);
  }

  Future<Map<String, dynamic>> getDatosAlumno(String opId, String alumnoId) async {
    final resp = await _dio.get('/operativos/$opId/alumnos/$alumnoId/datos/');
    return resp.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> patchDatosAlumno(String opId, String alumnoId, Map<String, dynamic> data) async {
    final resp = await _dio.patch('/operativos/$opId/alumnos/$alumnoId/datos/', data: data);
    return resp.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> patchEstadoAlumno(
    String opId,
    String alumnoId,
    String estado, {
    String? observaciones,
  }) async {
    final resp = await _dio.patch(
      '/operativos/$opId/alumnos/$alumnoId/',
      data: {
        'estado': estado,
        'observaciones': ?observaciones,
      },
    );
    return resp.data as Map<String, dynamic>;
  }
}
