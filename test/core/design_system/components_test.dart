import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prosane_app/core/design_system/app_switch.dart';
import 'package:prosane_app/core/design_system/app_link.dart';
import 'package:prosane_app/core/design_system/app_gradient_scaffold.dart';
import 'package:prosane_app/core/design_system/app_card.dart';

void main() {
  testWidgets('AppSwitch dispara onChanged una sola vez (sin doble-toggle)', (tester) async {
    var calls = 0;
    bool? changed;
    await tester.pumpWidget(MaterialApp(home: Scaffold(
      body: AppSwitch(value: false, label: 'Recordarme', onChanged: (v) { calls++; changed = v; }))));
    await tester.tap(find.byType(AppSwitch));
    expect(changed, true);
    expect(calls, 1);
  });

  testWidgets('AppLink dispara onTap', (tester) async {
    var tapped = false;
    await tester.pumpWidget(MaterialApp(home: Scaffold(
      body: AppLink(text: 'Regístrese aquí', onTap: () => tapped = true))));
    await tester.tap(find.text('Regístrese aquí'));
    expect(tapped, true);
  });

  testWidgets('AppGradientScaffold y AppCard renderizan su child', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: AppGradientScaffold(
      child: AppCard(child: Text('contenido')))));
    expect(find.text('contenido'), findsOneWidget);
  });
}
