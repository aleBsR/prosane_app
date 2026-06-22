import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/design_system/app_card.dart';
import '../../../core/design_system/app_gradient_scaffold.dart';
import '../../../core/design_system/empty_state.dart';
import '../../../core/session/entities.dart';
import '../../../core/session/session_controller.dart';
import '../../hijos/hijos_count_provider.dart';

/// Indicador global de sync (offline-first).
/// Para tutores sin hijos registrados localmente, muestra un nudge de
/// consentimiento. Para todos los demás casos, muestra el estado vacío honesto.
class PendientesScreen extends ConsumerWidget {
  const PendientesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionControllerProvider);
    final esTutor =
        session is SesionAutenticada && session.sesion.usuario.rolName == 'tutor';

    // Mientras el conteo no haya resuelto, asumimos ≥1 hijo para no mostrar
    // el nudge de forma prematura (evitar parpadeo). El nudge aparece sólo
    // cuando sabemos con certeza que no hay hijos.
    final hijosCount = esTutor
        ? ref.watch(hijosCountProvider).maybeWhen(
              data: (v) => v,
              orElse: () => 1,
            )
        : 1;

    final mostrarNudge = esTutor && hijosCount == 0;

    return AppGradientScaffold(
      child: mostrarNudge ? _NudgeConsentimiento() : const EmptyState(
        icon: Icons.check_circle_outline,
        titulo: 'Todo sincronizado',
      ),
    );
  }
}

class _NudgeConsentimiento extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: GestureDetector(
          onTap: () => context.go('/hijos/nuevo'),
          child: AppCard(
            child: Row(
              children: [
                const Icon(Icons.assignment_outlined, size: 40, color: Colors.deepPurple),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Completá el consentimiento de tu hijo',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tocá para registrar a tu hijo y firmar el consentimiento.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.grey),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
