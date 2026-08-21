import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/providers.dart';
import '../../domain/usecases/reset_password.dart';

class ForgotPasswordState {
  const ForgotPasswordState({this.isLoading = false, this.error});
  final bool isLoading;
  final String? error;
}

class ForgotPasswordController extends StateNotifier<ForgotPasswordState> {
  ForgotPasswordController({required SolicitarResetPassword solicitar})
      : _solicitar = solicitar,
        super(const ForgotPasswordState());

  final SolicitarResetPassword _solicitar;

  Future<bool> enviar(String email) async {
    state = const ForgotPasswordState(isLoading: true);
    try {
      await _solicitar(email);
      state = const ForgotPasswordState();
      return true;
    } on Failure catch (f) {
      state = ForgotPasswordState(error: f.mensaje);
      return false;
    } catch (_) {
      state = const ForgotPasswordState(error: 'Hubo un problema, probá de nuevo');
      return false;
    }
  }
}

final forgotPasswordControllerProvider =
    StateNotifierProvider.autoDispose<ForgotPasswordController, ForgotPasswordState>(
        (ref) {
  return ForgotPasswordController(
    solicitar: SolicitarResetPassword(ref.watch(authRepositoryProvider)),
  );
});

class ResetPasswordState {
  const ResetPasswordState({this.isLoading = false, this.error});
  final bool isLoading;
  final String? error;
}

class ResetPasswordController extends StateNotifier<ResetPasswordState> {
  ResetPasswordController({required ConfirmarResetPassword confirmar})
      : _confirmar = confirmar,
        super(const ResetPasswordState());

  final ConfirmarResetPassword _confirmar;

  Future<bool> confirmar(String email, String code, String newPassword) async {
    state = const ResetPasswordState(isLoading: true);
    try {
      await _confirmar(email, code, newPassword);
      state = const ResetPasswordState();
      return true;
    } on Failure catch (f) {
      state = ResetPasswordState(error: f.mensaje);
      return false;
    } catch (_) {
      state = const ResetPasswordState(error: 'Hubo un problema, probá de nuevo');
      return false;
    }
  }
}

final resetPasswordControllerProvider =
    StateNotifierProvider.autoDispose<ResetPasswordController, ResetPasswordState>(
        (ref) {
  return ResetPasswordController(
    confirmar: ConfirmarResetPassword(ref.watch(authRepositoryProvider)),
  );
});