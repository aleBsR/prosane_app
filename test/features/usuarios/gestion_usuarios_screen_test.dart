import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:prosane_app/core/session/entities.dart';
import 'package:prosane_app/core/session/session_controller.dart';
import 'package:prosane_app/features/usuarios/presentation/screens/gestion_usuarios_screen.dart';

Accion _a(String name, String label, String cat) => Accion(
    name: name,
    label: label,
    icon: 'draw',
    color: '#2E7D32',
    type: 'form',
    category: cat,
    isSensitive: false,
    sortOrder: 1);

void main() {
  testWidgets('muestra las tres opciones de gestión', (tester) async {
    final c = SessionController()
      ..setSesion(Sesion(
          usuario: const Usuario(
              id: '1', nombre: 'Admin', rolName: 'superadmin', rolLabel: 'Superadmin'),
          acciones: [
            _a('verGestionUsuarios', 'Gestión de usuarios', 'usuarios'),
            _a('gestionarUsuariosEscuela', 'Gestionar usuarios escuela', 'usuarios'),
            _a('gestionarAyudantes', 'Gestionar usuarios ayudantes', 'usuarios'),
            _a('gestionarProfesionales', 'Gestionar profesionales', 'usuarios'),
          ]));

    await tester.pumpWidget(ProviderScope(
      overrides: [sessionControllerProvider.overrideWith((ref) => c)],
      child: const MaterialApp(home: GestionUsuariosScreen()),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Gestión de usuarios'), findsOneWidget);
    expect(find.text('Usuarios de escuelas'), findsOneWidget);
    expect(find.text('Ayudantes'), findsOneWidget);
    expect(find.text('Profesionales'), findsOneWidget);
  });

  testWidgets('navega a usuarios-escuela', (tester) async {
    final router = GoRouter(
      initialLocation: '/gestion-usuarios',
      routes: [
        GoRoute(path: '/gestion-usuarios', builder: (c, s) => const GestionUsuariosScreen()),
        GoRoute(path: '/usuarios-escuela', builder: (c, s) => const Scaffold(body: Text('Usuarios escuela'))),
      ],
    );

    final c = SessionController()
      ..setSesion(Sesion(
          usuario: const Usuario(
              id: '1', nombre: 'Admin', rolName: 'superadmin', rolLabel: 'Superadmin'),
          acciones: [_a('gestionarUsuariosEscuela', 'Gestionar usuarios escuela', 'usuarios')]));

    await tester.pumpWidget(ProviderScope(
      overrides: [sessionControllerProvider.overrideWith((ref) => c)],
      child: MaterialApp.router(routerConfig: router),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Usuarios de escuelas'));
    await tester.pumpAndSettle();

    expect(router.state.uri.path, '/usuarios-escuela');
  });
}