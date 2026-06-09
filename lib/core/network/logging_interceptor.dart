import 'dart:developer' as dev;
import 'package:dio/dio.dart';

const _camposSensibles = {
  'password',
  'confirmPassword',
  'access',
  'refresh',
  'token',
};

/// Redacta campos sensibles antes de logguear.
/// - Campos en [_camposSensibles]: reemplaza el valor por '***'.
/// - Campo 'email': enmascara la parte local (e.g. 'ana@b.com' → 'a***@b.com').
Map<String, dynamic> redactarSensibles(Map<String, dynamic> data) {
  return data.map((k, v) {
    if (_camposSensibles.contains(k)) return MapEntry(k, '***');
    if (k == 'email' && v is String && v.contains('@')) {
      final parts = v.split('@');
      final local = parts.first;
      final domain = parts.last;
      final masked = local.isNotEmpty
          ? '${local.substring(0, 1)}***@$domain'
          : '***@$domain';
      return MapEntry(k, masked);
    }
    // Recursión: maps y listas anidadas también se redactan (un secreto
    // anidado, ej. {'usuario': {'password': ...}}, no debe filtrarse).
    if (v is Map<String, dynamic>) return MapEntry(k, redactarSensibles(v));
    if (v is List) {
      return MapEntry(
        k,
        v.map((e) => e is Map<String, dynamic> ? redactarSensibles(e) : e).toList(),
      );
    }
    return MapEntry(k, v);
  });
}

/// Interceptor de logging — SOLO para modo desarrollo.
/// Nunca loguea passwords, tokens ni emails en texto plano (Ley 25.326).
class LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final data = options.data;
    // Bodies no-Map (FormData, String JSON ya serializado, etc.) no se pueden
    // redactar campo a campo: se loguea solo el tipo, nunca el contenido crudo.
    final body = data is Map<String, dynamic>
        ? redactarSensibles(data)
        : (data == null ? null : '[${data.runtimeType}]');
    dev.log(
      '→ ${options.method} ${options.path} body=$body',
      name: 'http',
    );
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    dev.log(
      '← ${response.statusCode} ${response.requestOptions.path}',
      name: 'http',
    );
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    dev.log(
      '✗ ${err.response?.statusCode} ${err.requestOptions.path}: ${err.message}',
      name: 'http',
    );
    handler.next(err);
  }
}
