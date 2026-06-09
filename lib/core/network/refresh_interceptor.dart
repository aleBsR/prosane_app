import 'dart:developer' as dev;
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../storage/token_storage.dart';

/// Interceptor que maneja la renovación automática del JWT.
///
/// - Ante un 401, llama a POST /token/refresh con el [refreshDio] bare
///   (sin interceptors, para evitar recursión).
/// - Reintenta el request original con el [retryDio].
/// - Implementa single-flight: múltiples 401 concurrentes disparan
///   UN SOLO POST /token/refresh.
/// - Si el refresh falla, llama a [onLogout] y propaga el error.
class RefreshInterceptor extends Interceptor {
  RefreshInterceptor({
    required TokenStorage tokens,
    required Dio retryDio,
    required Dio refreshDio,
    this.onLogout,
  })  : _tokens = tokens,
        _retryDio = retryDio,
        _refreshDio = refreshDio;

  final TokenStorage _tokens;
  final Dio _retryDio; // reintenta el request original
  final Dio _refreshDio; // bare: POST /token/refresh (sin interceptors)
  final Future<void> Function()? onLogout;

  /// Lock de single-flight: si hay un refresh en vuelo, los demás esperan.
  Future<String?>? _refreshEnVuelo;

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    // Solo manejar 401 y evitar loop infinito en el reintento
    if (err.response?.statusCode != 401 ||
        err.requestOptions.extra['retry'] == true) {
      return handler.next(err);
    }

    // Single-flight: si ya hay un refresh en curso, reusar la misma Future.
    // El reset incondicional a null tras el await es seguro en el event loop
    // single-thread de Dart: todos los que esperaban ya capturaron el resultado.
    _refreshEnVuelo ??= _refrescar();
    final nuevo = await _refreshEnVuelo;
    _refreshEnVuelo = null;

    if (nuevo == null) {
      await onLogout?.call();
      return handler.next(err);
    }

    // Reintentar el request original con el nuevo token
    final req = err.requestOptions
      ..extra['retry'] = true
      ..headers['Authorization'] = 'Bearer $nuevo';
    try {
      handler.resolve(await _retryDio.fetch(req));
    } catch (_) {
      handler.next(err);
    }
  }

  Future<String?> _refrescar() async {
    final refresh = await _tokens.refresh();
    if (refresh == null) return null;
    try {
      final r = await _refreshDio.post(
        '/token/refresh',
        data: {'refresh': refresh},
      );
      final access = r.data['access'] as String;
      await _tokens.guardar(access: access, refresh: refresh);
      return access;
    } catch (e) {
      // Falla el refresh (sin red, 401 del refresh, o cambió el contrato de la
      // API): se devuelve null → logout. En release no se loguea (solo dev).
      if (kDebugMode) dev.log('refresh falló: $e', name: 'http');
      return null;
    }
  }
}
