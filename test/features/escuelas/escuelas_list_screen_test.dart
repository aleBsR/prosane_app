import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:prosane_app/core/providers.dart';
import 'package:prosane_app/core/theme/app_theme.dart';
import 'package:prosane_app/features/escuelas/data/escuelas_repository.dart';
import 'package:prosane_app/features/escuelas/presentation/controllers/escuelas_list_controller.dart';
import 'package:prosane_app/features/escuelas/presentation/screens/escuelas_list_screen.dart';

class _MockRepo extends Mock implements EscuelasRepository {}

Widget _buildScreen(_MockRepo repo, List<Escuela> escuelas) {
  return ProviderScope(
    overrides: [
      escuelasRepositoryProvider.overrideWithValue(repo),
      escuelasListControllerProvider.overrideWith((ref) async => escuelas),
    ],
    child: MaterialApp(
      // Sin ripple: el shader ink_sparkle no carga en este entorno de test.
      theme: AppTheme.light().copyWith(splashFactory: NoSplash.splashFactory),
      home: const Scaffold(body: EscuelasListScreen()),
    ),
  );
}

void main() {
  final escuela = Escuela(
    id: 'e1',
    nombre: 'Escuela 1',
    cue: '66000001',
    localidad: 'Salta',
    activa: true,
  );

  testWidgets('lista las escuelas sin acciones por tarjeta', (tester) async {
    final repo = _MockRepo();
    await tester.pumpWidget(_buildScreen(repo, [escuela]));
    await tester.pumpAndSettle();

    expect(find.text('Escuela 1'), findsOneWidget);
    // La tarjeta solo navega al detalle: sin editar/eliminar acá.
    expect(find.byIcon(Icons.edit_outlined), findsNothing);
    expect(find.byIcon(Icons.delete_outline), findsNothing);
  });

  testWidgets('la tarjeta muestra nombre, CUE, localidad y usuario asociado',
      (tester) async {
    final repo = _MockRepo();
    final completa = Escuela(
      id: 'e2',
      nombre: 'Rural',
      cue: '66000002',
      localidad: 'Cerrillos',
      ambito: 'rural',
      plurigradoRural: true,
      usuariosAsociados: [
        {'email': 'escuela@prosane.test', 'nombre': '', 'is_active': true},
      ],
    );
    await tester.pumpWidget(_buildScreen(repo, [completa]));
    await tester.pumpAndSettle();

    expect(find.text('Rural'), findsOneWidget);
    expect(find.text('CUE 66000002 • Cerrillos'), findsOneWidget);
    expect(find.text('Usuario: escuela@prosane.test'), findsOneWidget);
    expect(find.text('Sin usuario asociado'), findsNothing);
    // Nada más: ni ámbito ni notas en la lista.
    expect(find.textContaining('rural'), findsNothing);
    expect(find.text('Plurigrado rural: no usa cursos'), findsNothing);
  });

  testWidgets('la tarjeta advierte si no hay usuario asociado',
      (tester) async {
    final repo = _MockRepo();
    await tester.pumpWidget(_buildScreen(repo, [escuela]));
    await tester.pumpAndSettle();

    expect(find.text('Escuela 1'), findsOneWidget);
    expect(find.text('Sin usuario asociado'), findsOneWidget);
  });
}
