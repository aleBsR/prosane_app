import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:prosane_app/core/error/failure.dart';
import 'package:prosane_app/core/session/entities.dart';
import 'package:prosane_app/features/auth/domain/usecases/login.dart';
import 'package:prosane_app/features/auth/presentation/controllers/login_controller.dart';

class _MockLogin extends Mock implements Login {}

void main() {
  test('éxito: llama onAutenticado con la sesión y limpia el estado', () async {
    final login = _MockLogin();
    final sesion = Sesion(usuario: const Usuario(id: '1', nombre: 'Ana', rol: 'p'), permisos: const {});
    when(() => login.call(any(), any())).thenAnswer((_) async => sesion);
    Sesion? capturada;
    final c = LoginController(login: login, onAutenticado: (s) => capturada = s);
    await c.enviar('a@b.com', 'x');
    expect(capturada, sesion);
    expect(c.state.isLoading, false);
    expect(c.state.error, isNull);
  });

  test('401 (InvalidCredentialsFailure) muestra "Credenciales incorrectas"', () async {
    final login = _MockLogin();
    when(() => login.call(any(), any())).thenThrow(const InvalidCredentialsFailure());
    final c = LoginController(login: login, onAutenticado: (_) {});
    await c.enviar('a@b.com', 'x');
    expect(c.state.error, 'Credenciales incorrectas');
  });

  test('500 (ServerFailure) NO muestra credenciales', () async {
    final login = _MockLogin();
    when(() => login.call(any(), any())).thenThrow(const ServerFailure());
    final c = LoginController(login: login, onAutenticado: (_) {});
    await c.enviar('a@b.com', 'x');
    expect(c.state.error, 'Hubo un problema, probá de nuevo');
    expect(c.state.error, isNot('Credenciales incorrectas'));
  });

  test('error inesperado (no Failure) cae al mensaje genérico', () async {
    final login = _MockLogin();
    when(() => login.call(any(), any())).thenThrow(Exception('raro'));
    final c = LoginController(login: login, onAutenticado: (_) {});
    await c.enviar('a@b.com', 'x');
    expect(c.state.error, 'Hubo un problema, probá de nuevo');
  });
}
