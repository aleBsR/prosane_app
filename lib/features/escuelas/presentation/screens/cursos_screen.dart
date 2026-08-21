import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/design_system/app_button.dart';
import '../../../../core/design_system/app_card.dart';
import '../../../../core/design_system/app_gradient_scaffold.dart';
import '../../../../core/design_system/app_text_field.dart';
import '../../../../core/notificaciones/notificacion_controller.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../controllers/cursos_controller.dart';
import '../../data/escuelas_repository.dart';

class CursosScreen extends ConsumerWidget {
  const CursosScreen({super.key, required this.escuelaId, this.escuelaNombre});

  final String escuelaId;
  final String? escuelaNombre;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cursosAsync = ref.watch(cursosProvider(escuelaId));
    final ctrl = ref.read(cursosControllerProvider(escuelaId).notifier);
    final estado = ref.watch(cursosControllerProvider(escuelaId));

    return AppGradientScaffold(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            child: Row(children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: AppColors.blanco),
                onPressed: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go('/escuelas');
                  }
                },
              ),
              Expanded(
                child: Text(escuelaNombre ?? 'Cursos',
                    style: AppTypography.titulo.copyWith(
                        color: AppColors.blanco, fontSize: 22),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ),
            ]),
          ),
          Expanded(
            child: cursosAsync.when(
              data: (cursos) {
                if (cursos.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.menu_book_outlined,
                            size: 64,
                            color: AppColors.blanco.withValues(alpha: 0.3)),
                        const SizedBox(height: AppSpacing.md),
                        Text('No hay cursos',
                            style: AppTypography.subtitulo
                                .copyWith(color: AppColors.blanco)),
                        const SizedBox(height: AppSpacing.sm),
                        Text('Agregá un curso para comenzar',
                            style: AppTypography.texto.copyWith(
                                color: AppColors.blanco.withValues(alpha: 0.7))),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  itemCount: cursos.length,
                  itemBuilder: (context, i) {
                    final curso = cursos[i];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: AppCard(
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(curso.etiqueta,
                                      style: AppTypography.subtitulo),
                                  if (curso.cicloLectivo != null) ...[
                                    const SizedBox(height: 4),
                                    Text('Ciclo ${curso.cicloLectivo}',
                                        style: AppTypography.texto.copyWith(
                                            fontSize: 12,
                                            color: AppColors.texto
                                                .withValues(alpha: 0.6))),
                                  ],
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit_outlined),
                              onPressed: () => _editarCursoDialog(
                                  context, ref, curso),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline,
                                  color: AppColors.error),
                              onPressed: () =>
                                  _confirmarEliminar(context, ref, ctrl, curso),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => Center(child: Text('Error: $e')),
            ),
          ),
          if (estado.error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Text(estado.error!,
                  style: AppTypography.texto.copyWith(color: AppColors.error)),
            ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: AppButton(
              label: 'Agregar curso',
              isLoading: estado.guardando,
              onPressed: estado.guardando
                  ? null
                  : () => _crearCursoDialog(context, ref),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _crearCursoDialog(BuildContext context, WidgetRef ref) async {
    final gradoCtrl = TextEditingController();
    final divisionCtrl = TextEditingController();
    final cicloCtrl = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Agregar curso'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppTextField(
                label: 'Grado / Sala (ej: 1°) *',
                controller: gradoCtrl,
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                label: 'División (ej: A) *',
                controller: divisionCtrl,
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                label: 'Ciclo lectivo',
                controller: cicloCtrl,
                keyboardType: TextInputType.number,
                hint: 'Ej: 2026',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Cancelar')),
          TextButton(
            onPressed: () async {
              if (gradoCtrl.text.trim().isEmpty ||
                  divisionCtrl.text.trim().isEmpty) {
                return;
              }
              final ciclo = int.tryParse(cicloCtrl.text.trim());
              final ctrl = ref.read(
                  cursosControllerProvider(escuelaId).notifier);
              final ok = await ctrl.crear(
                grado: gradoCtrl.text.trim(),
                division: divisionCtrl.text.trim().toUpperCase(),
                cicloLectivo: ciclo,
              );
              if (dialogCtx.mounted) Navigator.pop(dialogCtx);
              if (ok) {
                ref.invalidate(cursosProvider(escuelaId));
                if (context.mounted) {
                  ref.read(notificacionProvider.notifier).exito('¡Curso creado!');
                }
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  Future<void> _editarCursoDialog(
      BuildContext context, WidgetRef ref, Curso curso) async {
    final gradoCtrl = TextEditingController(text: curso.salaGradoAnio);
    final divisionCtrl = TextEditingController(text: curso.division);
    final cicloCtrl = TextEditingController(
        text: curso.cicloLectivo?.toString() ?? '');

    await showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Editar curso'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppTextField(
              label: 'Grado / Sala',
              controller: gradoCtrl,
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              label: 'División',
              controller: divisionCtrl,
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              label: 'Ciclo lectivo',
              controller: cicloCtrl,
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Cancelar')),
          TextButton(
            onPressed: () async {
              final ciclo = int.tryParse(cicloCtrl.text.trim());
              final ctrl = ref.read(
                  cursosControllerProvider(escuelaId).notifier);
              final ok = await ctrl.editar(
                cursoId: curso.id,
                grado: gradoCtrl.text.trim(),
                division: divisionCtrl.text.trim().toUpperCase(),
                cicloLectivo: ciclo,
              );
              if (dialogCtx.mounted) Navigator.pop(dialogCtx);
              if (ok) {
                ref.invalidate(cursosProvider(escuelaId));
                if (context.mounted) {
                  ref
                      .read(notificacionProvider.notifier)
                      .exito('¡Curso actualizado!');
                }
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmarEliminar(BuildContext context, WidgetRef ref,
      CursosController ctrl, Curso curso) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text('¿Eliminar ${curso.etiqueta}?'),
        content: const Text('Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogCtx, false),
              child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, true),
            child: const Text('Eliminar',
                style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirmar != true) return;
    final ok = await ctrl.eliminar(curso.id);
    if (ok) {
      ref.invalidate(cursosProvider(escuelaId));
      if (context.mounted) {
        ref.read(notificacionProvider.notifier).exito('Curso eliminado');
      }
    }
  }
}
