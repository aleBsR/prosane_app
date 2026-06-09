import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:prosane_app/core/error/failure.dart';
import 'package:prosane_app/core/session/entities.dart';
import 'package:prosane_app/core/theme/app_theme.dart';
import 'package:prosane_app/features/auth/domain/usecases/login.dart';
import 'package:prosane_app/features/auth/presentation/controllers/login_controller.dart';
import 'package:prosane_app/features/auth/presentation/screens/login_screen.dart';

class _MockLogin extends Mock implements Login {}

/// Helper: monta la LoginScreen con un override del loginControllerProvider.
Widget _buildScreen(LoginController Function() factory) {
  return ProviderScope(
    overrides: [
      loginControllerProvider.overrideWith((ref) => factory()),
    ],
    child: MaterialApp(
      theme: AppTheme.light(),
      home: const Scaffold(
        body: LoginScreen(),
      ),
    ),
  );
}

void main() {
  testWidgets('(a) tocar INICIAR SESIÓN llama enviar en el controller', (tester) async {
    final mockLogin = _MockLogin();
    // Completer nunca completa → no hay timers pendientes, el future queda vivo
    // solo mientras el widget está montado; autoDispose lo cancela al desmontar.
    final completer = Completer<Sesion>();
    when(() => mockLogin.call(any(), any()))
        .thenAnswer((_) => completer.future);

    await tester.pumpWidget(_buildScreen(
      () => LoginController(login: mockLogin, onAutenticado: (_) {}),
    ));

    await tester.pump(); // primer frame

    await tester.tap(find.text('INICIAR SESIÓN'));
    await tester.pump();

    verify(() => mockLogin.call(any(), any())).called(1);
  });

  testWidgets('(b) con isLoading: true el botón muestra el spinner', (tester) async {
    final mockLogin = _MockLogin();
    // login que nunca completa → el controller queda en isLoading: true
    final neverCompletes = Completer<Sesion>(); // dart:async Completer
    when(() => mockLogin.call(any(), any()))
        .thenAnswer((_) => neverCompletes.future);

    await tester.pumpWidget(_buildScreen(
      () => LoginController(login: mockLogin, onAutenticado: (_) {}),
    ));

    await tester.pump();
    await tester.tap(find.text('INICIAR SESIÓN'));
    await tester.pump();

    // Con isLoading: true el AppButton renderiza un CircularProgressIndicator
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('(c) con error no nulo se muestra el mensaje de error', (tester) async {
    final mockLogin = _MockLogin();
    when(() => mockLogin.call(any(), any()))
        .thenThrow(const InvalidCredentialsFailure());

    await tester.pumpWidget(_buildScreen(
      () => LoginController(login: mockLogin, onAutenticado: (_) {}),
    ));

    await tester.pump();
    await tester.tap(find.text('INICIAR SESIÓN'));
    await tester.pumpAndSettle();

    // El mensaje de error aparece en la pantalla
    expect(find.text('Credenciales incorrectas'), findsWidgets);
  });
}

