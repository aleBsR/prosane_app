import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/providers.dart';
import 'core/router/app_router.dart';
import 'core/session/session_controller.dart';
import 'core/theme/app_theme.dart';

class ProsaneApp extends ConsumerStatefulWidget {
  const ProsaneApp({super.key});

  @override
  ConsumerState<ProsaneApp> createState() => _ProsaneAppState();
}

class _ProsaneAppState extends ConsumerState<ProsaneApp> {
  @override
  void initState() {
    super.initState();
    // Hidrata la sesión desde el cache de Drift (arranque offline-first).
    ref.read(sessionControllerProvider.notifier)
        .hidratar(ref.read(authRepositoryProvider).sesionCacheada);

    // Arranca el scheduler: reacciona a cambios de conectividad y hace un
    // flush inicial para empujar cualquier draft pendiente de sesiones previas.
    // dispararPorEscritura() es necesario porque onlineStream solo emite en
    // CAMBIOS; si ya estamos online al abrir no dispararía por sí solo.
    final scheduler = ref.read(syncSchedulerProvider);
    scheduler.iniciar();
    scheduler.dispararPorEscritura();
  }

  @override
  Widget build(BuildContext context) => MaterialApp.router(
        title: 'PROSANE',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        routerConfig: ref.watch(goRouterProvider),
      );
}
