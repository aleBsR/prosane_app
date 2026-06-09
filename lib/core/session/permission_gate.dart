import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'entities.dart';
import 'session_controller.dart';

/// Muestra [child] solo si la sesión activa tiene [permiso].
/// Observa el ESTADO (no el notifier) para re-renderizar cuando cambian los
/// permisos — por ejemplo, al hacer login o logout.
class PermissionGate extends ConsumerWidget {
  const PermissionGate({
    super.key,
    required this.permiso,
    required this.child,
    this.fallback,
  });

  final String permiso;
  final Widget child;

  /// Widget a mostrar cuando no hay permiso. Por defecto [SizedBox.shrink].
  final Widget? fallback;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Observa el ESTADO (SesionState), no el notifier — garantiza re-render.
    final puede = ref.watch(sessionControllerProvider).can(permiso);
    return puede ? child : (fallback ?? const SizedBox.shrink());
  }
}
