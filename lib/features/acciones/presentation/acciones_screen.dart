import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/design_system/accion_presentacion.dart';
import '../../../core/design_system/action_group.dart';
import '../../../core/design_system/action_tile.dart';
import '../../../core/design_system/app_gradient_scaffold.dart';
import '../../../core/design_system/empty_state.dart';
import '../../../core/session/agrupar_acciones.dart';
import '../../../core/session/entities.dart';
import '../../../core/session/session_controller.dart';
import '../../../core/theme/app_typography.dart';

class AccionesScreen extends ConsumerWidget {
  const AccionesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final estado = ref.watch(sessionControllerProvider);
    final acciones = estado is SesionAutenticada ? estado.sesion.acciones : const <Accion>[];

    return AppGradientScaffold(
      child: acciones.isEmpty
          ? const EmptyState(
              icon: Icons.inbox_outlined,
              titulo: 'No tenés acciones disponibles todavía',
              subtitulo: 'Cuando te asignen un rol, vas a ver acá lo que podés hacer.')
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 22, 16, 120), // 120 abajo: deja espacio para la FloatingNavBar
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 4, 4, 18),
                  child: Text(
                    'Acciones',
                    style: AppTypography.titulo.copyWith(fontSize: 24, color: Colors.white),
                  ),
                ),
                for (final g in agruparPorCategoria(acciones))
                  ActionGroup(
                    titulo: g.categoria.toUpperCase(),
                    children: [
                      for (final a in g.acciones)
                        ActionTile(
                          color: colorDesdeHex(a.color),
                          icon: accionIcon(a.icon),
                          label: a.label,
                          onTap: () => _placeholder(context, a.label),
                        ),
                    ],
                  ),
              ],
            ),
    );
  }

  void _placeholder(BuildContext context, String label) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        content: Text('$label — próximamente'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
