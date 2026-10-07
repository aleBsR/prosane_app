import 'package:dio/dio.dart';

class UsuarioAdministrativo {
  final String id;
  final String email;
  final bool isActive;

  UsuarioAdministrativo({
    required this.id,
    required this.email,
    this.isActive = true,
  });

  factory UsuarioAdministrativo.fromJson(Map<String, dynamic> json) {
    return UsuarioAdministrativo(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      isActive: json['is_active'] ?? true,
    );
  }
}

class UsuariosAdministrativosRepository {
  final Dio _dio;

  UsuariosAdministrativosRepository(this._dio);

  Future<List<UsuarioAdministrativo>> listar() async {
    try {
      final res = await _dio.get('/usuarios/administrativos/');
      if (res.statusCode == 200) {
        final data = res.data as List;
        return data
            .map((e) => UsuarioAdministrativo.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      throw Exception('Error ${res.statusCode}');
    } on DioException catch (e) {
      throw Exception(_mensajeError(e));
    }
  }

  Future<UsuarioAdministrativo> crear({
    required String email,
  }) async {
    try {
      final res = await _dio.post('/usuarios/administrativos/', data: {
        'email': email,
      });
      if (res.statusCode == 201) {
        return UsuarioAdministrativo.fromJson(res.data as Map<String, dynamic>);
      }
      throw Exception('Error ${res.statusCode}');
    } on DioException catch (e) {
      throw Exception(_mensajeError(e));
    }
  }

  Future<void> reenviarTemporal(String id) async {
    try {
      final res = await _dio.post('/usuarios/administrativos/$id/resend-temp/');
      if (res.statusCode != 200) throw Exception('Error ${res.statusCode}');
    } on DioException catch (e) {
      throw Exception(_mensajeError(e));
    }
  }

  /// Edita una cuenta de administrativo. [cambios] admite `email`, `password`
  /// e `is_active` (solo se envían los campos a modificar).
  Future<UsuarioAdministrativo> editar(String id, Map<String, dynamic> cambios) async {
    try {
      final res = await _dio.patch('/usuarios/administrativos/$id/', data: cambios);
      if (res.statusCode == 200) {
        return UsuarioAdministrativo.fromJson(res.data as Map<String, dynamic>);
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