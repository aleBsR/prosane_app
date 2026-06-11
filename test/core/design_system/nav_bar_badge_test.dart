import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prosane_app/core/design_system/nav_bar_badge.dart';

void main() {
  Future<void> pump(WidgetTester t, int count) => t.pumpWidget(
      MaterialApp(home: Scaffold(body: NavBarBadge(count: count))));

  testWidgets('count 0 → no muestra nada', (t) async {
    await pump(t, 0);
    expect(find.byType(Text), findsNothing);
  });

  testWidgets('count 3 → muestra "3"', (t) async {
    await pump(t, 3);
    expect(find.text('3'), findsOneWidget);
  });

  testWidgets('count 99 → muestra "99" (no "99+")', (t) async {
    await pump(t, 99);
    expect(find.text('99'), findsOneWidget);
    expect(find.text('99+'), findsNothing);
  });

  testWidgets('count > 99 → muestra "99+"', (t) async {
    await pump(t, 150);
    expect(find.text('99+'), findsOneWidget);
  });
}
