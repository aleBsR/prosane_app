import 'package:dio/dio.dart';
import '../dtos/me_response.dart';

typedef Tokens = ({String access, String refresh});

abstract class AuthRemoteDataSource {
  Future<Tokens> login(String email, String password);
  Future<void> register(Map<String, dynamic> datos);
  Future<Tokens> registerTutor(Map<String, dynamic> datos);
  Future<MeResponse> me();
  Future<void> logout(String refresh);
  Future<void> solicitarResetPassword(String email);
  Future<void> confirmarResetPassword(String email, String code, String newPassword);
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  AuthRemoteDataSourceImpl(this._dio);
  final Dio _dio;

  @override
  Future<Tokens> login(String email, String password) async {
    final r = await _dio.post('/token/', data: {'email': email, 'password': password});
    return (access: r.data['access'] as String, refresh: r.data['refresh'] as String);
  }

  @override
  Future<void> register(Map<String, dynamic> datos) => _dio.post('/register/', data: datos);

  @override
  Future<Tokens> registerTutor(Map<String, dynamic> datos) async {
    final r = await _dio.post('/register/tutor/', data: datos);
    return (access: r.data['access'] as String, refresh: r.data['refresh'] as String);
  }

  @override
  Future<MeResponse> me() async =>
      MeResponse.fromJson((await _dio.get('/me/')).data as Map<String, dynamic>);

  @override
  Future<void> logout(String refresh) => _dio.post('/logout/', data: {'refresh': refresh});

  @override
  Future<void> solicitarResetPassword(String email) =>
      _dio.post('/auth/reset-password/', data: {'email': email});

  @override
  Future<void> confirmarResetPassword(String email, String code, String newPassword) =>
      _dio.post('/auth/reset-password/confirm/', data: {
        'email': email,
        'code': code,
        'new_password': newPassword,
      });
}
