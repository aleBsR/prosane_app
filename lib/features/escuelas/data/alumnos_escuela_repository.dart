import 'package:dio/dio.dart';

class AlumnoEscuela {
  AlumnoEscuela({
    required this.id,
    required this.nombre,
    required this.apellido,
    required this.dni,
    required this.fechaNacimiento,
    required this.sexo,
    required this.edad,
    this.localidad = '',
    this.telefonoFijo = '',
    this.celular = '',
    this.tieneCud = '',
    this.tipoCobertura = '',
    this.nombreCobertura = '',
    this.antecedentes,
    this.operativos = const [],
  });

  final String id;
  final String nombre;
  final String apellido;
  final String dni;
  final String fechaNacimiento;
  final String sexo;
  final int edad;
  final String localidad;
  final String telefonoFijo;
  final String celular;
  final String tieneCud;
  final String tipoCobertura;
  final String nombreCobertura;
  final Map<String, dynamic>? antecedentes;
  final List<Map<String, dynamic>> operativos;

  factory AlumnoEscuela.fromJson(Map<String, dynamic> json) {
    final persona = (json['persona'] as Map?)?.cast<String, dynamic>() ?? {};
    final domicilio = (json['domicilio'] as Map?)?.cast<String, dynamic>() ?? {};
    return AlumnoEscuela(
      id: '${json['id'] ?? ''}',
      nombre: '${persona['nombre'] ?? ''}',
      apellido: '${persona['apellido'] ?? ''}',
      dni: '${persona['dni'] ?? ''}',
      fechaNacimiento: '${persona['fecha_nacimiento'] ?? ''}',
      sexo: '${persona['sexo'] ?? ''}',
      edad: (json['edad'] as num?)?.toInt() ?? 0,
      localidad: '${domicilio['localidad'] ?? ''}',
      telefonoFijo: '${json['telefono_fijo'] ?? ''}',
      celular: '${json['celular'] ?? ''}',
      tieneCud: '${json['tiene_cud'] ?? ''}',
      tipoCobertura: '${json['tipo_cobertura'] ?? ''}',
      nombreCobertura: '${json['nombre_cobertura'] ?? ''}',
      antecedentes: (json['antecedentes'] as Map?)?.cast<String, dynamic>(),
      operativos: (json['operativos'] as List?)?.map((e) => Map<String, dynamic>.from(e as Map)).toList() ?? const [],
    );
  }
}

class AlumnosEscuelaRepository {
  AlumnosEscuelaRepository(this._dio);
  final Dio _dio;

  Future<List<AlumnoEscuela>> listar() async {
    final res = await _dio.get('/alumnos/');
    final data = res.data as List;
    return data
        .map((e) => AlumnoEscuela.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Alumnos de una escuela puntual (solo superadmin; el detalle de escuela).
  Future<List<AlumnoEscuela>> listarPorEscuela(String escuelaId) async {
    try {
      final res = await _dio.get('/alumnos/',
          queryParameters: {'escuela_id': escuelaId});
      final data = res.data as List;
      return data
          .map((e) => AlumnoEscuela.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw Exception(e.message);
    }
  }

  Future<AlumnoEscuela> crear(Map<String, dynamic> payload) async {
    try {
      final res = await _dio.post('/alumnos/', data: payload);
      return AlumnoEscuela.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      final data = e.response?.data;
      if (data is Map) {
        // Backend devuelve { "persona.dni": ["Ya existe..."], "detail": "..." } o similar
        final msgs = <String>[];
        data.forEach((k, v) {
          if (v is List) {
            msgs.add('$k: ${v.join(", ")}');
          } else {
            msgs.add('$k: $v');
          }
        });
        if (msgs.isNotEmpty) throw Exception(msgs.join('\n'));
      }
      throw Exception(e.message ?? 'Error al registrar alumno');
    }
  }

  Future<Map<String, dynamic>> fetchAntecedentes(String alumnoId) async {
    final res = await _dio.get('/alumnos/$alumnoId/antecedentes/');
    return Map<String, dynamic>.from(res.data as Map);
  }

  Future<Map<String, dynamic>> patchAntecedentes(String alumnoId, Map<String, dynamic> payload) async {
    final res = await _dio.patch('/alumnos/$alumnoId/antecedentes/', data: payload);
    return Map<String, dynamic>.from(res.data as Map);
  }
}
