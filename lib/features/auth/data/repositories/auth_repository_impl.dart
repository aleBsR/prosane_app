import '../../../../core/error/error_mapper.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/session/entities.dart';
import '../../../../core/storage/token_storage.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({required this.remote, required this.tokens});
  final AuthRemoteDataSource remote;
  final TokenStorage tokens;

  @override
  Future<Sesion> login(String email, String password) async {
    try {
      final t = await remote.login(email, password);
      await tokens.guardar(access: t.access, refresh: t.refresh); // PRIMERO los tokens
      try {
        final me = await remote.me(); // /me usa el access recién guardado
        return Sesion(
          usuario: Usuario(id: me.id, nombre: me.nombre, rol: me.rol),
          permisos: me.permisos,
        );
      } catch (_) {
        // Login atómico: si /me falla, no dejamos tokens huérfanos (tokens sin
        // sesión). El usuario reintenta el login limpio.
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

  /// Sin cache aún: Auth requiere red la 1ra vez. El cache real en Drift se
  /// cabléa cuando exista una pantalla post-login que lo use (fuera de esta iteración).
  @override
  Future<Sesion?> sesionCacheada() async => null;

  @override
  Future<void> logout() => tokens.limpiar();
}
