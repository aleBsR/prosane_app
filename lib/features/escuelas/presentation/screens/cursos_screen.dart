import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/design_system/app_button.dart';
import '../../../../core/design_system/app_card.dart';
import '../../../../core/design_system/app_gradient_scaffold.dart';
import '../../../../core/design_system/app_dialog.dart';
import '../../../../core/design_system/app_text_field.dart';
import '../../../../core/notificaciones/notificacion_controller.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../controllers/cursos_controller.dart';
import '../../data/curso_utils.dart';
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
                icon:  Icon(Icons.arrow_back, color: AppColors.blanco),
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
                  padding:  EdgeInsets.all(AppSpacing.md),
                  itemCount: cursos.length,
                  itemBuilder: (context, i) {
                    final curso = cursos[i];
                    return Padding(
                      padding:  EdgeInsets.only(bottom: AppSpacing.md),
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
                                     SizedBox(height: 4),
                                    Text('Ciclo ${curso.cicloLectivo}',
                                        style: AppTypography.texto.copyWith(
                                            fontSize: 12,
                                            color: AppColors.texto
                                                .withValues(alpha: 0.6))),
                                  ],
                                ],
                              ),
                            ),
                            PopupMenuButton<String>(
                              icon:  Icon(Icons.more_vert,
                                  color: AppColors.texto),
                              onSelected: (valor) {
                                if (valor == 'editar') {
                                  _editarCursoDialog(context, ref, curso);
                                } else if (valor == 'eliminar') {
                                  _confirmarEliminar(
                                      context, ref, ctrl, curso);
                                }
                              },
                              itemBuilder: (_) =>  [
                                PopupMenuItem(
                                  value: 'editar',
                                  child: Row(
                                    children: [
                                      Icon(Icons.edit_outlined,
                                          size: 18,
                                          color: AppColors.primario),
                                      SizedBox(width: 8),
                                      Text('Editar'),
                                    ],
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'eliminar',
                                  child: Row(
                                    children: [
                                      Icon(Icons.delete_outline,
                                          size: 18, color: AppColors.error),
                                      SizedBox(width: 8),
                                      Text('Eliminar',
                                          style: TextStyle(
                                              color: AppColors.error)),
                                    ],
                                  ),
                                ),
                              ],
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
    final existentes =
        ref.read(cursosProvider(escuelaId)).valueOrNull ?? const <Curso>[];
    String? errorMsg;
    bool guardando = false;

    await showDialog<void>(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (dialogCtx, setState) => WideFormDialog(
          title: 'Agregar curso',
          error: errorMsg,
          saving: guardando,
          onSave: () async {
            final grado = normalizarGrado(gradoCtrl.text);
            final division = normalizarDivision(divisionCtrl.text);
            if (grado.isEmpty || division.isEmpty) {
              setState(() =>
                  errorMsg = 'Completá grado y división para guardar.');
              return;
            }
            final ciclo = int.tryParse(cicloCtrl.text.trim());
            // Aviso inmediato sin ir al servidor.
            if (esCursoDuplicado(
              existentes: existentes,
              grado: grado,
              division: division,
              cicloLectivo: ciclo,
            )) {
              setState(() => errorMsg = mensajeCursoDuplicado);
              return;
            }
            setState(() {
              guardando = true;
              errorMsg = null;
            });
            final ctrl =
                ref.read(cursosControllerProvider(escuelaId).notifier);
            final ok = await ctrl.crear(
              grado: grado,
              division: division,
              cicloLectivo: ciclo,
            );
            if (!dialogCtx.mounted) return;
            if (ok) {
              Navigator.pop(dialogCtx);
              ref.invalidate(cursosProvider(escuelaId));
              if (context.mounted) {
                ref.read(notificacionProvider.notifier).exito('¡Curso creado!');
              }
            } else {
              final crudo =
                  ref.read(cursosControllerProvider(escuelaId)).error;
              final mensaje = crudo == null
                  ? 'No se pudo guardar el curso.'
                  : mensajeAmigableCurso(crudo);
              setState(() {
                guardando = false;
                errorMsg = mensaje;
              });
              if (context.mounted) {
                ref.read(notificacionProvider.notifier).error(mensaje);
              }
            }
          },
          onCancel: () => Navigator.pop(dialogCtx),
          children: [
            AppTextField(
              label: 'Grado / Sala (ej: 1°) *',
              controller: gradoCtrl,
              hint: 'Escribí 1 y se completa a 1°',
              onChanged: (v) {
                final completo = autocompletarGrado(v);
                if (completo != null && completo != v) {
                  gradoCtrl.text = completo;
                  gradoCtrl.selection = TextSelection.fromPosition(
                    TextPosition(offset: completo.length),
                  );
                }
              },
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
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Escuelas plurigrado: usá "Plurigrado" como grado para agrupar varios años en un mismo curso.',
              style: AppTypography.texto.copyWith(fontSize: 11, color: AppColors.texto.withValues(alpha: 0.6)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editarCursoDialog(
      BuildContext context, WidgetRef ref, Curso curso) async {
    final gradoCtrl = TextEditingController(text: curso.salaGradoAnio);
    final divisionCtrl = TextEditingController(text: curso.division);
    final cicloCtrl = TextEditingController(
        text: curso.cicloLectivo?.toString() ?? '');
    final existentes =
        ref.read(cursosProvider(escuelaId)).valueOrNull ?? const <Curso>[];
    String? errorMsg;
    bool guardando = false;

    await showDialog<void>(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (dialogCtx, setState) => WideFormDialog(
          title: 'Editar curso',
          error: errorMsg,
          saving: guardando,
          onSave: () async {
            final grado = normalizarGrado(gradoCtrl.text);
            final division = normalizarDivision(divisionCtrl.text);
            if (grado.isEmpty || division.isEmpty) {
              setState(() =>
                  errorMsg = 'Completá grado y división para guardar.');
              return;
            }
            final ciclo = int.tryParse(cicloCtrl.text.trim());
            // Aviso inmediato sin ir al servidor (ignora este curso).
            if (esCursoDuplicado(
              existentes: existentes,
              grado: grado,
              division: division,
              cicloLectivo: ciclo,
              excluirId: curso.id,
            )) {
              setState(() => errorMsg = mensajeCursoDuplicado);
              return;
            }
            setState(() {
              guardando = true;
              errorMsg = null;
            });
            final ctrl =
                ref.read(cursosControllerProvider(escuelaId).notifier);
            final ok = await ctrl.editar(
              cursoId: curso.id,
              grado: grado,
              division: division,
              cicloLectivo: ciclo,
            );
            if (!dialogCtx.mounted) return;
            if (ok) {
              Navigator.pop(dialogCtx);
              ref.invalidate(cursosProvider(escuelaId));
              if (context.mounted) {
                ref
                    .read(notificacionProvider.notifier)
                    .exito('¡Curso actualizado!');
              }
            } else {
              final crudo =
                  ref.read(cursosControllerProvider(escuelaId)).error;
              final mensaje = crudo == null
                  ? 'No se pudo guardar el curso.'
                  : mensajeAmigableCurso(crudo);
              setState(() {
                guardando = false;
                errorMsg = mensaje;
              });
              if (context.mounted) {
                ref.read(notificacionProvider.notifier).error(mensaje);
              }
            }
          },
          onCancel: () => Navigator.pop(dialogCtx),
          children: [
            AppTextField(
              label: 'Grado / Sala',
              controller: gradoCtrl,
              hint: 'Escribí 1 y se completa a 1°',
              onChanged: (v) {
                final completo = autocompletarGrado(v);
                if (completo != null && completo != v) {
                  gradoCtrl.text = completo;
                  gradoCtrl.selection = TextSelection.fromPosition(
                    TextPosition(offset: completo.length),
                  );
                }
              },
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
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Escuelas plurigrado: usá "Plurigrado" como grado.',
              style: AppTypography.texto.copyWith(fontSize: 11, color: AppColors.texto.withValues(alpha: 0.6)),
            ),
          ],
        ),
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
              child: const Text('No')),
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, true),
            child:  Text('Sí',
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
