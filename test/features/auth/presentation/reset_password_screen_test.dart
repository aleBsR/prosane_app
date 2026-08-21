import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:prosane_app/core/design_system/app_button.dart';
import 'package:prosane_app/core/error/failure.dart';
import 'package:prosane_app/core/theme/app_theme.dart';
import 'package:prosane_app/features/auth/domain/usecases/reset_password.dart';
import 'package:prosane_app/features/auth/presentation/controllers/reset_password_controller.dart';
import 'package:prosane_app/features/auth/presentation/screens/reset_password_screen.dart';

class _MockConfirmar extends Mock implements ConfirmarResetPassword {}

AppButton _boton(WidgetTester tester) =>
    tester.widget<AppButton>(find.byType(AppButton));

Widget _buildScreen(_MockConfirmar confirmar, {String? email}) {
  return ProviderScope(
    overrides: [
      resetPasswordControllerProvider.overrideWith(
        (ref) => ResetPasswordController(confirmar: confirmar),
      ),
    ],
    child: MaterialApp(
      theme: AppTheme.light(),
      home: Scaffold(body: ResetPasswordScreen(email: email)),
    ),
  );
}

void main() {
  testWidgets('botón deshabilitado hasta completar código y contraseña',
      (tester) async {
    final confirmar = _MockConfirmar();
    await tester.pumpWidget(_buildScreen(confirmar, email: 'a@b.com'));

    expect(_boton(tester).onPressed, isNull);

    await tester.enterText(
        find.byType(TextField).at(1), '12345'); // código incompleto
    await tester.pump();
    expect(_boton(tester).onPressed, isNull);

    await tester.enterText(
        find.byType(TextField).at(1), '123456'); // código completo
    await tester.pump();
    expect(_boton(tester).onPressed, isNull); // falta contraseña

    await tester.enterText(
        find.byType(TextField).at(2), 'nueva1'); // contraseña 6+
    await tester.pump();
    expect(_boton(tester).onPressed, isNotNull);
  });

  testWidgets('éxito: llama al usecase y navega a /login', (tester) async {
    final confirmar = _MockConfirmar();
    when(() => confirmar('a@b.com', '123456', 'nueva1'))
        .thenAnswer((_) async {});

    await tester.pumpWidget(ProviderScope(
      overrides: [
        resetPasswordControllerProvider.overrideWith(
          (ref) => ResetPasswordController(confirmar: confirmar),
        ),
      ],
      child: MaterialApp.router(
        theme: AppTheme.light(),
        routerConfig: GoRouter(
          initialLocation: '/reset-password',
          routes: [
            GoRoute(
              path: '/reset-password',
              builder: (_, s) =>
                  ResetPasswordScreen(email: s.extra as String?),
            ),
            GoRoute(path: '/login', builder: (_, _) => const SizedBox()),
          ],
        ),
      ),
    ));

    await tester.enterText(find.byType(TextField).at(0), 'a@b.com');
    await tester.enterText(find.byType(TextField).at(1), '123456');
    await tester.enterText(find.byType(TextField).at(2), 'nueva1');
    await tester.pump();
    await tester.tap(find.text('RESTABLECER CONTRASEÑA'));
    await tester.pumpAndSettle();

    verify(() => confirmar('a@b.com', '123456', 'nueva1')).called(1);
    expect(find.byType(SizedBox), findsOneWidget);
  });

  testWidgets('error del servidor se muestra en pantalla', (tester) async {
    final confirmar = _MockConfirmar();
    when(() => confirmar(any(), any(), any()))
        .thenThrow(const ServerFailure());

    await tester.pumpWidget(_buildScreen(confirmar, email: 'a@b.com'));
    await tester.enterText(find.byType(TextField).at(1), '123456');
    await tester.enterText(find.byType(TextField).at(2), 'nueva1');
    await tester.pump();
    await tester.tap(find.text('RESTABLECER CONTRASEÑA'));
    await tester.pumpAndSettle();

    expect(find.text('Hubo un problema, probá de nuevo'), findsOneWidget);
  });
}