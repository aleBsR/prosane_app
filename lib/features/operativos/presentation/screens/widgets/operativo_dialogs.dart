import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/design_system/app_date_field.dart';
import '../../../../../core/design_system/app_dialog.dart';
import '../../../../../core/design_system/app_dropdown_field.dart';
import '../../../../../core/design_system/app_text_field.dart';
import '../../../../../core/notificaciones/notificacion_controller.dart';
import '../../../../../core/providers.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../pendientes/pendientes_count_provider.dart';
import '../../controllers/operativo_detail_controller.dart';
import '../../controllers/operativos_list_controller.dart';

const _lugaresOperativo = [
  (value: '', label: '-- Seleccionar --'),
  (value: 'escuela', label: 'En la escuela'),
  (value: 'centro_salud', label: 'En el centro de salud'),
  (value: 'otros', label: 'Otros'),
];

String _fechaAtexto(DateTime f) =>
    '${f.year.toString().padLeft(4, '0')}-${f.month.toString().padLeft(2, '0')}-${f.day.toString().padLeft(2, '0')}';

String? _mensajeError(Object e) {
  if (e is DioException) {
    final data = e.response?.data;
    if (data is Map<String, dynamic>) {
      for (final key in ['error', 'detail', 'message']) {
        final v = data[key];
        if (v is String && v.isNotEmpty) return v;
      }
      for (final value in data.values) {
        if (value is List && value.isNotEmpty) {
          return value.first.toString();
        }
      }
    }
  }
  return null;
}

/// Diálogo de edición del operativo (nombre, fecha, lugar y notas).
/// La escuela no se cambia: mover alumnos entre escuelas queda fuera
/// de alcance. Tras guardar invalida detalle y lista.
Future<void> mostrarEditarOperativoDialog(
  BuildContext context,
  WidgetRef ref,
  Map<String, dynamic> op,
) async {
  final repo = ref.read(operativosRepositoryProvider);
  final operativoId = '${op['id']}';
  final nombreCtrl = TextEditingController(text: '${op['nombre'] ?? ''}');
  final notasCtrl = TextEditingController(text: '${op['notas'] ?? ''}');
  DateTime? fecha;
  final fechaRaw = op['fecha'];
  if (fechaRaw is String && fechaRaw.isNotEmpty) {
    fecha = DateTime.tryParse(fechaRaw);
  }
  String? lugar = () {
    final v = '${op['lugar_realizacion'] ?? ''}';
    return _lugaresOperativo.any((e) => e.value == v && v.isNotEmpty) ? v : null;
  }();

  if (!context.mounted) return;
  await showDialog<void>(
    context: context,
    builder: (dialogCtx) => StatefulBuilder(
      builder: (ctx, setState) => WideFormDialog(
        title: 'Editar operativo',
        onSave: () async {
          if (fecha == null) {
            ref
                .read(notificacionProvider.notifier)
                .error('La fecha es obligatoria');
            return;
          }
          try {
            await repo.actualizar(operativoId, {
              'nombre': nombreCtrl.text.trim(),
              'fecha': _fechaAtexto(fecha!),
              if (lugar != null && lugar!.isNotEmpty)
                'lugar_realizacion': lugar,
              'notas': notasCtrl.text.trim(),
            });
          } catch (e) {
            if (dialogCtx.mounted) Navigator.pop(dialogCtx);
            if (context.mounted) {
              ref.read(notificacionProvider.notifier).error(
                  _mensajeError(e) ?? 'No se pudo editar el operativo');
            }
            return;
          }
          if (dialogCtx.mounted) Navigator.pop(dialogCtx);
          ref.invalidate(operativoDetailProvider(operativoId));
          ref.invalidate(operativosListControllerProvider);
          if (context.mounted) {
            ref
                .read(notificacionProvider.notifier)
                .exito('Operativo actualizado');
          }
        },
        onCancel: () => Navigator.pop(dialogCtx),
        children: [
          AppTextField(
            label: 'Nombre',
            hint: 'Ej: Operativo 2026',
            controller: nombreCtrl,
          ),
          const SizedBox(height: AppSpacing.md),
          AppDateField(
            label: 'Fecha del operativo *',
            value: fecha,
            onChanged: (v) => setState(() => fecha = v),
          ),
          const SizedBox(height: AppSpacing.md),
          AppDropdownField(
            label: 'Lugar de realización',
            value: lugar,
            items: _lugaresOperativo,
            onChanged: (v) => setState(() => lugar = v),
          ),
          const SizedBox(height: AppSpacing.md),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Notas', style: AppTypography.subtitulo),
              const SizedBox(height: 6),
              TextField(
                maxLines: 3,
                controller: notasCtrl,
                style: AppTypography.campo,
                decoration: InputDecoration(
                  hintText: 'Añadí notas...',
                  filled: true,
                  fillColor: AppColors.campo,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide:
                        const BorderSide(color: Colors.transparent),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide:
                        const BorderSide(color: Colors.transparent),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide:  BorderSide(
                      color: AppColors.primario,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

/// Confirma y cancela el operativo (DELETE). Devuelve true si se canceló.
/// Si el backend lo rechaza (409 en finalizado/cancelado), muestra el motivo
/// y devuelve false.
Future<bool> confirmarEliminarOperativo(
    BuildContext context, WidgetRef ref, String operativoId, String titulo) async {
  final confirmar = await showDialog<bool>(
    context: context,
    builder: (dialogCtx) => AlertDialog(
      title: Text('¿Eliminar $titulo?'),
      content: const Text(
          'El operativo se cancelará. Esta acción no se puede deshacer.'),
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
  if (confirmar != true) return false;

  final repo = ref.read(operativosRepositoryProvider);
  try {
    await repo.cancelar(operativoId);
  } catch (e) {
    if (context.mounted) {
      ref.read(notificacionProvider.notifier).error(
          _mensajeError(e) ?? 'No se pudo eliminar el operativo');
    }
    return false;
  }
  ref.invalidate(operativosListControllerProvider);
  ref.invalidate(operativosPendientesProvider);
  if (context.mounted) {
    ref.read(notificacionProvider.notifier).exito('Operativo cancelado');
  }
  return true;
}
