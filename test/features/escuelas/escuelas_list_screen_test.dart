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
      theme: AppTheme.light(),
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

  testWidgets('lista las escuelas y muestra iconos de editar y eliminar',
      (tester) async {
    final repo = _MockRepo();
    await tester.pumpWidget(_buildScreen(repo, [escuela]));
    await tester.pumpAndSettle();

    expect(find.text('Escuela 1'), findsOneWidget);
    expect(find.byIcon(Icons.edit_outlined), findsOneWidget);
    expect(find.byIcon(Icons.delete_outline), findsOneWidget);
  });

  testWidgets('editar abre el diálogo y llama al repositorio', (tester) async {
    final repo = _MockRepo();
    when(() => repo.obtener('e1')).thenAnswer((_) async => escuela);
    when(() => repo.editar(any(), any())).thenAnswer((_) async => escuela);

    await tester.pumpWidget(_buildScreen(repo, [escuela]));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.edit_outlined));
    await tester.pumpAndSettle();

    expect(find.text('Editar escuela'), findsOneWidget);

    await tester.enterText(find.byType(TextField).at(0), 'Escuela 1 editada');
    await tester.pump();
    await tester.tap(find.text('Guardar'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    verify(() => repo.editar('e1', any(that: isA<Map<String, dynamic>>())))
        .called(1);
    expect(find.text('Editar escuela'), findsNothing);
  });

  testWidgets('eliminar muestra confirmación y llama al repositorio',
      (tester) async {
    final repo = _MockRepo();
    when(() => repo.eliminar('e1')).thenAnswer((_) async {});

    await tester.pumpWidget(_buildScreen(repo, [escuela]));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();

    expect(find.text('¿Eliminar Escuela 1?'), findsOneWidget);

    await tester.tap(find.text('Eliminar'));
    await tester.pumpAndSettle();

    verify(() => repo.eliminar('e1')).called(1);
    expect(find.text('¿Eliminar Escuela 1?'), findsNothing);
  });
}