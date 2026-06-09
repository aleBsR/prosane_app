import 'package:dio/dio.dart';
import '../dtos/me_response.dart';

typedef Tokens = ({String access, String refresh});

abstract class AuthRemoteDataSource {
  Future<Tokens> login(String email, String password);
  Future<void> register(Map<String, dynamic> datos);
  Future<MeResponse> me();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  AuthRemoteDataSourceImpl(this._dio);
  final Dio _dio;

  @override
  Future<Tokens> login(String email, String password) async {
    final r = await _dio.post('/token', data: {'email': email, 'password': password});
    return (access: r.data['access'] as String, refresh: r.data['refresh'] as String);
  }

  @override
  Future<void> register(Map<String, dynamic> datos) => _dio.post('/register', data: datos);

  @override
  Future<MeResponse> me() async =>
      MeResponse.fromJson((await _dio.get('/me')).data as Map<String, dynamic>);
}
