import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../config/app_config.dart';
import '../storage/token_storage.dart';
import 'auth_interceptor.dart';
import 'logging_interceptor.dart';
import 'refresh_interceptor.dart';

/// Construye el [Dio] principal con todos los interceptors configurados.
///
/// - [tokens]: almacén de JWT (access + refresh).
/// - [onLogout]: callback invocado cuando el refresh falla (sesión expirada).
///
/// Internamente crea un [refreshDio] bare (sin interceptors) para evitar
/// recursión al renovar el token.
Dio buildDio(TokenStorage tokens, {Future<void> Function()? onLogout}) {
  final dio = Dio(
    BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
    ),
  );

  // refreshDio bare: sin interceptors, solo para POST /token/refresh
  final refreshDio = Dio(BaseOptions(baseUrl: AppConfig.apiBaseUrl));

  dio.interceptors.addAll([
    AuthInterceptor(tokens),
    RefreshInterceptor(
      tokens: tokens,
      retryDio: dio,
      refreshDio: refreshDio,
      onLogout: onLogout,
    ),
  ]);

  // Logging SOLO en debug: jamás en release. Datos sensibles de menores
  // (Ley 25.326); en Android dev.log llega a logcat. En release el interceptor
  // ni siquiera existe en el árbol.
  if (kDebugMode) {
    dio.interceptors.add(LoggingInterceptor());
  }

  return dio;
}
