import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:prosane_app/core/error/failure.dart';
import 'package:prosane_app/features/auth/domain/usecases/reset_password.dart';
import 'package:prosane_app/features/auth/presentation/controllers/reset_password_controller.dart';

class _MockSolicitar extends Mock implements SolicitarResetPassword {}

class _MockConfirmar extends Mock implements ConfirmarResetPassword {}

void main() {
  group('ForgotPasswordController', () {
    test('éxito: enviar devuelve true y limpia el estado', () async {
      final solicitar = _MockSolicitar();
      when(() => solicitar('a@b.com')).thenAnswer((_) async {});
      final c = ForgotPasswordController(solicitar: solicitar);
      final ok = await c.enviar('a@b.com');
      expect(ok, true);
      expect(c.state.isLoading, false);
      expect(c.state.error, isNull);
    });

    test('Failure muestra su mensaje y devuelve false', () async {
      final solicitar = _MockSolicitar();
      when(() => solicitar(any())).thenThrow(const ServerFailure());
      final c = ForgotPasswordController(solicitar: solicitar);
      final ok = await c.enviar('a@b.com');
      expect(ok, false);
      expect(c.state.error, 'Hubo un problema, probá de nuevo');
    });

    test('error inesperado cae al mensaje genérico', () async {
      final solicitar = _MockSolicitar();
      when(() => solicitar(any())).thenThrow(Exception('raro'));
      final c = ForgotPasswordController(solicitar: solicitar);
      final ok = await c.enviar('a@b.com');
      expect(ok, false);
      expect(c.state.error, 'Hubo un problema, probá de nuevo');
    });
  });

  group('ResetPasswordController', () {
    test('éxito: confirmar devuelve true y limpia el estado', () async {
      final confirmar = _MockConfirmar();
      when(() => confirmar('a@b.com', '123456', 'nueva1'))
          .thenAnswer((_) async {});
      final c = ResetPasswordController(confirmar: confirmar);
      final ok = await c.confirmar('a@b.com', '123456', 'nueva1');
      expect(ok, true);
      expect(c.state.isLoading, false);
      expect(c.state.error, isNull);
    });

    test('Failure muestra su mensaje y devuelve false', () async {
      final confirmar = _MockConfirmar();
      when(() => confirmar(any(), any(), any()))
          .thenThrow(const ServerFailure());
      final c = ResetPasswordController(confirmar: confirmar);
      final ok = await c.confirmar('a@b.com', '123456', 'nueva1');
      expect(ok, false);
      expect(c.state.error, 'Hubo un problema, probá de nuevo');
    });

    test('error inesperado cae al mensaje genérico', () async {
      final confirmar = _MockConfirmar();
      when(() => confirmar(any(), any(), any())).thenThrow(Exception('raro'));
      final c = ResetPasswordController(confirmar: confirmar);
      final ok = await c.confirmar('a@b.com', '123456', 'nueva1');
      expect(ok, false);
      expect(c.state.error, 'Hubo un problema, probá de nuevo');
    });
  });
}