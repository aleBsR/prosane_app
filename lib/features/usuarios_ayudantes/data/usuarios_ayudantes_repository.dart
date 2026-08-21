import 'package:dio/dio.dart';

class UsuarioAyudante {
  final String id;
  final String email;
  final bool isActive;

  UsuarioAyudante({
    required this.id,
    required this.email,
    this.isActive = true,
  });

  factory UsuarioAyudante.fromJson(Map<String, dynamic> json) {
    return UsuarioAyudante(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      isActive: json['is_active'] ?? true,
    );
  }
}

class UsuariosAyudantesRepository {
  final Dio _dio;

  UsuariosAyudantesRepository(this._dio);

  Future<List<UsuarioAyudante>> listar() async {
    try {
      final res = await _dio.get('/usuarios/ayudantes/');
      if (res.statusCode == 200) {
        final data = res.data as List;
        return data
            .map((e) => UsuarioAyudante.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      throw Exception('Error ${res.statusCode}');
    } on DioException catch (e) {
      throw Exception(_mensajeError(e));
    }
  }

  Future<UsuarioAyudante> crear({
    required String email,
    required String password,
  }) async {
    try {
      final res = await _dio.post('/usuarios/ayudantes/', data: {
        'email': email,
        'password': password,
      });
      if (res.statusCode == 201) {
        return UsuarioAyudante.fromJson(res.data as Map<String, dynamic>);
      }
      throw Exception('Error ${res.statusCode}');
    } on DioException catch (e) {
      throw Exception(_mensajeError(e));
    }
  }

  /// Edita una cuenta de ayudante. [cambios] admite `email`, `password`
  /// e `is_active` (solo se envían los campos a modificar).
  Future<UsuarioAyudante> editar(String id, Map<String, dynamic> cambios) async {
    try {
      final res = await _dio.patch('/usuarios/ayudantes/$id/', data: cambios);
      if (res.statusCode == 200) {
        return UsuarioAyudante.fromJson(res.data as Map<String, dynamic>);
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