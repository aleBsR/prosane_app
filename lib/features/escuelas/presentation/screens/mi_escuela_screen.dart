import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/design_system/app_gradient_scaffold.dart';
import '../../../../core/design_system/detail_post_card.dart';
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
                // Plurigrado rural no usa cursos: los alumnos se registran
                // sin curso ("Plurigrado por defecto").
                final esPlurigrado = escuela['plurigrado_rural'] == true;
                final subtitulo = [
                  if ('${escuela['cue'] ?? ''}'.isNotEmpty)
                    'CUE ${escuela['cue']}',
                ].join(' • ');
                return ListView(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  children: [
                    DetailPostCard(
                      avatarLetter: nombre,
                      title: nombre,
                      subtitle: subtitulo,
                      bannerIcon: Icons.school_outlined,
                      bannerChips: [
                        '${cursos.length} curso${cursos.length == 1 ? '' : 's'}',
                        if (esPlurigrado) 'Plurigrado rural',
                      ],
                      actions: [
                        if (!esPlurigrado && id.isNotEmpty)
                          PostActionButton(
                            icono: Icons.menu_book_outlined,
                            texto: 'Gestionar cursos',
                            colorFondo: AppColors.primario,
                            colorTexto: AppColors.blanco,
                            onPressed: () => context.push(
                                '/escuelas/$id/cursos?nombre=${Uri.encodeComponent(nombre)}'),
                          ),
                        PostActionButton(
                          icono: Icons.event_note_outlined,
                          texto: 'Ver operativos',
                          colorFondo: AppColors.primario,
                          colorTexto: AppColors.blanco,
                          onPressed: () => context.push('/operativos'),
                        ),
                      ],
                      body: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (esPlurigrado)
                            Text(
                              'Escuela plurigrado rural: no necesita cursos. Los alumnos se registran sin curso.',
                              style: AppTypography.texto.copyWith(
                                  fontSize: 12,
                                  fontStyle: FontStyle.italic,
                                  color: AppColors.texto
                                      .withValues(alpha: 0.7)),
                            )
                          else if (cursos.isEmpty)
                            Text('Todavía no hay cursos cargados.',
                                style: AppTypography.texto)
                          else
                            for (final curso in cursos)
                              Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(
                                    '${curso['sala_grado_anio'] ?? ''} ${curso['division'] ?? ''}',
                                    style: AppTypography.texto),
                              ),
                        ],
                      ),
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
