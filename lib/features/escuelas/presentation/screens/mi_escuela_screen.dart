import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/design_system/app_button.dart';
import '../../../../core/design_system/app_card.dart';
import '../../../../core/design_system/app_gradient_scaffold.dart';
import '../../../../core/design_system/detail_post_card.dart';
import '../../../../core/notificaciones/notificacion_controller.dart';
import '../../../../core/providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../data/escuelas_repository.dart';
import '../controllers/mi_escuela_controller.dart';
import 'widgets/escuela_dialogs.dart';

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
                icon:  Icon(Icons.arrow_back, color: AppColors.blanco),
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
                // El alta del admin solo pide nombre + CUE: la escuela debe
                // completar el resto al ingresar. Señal del backend.
                final perfilCompleto = escuela['perfil_completo'] == true;
                final faltantes =
                    (escuela['campos_faltantes'] as List?)
                            ?.map((e) => '$e')
                            .toList() ??
                        const [];
                return ListView(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  children: [
                    if (!perfilCompleto)
                      AppCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                 Icon(Icons.warning_amber_outlined,
                                    color: AppColors.error),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                      'Completá los datos de tu escuela (obligatorio)',
                                      style: AppTypography.subtitulo.copyWith(
                                          color: AppColors.error)),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                                'Falta: ${faltantes.isEmpty ? 'datos del establecimiento' : faltantes.join(', ')}.',
                                style: AppTypography.texto),
                            const SizedBox(height: AppSpacing.md),
                            AppButton(
                              label: 'Completar datos',
                              onPressed: () async {
                                final repo = ref.read(
                                    escuelasRepositoryProvider);
                                await mostrarEditarEscuelaDialog(
                                  context,
                                  ref,
                                  Escuela.fromJson(escuela),
                                  titulo: 'Completar datos de mi escuela',
                                  detalleInicial:
                                      Escuela.fromJson(escuela),
                                  onGuardar: (payload) async {
                                    try {
                                      await repo
                                          .completarMiEscuela(payload);
                                      ref.invalidate(miEscuelaProvider);
                                      if (context.mounted) {
                                        ref
                                            .read(notificacionProvider
                                                .notifier)
                                            .exito(
                                                '¡Datos de la escuela actualizados!');
                                      }
                                      return true;
                                    } catch (e) {
                                      if (context.mounted) {
                                        ref
                                            .read(notificacionProvider
                                                .notifier)
                                            .error(e
                                                .toString()
                                                .replaceFirst(
                                                    'Exception: ', ''));
                                      }
                                      return false;
                                    }
                                  },
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    if (!perfilCompleto)
                      const SizedBox(height: AppSpacing.md),
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
                      body: esPlurigrado
                          ? Text(
                              'Escuela plurigrado rural: no necesita cursos. Los alumnos se registran sin curso.',
                              style: AppTypography.texto.copyWith(
                                  fontSize: 12,
                                  fontStyle: FontStyle.italic,
                                  color: AppColors.texto
                                      .withValues(alpha: 0.7)),
                            )
                          : null,
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
