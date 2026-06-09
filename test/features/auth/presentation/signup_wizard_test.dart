import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prosane_app/core/theme/app_theme.dart';
import 'package:prosane_app/features/auth/presentation/screens/signup_wizard_screen.dart';

void main() {
  testWidgets('conserva los datos al avanzar y volver de etapa', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const SignupWizardScreen(),
        ),
      ),
    );
    await tester.pump();

    // --- Etapa 0: completar campos para habilitar SIGUIENTE ---

    // Seleccionar tipo de documento = 'DNI'
    final tipoDocFinder = find.byKey(const Key('signup_tipo_documento'));
    await tester.ensureVisible(tipoDocFinder);
    await tester.pump();
    await tester.tap(tipoDocFinder);
    await tester.pumpAndSettle();
    // En el menú dropdown aparecen ítems, seleccionar DNI
    await tester.tap(find.text('DNI').last);
    await tester.pumpAndSettle();

    // Ingresar número de documento
    final numDocFinder = find.byKey(const Key('signup_numero_documento'));
    await tester.ensureVisible(numDocFinder);
    await tester.pump();
    await tester.enterText(numDocFinder, '12345678');
    await tester.pump();

    // Activar el switch "Acepto la política"
    // Tapeamos el texto del label que está dentro del GestureDetector del
    // AppSwitch pero FUERA del IgnorePointer del Switch track → hit garantizado.
    final switchLabelFinder = find.text('Acepto la política de privacidad y términos');
    await tester.ensureVisible(switchLabelFinder);
    await tester.pump();
    await tester.tap(switchLabelFinder);
    await tester.pump();

    // Verificar que SIGUIENTE está en el árbol y tocarlo
    final siguienteFinder = find.byKey(const Key('wizard_siguiente'));
    await tester.ensureVisible(siguienteFinder);
    await tester.pump();
    await tester.tap(siguienteFinder);
    await tester.pumpAndSettle();

    // Verificar que estamos en la etapa 2 (debe aparecer "Etapa 2 de 4")
    expect(find.text('Etapa 2 de 4'), findsOneWidget);

    // --- Volver a etapa 0 ---
    final anteriorFinder = find.byKey(const Key('wizard_anterior'));
    await tester.ensureVisible(anteriorFinder);
    await tester.pump();
    await tester.tap(anteriorFinder);
    await tester.pumpAndSettle();

    // Estamos en etapa 0 nuevamente
    expect(find.text('Etapa 1 de 4'), findsOneWidget);

    // El campo numeroDocumento debe conservar '12345678' (gracias al IndexedStack)
    expect(find.text('12345678'), findsOneWidget);
  });

  testWidgets('SIGUIENTE deshabilitado cuando etapa 0 incompleta', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const SignupWizardScreen(),
        ),
      ),
    );
    await tester.pump();

    // Sin completar nada, tocar SIGUIENTE no debe cambiar de etapa
    final siguienteFinder = find.byKey(const Key('wizard_siguiente'));
    await tester.ensureVisible(siguienteFinder);
    await tester.pump();
    await tester.tap(siguienteFinder, warnIfMissed: false);
    await tester.pumpAndSettle();

    // Seguimos en etapa 1/4
    expect(find.text('Etapa 1 de 4'), findsOneWidget);
  });

  testWidgets('ANTERIOR no aparece en etapa 0', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const SignupWizardScreen(),
        ),
      ),
    );
    await tester.pump();

    expect(find.byKey(const Key('wizard_anterior')), findsNothing);
  });

  testWidgets('link iniciar sesión presente en etapa 0', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const SignupWizardScreen(),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('¿Ya tienes una cuenta? Ingrese aquí'), findsOneWidget);
  });
}
