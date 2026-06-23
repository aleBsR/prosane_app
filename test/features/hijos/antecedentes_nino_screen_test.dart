import 'dart:convert';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:prosane_app/core/database/app_database.dart';
import 'package:prosane_app/core/database/database_provider.dart';
import 'package:prosane_app/features/hijos/presentation/screens/antecedentes_nino_screen.dart';

Widget _app(AppDatabase db) {
  final router = GoRouter(initialLocation: '/hijos/h1/antecedentes', routes: [
    GoRoute(
      path: '/hijos/:hijoLocalId/antecedentes',
      builder: (c, s) => AntecedentesNinoScreen(hijoLocalId: s.pathParameters['hijoLocalId']!),
    ),
    GoRoute(path: '/inicio', builder: (c, s) => const Scaffold(body: Text('inicio'))),
  ]);
  return ProviderScope(
    overrides: [databaseProvider.overrideWithValue(db)],
    child: MaterialApp.router(routerConfig: router),
  );
}

void main() {
  testWidgets('muestra la pregunta de prematuro y oculta menstruación si es M', (t) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    await db.insertHijoDraft(
      id: 'h1', tutorId: 'tut-1', nombreNna: 'Juan', apellidoNna: 'P',
      payloadJson: jsonEncode({'persona': {'sexo': 'M'}}),
    );
    await t.pumpWidget(_app(db));
    await t.pumpAndSettle();
    expect(find.textContaining('prematuro', findRichText: true), findsOneWidget);
    expect(find.textContaining('menstruación', findRichText: true), findsNothing);
  });

  testWidgets('muestra menstruación si es F', (t) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    await db.insertHijoDraft(
      id: 'h1', tutorId: 'tut-1', nombreNna: 'Ana', apellidoNna: 'P',
      payloadJson: jsonEncode({'persona': {'sexo': 'F'}}),
    );
    await t.pumpWidget(_app(db));
    await t.pumpAndSettle();
    expect(find.textContaining('menstruación', findRichText: true), findsWidgets);
  });
}
