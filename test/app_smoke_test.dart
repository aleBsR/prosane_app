import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prosane_app/app.dart';

void main() {
  testWidgets('la app arranca y muestra un MaterialApp', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: ProsaneApp()));
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
