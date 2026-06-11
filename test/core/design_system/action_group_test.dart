import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prosane_app/core/design_system/action_group.dart';

void main() {
  Future<void> pump(WidgetTester t) => t.pumpWidget(const MaterialApp(home: Scaffold(
      body: ActionGroup(titulo: 'SALUD', children: [Text('hijo')]))));

  testWidgets('arranca expandido: el hijo es visible', (t) async {
    await pump(t);
    expect(find.text('hijo'), findsOneWidget);
    expect(find.text('SALUD'), findsOneWidget);
  });

  testWidgets('tocar el header colapsa (oculta el hijo)', (t) async {
    await pump(t);
    await t.tap(find.text('SALUD'));
    await t.pumpAndSettle();
    expect(find.text('hijo'), findsNothing);
  });

  testWidgets('tocar de nuevo vuelve a expandir (el hijo reaparece)', (t) async {
    await pump(t);
    await t.tap(find.text('SALUD'));
    await t.pumpAndSettle();
    expect(find.text('hijo'), findsNothing);
    await t.tap(find.text('SALUD'));
    await t.pumpAndSettle();
    expect(find.text('hijo'), findsOneWidget);
  });
}
