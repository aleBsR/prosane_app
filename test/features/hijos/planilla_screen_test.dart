import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:prosane_app/core/database/app_database.dart';
import 'package:prosane_app/core/database/database_provider.dart';
import 'package:prosane_app/core/design_system/app_button.dart';
import 'package:prosane_app/core/session/entities.dart';
import 'package:prosane_app/core/session/session_controller.dart';
import 'package:prosane_app/features/hijos/presentation/screens/planilla_screen.dart';

SessionController _tutor() => SessionController()
  ..setSesion(const Sesion(
    usuario: Usuario(id: 'u1', nombre: 'Juan', rolName: 'tutor', rolLabel: 'Tutor', tutorId: 'tut-1'),
    acciones: [],
  ));

Widget _app(AppDatabase db) {
  final router = GoRouter(initialLocation: '/hijos/nuevo', routes: [
    GoRoute(path: '/hijos/nuevo', builder: (c, s) => const PlanillaScreen()),
    GoRoute(path: '/inicio', builder: (c, s) => const Scaffold(body: Text('inicio'))),
  ]);
  return ProviderScope(
    overrides: [
      databaseProvider.overrideWithValue(db),
      sessionControllerProvider.overrideWith((ref) => _tutor()),
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

void main() {
  testWidgets('muestra las 3 cards y NO la de antecedentes', (t) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    await t.pumpWidget(_app(db));
    await t.pumpAndSettle();
    expect(find.text('Datos del niño/a'), findsOneWidget);
    expect(find.text('Domicilio'), findsOneWidget);
    expect(find.text('Cobertura de salud'), findsOneWidget);
    expect(find.textContaining('Antecedentes', findRichText: true), findsNothing);
    expect(find.textContaining('Asma', findRichText: true), findsNothing);
  });

  testWidgets('muestra campos nuevos de domicilio y telefonos', (t) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    await t.pumpWidget(_app(db));
    await t.pumpAndSettle();
    expect(find.text('Teléfono fijo'), findsOneWidget);
    expect(find.text('Celular'), findsOneWidget);
    expect(find.text('Piso'), findsOneWidget);
    expect(find.text('Localidad'), findsOneWidget);
  });

  testWidgets('nombre de cobertura NO aparece por defecto (sin cobertura elegida)', (t) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    await t.pumpWidget(_app(db));
    await t.pumpAndSettle();
    expect(find.text('Nombre de la cobertura'), findsNothing);
  });

  testWidgets('Guardar arranca deshabilitado sin requeridos', (t) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    await t.pumpWidget(_app(db));
    await t.pumpAndSettle();
    final boton = t.widget<AppButton>(find.byType(AppButton));
    expect(boton.onPressed, isNull);
  });
}
