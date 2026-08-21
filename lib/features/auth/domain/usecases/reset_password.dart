import '../repositories/auth_repository.dart';

/// Pide el envío del código de restablecimiento de contraseña por email.
class SolicitarResetPassword {
  SolicitarResetPassword(this._repo);
  final AuthRepository _repo;
  Future<void> call(String email) => _repo.solicitarResetPassword(email);
}

/// Valida el código recibido por email y setea la nueva contraseña.
class ConfirmarResetPassword {
  ConfirmarResetPassword(this._repo);
  final AuthRepository _repo;
  Future<void> call(String email, String code, String newPassword) =>
      _repo.confirmarResetPassword(email, code, newPassword);
}