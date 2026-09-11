import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../session/entities.dart';
import '../session/session_controller.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/signup_wizard_screen.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/auth/presentation/screens/reset_password_screen.dart';
import '../../features/acciones/presentation/acciones_screen.dart';
import '../../features/pendientes/presentation/pendientes_screen.dart';
import '../../features/usuario/presentation/usuario_screen.dart';
import '../../features/usuario/presentation/configuracion_screen.dart';
import '../../features/auth/presentation/screens/force_change_password_screen.dart';
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
import '../../features/operativos/presentation/screens/constancia_screen.dart';
import '../../features/operativos/presentation/screens/escuela_datos_screen.dart';
import '../../features/operativos/presentation/screens/alumno_detail_screen.dart';
import '../../features/escuelas/presentation/screens/escuela_create_screen.dart';
import '../../features/escuelas/presentation/screens/escuela_detail_screen.dart';
import '../../features/escuelas/presentation/screens/escuelas_list_screen.dart';
import '../../features/escuelas/presentation/screens/cursos_screen.dart';
import '../../features/escuelas/presentation/screens/mi_escuela_screen.dart';
import '../../features/escuelas/presentation/screens/alumnos_escuela_screen.dart';
import '../../features/usuarios/presentation/screens/gestion_usuarios_screen.dart';
import '../../features/usuarios_escuela/presentation/screens/usuarios_escuela_screen.dart';
import '../../features/usuarios_ayudantes/presentation/screens/usuarios_ayudantes_screen.dart';
import '../../features/profesionales/presentation/screens/profesionales_screen.dart';
import 'app_shell.dart';

typedef Redirect = String? Function(String location);

/// Función PURA del guard: dada la sesión (autenticado o no), decide el redirect.
/// Testeable sin Flutter ni Riverpod.
Redirect construirRedirect(bool autenticado) => (location) {
      final enAuth = location == '/login' ||
          location == '/signup' ||
          location == '/forgot-password' ||
          location.startsWith('/reset-password');
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
      final sessionState = ref.read(sessionControllerProvider);
      final autenticado = sessionState is SesionAutenticada;
      // Bloqueo por contraseña temporal: debe cambiar antes de cualquier otra pantalla
      if (autenticado) {
        final mustChange = (sessionState).sesion.usuario.mustChangePassword;
        final loc = state.matchedLocation;
        if (mustChange && loc != '/change-password') return '/change-password';
        if (!mustChange && loc == '/change-password') return '/inicio';
      }
      return construirRedirect(autenticado)(state.matchedLocation);
    },
    routes: [
      GoRoute(path: '/change-password', builder: (c, s) => const ForceChangePasswordScreen()),
      GoRoute(path: '/login', builder: (c, s) => const LoginScreen()),
      GoRoute(path: '/signup', builder: (c, s) => const SignupWizardScreen()),
      GoRoute(
        path: '/forgot-password',
        builder: (c, s) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/reset-password',
        builder: (c, s) => ResetPasswordScreen(email: s.extra as String?),
      ),
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
        path: '/operativos/:operativoId/alumnos/:alumnoId',
        builder: (c, s) => AlumnoDetailScreen(
          operativoId: s.pathParameters['operativoId']!,
          alumnoId: s.pathParameters['alumnoId']!,
        ),
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
      GoRoute(
        path: '/operativos/:operativoId/alumnos/:alumnoId/constancia',
        builder: (c, s) => ConstanciaScreen(
          operativoId: s.pathParameters['operativoId']!,
          alumnoId: s.pathParameters['alumnoId']!,
        ),
      ),
      GoRoute(
        path: '/operativos/:operativoId/alumnos/:alumnoId/datos',
        builder: (c, s) => EscuelaDatosScreen(
          operativoId: s.pathParameters['operativoId']!,
          alumnoId: s.pathParameters['alumnoId']!,
        ),
      ),
      GoRoute(path: '/escuelas', builder: (c, s) => const EscuelasListScreen()),
      GoRoute(path: '/escuelas/nuevo', builder: (c, s) => const EscuelaCreateScreen()),
      GoRoute(
        path: '/escuelas/:escuelaId/cursos',
        builder: (c, s) => CursosScreen(
          escuelaId: s.pathParameters['escuelaId']!,
          escuelaNombre: s.uri.queryParameters['nombre'],
        ),
      ),
      GoRoute(
        path: '/escuelas/mi-escuela',
        builder: (c, s) => const MiEscuelaScreen(),
      ),
      GoRoute(
        path: '/escuelas/alumnos',
        builder: (c, s) => AlumnosEscuelaScreen(
          abrirRegistro: s.uri.queryParameters['registrar'] == '1',
        ),
      ),
      GoRoute(
        path: '/escuelas/:escuelaId',
        builder: (c, s) => EscuelaDetailScreen(
          escuelaId: s.pathParameters['escuelaId']!,
        ),
      ),
      GoRoute(
        path: '/escuelas/:escuelaId/alumnos',
        builder: (c, s) => AlumnosEscuelaScreen(
          escuelaId: s.pathParameters['escuelaId']!,
          escuelaNombre: s.uri.queryParameters['nombre'],
        ),
      ),
      GoRoute(
        path: '/gestion-usuarios',
        builder: (c, s) => const GestionUsuariosScreen(),
      ),
      GoRoute(
        path: '/usuarios-escuela',
        builder: (c, s) => const UsuariosEscuelaScreen(),
      ),
      GoRoute(
        path: '/usuarios-ayudantes',
        builder: (c, s) => const UsuariosAyudantesScreen(),
      ),
      GoRoute(
        path: '/profesionales',
        builder: (c, s) => const ProfesionalesScreen(),
      ),
      GoRoute(path: '/usuario/configuracion', builder: (c, s) => const ConfiguracionScreen()),
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
