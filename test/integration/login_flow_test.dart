import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:prosane_app/app.dart';
import 'package:prosane_app/core/session/entities.dart';
import 'package:prosane_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:prosane_app/core/providers.dart';
import 'package:drift/native.dart';
import 'package:prosane_app/core/database/app_database.dart';
import 'package:prosane_app/core/database/database_provider.dart';

class _FakeAuthRepo extends Mock implements AuthRepository {}

void main() {
  testWidgets('login exitoso navega de /login a /inicio (AccionesScreen)', (tester) async {
    final repo = _FakeAuthRepo();
    when(() => repo.login(any(), any())).thenAnswer((_) async => Sesion(
          usuario: const Usuario(id: '1', nombre: 'Ana', rolName: 'profesional', rolLabel: 'Profesional'),
          acciones: const [],
        ));
    when(() => repo.sesionCacheada()).thenAnswer((_) async => null);

    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    await tester.pumpWidget(ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(repo),
        databaseProvider.overrideWithValue(db),
      ],
      child: const ProsaneApp(),
    ));
    await tester.pumpAndSettle();

    // Estamos en /login (LoginScreen). Completar y enviar.
    expect(find.text('Bienvenido'), findsOneWidget);
    await tester.enterText(find.byType(TextField).at(0), 'a@b.com');
    await tester.enterText(find.byType(TextField).at(1), 'secreto');
    await tester.tap(find.text('INICIAR SESIÓN'));
    await tester.pumpAndSettle();

    // Tras login, el guard redirige a /inicio (AccionesScreen + AppShell).
    expect(find.text('Bienvenido'), findsNothing);
    // Sin acciones asignadas, AccionesScreen muestra el estado vacío.
    expect(find.text('No tenés acciones disponibles todavía'), findsOneWidget);
  });

  testWidgets('logout navega de /inicio a /login', (tester) async {
    final repo = _FakeAuthRepo();
    when(() => repo.login(any(), any())).thenAnswer((_) async => Sesion(
          usuario: const Usuario(id: '1', nombre: 'Ana', rolName: 'profesional', rolLabel: 'Profesional'),
          acciones: const [],
        ));
    when(() => repo.sesionCacheada()).thenAnswer((_) async => null);
    when(() => repo.logout()).thenAnswer((_) async {});

    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    await tester.pumpWidget(ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(repo),
        databaseProvider.overrideWithValue(db),
      ],
      child: const ProsaneApp(),
    ));
    await tester.pumpAndSettle();

    // Login → /inicio
    await tester.enterText(find.byType(TextField).at(0), 'a@b.com');
    await tester.enterText(find.byType(TextField).at(1), 'secreto');
    await tester.tap(find.text('INICIAR SESIÓN'));
    await tester.pumpAndSettle();
    expect(find.text('No tenés acciones disponibles todavía'), findsOneWidget);

    // Navegar a la pestaña Usuario (índice 2 en la FloatingNavBar).
    await tester.tap(find.text('Usuario'));
    await tester.pumpAndSettle();

    // Cerrar sesión desde UsuarioScreen → el guard vuelve a /login
    await tester.tap(find.text('Cerrar sesión'));
    await tester.pumpAndSettle();
    expect(find.text('No tenés acciones disponibles todavía'), findsNothing);
    expect(find.text('Bienvenido'), findsOneWidget);
  });
}
