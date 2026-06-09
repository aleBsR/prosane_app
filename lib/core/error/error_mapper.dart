import 'package:dio/dio.dart';
import 'failure.dart';

Failure mapDioError(Object error) {
  if (error is! DioException) return const UnknownFailure();
  switch (error.type) {
    case DioExceptionType.connectionError:
      return const NoConnectionFailure();
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.receiveTimeout:
    case DioExceptionType.sendTimeout:
      return const ServerFailure();
    case DioExceptionType.badResponse:
      final code = error.response?.statusCode ?? 0;
      if (code == 401) return const InvalidCredentialsFailure();
      if (code >= 500) return const ServerFailure();
      return const UnknownFailure();
    // Sin `default`: el switch queda exhaustivo sobre DioExceptionType, así un
    // tipo nuevo en una futura versión de Dio rompe la compilación en vez de
    // caer silenciosamente acá.
    case DioExceptionType.badCertificate:
    case DioExceptionType.cancel:
    case DioExceptionType.unknown:
      return const UnknownFailure();
  }
}
