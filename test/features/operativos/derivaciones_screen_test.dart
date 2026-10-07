import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:prosane_app/core/providers.dart';
import 'package:prosane_app/features/operativos/data/operativos_repository.dart';
import 'package:prosane_app/features/operativos/presentation/screens/derivaciones_screen.dart';

class _MockRepo extends Mock implements OperativosRepository {}

void main() {
  final payload = {
    'total': 2,
    'por_especialidad': {'oftalmologia': 1, 'pediatria': 1},
    'derivaciones': [
      {
        'alumno_id': 'a1',
        'apellido': 'Perez',
        'nombre': 'Ana',
        'dni': '40111223',
        'curso': '3° A',
        'especialidad': 'oftalmologia',
        'especialidad_label': 'Oftalmología',
        'motivo': 'Disminucion agudeza',
        'profesional': 'Dra. X',
        'fecha_evaluacion': null,
      },
      {
        'alumno_id': 'a1',
        'apellido': 'Perez',
        'nombre': 'Ana',
        'dni': '40111223',
        'curso': '3° A',
        'especialidad': 'pediatria',
        'especialidad_label': 'Pediatría',
        'motivo': 'Control',
        'profesional': '',
        'fecha_evaluacion': null,
      },
    ],
  };

  Future<void> pump(WidgetTester t, _MockRepo repo) async {
    await t.pumpWidget(ProviderScope(
      overrides: [operativosRepositoryProvider.overrideWithValue(repo)],
      child: const MaterialApp(
        home: DerivacionesScreen(operativoId: 'op1'),
      ),
    ));
    await t.pumpAndSettle();
  }

  testWidgets('lista derivaciones con filtro por especialidad', (t) async {
    final repo = _MockRepo();
    when(() => repo.getDerivaciones('op1',
            especialidad: any(named: 'especialidad')))
        .thenAnswer((_) async => payload);
    await pump(t, repo);

    expect(find.text('Perez, Ana'), findsWidgets);
    expect(find.text('Disminucion agudeza'), findsOneWidget);
    expect(find.text('2 derivaciones'), findsOneWidget);

    await t.tap(find.text('Pediatría').first);
    await t.pumpAndSettle();
    verify(() => repo.getDerivaciones('op1', especialidad: 'pediatria'))
        .called(greaterThanOrEqualTo(1));
  });

  testWidgets('sin derivaciones muestra vacío', (t) async {
    final repo = _MockRepo();
    when(() => repo.getDerivaciones('op1',
            especialidad: any(named: 'especialidad')))
        .thenAnswer(
            (_) async => {'total': 0, 'por_especialidad': {}, 'derivaciones': []});
    await pump(t, repo);
    expect(find.text('Sin derivaciones registradas'), findsOneWidget);
  });
}
