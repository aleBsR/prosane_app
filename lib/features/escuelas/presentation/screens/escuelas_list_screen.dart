import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/design_system/app_card.dart';
import '../../../../core/design_system/app_dropdown_field.dart';
import '../../../../core/design_system/app_gradient_scaffold.dart';
import '../../../../core/design_system/app_text_field.dart';
import '../../../../core/notificaciones/notificacion_controller.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../data/escuelas_repository.dart';
import '../controllers/escuelas_acciones_controller.dart';
import '../controllers/escuelas_list_controller.dart';

class EscuelasListScreen extends ConsumerWidget {
  const EscuelasListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final escuelasAsync = ref.watch(escuelasListControllerProvider);

    return AppGradientScaffold(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: AppColors.blanco),
                  onPressed: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go('/inicio');
                    }
                  },
                ),
                Expanded(
                  child: Text('Escuelas',
                      style: AppTypography.titulo.copyWith(
                          color: AppColors.blanco, fontSize: 24)),
                ),
              ],
            ),
          ),
          Expanded(
            child: escuelasAsync.when(
              data: (escuelas) {
                if (escuelas.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.school_outlined,
                            size: 64,
                            color: AppColors.blanco.withValues(alpha: 0.3)),
                        const SizedBox(height: AppSpacing.md),
                        Text('No hay escuelas registradas',
                            style: AppTypography.subtitulo
                                .copyWith(color: AppColors.blanco)),
                        const SizedBox(height: AppSpacing.sm),
                        Text('Creá una para comenzar',
                            style: AppTypography.texto.copyWith(
                                color:
                                    AppColors.blanco.withValues(alpha: 0.7))),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  itemCount: escuelas.length,
                  itemBuilder: (context, i) {
                    final e = escuelas[i];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: AppCard(
                        child: Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: () => context.push(
                                  '/escuelas/${e.id}/cursos?nombre=${Uri.encodeComponent(e.nombre)}',
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(e.nombre,
                                        style: AppTypography.subtitulo,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis),
                                    const SizedBox(height: 4),
                                    Text(
                                      [
                                        if (e.cue != null && e.cue!.isNotEmpty)
                                          'CUE ${e.cue}',
                                        if (e.localidad != null &&
                                            e.localidad!.isNotEmpty)
                                          e.localidad!,
                                        if (e.ambito != null &&
                                            e.ambito!.isNotEmpty)
                                          e.ambito!,
                                      ].join(' • '),
                                      style: AppTypography.texto.copyWith(
                                          fontSize: 12,
                                          color: AppColors.texto
                                              .withValues(alpha: 0.6)),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit_outlined),
                              onPressed: () => _editarEscuelaDialog(
                                  context, ref, e),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline,
                                  color: AppColors.error),
                              onPressed: () => _confirmarEliminar(
                                  context, ref, e),
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
        ],
      ),
    );
  }

  Future<void> _editarEscuelaDialog(
      BuildContext context, WidgetRef ref, Escuela escuela) async {
    final ctrl = ref.read(escuelasAccionesControllerProvider.notifier);
    final detalle = await ctrl.obtener(escuela.id);
    if (detalle == null) {
      if (context.mounted) {
        ref.read(notificacionProvider.notifier).error('No se pudo cargar la escuela');
      }
      return;
    }

    final nombreCtrl = TextEditingController(text: detalle.nombre);
    final cueCtrl = TextEditingController(text: detalle.cue ?? '');
    final modalidadCtrl = TextEditingController(text: detalle.modalidadEducativa ?? '');
    final telefonoCtrl = TextEditingController(text: detalle.telefono ?? '');
    final localidadCtrl = TextEditingController(text: detalle.localidad ?? '');
    String? sectorGestion = detalle.sectorGestion?.isNotEmpty == true
        ? detalle.sectorGestion
        : null;
    bool interculturalBilingue = detalle.interculturalBilingue;
    bool plurigradoRural = detalle.plurigradoRural;

    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Editar escuela'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppTextField(
                  label: 'Nombre *',
                  controller: nombreCtrl,
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  label: 'CUE',
                  controller: cueCtrl,
                ),
                const SizedBox(height: AppSpacing.md),
                AppDropdownField(
                  label: 'Sector de gestión',
                  value: sectorGestion,
                  items: const [
                    (value: 'publica', label: 'Pública'),
                    (value: 'privada', label: 'Privada'),
                  ],
                  onChanged: (v) => setState(() => sectorGestion = v),
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  label: 'Modalidad educativa',
                  controller: modalidadCtrl,
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  label: 'Teléfono',
                  controller: telefonoCtrl,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  label: 'Localidad',
                  controller: localidadCtrl,
                ),
                const SizedBox(height: AppSpacing.md),
                _CheckRow(
                  label: 'Intercultural bilingüe',
                  value: interculturalBilingue,
                  onChanged: (v) => setState(() => interculturalBilingue = v),
                ),
                _CheckRow(
                  label: 'Plurigrado rural',
                  value: plurigradoRural,
                  onChanged: (v) => setState(() => plurigradoRural = v),
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
                final nombre = nombreCtrl.text.trim();
                if (nombre.isEmpty) return;

                final payload = {
                  'nombre': nombre,
                  if (cueCtrl.text.trim().isNotEmpty) 'cue': cueCtrl.text.trim(),
                  if (sectorGestion != null && sectorGestion!.isNotEmpty)
                    'sector_gestion': sectorGestion,
                  if (modalidadCtrl.text.trim().isNotEmpty)
                    'modalidad_educativa': modalidadCtrl.text.trim(),
                  if (telefonoCtrl.text.trim().isNotEmpty)
                    'telefono': telefonoCtrl.text.trim(),
                  'intercultural_bilingue': interculturalBilingue,
                  'plurigrado_rural': plurigradoRural,
                  if (localidadCtrl.text.trim().isNotEmpty)
                    'domicilio': {'localidad': localidadCtrl.text.trim()},
                };

                final ok = await ctrl.editar(escuela.id, payload);
                if (dialogCtx.mounted) Navigator.pop(dialogCtx);
                if (ok) {
                  ref.invalidate(escuelasListControllerProvider);
                  if (context.mounted) {
                    ref.read(notificacionProvider.notifier).exito('Escuela actualizada');
                  }
                } else {
                  final error = ref.read(escuelasAccionesControllerProvider).error;
                  if (context.mounted) {
                    ref.read(notificacionProvider.notifier).error(error ?? 'Error al editar');
                  }
                }
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmarEliminar(
      BuildContext context, WidgetRef ref, Escuela escuela) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text('¿Eliminar ${escuela.nombre}?'),
        content: const Text('La escuela se desactivará. Esta acción no se puede deshacer.'),
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

    final ctrl = ref.read(escuelasAccionesControllerProvider.notifier);
    final ok = await ctrl.eliminar(escuela.id);
    if (ok) {
      ref.invalidate(escuelasListControllerProvider);
      if (context.mounted) {
        ref.read(notificacionProvider.notifier).exito('Escuela eliminada');
      }
    } else {
      final error = ref.read(escuelasAccionesControllerProvider).error;
      if (context.mounted) {
        ref.read(notificacionProvider.notifier).error(error ?? 'Error al eliminar');
      }
    }
  }
}

class _CheckRow extends StatelessWidget {
  const _CheckRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!value),
      child: Row(
        children: [
          Checkbox(
            value: value,
            onChanged: (v) => onChanged(v ?? false),
          ),
          Expanded(
            child: Text(label, style: AppTypography.texto),
          ),
        ],
      ),
    );
  }
}