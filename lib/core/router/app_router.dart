import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../session/entities.dart';
import '../session/session_controller.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/signup_wizard_screen.dart';
import '../../features/home/presentation/home_screen.dart';

typedef Redirect = String? Function(String location);

/// Función PURA del guard: dada la sesión (autenticado o no), decide el redirect.
/// Testeable sin Flutter ni Riverpod.
Redirect construirRedirect(bool autenticado) => (location) {
      final enAuth = location == '/login' || location == '/signup';
      if (!autenticado && !enAuth) return '/login';
      if (autenticado && enAuth) return '/home';
      return null;
    };

/// Provider reactivo a la sesión: cuando cambia el estado, go_router re-evalúa
/// el redirect via [refreshListenable].
final goRouterProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<int>(0);
  ref.listen(sessionControllerProvider, (prev, next) => refresh.value++);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: '/login',
    refreshListenable: refresh,
    redirect: (context, state) {
      final autenticado =
          ref.read(sessionControllerProvider) is SesionAutenticada;
      return construirRedirect(autenticado)(state.matchedLocation);
    },
    routes: [
      GoRoute(path: '/login', builder: (c, s) => const LoginScreen()),
      GoRoute(path: '/signup', builder: (c, s) => const SignupWizardScreen()),
      GoRoute(path: '/home', builder: (c, s) => const HomeScreen()),
    ],
  );
});
