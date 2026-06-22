import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prosane_app/core/design_system/app_dropdown_field.dart';

void main() {
  testWidgets('muestra label y opciones; dispara onChanged con el value', (tester) async {
    String? elegido;
    await tester.pumpWidget(MaterialApp(home: Scaffold(
      body: AppDropdownField(
        label: 'Sexo',
        items: const [(value: 'F', label: 'Femenino'), (value: 'M', label: 'Masculino')],
        onChanged: (v) => elegido = v,
      ),
    )));
    expect(find.text('Sexo'), findsOneWidget);
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Femenino').last);
    await tester.pumpAndSettle();
    expect(elegido, 'F');
  });
}
