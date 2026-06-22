import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/error/error_mapper.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/session/entities.dart';
import '../../../../core/storage/token_storage.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../../../core/session/session_cache.dart';
import '../datasources/auth_remote_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({required this.remote, required this.tokens, required this.cache});
  final AuthRemoteDataSource remote;
  final TokenStorage tokens;
  final SessionCache cache;

  Future<Sesion> _sesionDesdeMe() async {
    final me = await remote.me();
    final sesion = Sesion(
      usuario: Usuario(
        id: me.id, nombre: me.nombre, rolName: me.rolName, rolLabel: me.rolLabel,
        tutorId: me.tutorId, nombrePila: me.nombrePila, apellido: me.apellido,
        tipoDni: me.tipoDni, dni: me.dni,
        consentimientoAceptado: me.consentimientoAceptado,
        antecedentesFamiliaresCompletos: me.antecedentesFamiliaresCompletos,
      ),
      acciones: me.acciones,
    );
    await cache.guardarSesion(sesion,
        email: me.email, version: me.metaVersion, syncedAtIso: me.metaSyncedAt);
    return sesion;
  }

  @override
  Future<Sesion> login(String email, String password) async {
    try {
      final t = await remote.login(email, password);
      await tokens.guardar(access: t.access, refresh: t.refresh); // PRIMERO los tokens
      try {
        final sesion = await _sesionDesdeMe(); // /me usa el access recién guardado
        return sesion;
      } catch (_) {
        // Login atómico: si /me O el guardado en cache fallan, no dejamos tokens
        // huérfanos (tokens sin sesión persistida). El usuario reintenta el login limpio.
        await tokens.limpiar();
        rethrow;
      }
    } on Failure {
      rethrow;
    } catch (e) {
      throw mapDioError(e); // DioException→Failure (401→InvalidCredentials, etc.); no-Dio→UnknownFailure
    }
  }

  @override
  Future<Sesion> register(Map<String, dynamic> datos) async {
    try {
      final t = await remote.registerTutor(datos);
      await tokens.guardar(access: t.access, refresh: t.refresh);
      try {
        final sesion = await _sesionDesdeMe();
        return sesion;
      } catch (_) {
        await tokens.limpiar();
        rethrow;
      }
    } on Failure {
      rethrow;
    } catch (e) {
      throw mapDioError(e);
    }
  }

  @override
  Future<Sesion> refrescarSesion() => _sesionDesdeMe();

  @override
  Future<Sesion?> sesionCacheada() => cache.leerSesion();

  @override
  Future<void> logout() async {
    // Best-effort: blacklistear el refresh server-side ANTES de limpiar (los tokens
    // deben estar presentes para que el interceptor agregue el Bearer). Si está
    // offline o falla, NO bloquea ni revierte el logout local (offline-first).
    final refresh = await tokens.refresh();
    if (refresh != null && refresh.isNotEmpty) {
      try {
        await remote.logout(refresh);
      } on DioException catch (_) {
        // offline / error HTTP: el logout local procede igual.
      } catch (e, st) {
        // error inesperado (bug en el datasource): no bloquea el logout local.
        if (kDebugMode) debugPrint('logout best-effort: error inesperado: $e\n$st');
      }
    }
    await tokens.limpiar();
    await cache.limpiarSesion();
  }
}
