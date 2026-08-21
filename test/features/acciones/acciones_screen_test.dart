import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:prosane_app/core/session/entities.dart';
import 'package:prosane_app/core/session/session_controller.dart';
import 'package:prosane_app/features/acciones/presentation/acciones_screen.dart';

Accion _a(String name, String label, String cat) => Accion(name: name, label: label, icon: 'draw',
    color: '#2E7D32', type: 'form', category: cat, isSensitive: false, sortOrder: 1);

void main() {
  Future<void> pump(WidgetTester t, List<Accion> acciones) async {
    final c = SessionController()..setSesion(Sesion(
        usuario: const Usuario(id: '1', nombre: 'Ana', rolName: 'medico', rolLabel: 'Médico/a'),
        acciones: acciones));
    // c es propiedad del ProviderScope: lo destruye al hacer dispose del scope.
    // No llamar c.dispose() en tearDown para evitar el doble-dispose.
    await t.pumpWidget(ProviderScope(
      overrides: [sessionControllerProvider.overrideWith((ref) => c)],
      child: const MaterialApp(home: AccionesScreen()),
    ));
  }

  testWidgets('agrupa por categoría y lista las acciones del rol', (t) async {
    await pump(t, [_a('listarPacientes', 'Listar pacientes', 'salud'), _a('verConstancias', 'Ver constancias', 'consentimiento')]);
    // Los headers de grupo son visibles aunque los grupos arranquen colapsados
    expect(find.text('SALUD'), findsOneWidget);
    expect(find.text('CONSENTIMIENTO'), findsOneWidget);
    // Las acciones están ocultas hasta que se expande el grupo
    expect(find.text('Listar pacientes'), findsNothing);
    // Al tocar el header SALUD se expande y aparece la acción
    await t.tap(find.text('SALUD'));
    await t.pumpAndSettle();
    expect(find.text('Listar pacientes'), findsOneWidget);
  });

  testWidgets('sin acciones muestra el estado vacío', (t) async {
    await pump(t, const []);
    expect(find.text('No tenés acciones disponibles todavía'), findsOneWidget);
  });

  testWidgets('tocar una acción abre el placeholder "próximamente"', (t) async {
    await pump(t, [_a('firmarApto', 'Firmar apto físico', 'salud')]);
    // El grupo arranca colapsado: expandir primero
    await t.tap(find.text('SALUD'));
    await t.pumpAndSettle();
    await t.tap(find.text('Firmar apto físico'));
    await t.pumpAndSettle();
    expect(find.textContaining('próximamente'), findsOneWidget);
  });

  testWidgets('registrarHijo navega a /hijos/nuevo', (t) async {
    final router = GoRouter(
      initialLocation: '/inicio',
      routes: [
        GoRoute(path: '/inicio', builder: (c, s) => const AccionesScreen()),
        GoRoute(path: '/hijos/nuevo', builder: (c, s) => const Scaffold(body: Text('Planilla familiar'))),
      ],
    );

    final c = SessionController()
      ..setSesion(Sesion(
          usuario: const Usuario(id: '1', nombre: 'Ana', rolName: 'tutor', rolLabel: 'Tutor', consentimientoAceptado: true),
          acciones: [_a('registrarHijo', 'Registrar hijo', 'familia')]));

    await t.pumpWidget(ProviderScope(
      overrides: [sessionControllerProvider.overrideWith((ref) => c)],
      child: MaterialApp.router(routerConfig: router),
    ));
    await t.pumpAndSettle();

    // El grupo arranca colapsado: expandir primero
    await t.tap(find.text('FAMILIA'));
    await t.pumpAndSettle();

    await t.tap(find.text('Registrar hijo'));
    await t.pumpAndSettle();

    expect(router.state.uri.path, '/hijos/nuevo');
  });

  testWidgets('verHijos navega a /hijos', (t) async {
    final router = GoRouter(
      initialLocation: '/inicio',
      routes: [
        GoRoute(path: '/inicio', builder: (c, s) => const AccionesScreen()),
        GoRoute(path: '/hijos', builder: (c, s) => const Scaffold(body: Text('Mis hijos'))),
      ],
    );

    final c = SessionController()
      ..setSesion(Sesion(
          usuario: const Usuario(id: '1', nombre: 'Ana', rolName: 'medico', rolLabel: 'Médico/a'),
          acciones: [_a('verHijos', 'Ver hijos', 'familia')]));

    await t.pumpWidget(ProviderScope(
      overrides: [sessionControllerProvider.overrideWith((ref) => c)],
      child: MaterialApp.router(routerConfig: router),
    ));
    await t.pumpAndSettle();

    await t.tap(find.text('FAMILIA'));
    await t.pumpAndSettle();

    await t.tap(find.text('Ver hijos'));
    await t.pumpAndSettle();

    expect(router.state.uri.path, '/hijos');
  });

  testWidgets('registrarHijo sin consentimiento navega a /consentimiento', (t) async {
    final router = GoRouter(
      initialLocation: '/inicio',
      routes: [
        GoRoute(path: '/inicio', builder: (c, s) => const AccionesScreen()),
        GoRoute(path: '/consentimiento', builder: (c, s) => const Scaffold(body: Text('Consentimiento'))),
      ],
    );

    final c = SessionController()
      ..setSesion(Sesion(
          usuario: const Usuario(id: '1', nombre: 'Ana', rolName: 'tutor', rolLabel: 'Tutor'),
          acciones: [_a('registrarHijo', 'Registrar hijo', 'familia')]));

    await t.pumpWidget(ProviderScope(
      overrides: [sessionControllerProvider.overrideWith((ref) => c)],
      child: MaterialApp.router(routerConfig: router),
    ));
    await t.pumpAndSettle();

    await t.tap(find.text('FAMILIA'));
    await t.pumpAndSettle();

    await t.tap(find.text('Registrar hijo'));
    await t.pumpAndSettle();

    expect(router.state.uri.path, '/consentimiento');
  });

  testWidgets('darConsentimiento navega a /consentimiento', (t) async {
    final router = GoRouter(
      initialLocation: '/inicio',
      routes: [
        GoRoute(path: '/inicio', builder: (c, s) => const AccionesScreen()),
        GoRoute(path: '/consentimiento', builder: (c, s) => const Scaffold(body: Text('Consentimiento'))),
      ],
    );

    final c = SessionController()
      ..setSesion(Sesion(
          usuario: const Usuario(id: '1', nombre: 'Ana', rolName: 'tutor', rolLabel: 'Tutor'),
          acciones: [_a('darConsentimiento', 'Dar consentimiento', 'familia')]));

    await t.pumpWidget(ProviderScope(
      overrides: [sessionControllerProvider.overrideWith((ref) => c)],
      child: MaterialApp.router(routerConfig: router),
    ));
    await t.pumpAndSettle();

    await t.tap(find.text('FAMILIA'));
    await t.pumpAndSettle();

    await t.tap(find.text('Dar consentimiento'));
    await t.pumpAndSettle();

    expect(router.state.uri.path, '/consentimiento');
  });

  testWidgets('cargarAntecedentesFamiliares navega a /antecedentes-familiares', (t) async {
    final router = GoRouter(
      initialLocation: '/inicio',
      routes: [
        GoRoute(path: '/inicio', builder: (c, s) => const AccionesScreen()),
        GoRoute(path: '/antecedentes-familiares', builder: (c, s) => const Scaffold(body: Text('Antecedentes familiares'))),
      ],
    );

    final c = SessionController()
      ..setSesion(Sesion(
          usuario: const Usuario(id: '1', nombre: 'Ana', rolName: 'tutor', rolLabel: 'Tutor'),
          acciones: [_a('cargarAntecedentesFamiliares', 'Antecedentes familiares', 'familia')]));

    await t.pumpWidget(ProviderScope(
      overrides: [sessionControllerProvider.overrideWith((ref) => c)],
      child: MaterialApp.router(routerConfig: router),
    ));
    await t.pumpAndSettle();

    await t.tap(find.text('FAMILIA'));
    await t.pumpAndSettle();

    await t.tap(find.text('Antecedentes familiares'));
    await t.pumpAndSettle();

    expect(router.state.uri.path, '/antecedentes-familiares');
  });

  testWidgets('verGestionUsuarios navega a /gestion-usuarios', (t) async {
    final router = GoRouter(
      initialLocation: '/inicio',
      routes: [
        GoRoute(path: '/inicio', builder: (c, s) => const AccionesScreen()),
        GoRoute(path: '/gestion-usuarios', builder: (c, s) => const Scaffold(body: Text('Gestión de usuarios'))),
      ],
    );

    final c = SessionController()
      ..setSesion(Sesion(
          usuario: const Usuario(id: '1', nombre: 'Admin', rolName: 'superadmin', rolLabel: 'Superadmin'),
          acciones: [_a('verGestionUsuarios', 'Gestión de usuarios', 'usuarios')]));

    await t.pumpWidget(ProviderScope(
      overrides: [sessionControllerProvider.overrideWith((ref) => c)],
      child: MaterialApp.router(routerConfig: router),
    ));
    await t.pumpAndSettle();

    await t.tap(find.text('USUARIOS'));
    await t.pumpAndSettle();

    await t.tap(find.text('Gestión de usuarios'));
    await t.pumpAndSettle();

    expect(router.state.uri.path, '/gestion-usuarios');
  });

  testWidgets('verEscuelas navega a /escuelas y no a /operativos', (t) async {
    final router = GoRouter(
      initialLocation: '/inicio',
      routes: [
        GoRoute(path: '/inicio', builder: (c, s) => const AccionesScreen()),
        GoRoute(path: '/escuelas', builder: (c, s) => const Scaffold(body: Text('Lista de escuelas'))),
      ],
    );

    final c = SessionController()
      ..setSesion(Sesion(
          usuario: const Usuario(id: '1', nombre: 'Ana', rolName: 'superadmin', rolLabel: 'Superadmin'),
          acciones: [_a('verEscuelas', 'Ver escuelas', 'escuelas')]));

    await t.pumpWidget(ProviderScope(
      overrides: [sessionControllerProvider.overrideWith((ref) => c)],
      child: MaterialApp.router(routerConfig: router),
    ));
    await t.pumpAndSettle();

    await t.tap(find.text('ESCUELAS'));
    await t.pumpAndSettle();

    await t.tap(find.text('Ver escuelas'));
    await t.pumpAndSettle();

    expect(router.state.uri.path, '/escuelas');
  });
}
