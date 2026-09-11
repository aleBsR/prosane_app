import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:prosane_app/core/providers.dart';
import 'package:prosane_app/core/theme/app_theme.dart';
import 'package:prosane_app/features/escuelas/data/escuelas_repository.dart';
import 'package:prosane_app/features/escuelas/presentation/screens/escuela_create_screen.dart';

class _MockRepo extends Mock implements EscuelasRepository {}

Widget _buildScreen(_MockRepo repo) {
  return ProviderScope(
    overrides: [
      escuelasRepositoryProvider.overrideWithValue(repo),
    ],
    child: MaterialApp(
      theme: AppTheme.light(),
      home: const Scaffold(body: EscuelaCreateScreen()),
    ),
  );
}

void main() {
  testWidgets('alta mínima: solo pide nombre y CUE', (tester) async {
    await tester.pumpWidget(_buildScreen(_MockRepo()));
    await tester.pumpAndSettle();

    expect(find.text('Nombre *'), findsOneWidget);
    expect(find.text('CUE'), findsOneWidget);
    // El resto lo completa la escuela al ingresar.
    expect(find.text('Modalidad educativa'), findsNothing);
    expect(find.text('Sector de gestión'), findsNothing);
    expect(find.text('Teléfono'), findsNothing);
    expect(find.text('Localidad'), findsNothing);
    expect(
        find.text(
            'Solo se pide lo mínimo. Los demás datos del establecimiento los completa la escuela al ingresar.'),
        findsOneWidget);
  });
}
