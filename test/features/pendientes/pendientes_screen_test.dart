import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prosane_app/features/pendientes/presentation/pendientes_screen.dart';

void main() {
  testWidgets('sin pendientes muestra "Todo sincronizado"', (t) async {
    await t.pumpWidget(const MaterialApp(home: PendientesScreen()));
    expect(find.text('Todo sincronizado'), findsOneWidget);
  });
}
