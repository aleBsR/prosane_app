import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/providers.dart';
import '../../../../core/session/entities.dart';
import '../../../../core/session/session_controller.dart';
import '../../domain/usecases/login.dart';

class LoginState {
  const LoginState({this.isLoading = false, this.error});
  final bool isLoading;
  final String? error;
}

class LoginController extends StateNotifier<LoginState> {
  LoginController({required Login login, required this.onAutenticado})
      : _login = login,
        super(const LoginState());

  final Login _login;
  final void Function(Sesion) onAutenticado;

  Future<void> enviar(String email, String password) async {
    state = const LoginState(isLoading: true);
    try {
      final sesion = await _login(email, password);
      onAutenticado(sesion);
      state = const LoginState();
    } on Failure catch (f) {
      state = LoginState(error: f.mensaje);
    } catch (_) {
      state = const LoginState(error: 'Hubo un problema, probá de nuevo');
    }
  }
}

final loginControllerProvider =
    StateNotifierProvider.autoDispose<LoginController, LoginState>((ref) {
  return LoginController(
    login: ref.watch(loginUseCaseProvider),
    onAutenticado: (sesion) =>
        ref.read(sessionControllerProvider.notifier).setSesion(sesion),
  );
});
