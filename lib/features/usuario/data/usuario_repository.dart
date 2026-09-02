import 'package:dio/dio.dart';

class UsuarioRepository {
  UsuarioRepository(this._dio);
  final Dio _dio;

  Future<Map<String, dynamic>> fetchMe() async {
    final res = await _dio.get('/auth/me/');
    return Map<String, dynamic>.from(res.data as Map);
  }

  Future<Map<String, dynamic>> patchMe({String? nombre, String? apellido}) async {
    final payload = <String, dynamic>{};
    if (nombre != null) payload['nombre'] = nombre;
    if (apellido != null) payload['apellido'] = apellido;
    final res = await _dio.patch('/auth/me/', data: payload);
    return Map<String, dynamic>.from(res.data as Map);
  }

  Future<void> changePassword({required String oldPassword, required String newPassword}) async {
    await _dio.post('/auth/change-password/', data: {
      'old_password': oldPassword,
      'new_password': newPassword,
    });
  }
}
