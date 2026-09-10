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
}
