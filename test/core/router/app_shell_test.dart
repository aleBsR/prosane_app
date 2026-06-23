import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prosane_app/core/design_system/floating_nav_bar.dart';
import 'package:prosane_app/core/router/app_shell.dart';

void main() {
  testWidgets('al scrollear hacia abajo la barra se compacta', (t) async {
    await t.pumpWidget(MaterialApp(home: AppShell(
      selectedIndex: 0, onTap: (_) {},
      child: ListView(children: List.generate(40, (i) => SizedBox(height: 60, child: Text('item $i')))),
    )));
    FloatingNavBar barra() => t.widget<FloatingNavBar>(find.byType(FloatingNavBar));
    expect(barra().compacta, false);                 // arriba: expandida
    await t.drag(find.text('item 1'), const Offset(0, -300));
    await t.pump();
    expect(barra().compacta, true);                  // scroll abajo: compacta
  });

  testWidgets('el badge de Pendientes refleja badgePendientes', (t) async {
    await t.pumpWidget(MaterialApp(home: AppShell(
      selectedIndex: 0, onTap: (_) {}, badgePendientes: 3,
      child: const SizedBox())));
    expect(find.text('3'), findsOneWidget);
  });

  testWidgets('badgePendientes 0 → no muestra badge', (t) async {
    await t.pumpWidget(MaterialApp(home: AppShell(
      selectedIndex: 0, onTap: (_) {}, badgePendientes: 0, child: const SizedBox())));
    expect(find.text('0'), findsNothing);
  });

  testWidgets('el tab Pendientes está visible para todos los roles', (t) async {
    await t.pumpWidget(MaterialApp(home: AppShell(
      selectedIndex: 0, onTap: (_) {}, child: const SizedBox())));
    expect(find.text('Pendientes'), findsOneWidget);
  });
}
