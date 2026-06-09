import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prosane_app/core/design_system/app_text_field.dart';

void main() {
  testWidgets('muestra label y errorText', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(
      body: AppTextField(label: 'E-mail', errorText: 'Campo requerido'))));
    expect(find.text('E-mail'), findsOneWidget);
    expect(find.text('Campo requerido'), findsOneWidget);
  });

  testWidgets('password: el ojo alterna la visibilidad', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(
      body: AppTextField(label: 'Contraseña', isPassword: true))));
    expect(find.byIcon(Icons.visibility_off), findsOneWidget);
    expect(tester.widget<TextField>(find.byType(TextField)).obscureText, isTrue);

    await tester.tap(find.byIcon(Icons.visibility_off));
    await tester.pump();

    expect(find.byIcon(Icons.visibility), findsOneWidget);
    expect(tester.widget<TextField>(find.byType(TextField)).obscureText, isFalse);
  });

  testWidgets('estado validado muestra el check', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(
      body: AppTextField(label: 'Cuil', isValid: true))));
    expect(find.byIcon(Icons.check_circle), findsOneWidget);
  });

  testWidgets('helperText solo (sin errorText) se muestra y no explota', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(
      body: AppTextField(label: 'Cuil', helperText: 'Ingrese su número de Cuil'))));
    expect(find.text('Ingrese su número de Cuil'), findsOneWidget);
    expect(find.byIcon(Icons.cancel), findsNothing); // no es estado de error
  });
}
