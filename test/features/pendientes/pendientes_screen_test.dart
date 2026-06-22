import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:prosane_app/core/database/app_database.dart';
import 'package:prosane_app/core/database/database_provider.dart';
import 'package:prosane_app/core/session/entities.dart';
import 'package:prosane_app/core/session/session_controller.dart';
import 'package:prosane_app/features/pendientes/presentation/pendientes_screen.dart';

// ---------------------------------------------------------------------------
// Helpers de sesión
// ---------------------------------------------------------------------------

SessionController _tutorSinConsentimiento() => SessionController()
  ..setSesion(const Sesion(
    usuario: Usuario(
      id: 'u1',
      nombre: 'Marta',
      rolName: 'tutor',
      rolLabel: 'Tutor/a',
      consentimientoAceptado: false,
      antecedentesFamiliaresCompletos: false,
    ),
    acciones: [],
  ));

SessionController _tutorCompleto() => SessionController()
  ..setSesion(const Sesion(
    usuario: Usuario(
      id: 'u1',
      nombre: 'Marta',
      rolName: 'tutor',
      rolLabel: 'Tutor/a',
      consentimientoAceptado: true,
      antecedentesFamiliaresCompletos: true,
    ),
    acciones: [],
  ));

SessionController _medicoController() => SessionController()
  ..setSesion(const Sesion(
    usuario: Usuario(id: 'u2', nombre: 'Carlos', rolName: 'medico', rolLabel: 'Médico/a'),
    acciones: [],
  ));

// ---------------------------------------------------------------------------
// Helpers de widget
// ---------------------------------------------------------------------------

/// Construye un MaterialApp.router con la PendientesScreen en /pendientes y
/// un stub para la ruta de destino indicada.
Widget _appConRouter({
  required ProviderContainer container,
  required String rutaStub,
  required String textoStub,
}) {
  final router = GoRouter(
    initialLocation: '/pendientes',
    routes: [
      GoRoute(path: '/pendientes', builder: (c, s) => const PendientesScreen()),
      GoRoute(path: rutaStub, builder: (c, s) => Scaffold(body: Text(textoStub))),
    ],
  );
  return UncontrolledProviderScope(
    container: container,
    child: MaterialApp.router(routerConfig: router),
  );
}

/// Crea un ProviderContainer con DB en memoria + sesión dada.
ProviderContainer _container({
  required AppDatabase db,
  required SessionController Function() controllerFactory,
}) =>
    ProviderContainer(overrides: [
      databaseProvider.overrideWithValue(db),
      sessionControllerProvider.overrideWith((ref) => controllerFactory()),
    ]);

void main() {
  // ---------------------------------------------------------------------------
  // 1. Todo sincronizado (sin pendientes)
  // ---------------------------------------------------------------------------

  testWidgets('tutor con todo hecho y sin hijos → "Todo sincronizado"', (t) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final c = _container(db: db, controllerFactory: _tutorCompleto);
    addTearDown(c.dispose);

    await t.pumpWidget(UncontrolledProviderScope(
      container: c,
      child: const MaterialApp(home: PendientesScreen()),
    ));
    await t.pumpAndSettle();

    expect(find.text('Todo sincronizado'), findsOneWidget);
  });

  testWidgets('médico no ve pendientes → "Todo sincronizado"', (t) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final c = _container(db: db, controllerFactory: _medicoController);
    addTearDown(c.dispose);

    await t.pumpWidget(UncontrolledProviderScope(
      container: c,
      child: const MaterialApp(home: PendientesScreen()),
    ));
    await t.pumpAndSettle();

    expect(find.text('Todo sincronizado'), findsOneWidget);
  });

  // ---------------------------------------------------------------------------
  // 2. Tutor con consent pendiente → ve card "Consentimiento"
  // ---------------------------------------------------------------------------

  testWidgets('tutor sin consentimiento ve card "Consentimiento"', (t) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final c = _container(db: db, controllerFactory: _tutorSinConsentimiento);
    addTearDown(c.dispose);

    await t.pumpWidget(UncontrolledProviderScope(
      container: c,
      child: const MaterialApp(home: PendientesScreen()),
    ));
    await t.pumpAndSettle();

    expect(find.text('Consentimiento'), findsOneWidget);
    expect(find.text('Todo sincronizado'), findsNothing);
  });

  // ---------------------------------------------------------------------------
  // 3. Tap en card de consentimiento navega a /consentimiento
  // ---------------------------------------------------------------------------

  testWidgets('tocar card "Consentimiento" navega a /consentimiento', (t) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final c = _container(db: db, controllerFactory: _tutorSinConsentimiento);
    addTearDown(c.dispose);

    await t.pumpWidget(_appConRouter(
      container: c,
      rutaStub: '/consentimiento',
      textoStub: 'Pantalla consentimiento',
    ));
    await t.pumpAndSettle();

    // Tocar la card de consentimiento (GestureDetector envuelve la card)
    await t.tap(find.text('Consentimiento'));
    await t.pumpAndSettle();

    expect(find.text('Pantalla consentimiento'), findsOneWidget);
  });

  // ---------------------------------------------------------------------------
  // 4. Tutor con hijos → cards de evaluación
  // ---------------------------------------------------------------------------

  testWidgets('tutor con 1 hijo vivo (todo general OK) → card de evaluación', (t) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    await db.insertHijoDraft(
      id: 'h1', tutorId: 'u1', nombreNna: 'Lucía', apellidoNna: 'G', payloadJson: '{}',
    );
    await db.marcarHijoSincronizado('h1');

    final c = _container(db: db, controllerFactory: _tutorCompleto);
    addTearDown(c.dispose);

    await t.pumpWidget(UncontrolledProviderScope(
      container: c,
      child: const MaterialApp(home: PendientesScreen()),
    ));
    await t.pumpAndSettle();

    expect(find.textContaining('Lucía'), findsOneWidget);
    expect(find.text('Todo sincronizado'), findsNothing);
  });
}
