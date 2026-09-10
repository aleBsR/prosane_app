import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:prosane_app/core/providers.dart';
import 'package:prosane_app/core/theme/app_theme.dart';
import 'package:prosane_app/features/escuelas/data/escuelas_repository.dart';
import 'package:prosane_app/features/escuelas/presentation/controllers/escuelas_list_controller.dart';
import 'package:prosane_app/features/usuarios_escuela/data/usuarios_escuela_repository.dart';
import 'package:prosane_app/features/usuarios_escuela/presentation/controllers/usuarios_escuela_controller.dart';
import 'package:prosane_app/features/usuarios_escuela/presentation/screens/usuarios_escuela_screen.dart';

class _MockRepo extends Mock implements UsuariosEscuelaRepository {}

Widget _buildScreen(
    _MockRepo repo, List<UsuarioEscuela> usuarios, List<Escuela> escuelas) {
  return ProviderScope(
    overrides: [
      usuariosEscuelaRepositoryProvider.overrideWithValue(repo),
      usuariosEscuelaListProvider.overrideWith((ref) async => usuarios),
      escuelasListControllerProvider.overrideWith((ref) async => escuelas),
    ],
    child: MaterialApp(
      // Sin ripple: el shader ink_sparkle no carga en este entorno de test.
      theme: AppTheme.light().copyWith(splashFactory: NoSplash.splashFactory),
      home: const Scaffold(body: UsuariosEscuelaScreen()),
    ),
  );
}

void main() {
  final activa = Escuela(id: 'e1', nombre: 'Activa');
  final huerfano = UsuarioEscuela(
      id: 'u1', email: 'esc@test.com', escuelaId: 'borrada', escuelaNombre: null);

  testWidgets('editar usuario con escuela eliminada muestra aviso sin romper',
      (tester) async {
    await tester.pumpWidget(_buildScreen(_MockRepo(), [huerfano], [activa]));
    await tester.pumpAndSettle();

    // La tarjeta muestra "Sin escuela asignada" y menú ⋯ (sin iconos sueltos).
    expect(find.text('Sin escuela asignada'), findsOneWidget);
    expect(find.byIcon(Icons.edit_outlined), findsNothing);

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Editar'));
    await tester.pumpAndSettle();

    expect(find.text('Editar usuario'), findsOneWidget);
    expect(
        find.text(
            'La escuela asignada ya no está disponible: elegí una nueva.'),
        findsOneWidget);
  });

  testWidgets('editar usuario con escuela vigente no muestra aviso',
      (tester) async {
    final normal = UsuarioEscuela(
        id: 'u1',
        email: 'esc@test.com',
        escuelaId: 'e1',
        escuelaNombre: 'Activa');
    await tester.pumpWidget(_buildScreen(_MockRepo(), [normal], [activa]));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Editar'));
    await tester.pumpAndSettle();

    expect(find.text('Editar usuario'), findsOneWidget);
    expect(
        find.text(
            'La escuela asignada ya no está disponible: elegí una nueva.'),
        findsNothing);
  });
}
