import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:prosane_app/features/auth/data/datasources/auth_remote_datasource.dart';

void main() {
  late Dio dio;
  late DioAdapter adapter;
  late AuthRemoteDataSourceImpl ds;

  setUp(() {
    dio = Dio(BaseOptions(baseUrl: 'http://x/api/v1/auth'));
    adapter = DioAdapter(dio: dio);
    ds = AuthRemoteDataSourceImpl(dio);
  });

  test('registerTutor postea a /register/tutor/ y devuelve tokens', () async {
    adapter.onPost(
      '/register/tutor/',
      (s) => s.reply(201, {
        'user': {'id': 'u1', 'email': 'a@a.com', 'nombre': 'Ana', 'apellido': 'G'},
        'access': 'ACCESS',
        'refresh': 'REFRESH',
      }),
      data: Matchers.any,
    );

    final t = await ds.registerTutor({'email': 'a@a.com'});
    expect(t.access, 'ACCESS');
    expect(t.refresh, 'REFRESH');
  });
}
