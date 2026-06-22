import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:prosane_app/core/session/entities.dart';
import 'package:prosane_app/core/session/session_controller.dart';
import 'package:prosane_app/features/hijos/hijos_count_provider.dart';
import 'package:prosane_app/features/pendientes/presentation/pendientes_screen.dart';

// Helper para construir una sesión de tutor
SessionController _tutorController() => SessionController()
  ..setSesion(const Sesion(
    usuario: Usuario(id: 'u1', nombre: 'Marta', rolName: 'tutor', rolLabel: 'Tutor/a'),
    acciones: [],
  ));

// Helper para construir una sesión de otro rol (médico)
SessionController _medicoController() => SessionController()
  ..setSesion(const Sesion(
    usuario: Usuario(id: 'u2', nombre: 'Carlos', rolName: 'medico', rolLabel: 'Médico/a'),
    acciones: [],
  ));

void main() {
  testWidgets('sin pendientes muestra "Todo sincronizado"', (t) async {
    await t.pumpWidget(ProviderScope(
      overrides: [
        sessionControllerProvider.overrideWith((ref) => _medicoController()),
        hijosCountProvider.overrideWith((ref) => Future.value(0)),
      ],
      child: const MaterialApp(home: PendientesScreen()),
    ));
    await t.pumpAndSettle();
    expect(find.text('Todo sincronizado'), findsOneWidget);
  });

  testWidgets('tutor con 0 hijos ve el nudge de consentimiento', (t) async {
    final router = GoRouter(
      initialLocation: '/pendientes',
      routes: [
        GoRoute(path: '/pendientes', builder: (c, s) => const PendientesScreen()),
        GoRoute(
          path: '/hijos/nuevo',
          builder: (c, s) => const Scaffold(body: Text('Planilla familiar')),
        ),
      ],
    );

    await t.pumpWidget(ProviderScope(
      overrides: [
        sessionControllerProvider.overrideWith((ref) => _tutorController()),
        hijosCountProvider.overrideWith((ref) => Future.value(0)),
      ],
      child: MaterialApp.router(routerConfig: router),
    ));
    await t.pumpAndSettle();

    expect(find.textContaining('Completá el consentimiento'), findsOneWidget);
    expect(find.text('Todo sincronizado'), findsNothing);
  });

  testWidgets('tutor con 0 hijos: tocar nudge navega a /hijos/nuevo', (t) async {
    final router = GoRouter(
      initialLocation: '/pendientes',
      routes: [
        GoRoute(path: '/pendientes', builder: (c, s) => const PendientesScreen()),
        GoRoute(
          path: '/hijos/nuevo',
          builder: (c, s) => const Scaffold(body: Text('Planilla familiar')),
        ),
      ],
    );

    await t.pumpWidget(ProviderScope(
      overrides: [
        sessionControllerProvider.overrideWith((ref) => _tutorController()),
        hijosCountProvider.overrideWith((ref) => Future.value(0)),
      ],
      child: MaterialApp.router(routerConfig: router),
    ));
    await t.pumpAndSettle();

    await t.tap(find.textContaining('Completá el consentimiento'));
    await t.pumpAndSettle();

    expect(router.routeInformationProvider.value.uri.path, '/hijos/nuevo');
  });

  testWidgets('tutor con ≥1 hijo NO ve el nudge, muestra "Todo sincronizado"', (t) async {
    await t.pumpWidget(ProviderScope(
      overrides: [
        sessionControllerProvider.overrideWith((ref) => _tutorController()),
        hijosCountProvider.overrideWith((ref) => Future.value(1)),
      ],
      child: const MaterialApp(home: PendientesScreen()),
    ));
    await t.pumpAndSettle();

    expect(find.textContaining('Completá el consentimiento'), findsNothing);
    expect(find.text('Todo sincronizado'), findsOneWidget);
  });

  testWidgets('médico con 0 hijos NO ve el nudge, muestra "Todo sincronizado"', (t) async {
    await t.pumpWidget(ProviderScope(
      overrides: [
        sessionControllerProvider.overrideWith((ref) => _medicoController()),
        hijosCountProvider.overrideWith((ref) => Future.value(0)),
      ],
      child: const MaterialApp(home: PendientesScreen()),
    ));
    await t.pumpAndSettle();

    expect(find.textContaining('Completá el consentimiento'), findsNothing);
    expect(find.text('Todo sincronizado'), findsOneWidget);
  });
}
