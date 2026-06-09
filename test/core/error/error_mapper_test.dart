import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prosane_app/core/error/failure.dart';
import 'package:prosane_app/core/error/error_mapper.dart';

DioException _dio(int? status, {DioExceptionType type = DioExceptionType.badResponse}) => DioException(
      requestOptions: RequestOptions(path: '/'),
      type: type,
      response: status == null ? null : Response(requestOptions: RequestOptions(path: '/'), statusCode: status),
    );

void main() {
  test('401 -> InvalidCredentialsFailure', () {
    expect(mapDioError(_dio(401)), isA<InvalidCredentialsFailure>());
  });
  test('sin conexion -> NoConnectionFailure', () {
    expect(mapDioError(_dio(null, type: DioExceptionType.connectionError)), isA<NoConnectionFailure>());
  });
  test('500 -> ServerFailure (NO credenciales)', () {
    final f = mapDioError(_dio(500));
    expect(f, isA<ServerFailure>());
    expect(f, isNot(isA<InvalidCredentialsFailure>()));
  });
  test('timeout -> ServerFailure', () {
    expect(mapDioError(_dio(null, type: DioExceptionType.receiveTimeout)), isA<ServerFailure>());
  });
  test('error no-Dio -> UnknownFailure (nunca credenciales)', () {
    final f = mapDioError(Exception('algo raro'));
    expect(f, isA<UnknownFailure>());
    expect(f, isNot(isA<InvalidCredentialsFailure>()));
  });
  test('badResponse sin statusCode -> UnknownFailure (no credenciales)', () {
    final f = mapDioError(_dio(null)); // badResponse por defecto, sin response
    expect(f, isA<UnknownFailure>());
    expect(f, isNot(isA<InvalidCredentialsFailure>()));
  });
  test('403 -> no credenciales (UnknownFailure)', () {
    final f = mapDioError(_dio(403));
    expect(f, isA<UnknownFailure>());
    expect(f, isNot(isA<InvalidCredentialsFailure>()));
  });
}
