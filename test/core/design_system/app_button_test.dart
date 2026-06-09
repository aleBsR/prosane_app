import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prosane_app/core/design_system/app_button.dart';

void main() {
  testWidgets('cargando muestra spinner y deshabilita onPressed', (tester) async {
    var taps = 0;
    await tester.pumpWidget(MaterialApp(home: Scaffold(
      body: AppButton(label: 'INICIAR SESIÓN', isLoading: true, onPressed: () => taps++))));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.tap(find.byType(AppButton));
    expect(taps, 0);
  });

  testWidgets('normal dispara onPressed', (tester) async {
    var taps = 0;
    await tester.pumpWidget(MaterialApp(home: Scaffold(
      body: AppButton(label: 'OK', onPressed: () => taps++))));
    await tester.tap(find.byType(AppButton));
    expect(taps, 1);
  });

  testWidgets('estado validado muestra el check; error muestra la X (sin label)', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(
      body: AppButton(label: 'OK', state: AppButtonState.validado))));
    expect(find.byIcon(Icons.check), findsOneWidget);
    expect(find.text('OK'), findsNothing); // en validado no se muestra el label
    await tester.pumpWidget(const MaterialApp(home: Scaffold(
      body: AppButton(label: 'OK', state: AppButtonState.error))));
    expect(find.byIcon(Icons.close), findsOneWidget);
    expect(find.text('OK'), findsNothing); // en error tampoco
  });

  testWidgets('sin onPressed queda deshabilitado y el tap no rompe', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(
      body: AppButton(label: 'OK'))));
    await tester.tap(find.byType(AppButton));
    await tester.pump();
    // No hay handler: el tap no debe lanzar excepción (test pasa si no tira).
    expect(tester.takeException(), isNull);
  });
}
