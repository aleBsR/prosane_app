import 'package:flutter/material.dart';
import '../../../core/design_system/app_gradient_scaffold.dart';
import '../../../core/design_system/empty_state.dart';

/// Indicador global de sync (offline-first). Hoy, sin features sincronizables,
/// muestra el estado vacío honesto. La lista rica llega con la primera feature.
class PendientesScreen extends StatelessWidget {
  const PendientesScreen({super.key});

  @override
  Widget build(BuildContext context) => const AppGradientScaffold(
        child: EmptyState(icon: Icons.check_circle_outline, titulo: 'Todo sincronizado'),
      );
}
