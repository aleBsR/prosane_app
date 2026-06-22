import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prosane_app/core/design_system/app_gradient_scaffold.dart';

void main() {
  testWidgets('tocar fuera de un input cierra el teclado (pierde foco)', (tester) async {
    final focus = FocusNode();
    await tester.pumpWidget(MaterialApp(
      home: AppGradientScaffold(
        child: Column(children: [
          TextField(focusNode: focus),
          const SizedBox(height: 200, child: Text('zona vacía')),
        ]),
      ),
    ));

    // Foco el campo (simula abrir el teclado).
    await tester.tap(find.byType(TextField));
    await tester.pump();
    expect(focus.hasFocus, isTrue);

    // Toco fuera del input → debe perder el foco.
    await tester.tap(find.text('zona vacía'));
    await tester.pump();
    expect(focus.hasFocus, isFalse);
  });

  testWidgets('renderiza el child', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: AppGradientScaffold(child: Text('hola')),
    ));
    expect(find.text('hola'), findsOneWidget);
  });
}
