import '../../../../core/session/entities.dart';

/// Contrato del feature Auth. La implementación (data) habla con la API.
abstract class AuthRepository {
  /// [recordarme] false = sesión efímera: tokens en memoria y sin caché de
  /// Drift; al cerrar la app se pierde la sesión.
  Future<Sesion> login(String email, String password, {bool recordarme = true});
  Future<Sesion> register(Map<String, dynamic> datos);
  /// Pide el envío de un código de restablecimiento de contraseña por email.
  Future<void> solicitarResetPassword(String email);
  /// Valida el código recibido y setea una nueva contraseña.
  Future<void> confirmarResetPassword(String email, String code, String newPassword);
  /// Sesión cacheada para arranque offline (null si no hay / Auth requiere red la 1ra vez).
  Future<Sesion?> sesionCacheada();
  Future<void> logout();
  Future<Sesion> refrescarSesion();
}
