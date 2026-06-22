import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prosane_app/core/design_system/app_date_field.dart';

void main() {
  testWidgets('muestra hint sin valor y la fecha formateada con valor', (tester) async {
    await tester.pumpWidget(MaterialApp(home: Scaffold(
      body: AppDateField(label: 'Fecha', value: null, onChanged: (_) {}),
    )));
    expect(find.text('Seleccionar fecha'), findsOneWidget);

    await tester.pumpWidget(MaterialApp(home: Scaffold(
      body: AppDateField(label: 'Fecha', value: DateTime(2015, 3, 7), onChanged: (_) {}),
    )));
    expect(find.text('07/03/2015'), findsOneWidget);
  });

  testWidgets('abre el date picker al tocar', (tester) async {
    await tester.pumpWidget(MaterialApp(home: Scaffold(
      body: AppDateField(label: 'Fecha', value: null, onChanged: (_) {}),
    )));
    await tester.tap(find.byType(GestureDetector));
    await tester.pumpAndSettle();
    expect(find.text('OK'), findsOneWidget);
  });
}
