import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/design_system/app_card.dart';
import '../../../core/design_system/app_gradient_scaffold.dart';
import '../../../core/design_system/empty_state.dart';
import '../../../core/design_system/stacked_cards_deck.dart';
import '../../../core/theme/app_typography.dart';
import '../pendientes_count_provider.dart';

class PendientesScreen extends ConsumerWidget {
  const PendientesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(pendientesTotalProvider);

    if (items.isEmpty) {
      return const AppGradientScaffold(
        child: EmptyState(icon: Icons.check_circle_outline, titulo: 'Todo sincronizado'),
      );
    }

    return AppGradientScaffold(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 22, 16, 140),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 4, 4, 18),
            child: Text('Pendientes',
                style: AppTypography.titulo.copyWith(fontSize: 24, color: Colors.white)),
          ),
          StackedCardsDeck(
            items: [
              for (final it in items)
                (
                  child: AppCard(
                    child: Row(children: [
                      Icon(it.icono, size: 34, color: Colors.deepPurple),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(it.titulo,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 2),
                            Text(it.subtitulo,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodySmall),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: Colors.grey),
                    ]),
                  ),
                  onTap: () => context.push(it.ruta),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
