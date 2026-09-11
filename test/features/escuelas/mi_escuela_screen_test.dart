import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prosane_app/core/theme/app_theme.dart';
import 'package:prosane_app/features/escuelas/presentation/controllers/mi_escuela_controller.dart';
import 'package:prosane_app/features/escuelas/presentation/screens/mi_escuela_screen.dart';

Widget _buildScreen(Map<String, dynamic> escuela) {
  return ProviderScope(
    overrides: [
      miEscuelaProvider.overrideWith((ref) async => escuela),
    ],
    child: MaterialApp(
      theme: AppTheme.light(),
      home: const Scaffold(body: MiEscuelaScreen()),
    ),
  );
}

void main() {
  testWidgets('plurigrado oculta Gestionar cursos y muestra aviso',
      (tester) async {
    await tester.pumpWidget(_buildScreen({
      'id': 'e1',
      'nombre': 'Rural',
      'plurigrado_rural': true,
      'cursos': [],
    }));
    await tester.pumpAndSettle();

    expect(find.text('Gestionar cursos'), findsNothing);
    expect(
        find.text(
            'Escuela plurigrado rural: no necesita cursos. Los alumnos se registran sin curso.'),
        findsOneWidget);
  });

  testWidgets('escuela común muestra Gestionar cursos', (tester) async {
    await tester.pumpWidget(_buildScreen({
      'id': 'e1',
      'nombre': 'Urbana',
      'plurigrado_rural': false,
      'cursos': [],
    }));
    await tester.pumpAndSettle();

    expect(find.text('Gestionar cursos'), findsOneWidget);
  });

  testWidgets('perfil incompleto muestra aviso obligatorio', (tester) async {
    await tester.pumpWidget(_buildScreen({
      'id': 'e1',
      'nombre': 'Incompleta',
      'plurigrado_rural': false,
      'cursos': [],
      'perfil_completo': false,
      'campos_faltantes': ['CUE', 'Teléfono'],
    }));
    await tester.pumpAndSettle();

    expect(find.text('Completá los datos de tu escuela (obligatorio)'),
        findsOneWidget);
    expect(find.text('Completar datos'), findsOneWidget);
  });

  testWidgets('perfil completo no muestra aviso', (tester) async {
    await tester.pumpWidget(_buildScreen({
      'id': 'e1',
      'nombre': 'Completa',
      'plurigrado_rural': false,
      'cursos': [],
      'perfil_completo': true,
      'campos_faltantes': [],
    }));
    await tester.pumpAndSettle();

    expect(find.text('Completá los datos de tu escuela (obligatorio)'),
        findsNothing);
    expect(find.text('Completar datos'), findsNothing);
  });
}
