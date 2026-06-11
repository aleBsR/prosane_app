import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prosane_app/core/design_system/empty_state.dart';

void main() {
  testWidgets('muestra título y subtítulo', (t) async {
    await t.pumpWidget(const MaterialApp(home: Scaffold(body: EmptyState(
      icon: Icons.inbox_outlined, titulo: 'No tenés acciones disponibles todavía',
      subtitulo: 'Cuando te asignen un rol, vas a ver acá lo que podés hacer.'))));
    expect(find.text('No tenés acciones disponibles todavía'), findsOneWidget);
    expect(find.text('Cuando te asignen un rol, vas a ver acá lo que podés hacer.'), findsOneWidget);
    expect(find.byIcon(Icons.inbox_outlined), findsOneWidget);
  });

  testWidgets('sin subtítulo no rompe', (t) async {
    await t.pumpWidget(const MaterialApp(home: Scaffold(body: EmptyState(
      icon: Icons.check_circle_outline, titulo: 'Todo sincronizado'))));
    expect(find.text('Todo sincronizado'), findsOneWidget);
    expect(find.byType(Text), findsOneWidget); // solo el título, sin subtítulo
  });
}
