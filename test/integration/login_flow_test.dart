import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:prosane_app/app.dart';
import 'package:prosane_app/core/session/entities.dart';
import 'package:prosane_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:prosane_app/core/providers.dart';

class _FakeAuthRepo extends Mock implements AuthRepository {}

void main() {
  testWidgets('login exitoso navega de /login a /home', (tester) async {
    final repo = _FakeAuthRepo();
    when(() => repo.login(any(), any())).thenAnswer((_) async => Sesion(
          usuario: const Usuario(id: '1', nombre: 'Ana', rolName: 'profesional', rolLabel: 'Profesional'),
          acciones: const [],
        ));

    await tester.pumpWidget(ProviderScope(
      overrides: [authRepositoryProvider.overrideWithValue(repo)],
      child: const ProsaneApp(),
    ));
    await tester.pumpAndSettle();

    // Estamos en /login (LoginScreen). Completar y enviar.
    expect(find.text('Bienvenido'), findsOneWidget);
    await tester.enterText(find.byType(TextField).at(0), 'a@b.com');
    await tester.enterText(find.byType(TextField).at(1), 'secreto');
    await tester.tap(find.text('INICIAR SESIÓN'));
    await tester.pumpAndSettle();

    // Tras login, el guard redirige a /home.
    expect(find.text('Bienvenido'), findsNothing);
    // En /home hay algo identificable (ajustá al texto/Key de tu HomeScreen):
    expect(find.byKey(const Key('home_screen')), findsOneWidget);
  });

  testWidgets('logout navega de /home a /login', (tester) async {
    final repo = _FakeAuthRepo();
    when(() => repo.login(any(), any())).thenAnswer((_) async => Sesion(
          usuario: const Usuario(id: '1', nombre: 'Ana', rolName: 'profesional', rolLabel: 'Profesional'),
          acciones: const [],
        ));

    await tester.pumpWidget(ProviderScope(
      overrides: [authRepositoryProvider.overrideWithValue(repo)],
      child: const ProsaneApp(),
    ));
    await tester.pumpAndSettle();

    // Login → /home
    await tester.enterText(find.byType(TextField).at(0), 'a@b.com');
    await tester.enterText(find.byType(TextField).at(1), 'secreto');
    await tester.tap(find.text('INICIAR SESIÓN'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('home_screen')), findsOneWidget);

    // Cerrar sesión (IconButton del AppBar) → el guard vuelve a /login
    await tester.tap(find.byTooltip('Cerrar sesión'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('home_screen')), findsNothing);
    expect(find.text('Bienvenido'), findsOneWidget);
  });
}
