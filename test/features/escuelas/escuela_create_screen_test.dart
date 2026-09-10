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
  testWidgets('modalidad es desplegable con Común y Especial',
      (tester) async {
    await tester.pumpWidget(_buildScreen(_MockRepo()));
    await tester.pumpAndSettle();

    expect(find.text('Modalidad educativa'), findsOneWidget);
    // No hay campo de texto libre para la modalidad.
    expect(
        find.widgetWithText(TextField, 'Para plurigrado escribí'),
        findsNothing);

    // Abre el segundo desplegable (el primero es Sector de gestión).
    await tester.tap(find.byType(DropdownButtonFormField<String>).at(1));
    await tester.pumpAndSettle();

    expect(find.text('Común'), findsWidgets);
    expect(find.text('Especial'), findsWidgets);
  });

  testWidgets('sector ofrece Estatal, Privado y Social/cooperativa',
      (tester) async {
    await tester.pumpWidget(_buildScreen(_MockRepo()));
    await tester.pumpAndSettle();

    // Abre el primer desplegable (Sector de gestión).
    await tester.tap(find.byType(DropdownButtonFormField<String>).at(0));
    await tester.pumpAndSettle();

    expect(find.text('Estatal'), findsWidgets);
    expect(find.text('Privado'), findsWidgets);
    expect(find.text('Social/cooperativa'), findsWidgets);
    expect(find.text('Obra Social'), findsNothing);
  });
}
