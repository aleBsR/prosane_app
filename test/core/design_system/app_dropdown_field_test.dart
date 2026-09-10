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

  testWidgets('valor fuera de lista no rompe y muestra el hint', (tester) async {
    await tester.pumpWidget(MaterialApp(home: Scaffold(
      body: AppDropdownField(
        label: 'Última consulta',
        hint: 'Seleccioná',
        value: '2026-01-15', // dato viejo/inválido: no está en items
        items: const [
          (value: 'menos_1_anio', label: 'Hace menos de 1 año'),
          (value: 'NINGUNA', label: 'Ninguna'),
        ],
        onChanged: (_) {},
      ),
    )));
    await tester.pumpAndSettle();

    expect(find.text('Última consulta'), findsOneWidget);
    expect(find.text('Seleccioná'), findsOneWidget);
    expect(find.text('2026-01-15'), findsNothing);
  });
}
