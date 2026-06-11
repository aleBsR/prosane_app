import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prosane_app/core/design_system/floating_nav_bar.dart';

void main() {
  final items = const [
    NavItemData(outlinedIcon: Icons.home_outlined, filledIcon: Icons.home, label: 'Inicio'),
    NavItemData(outlinedIcon: Icons.sync_outlined, filledIcon: Icons.sync, label: 'Pendientes', badgeCount: 3),
    NavItemData(outlinedIcon: Icons.person_outline, filledIcon: Icons.person, label: 'Usuario'),
  ];

  Future<void> pump(WidgetTester t, {required bool compacta, int selected = 0, void Function(int)? onTap}) =>
      t.pumpWidget(MaterialApp(home: Scaffold(body: FloatingNavBar(
        items: items, selectedIndex: selected, compacta: compacta, onTap: onTap ?? (_) {}))));

  testWidgets('expandida muestra los labels; el activo usa el ícono filled', (t) async {
    await pump(t, compacta: false, selected: 0);
    expect(find.text('Inicio'), findsOneWidget);
    expect(find.byIcon(Icons.home), findsOneWidget);          // activo = filled
    expect(find.byIcon(Icons.sync_outlined), findsOneWidget);  // inactivo = outline
  });

  testWidgets('compacta NO muestra labels', (t) async {
    await pump(t, compacta: true);
    expect(find.text('Inicio'), findsNothing);
  });

  testWidgets('muestra el badge del item con badgeCount > 0', (t) async {
    await pump(t, compacta: false);
    expect(find.text('3'), findsOneWidget);
  });

  testWidgets('tocar un item dispara onTap con su índice', (t) async {
    int? tapped;
    await pump(t, compacta: false, onTap: (i) => tapped = i);
    await t.tap(find.text('Usuario'));
    expect(tapped, 2);
  });
}
