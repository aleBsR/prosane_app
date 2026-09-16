import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/design_system/app_dialog.dart';
import '../../../../../core/design_system/app_dropdown_field.dart';
import '../../../../../core/design_system/app_text_field.dart';
import '../../../../../core/notificaciones/notificacion_controller.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../data/escuelas_repository.dart';
import '../../controllers/escuelas_acciones_controller.dart';
import '../../controllers/escuelas_list_controller.dart';

/// Diálogo de edición de escuela. Usado desde la lista, desde el detalle y
/// desde "Mi escuela" (completar datos).
/// [onGuardar] permite redirigir el guardado (ej. la escuela usa
/// `PATCH /escuelas/mi-escuela/` en vez de `PATCH /escuelas/:id/`).
/// Tras guardar con éxito invalida la lista.
/// [titulo] personaliza el encabezado (ej. "Completar datos de mi escuela").
Future<void> mostrarEditarEscuelaDialog(
  BuildContext context,
  WidgetRef ref,
  Escuela escuela, {
  Future<bool> Function(Map<String, dynamic> payload)? onGuardar,
  String titulo = 'Editar escuela',
  Escuela? detalleInicial,
}) async {
  final ctrl = ref.read(escuelasAccionesControllerProvider.notifier);
  // La escuela no tiene permiso de ver el detalle por id: en ese flujo se
  // pasa el dato ya cargado desde "Mi escuela" y se omite la recarga.
  final detalle = detalleInicial ?? await ctrl.obtener(escuela.id);
  if (detalle == null) {
    if (context.mounted) {
      ref.read(notificacionProvider.notifier).error('No se pudo cargar la escuela');
    }
    return;
  }

  final nombreCtrl = TextEditingController(text: detalle.nombre);
  final cueCtrl = TextEditingController(text: detalle.cue ?? '');
  final telefonoCtrl = TextEditingController(text: detalle.telefono ?? '');
  final localidadCtrl = TextEditingController(text: detalle.localidad ?? '');
  String? sectorGestion = detalle.sectorGestion?.isNotEmpty == true &&
          sectoresGestion.any((m) => m.value == detalle.sectorGestion)
      ? detalle.sectorGestion
      : null;
  String? modalidad = detalle.modalidadEducativa?.isNotEmpty == true &&
          modalidadesEducativas.any((m) => m.value == detalle.modalidadEducativa)
      ? detalle.modalidadEducativa
      : null;
  bool interculturalBilingue = detalle.interculturalBilingue;
  bool plurigradoRural = detalle.plurigradoRural;

  if (!context.mounted) return;
  await showDialog<void>(
    context: context,
    builder: (dialogCtx) => StatefulBuilder(
      builder: (ctx, setState) => WideFormDialog(
        title: titulo,
        onSave: () async {
          final nombre = nombreCtrl.text.trim();
          if (nombre.isEmpty) return;

          final payload = {
            'nombre': nombre,
            if (cueCtrl.text.trim().isNotEmpty) 'cue': cueCtrl.text.trim(),
            if (sectorGestion != null && sectorGestion!.isNotEmpty)
              'sector_gestion': sectorGestion,
            if (modalidad != null && modalidad!.isNotEmpty)
              'modalidad_educativa': modalidad,
            if (telefonoCtrl.text.trim().isNotEmpty)
              'telefono': telefonoCtrl.text.trim(),
            'intercultural_bilingue': interculturalBilingue,
            'plurigrado_rural': plurigradoRural,
            if (localidadCtrl.text.trim().isNotEmpty)
              'domicilio': {'localidad': localidadCtrl.text.trim()},
          };

          final ok = onGuardar != null
              ? await onGuardar(payload)
              : await ctrl.editar(escuela.id, payload);
          if (dialogCtx.mounted) Navigator.pop(dialogCtx);
          if (ok) {
            ref.invalidate(escuelasListControllerProvider);
            if (onGuardar == null && context.mounted) {
              ref.read(notificacionProvider.notifier).exito('Escuela actualizada');
            }
          } else if (onGuardar == null) {
            // Con onGuardar personalizado, el llamador ya notificó el error.
            final error = ref.read(escuelasAccionesControllerProvider).error;
            if (context.mounted) {
              ref.read(notificacionProvider.notifier).error(error ?? 'Error al editar');
            }
          }
        },
        onCancel: () => Navigator.pop(dialogCtx),
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
            items: sectoresGestion,
            onChanged: (v) => setState(() => sectorGestion = v),
          ),
          const SizedBox(height: AppSpacing.md),
          AppDropdownField(
            label: 'Modalidad educativa',
            value: modalidad,
            items: modalidadesEducativas,
            onChanged: (v) => setState(() => modalidad = v),
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
          CheckRow(
            label: 'Intercultural bilingüe',
            value: interculturalBilingue,
            onChanged: (v) => setState(() => interculturalBilingue = v),
          ),
          CheckRow(
            label: 'Plurigrado rural',
            value: plurigradoRural,
            onChanged: (v) => setState(() => plurigradoRural = v),
          ),
        ],
      ),
    ),
  );
}

/// Confirma y elimina (desactiva) la escuela. Devuelve true si se eliminó.
/// Si el backend la rechaza (409 con usuarios/operativos), muestra el motivo
/// y devuelve false.
Future<bool> confirmarEliminarEscuela(
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
  if (confirmar != true) return false;

  final ctrl = ref.read(escuelasAccionesControllerProvider.notifier);
  final ok = await ctrl.eliminar(escuela.id);
  if (ok) {
    ref.invalidate(escuelasListControllerProvider);
    if (context.mounted) {
      ref.read(notificacionProvider.notifier).exito('Escuela eliminada');
    }
    return true;
  } else {
    final error = ref.read(escuelasAccionesControllerProvider).error;
    if (context.mounted) {
      ref.read(notificacionProvider.notifier).error(error ?? 'Error al eliminar');
    }
    return false;
  }
}

class CheckRow extends StatelessWidget {
  const CheckRow({
    super.key,
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
