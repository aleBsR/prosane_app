import 'package:dio/dio.dart';

class UsuarioEscuela {
  final String id;
  final String email;
  final String? escuelaId;
  final String? escuelaNombre;
  final bool isActive;

  UsuarioEscuela({
    required this.id,
    required this.email,
    this.escuelaId,
    this.escuelaNombre,
    this.isActive = true,
  });

  factory UsuarioEscuela.fromJson(Map<String, dynamic> json) {
    return UsuarioEscuela(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      escuelaId: json['escuela'],
      escuelaNombre: json['escuela_nombre'],
      isActive: json['is_active'] ?? true,
    );
  }
}

class UsuariosEscuelaRepository {
  final Dio _dio;

  UsuariosEscuelaRepository(this._dio);

  Future<List<UsuarioEscuela>> listar() async {
    try {
      final res = await _dio.get('/usuarios/escuelas/');
      if (res.statusCode == 200) {
        final data = res.data as List;
        return data
            .map((e) => UsuarioEscuela.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      throw Exception('Error ${res.statusCode}');
    } on DioException catch (e) {
      throw Exception(_mensajeError(e));
    }
  }

  Future<UsuarioEscuela> crear({
    required String email,
    required String password,
    required String escuelaId,
  }) async {
    try {
      final res = await _dio.post('/usuarios/escuelas/', data: {
        'email': email,
        'password': password,
        'escuela': escuelaId,
      });
      if (res.statusCode == 201) {
        return UsuarioEscuela.fromJson(res.data as Map<String, dynamic>);
      }
      throw Exception('Error ${res.statusCode}');
    } on DioException catch (e) {
      throw Exception(_mensajeError(e));
    }
  }

  /// Edita una cuenta escuela. [cambios] admite `email`, `password`,
  /// `escuela` e `is_active` (solo se envían los campos a modificar).
  Future<UsuarioEscuela> editar(String id, Map<String, dynamic> cambios) async {
    try {
      final res = await _dio.patch('/usuarios/escuelas/$id/', data: cambios);
      if (res.statusCode == 200) {
        return UsuarioEscuela.fromJson(res.data as Map<String, dynamic>);
      }
      throw Exception('Error ${res.statusCode}');
    } on DioException catch (e) {
      throw Exception(_mensajeError(e));
    }
  }

  /// Extrae el primer mensaje útil de un 400 de DRF ({campo: [msg]} o {detail: msg}).
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
