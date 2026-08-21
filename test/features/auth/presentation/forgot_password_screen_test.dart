import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:prosane_app/core/design_system/app_button.dart';
import 'package:prosane_app/core/error/failure.dart';
import 'package:prosane_app/core/theme/app_theme.dart';
import 'package:prosane_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:prosane_app/features/auth/domain/usecases/reset_password.dart';
import 'package:prosane_app/features/auth/presentation/controllers/reset_password_controller.dart';
import 'package:prosane_app/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:prosane_app/features/auth/presentation/screens/reset_password_screen.dart';

class _MockSolicitar extends Mock implements SolicitarResetPassword {}
class _MockAuthRepo extends Mock implements AuthRepository {}

/// Monta la pantalla dentro de un GoRouter con /forgot-password y /reset-password
/// para poder verificar la navegación.
Widget _buildScreen(_MockSolicitar solicitar) {
  return ProviderScope(
    overrides: [
      forgotPasswordControllerProvider.overrideWith(
        (ref) => ForgotPasswordController(solicitar: solicitar),
      ),
      resetPasswordControllerProvider.overrideWith(
        (ref) => ResetPasswordController(
          confirmar: ConfirmarResetPassword(
            _MockAuthRepo(),
          ),
        ),
      ),
    ],
    child: MaterialApp.router(
      theme: AppTheme.light(),
      routerConfig: GoRouter(
        initialLocation: '/forgot-password',
        routes: [
          GoRoute(
            path: '/forgot-password',
            builder: (_, _) => const ForgotPasswordScreen(),
          ),
          GoRoute(
            path: '/reset-password',
            builder: (_, s) =>
                ResetPasswordScreen(email: s.extra as String?),
          ),
        ],
      ),
    ),
  );
}

void main() {
  testWidgets('botón deshabilitado con email vacío', (tester) async {
    final solicitar = _MockSolicitar();
    await tester.pumpWidget(_buildScreen(solicitar));

    final btn = tester.widget<AppButton>(
      find.byType(AppButton),
    );
    expect(btn.onPressed, isNull);
  });

  testWidgets('éxito: navega a /reset-password con el email', (tester) async {
    final solicitar = _MockSolicitar();
    when(() => solicitar('a@b.com')).thenAnswer((_) async {});

    await tester.pumpWidget(_buildScreen(solicitar));
    await tester.enterText(find.byType(TextField).first, 'a@b.com');
    await tester.pump();
    await tester.tap(find.text('ENVIAR CÓDIGO'));
    await tester.pumpAndSettle();

    verify(() => solicitar('a@b.com')).called(1);
    expect(find.text('Restablecer contraseña'), findsOneWidget);
    expect(find.text('a@b.com'), findsOneWidget);
  });

  testWidgets('error del servidor se muestra en pantalla', (tester) async {
    final solicitar = _MockSolicitar();
    when(() => solicitar(any())).thenThrow(const ServerFailure());

    await tester.pumpWidget(_buildScreen(solicitar));
    await tester.enterText(find.byType(TextField).first, 'a@b.com');
    await tester.pump();
    await tester.tap(find.text('ENVIAR CÓDIGO'));
    await tester.pumpAndSettle();

    expect(
      find.text('Hubo un problema, probá de nuevo'),
      findsOneWidget,
    );
    expect(find.text('Restablecer contraseña'), findsNothing);
  });
}