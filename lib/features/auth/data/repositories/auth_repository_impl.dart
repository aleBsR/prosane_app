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

  @override
  Future<Sesion> login(String email, String password) async {
    try {
      final t = await remote.login(email, password);
      await tokens.guardar(access: t.access, refresh: t.refresh); // PRIMERO los tokens
      try {
        final me = await remote.me(); // /me usa el access recién guardado
        final sesion = Sesion(
          usuario: Usuario(id: me.id, nombre: me.nombre, rolName: me.rolName, rolLabel: me.rolLabel),
          acciones: me.acciones,
        );
        await cache.guardarSesion(sesion, email: me.email, version: me.metaVersion, syncedAtIso: me.metaSyncedAt);
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
  Future<void> register(Map<String, dynamic> datos) async {
    try {
      await remote.register(datos);
    } on Failure {
      rethrow;
    } catch (e) {
      throw mapDioError(e);
    }
  }

  @override
  Future<Sesion?> sesionCacheada() => cache.leerSesion();

  @override
  Future<void> logout() async {
    await tokens.limpiar();
    await cache.limpiarSesion();
  }
}
