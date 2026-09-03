import 'package:dio/dio.dart';

class Profesional {
  final String id;
  final String email;
  final String rol;
  final String matricula;
  final String nombre;
  final String apellido;
  final bool isActive;

  Profesional({
    required this.id,
    required this.email,
    required this.rol,
    required this.matricula,
    this.nombre = '',
    this.apellido = '',
    this.isActive = true,
  });

  String get nombreCompleto {
    final nombreCompleto = '$nombre $apellido'.trim();
    return nombreCompleto.isNotEmpty ? nombreCompleto : 'Sin nombre cargado';
  }

  factory Profesional.fromJson(Map<String, dynamic> json) {
    return Profesional(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      rol: json['rol'] ?? '',
      matricula: json['matricula'] ?? '',
      nombre: json['nombre'] ?? '',
      apellido: json['apellido'] ?? '',
      isActive: json['is_active'] ?? true,
    );
  }
}

/// Datos devueltos por `POST /profesionales/validar-matricula/`.
class RefepsDatos {
  const RefepsDatos({required this.nombre, required this.apellido, required this.profesion});

  final String nombre;
  final String apellido;
  final String profesion;
}

class ProfesionalesRepository {
  final Dio _dio;

  ProfesionalesRepository(this._dio);

  Future<List<Profesional>> listar() async {
    try {
      final res = await _dio.get('/profesionales/');
      if (res.statusCode == 200) {
        final data = res.data as List;
        return data
            .map((e) => Profesional.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      throw Exception('Error ${res.statusCode}');
    } on DioException catch (e) {
      throw Exception(_mensajeError(e));
    }
  }

  Future<Profesional> crear({
    required String email,
    required String rol,
    required String matricula,
    String? nombre,
    String? apellido,
  }) async {
    try {
      final res = await _dio.post('/profesionales/', data: {
        'email': email,
        'rol': rol,
        'matricula': matricula,
        if (nombre != null && nombre.isNotEmpty) 'nombre': nombre,
        if (apellido != null && apellido.isNotEmpty) 'apellido': apellido,
      });
      if (res.statusCode == 201) {
        return Profesional.fromJson(res.data as Map<String, dynamic>);
      }
      throw Exception('Error ${res.statusCode}');
    } on DioException catch (e) {
      throw Exception(_mensajeError(e));
    }
  }

  /// Edita una cuenta. [cambios] admite `email`, `password`, `rol`,
  /// `matricula`, `nombre`, `apellido` (solo se envían los campos a modificar).
  Future<Profesional> editar(String id, Map<String, dynamic> cambios) async {
    try {
      final res = await _dio.patch('/profesionales/$id/', data: cambios);
      if (res.statusCode == 200) {
        return Profesional.fromJson(res.data as Map<String, dynamic>);
      }
      throw Exception('Error ${res.statusCode}');
    } on DioException catch (e) {
      throw Exception(_mensajeError(e));
    }
  }

  /// Valida la matrícula contra REFEPS. Lanza [Exception] si la matrícula no
  /// existe (404) o si el servicio está caído (503).
  Future<RefepsDatos> validarMatricula(String matricula) async {
    try {
      final res = await _dio.post(
        '/profesionales/validar-matricula/',
        data: {'matricula': matricula},
      );
      if (res.statusCode == 200) {
        final d = res.data as Map<String, dynamic>;
        return RefepsDatos(
          nombre: d['nombre'] as String? ?? '',
          apellido: d['apellido'] as String? ?? '',
          profesion: d['profesion'] as String? ?? '',
        );
      }
      throw Exception('Error ${res.statusCode}');
    } on DioException catch (e) {
      throw Exception(_mensajeError(e));
    }
  }

  /// Extrae el primer mensaje útil de un error de DRF ({campo: [msg]} o {detail: msg}).
  String _mensajeError(DioException e) {
    final data = e.response?.data;
    if (data is Map) {
      for (final value in data.values) {
        if (value is List && value.isNotEmpty) return value.first.toString();
        if (value is String) return value;
      }
    }
    return e.message ?? 'Error de red';
  }
}
