import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prosane_app/core/design_system/action_tile.dart';

void main() {
  testWidgets('muestra label e ícono y dispara onTap', (t) async {
    var tapped = false;
    await t.pumpWidget(MaterialApp(home: Scaffold(body: ActionTile(
      color: const Color(0xFF2E7D32), icon: Icons.draw_outlined, label: 'Firmar apto físico',
      onTap: () => tapped = true))));
    expect(find.text('Firmar apto físico'), findsOneWidget);
    expect(find.byIcon(Icons.draw_outlined), findsOneWidget);
    await t.tap(find.text('Firmar apto físico'));
    expect(tapped, true);
  });

  testWidgets('expone Semantics de botón con el label', (t) async {
    final handle = t.ensureSemantics();
    await t.pumpWidget(MaterialApp(home: Scaffold(body: ActionTile(
      color: const Color(0xFF1565C0), icon: Icons.people_outline, label: 'Listar pacientes', onTap: () {}))));
    expect(
      t.getSemantics(find.bySemanticsLabel('Listar pacientes')),
      isSemantics(isButton: true, label: 'Listar pacientes'),
    );
    handle.dispose();
  });
}
