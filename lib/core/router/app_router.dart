import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../session/entities.dart';
import '../session/session_controller.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/signup_wizard_screen.dart';
import '../../features/acciones/presentation/acciones_screen.dart';
import '../../features/pendientes/presentation/pendientes_screen.dart';
import '../../features/usuario/presentation/usuario_screen.dart';
import '../../features/pendientes/pendientes_count_provider.dart';
import '../../features/hijos/presentation/screens/hijos_list_screen.dart';
import '../../features/hijos/presentation/screens/planilla_screen.dart';
import '../../features/hijos/presentation/screens/antecedentes_nino_screen.dart';
import '../../features/familia/presentation/consentimiento_screen.dart';
import '../../features/familia/presentation/antecedentes_familiares_screen.dart';
import '../../features/operativos/presentation/screens/operativos_list_screen.dart';
import '../../features/operativos/presentation/screens/operativo_create_screen.dart';
import '../../features/operativos/presentation/screens/operativo_detail_screen.dart';
import '../../features/operativos/presentation/screens/evaluacion_medica_screen.dart';
import '../../features/operativos/presentation/screens/evaluacion_odontologica_screen.dart';
import '../../features/operativos/presentation/screens/seccion_escuela_screen.dart';
import '../../features/escuelas/presentation/screens/escuela_create_screen.dart';
import 'app_shell.dart';

typedef Redirect = String? Function(String location);

/// Función PURA del guard: dada la sesión (autenticado o no), decide el redirect.
/// Testeable sin Flutter ni Riverpod.
Redirect construirRedirect(bool autenticado) => (location) {
      final enAuth = location == '/login' || location == '/signup';
      if (!autenticado && !enAuth) return '/login';
      if (autenticado && enAuth) return '/inicio';
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
      GoRoute(path: '/hijos', builder: (c, s) => const HijosListScreen()),
      GoRoute(path: '/hijos/nuevo', builder: (c, s) => const PlanillaScreen()),
      GoRoute(
        path: '/hijos/:hijoLocalId/antecedentes',
        builder: (c, s) => AntecedentesNinoScreen(hijoLocalId: s.pathParameters['hijoLocalId']!),
      ),
      GoRoute(path: '/consentimiento', builder: (c, s) => const ConsentimientoScreen()),
      GoRoute(path: '/antecedentes-familiares', builder: (c, s) => const AntecedentesFamiliaresScreen()),
      GoRoute(path: '/operativos', builder: (c, s) => const OperativosListScreen()),
      GoRoute(path: '/operativos/nuevo', builder: (c, s) => const OperativoCreateScreen()),
      GoRoute(
        path: '/operativos/:operativoId',
        builder: (c, s) => OperativoDetailScreen(operativoId: s.pathParameters['operativoId']!),
      ),
      GoRoute(
        path: '/operativos/:operativoId/alumnos/:alumnoId/medica',
        builder: (c, s) => EvaluacionMedicaScreen(
          operativoId: s.pathParameters['operativoId']!,
          alumnoId: s.pathParameters['alumnoId']!,
        ),
      ),
      GoRoute(
        path: '/operativos/:operativoId/alumnos/:alumnoId/odontologica',
        builder: (c, s) => EvaluacionOdontologicaScreen(
          operativoId: s.pathParameters['operativoId']!,
          alumnoId: s.pathParameters['alumnoId']!,
        ),
      ),
      GoRoute(
        path: '/operativos/:operativoId/alumnos/:alumnoId/escuela',
        builder: (c, s) => SeccionEscuelaScreen(
          operativoId: s.pathParameters['operativoId']!,
          alumnoId: s.pathParameters['alumnoId']!,
        ),
      ),
      GoRoute(path: '/escuelas/nuevo', builder: (c, s) => const EscuelaCreateScreen()),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => Consumer(
          builder: (c, ref, _) {
            // Pendientes visible para todos los roles → sin remapeo de índices.
            return AppShell(
              selectedIndex: navigationShell.currentIndex,
              onTap: (i) => navigationShell.goBranch(i, initialLocation: i == navigationShell.currentIndex),
              badgePendientes: ref.watch(pendientesCountProvider).value ?? 0,
              child: navigationShell,
            );
          },
        ),
        branches: [
          StatefulShellBranch(routes: [GoRoute(path: '/inicio', builder: (c, s) => const AccionesScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/pendientes', builder: (c, s) => const PendientesScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/usuario', builder: (c, s) => const UsuarioScreen())]),
        ],
      ),
    ],
  );
});
