import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/notificaciones/notificacion_host.dart';
import 'core/providers.dart';
import 'core/router/app_router.dart';
import 'core/session/entities.dart';
import 'core/session/inactividad_watcher.dart';
import 'core/session/session_controller.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_controller.dart';

class ProsaneApp extends ConsumerStatefulWidget {
  const ProsaneApp({super.key});

  @override
  ConsumerState<ProsaneApp> createState() => _ProsaneAppState();
}

class _ProsaneAppState extends ConsumerState<ProsaneApp> {
  @override
  void initState() {
    super.initState();
    _hidratarYRefrescar();

    // Arranca el scheduler: reacciona a cambios de conectividad y hace un
    // flush inicial para empujar cualquier draft pendiente de sesiones previas.
    // dispararPorEscritura() es necesario porque onlineStream solo emite en
    // CAMBIOS; si ya estamos online al abrir no dispararía por sí solo.
    final scheduler = ref.read(syncSchedulerProvider);
    scheduler.iniciar();
    scheduler.dispararPorEscritura();
  }

  /// Hidrata la sesión desde el cache de Drift (arranque offline-first) y, si
  /// quedó autenticada, intenta refrescar /me en segundo plano (best-effort):
  /// repuebla tutorId/flags de caches viejos sin forzar re-login. Offline o
  /// token vencido → se ignora y seguimos con el cache.
  Future<void> _hidratarYRefrescar() async {
    final repo = ref.read(authRepositoryProvider);
    await ref.read(sessionControllerProvider.notifier).hidratar(repo.sesionCacheada);
    if (!mounted) return;
    if (ref.read(sessionControllerProvider) is! SesionAutenticada) return;
    try {
      final sesion = await repo.refrescarSesion();
      if (!mounted) return;
      ref.read(sessionControllerProvider.notifier).refrescar(sesion);
    } catch (_) {
      // offline-first: si no hay red o el token venció, seguimos con el cache.
    }
  }

  @override
  Widget build(BuildContext context) {
    final modo = ref.watch(themeModeProvider);
    // Fija el brillo ANTES de construir el tema: todos los AppColors de
    // este frame se resuelven con la paleta del modo activo.
    AppColors.brillo =
        modo == ThemeMode.dark ? Brightness.dark : Brightness.light;
    return MaterialApp.router(
      title: 'PROSANE',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: modo,
      routerConfig: ref.watch(goRouterProvider),
      // El host de notificaciones se monta una vez, por encima del router,
      // así la tarjeta flota sobre cualquier pantalla (incluida la de registro,
      // que está fuera del shell con nav bar).
      builder: (context, child) => InactividadWatcher(
        child: Stack(children: [?child, const NotificacionHost()]),
      ),
    );
  }
}
