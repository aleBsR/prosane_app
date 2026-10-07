import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:prosane_app/core/providers.dart';
import 'package:prosane_app/core/theme/app_theme.dart';
import 'package:prosane_app/features/usuarios_administrativos/data/usuarios_administrativos_repository.dart';
import 'package:prosane_app/features/usuarios_administrativos/presentation/controllers/usuarios_administrativos_controller.dart';
import 'package:prosane_app/features/usuarios_administrativos/presentation/screens/usuarios_administrativos_screen.dart';

class _MockRepo extends Mock implements UsuariosAdministrativosRepository {}

Widget _buildScreen(_MockRepo repo, List<UsuarioAdministrativo> usuarios) {
  return ProviderScope(
    overrides: [
      usuariosAdministrativosRepositoryProvider.overrideWithValue(repo),
      usuariosAdministrativosListProvider.overrideWith((ref) async => usuarios),
    ],
    child: MaterialApp(
      theme: AppTheme.light(),
      home: const Scaffold(body: UsuariosAdministrativosScreen()),
    ),
  );
}

void main() {
  testWidgets('muestra el estado vacío cuando no hay usuarios', (tester) async {
    final repo = _MockRepo();
    await tester.pumpWidget(_buildScreen(repo, []));
    await tester.pumpAndSettle();

    expect(find.text('No hay usuarios administrativos'), findsOneWidget);
  });

  testWidgets('lista los usuarios existentes', (tester) async {
    final repo = _MockRepo();
    final usuarios = [
      UsuarioAdministrativo(id: '1', email: 'ana@mail.com', isActive: true),
      UsuarioAdministrativo(id: '2', email: 'pedro@mail.com', isActive: false),
    ];
    await tester.pumpWidget(_buildScreen(repo, usuarios));
    await tester.pumpAndSettle();

    expect(find.text('ana@mail.com'), findsOneWidget);
    expect(find.text('pedro@mail.com'), findsOneWidget);
    expect(find.text('Cuenta desactivada'), findsOneWidget);
  });

  testWidgets('crear: el diálogo valida y llama al repositorio', (tester) async {
    final repo = _MockRepo();
    when(() => repo.crear(email: any(named: 'email')))
        .thenAnswer((_) async =>
            UsuarioAdministrativo(id: '9', email: 'nuevo@mail.com', isActive: true));

    await tester.pumpWidget(_buildScreen(repo, []));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Nuevo usuario'));
    await tester.pumpAndSettle();

    expect(find.text('Nuevo usuario administrativo'), findsOneWidget);

    await tester.enterText(find.byType(TextField).at(0), 'nuevo@mail.com');
    await tester.enterText(find.byType(TextField).at(1), 'nuevo@mail.com');
    await tester.pump();
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();

    verify(() => repo.crear(email: 'nuevo@mail.com'))
        .called(1);
    expect(find.text('Nuevo usuario administrativo'), findsNothing);
  });

  testWidgets('crear: bloquea el guardado si los correos no coinciden', (tester) async {
    final repo = _MockRepo();
    when(() => repo.crear(email: any(named: 'email')))
        .thenAnswer((_) async =>
            UsuarioAdministrativo(id: '9', email: 'nuevo@mail.com', isActive: true));

    await tester.pumpWidget(_buildScreen(repo, []));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Nuevo usuario'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).at(0), 'nuevo@mail.com');
    await tester.enterText(find.byType(TextField).at(1), 'otro@mail.com');
    await tester.pump();
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();

    verifyNever(() => repo.crear(email: any(named: 'email')));
    expect(find.text('Los correos no coinciden'), findsWidgets);
  });
}