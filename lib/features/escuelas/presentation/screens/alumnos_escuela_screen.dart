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
import '../controllers/alumnos_escuela_controller.dart';
import '../controllers/mi_escuela_controller.dart';
import '../../../operativos/presentation/controllers/operativos_list_controller.dart';

class AlumnosEscuelaScreen extends ConsumerWidget {
  const AlumnosEscuelaScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alumnosAsync = ref.watch(alumnosEscuelaProvider);
    final state = ref.watch(alumnosEscuelaControllerProvider);
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
              Text('Alumnos de mi escuela',
                  style: AppTypography.titulo.copyWith(
                      color: AppColors.blanco, fontSize: 22)),
            ]),
          ),
          Expanded(
            child: alumnosAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (alumnos) => ListView.builder(
                padding: const EdgeInsets.all(AppSpacing.md),
                itemCount: alumnos.length,
                itemBuilder: (context, index) {
                  final alumno = alumnos[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${alumno.apellido}, ${alumno.nombre}',
                              style: AppTypography.subtitulo),
                          const SizedBox(height: 4),
                          Text('DNI ${alumno.dni} • ${alumno.edad} años',
                              style: AppTypography.texto.copyWith(fontSize: 12)),
                          if (alumno.localidad.isNotEmpty)
                            Text(alumno.localidad,
                                style: AppTypography.texto.copyWith(
                                    fontSize: 12,
                                    color: AppColors.texto.withValues(alpha: 0.6))),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          if (state.error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Text(state.error!,
                  style: AppTypography.texto.copyWith(color: AppColors.error)),
            ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: AppButton(
              label: 'Registrar alumno',
              isLoading: state.guardando,
              onPressed: state.guardando
                  ? null
                  : () => _mostrarFormulario(context, ref),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _mostrarFormulario(BuildContext context, WidgetRef ref) async {
    late final Map<String, dynamic> escuela;
    late final List<Map<String, dynamic>> operativos;
    try {
      escuela = await ref.read(miEscuelaProvider.future);
      operativos = await ref.read(operativosListControllerProvider.future);
    } catch (e) {
      if (context.mounted) {
        ref.read(notificacionProvider.notifier).error('No se pudieron cargar cursos y operativos.');
      }
      return;
    }
    if (!context.mounted) return;
    final cursos = (escuela['cursos'] as List?)
            ?.whereType<Map>()
            .map((e) => e.cast<String, dynamic>())
            .toList() ??
        <Map<String, dynamic>>[];
    final nombre = TextEditingController();
    final apellido = TextEditingController();
    final dni = TextEditingController();
    final fecha = TextEditingController();
    final sexo = TextEditingController();
    final edad = TextEditingController();
    final localidad = TextEditingController();
    final telefono = TextEditingController();
    String? cursoId;
    String? operativoId;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: const Text('Registrar alumno'),
          content: SingleChildScrollView(
            child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppTextField(label: 'Nombre *', controller: nombre),
              const SizedBox(height: AppSpacing.sm),
              AppTextField(label: 'Apellido *', controller: apellido),
              const SizedBox(height: AppSpacing.sm),
              AppTextField(label: 'DNI *', controller: dni,
                  keyboardType: TextInputType.number),
              const SizedBox(height: AppSpacing.sm),
              AppTextField(label: 'Fecha de nacimiento (AAAA-MM-DD) *', controller: fecha),
              const SizedBox(height: AppSpacing.sm),
              AppTextField(label: 'Sexo *', controller: sexo),
              const SizedBox(height: AppSpacing.sm),
              AppTextField(label: 'Edad *', controller: edad,
                  keyboardType: TextInputType.number),
              const SizedBox(height: AppSpacing.sm),
              DropdownButtonFormField<String>(
                key: ValueKey('curso-$cursoId'),
                initialValue: cursoId,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Curso'),
                hint: const Text('Seleccioná un curso'),
                items: cursos.map((curso) {
                  final id = '${curso['id']}';
                  return DropdownMenuItem<String>(
                    value: id,
                    child: Text('${curso['sala_grado_anio'] ?? ''} ${curso['division'] ?? ''}'),
                  );
                }).toList(),
                onChanged: (value) => setDialogState(() => cursoId = value),
              ),
              const SizedBox(height: AppSpacing.sm),
              DropdownButtonFormField<String>(
                key: ValueKey('operativo-$operativoId'),
                initialValue: operativoId,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Operativo'),
                hint: const Text('Seleccioná un operativo'),
                items: operativos.map((operativo) {
                  final id = '${operativo['id']}';
                  final nombre = '${operativo['nombre'] ?? 'Operativo'}';
                  final fecha = '${operativo['fecha'] ?? ''}';
                  return DropdownMenuItem<String>(
                    value: id,
                    child: Text('$nombre • $fecha', overflow: TextOverflow.ellipsis),
                  );
                }).toList(),
                onChanged: (value) => setDialogState(() => operativoId = value),
              ),
              const SizedBox(height: AppSpacing.sm),
              AppTextField(label: 'Localidad', controller: localidad),
              const SizedBox(height: AppSpacing.sm),
              AppTextField(label: 'Celular', controller: telefono,
                  keyboardType: TextInputType.phone),
            ],
          ),
        ),
          actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancelar')),
          TextButton(
            onPressed: () async {
              if ([nombre, apellido, dni, fecha, sexo, edad]
                  .any((c) => c.text.trim().isEmpty)) {
                return;
              }
              final payload = {
                'persona': {
                  'nombre': nombre.text.trim(),
                  'apellido': apellido.text.trim(),
                  'dni': dni.text.trim(),
                  'tipo_dni': 'DNI',
                  'sexo': sexo.text.trim(),
                  'fecha_nacimiento': fecha.text.trim(),
                },
                'edad': int.tryParse(edad.text.trim()) ?? 0,
                'domicilio': {'localidad': localidad.text.trim()},
                'curso_id': ?cursoId,
                'operativo_id': ?operativoId,
                if (telefono.text.trim().isNotEmpty)
                  'celular': telefono.text.trim(),
              };
              final ctrl = ref.read(alumnosEscuelaControllerProvider.notifier);
              final ok = await ctrl.crear(payload);
              if (dialogContext.mounted) Navigator.pop(dialogContext);
              if (ok) {
                ref.invalidate(alumnosEscuelaProvider);
                if (context.mounted) {
                  ref.read(notificacionProvider.notifier).exito('¡Alumno registrado!');
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
}
