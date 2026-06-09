import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../session/entities.dart';
import '../session/session_controller.dart';

typedef Redirect = String? Function(String location);

/// Función PURA del guard: dada la sesión (autenticado o no), decide el redirect.
/// Testeable sin Flutter ni Riverpod.
Redirect construirRedirect(bool autenticado) => (location) {
      final enAuth = location == '/login' || location == '/signup';
      if (!autenticado && !enAuth) return '/login';
      if (autenticado && enAuth) return '/home';
      return null;
    };

/// Arma el GoRouter cableando el guard con el estado de sesión.
/// Las rutas son PLACEHOLDERS hasta la Fase 5 (login/signup/home reales).
GoRouter buildRouter(Ref ref) {
  final autenticado = ref.read(sessionControllerProvider) is SesionAutenticada;
  final redirect = construirRedirect(autenticado);
  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) => redirect(state.matchedLocation),
    routes: [
      GoRoute(path: '/login', builder: (c, s) => const _Placeholder('login')),
      GoRoute(path: '/signup', builder: (c, s) => const _Placeholder('signup')),
      GoRoute(path: '/home', builder: (c, s) => const _Placeholder('home')),
    ],
  );
}

class _Placeholder extends StatelessWidget {
  const _Placeholder(this.nombre);
  final String nombre;
  @override
  Widget build(BuildContext context) =>
      Scaffold(body: Center(child: Text('placeholder: $nombre')));
}
