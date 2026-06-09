import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prosane_app/app.dart';

void main() {
  testWidgets('la app arranca en /login (sin sesión)', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: ProsaneApp()));
    await tester.pumpAndSettle();
    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.text('Bienvenido'), findsOneWidget); // arranca en LoginScreen
  });
}
