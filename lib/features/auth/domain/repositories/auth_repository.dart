import '../../../../core/session/entities.dart';

/// Contrato del feature Auth. La implementación (data) habla con la API.
abstract class AuthRepository {
  Future<Sesion> login(String email, String password);
  Future<Sesion> register(Map<String, dynamic> datos);
  /// Sesión cacheada para arranque offline (null si no hay / Auth requiere red la 1ra vez).
  Future<Sesion?> sesionCacheada();
  Future<void> logout();
}
