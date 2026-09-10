import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:prosane_app/core/providers.dart';
import 'package:prosane_app/core/theme/app_theme.dart';
import 'package:prosane_app/features/escuelas/data/escuelas_repository.dart';
import 'package:prosane_app/features/escuelas/presentation/controllers/cursos_controller.dart';
import 'package:prosane_app/features/escuelas/presentation/screens/cursos_screen.dart';

class _MockRepo extends Mock implements EscuelasRepository {}

Widget _buildScreen(_MockRepo repo) {
  final curso = Curso(
      id: 'c1',
      escuela: 'e1',
      salaGradoAnio: '1°',
      division: 'A',
      cicloLectivo: 2026);
  return ProviderScope(
    overrides: [
      escuelasRepositoryProvider.overrideWithValue(repo),
      cursosProvider.overrideWith((ref, id) async => [curso]),
      cursosControllerProvider.overrideWith(
          (ref, id) => CursosController(repo, id)),
    ],
    child: MaterialApp(
      // Sin ripple: el shader ink_sparkle no carga en este entorno de test.
      theme: AppTheme.light().copyWith(splashFactory: NoSplash.splashFactory),
      home: const Scaffold(
          body: CursosScreen(escuelaId: 'e1', escuelaNombre: 'Escuela 1')),
    ),
  );
}

void main() {
  testWidgets('tarjeta con menú ⋯ para editar y eliminar', (tester) async {
    await tester.pumpWidget(_buildScreen(_MockRepo()));
    await tester.pumpAndSettle();

    expect(find.text('1° A'), findsOneWidget);
    // Sin iconos sueltos: todo va por el menú.
    expect(find.byIcon(Icons.edit_outlined), findsNothing);
    expect(find.byIcon(Icons.delete_outline), findsNothing);

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();

    expect(find.text('Editar'), findsOneWidget);
    expect(find.text('Eliminar'), findsOneWidget);
  });

  testWidgets('Editar abre el diálogo', (tester) async {
    await tester.pumpWidget(_buildScreen(_MockRepo()));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Editar'));
    await tester.pumpAndSettle();

    expect(find.text('Editar curso'), findsOneWidget);
  });
}
