import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/design_system/app_button.dart';
import '../../../../core/design_system/app_card.dart';
import '../../../../core/design_system/app_gradient_scaffold.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../controllers/mi_escuela_controller.dart';

class MiEscuelaScreen extends ConsumerWidget {
  const MiEscuelaScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final escuelaAsync = ref.watch(miEscuelaProvider);
    return AppGradientScaffold(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            child: Row(children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: AppColors.blanco),
                onPressed: () => context.go('/inicio'),
              ),
              Text('Mi escuela',
                  style: AppTypography.titulo.copyWith(
                      color: AppColors.blanco, fontSize: 22)),
            ]),
          ),
          Expanded(
            child: escuelaAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (escuela) {
                final cursos = (escuela['cursos'] as List?) ?? const [];
                final id = '${escuela['id'] ?? ''}';
                final nombre = '${escuela['nombre'] ?? 'Escuela'}';
                return ListView(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  children: [
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(nombre, style: AppTypography.subtitulo),
                          if ('${escuela['cue'] ?? ''}'.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text('CUE ${escuela['cue']}',
                                style: AppTypography.texto.copyWith(
                                    fontSize: 12,
                                    color: AppColors.texto.withValues(alpha: 0.6))),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text('Cursos (${cursos.length})',
                              style: AppTypography.subtitulo),
                          const SizedBox(height: AppSpacing.sm),
                          if (cursos.isEmpty)
                            Text('Todavía no hay cursos cargados.',
                                style: AppTypography.texto),
                          for (final curso in cursos)
                            Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(
                                  '${curso['sala_grado_anio'] ?? ''} ${curso['division'] ?? ''}',
                                  style: AppTypography.texto),
                            ),
                          const SizedBox(height: AppSpacing.md),
                          AppButton(
                            label: 'Gestionar cursos',
                            onPressed: id.isEmpty
                                ? null
                                : () => context.push(
                                    '/escuelas/$id/cursos?nombre=${Uri.encodeComponent(nombre)}'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppButton(
                      label: 'Ver operativos de mi escuela',
                      onPressed: () => context.push('/operativos'),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
