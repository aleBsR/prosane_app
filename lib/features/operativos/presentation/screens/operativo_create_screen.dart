import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/design_system/app_button.dart';
import '../../../../core/design_system/app_card.dart';
import '../../../../core/design_system/app_date_field.dart';
import '../../../../core/design_system/app_dropdown_field.dart';
import '../../../../core/design_system/app_gradient_scaffold.dart';
import '../../../../core/design_system/app_text_field.dart';
import '../../../../core/notificaciones/notificacion_controller.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../pendientes/pendientes_count_provider.dart';
import '../controllers/operativo_create_controller.dart';

class OperativoCreateScreen extends ConsumerWidget {
  const OperativoCreateScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(operativoCreateControllerProvider);
    final ctrl = ref.read(operativoCreateControllerProvider.notifier);

    ref.listen(operativoCreateControllerProvider, (prev, next) {
      if (next.exito && !(prev?.exito ?? false)) {
        ref.read(notificacionProvider.notifier).exito('¡Operativo creado!');
        ref.invalidate(operativosPendientesProvider);
        context.go('/operativos/${next.operativoId}');
      }
      if (next.error != null && next.error != prev?.error) {
        ref.read(notificacionProvider.notifier).error(next.error!);
      }
    });

    return AppGradientScaffold(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            child: Row(children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: AppColors.blanco),
                onPressed: () => context.pop(),
              ),
              Expanded(
                child: Text('Nuevo operativo',
                    style: AppTypography.titulo.copyWith(color: AppColors.blanco, fontSize: 22)),
              ),
            ]),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        AppTextField(
                          label: 'Nombre (opcional)',
                          hint: 'Ej: Jornada de vacunación',
                          onChanged: ctrl.setNombre,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _EscuelaDropdown(state: state, ctrl: ctrl),
                        const SizedBox(height: AppSpacing.md),
                        AppDateField(
                          label: 'Fecha del operativo *',
                          value: state.fecha,
                          onChanged: ctrl.setFecha,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        AppDropdownField(
                          label: 'Lugar de realización *',
                          value: state.lugar,
                          items: const [
                            (value: '', label: '-- Seleccionar --'),
                            (value: 'escuela', label: 'En la escuela'),
                            (value: 'centro_salud', label: 'En el centro de salud'),
                            (value: 'otros', label: 'Otros'),
                          ],
                          onChanged: ctrl.setLugar,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Notas (opcional)', style: AppTypography.subtitulo),
                            const SizedBox(height: 6),
                            TextField(
                              maxLines: 3,
                              onChanged: ctrl.setNotas,
                              style: AppTypography.campo,
                              decoration: InputDecoration(
                                hintText: 'Añade notas...',
                                filled: true,
                                fillColor: AppColors.campo,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(color: Colors.transparent),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(color: Colors.transparent),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(color: AppColors.primario, width: 1.5),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppCard(
                    child: AppButton(
                      label: 'Crear operativo',
                      isLoading: state.guardando,
                      onPressed: state.puedeGuardar && !state.guardando ? ctrl.guardar : null,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EscuelaDropdown extends ConsumerWidget {
  const _EscuelaDropdown({
    required this.state,
    required this.ctrl,
  });

  final OperativoCreateState state;
  final OperativoCreateController ctrl;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final escuelasAsync = state.escuelasAsync;

    return escuelasAsync.when(
      data: (escuelas) {
        if (escuelas.isEmpty) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Escuela *',
                style: AppTypography.subtitulo,
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.campo,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange, width: 1.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'No hay escuelas. Creá una primero.',
                      style: AppTypography.campo.copyWith(color: Colors.orange),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    SizedBox(
                      height: 40,
                      child: TextButton(
                        onPressed: () => context.push('/escuelas/nuevo'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.primario,
                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                        ),
                        child: const Text('Crear escuela'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        }

        return AppDropdownField(
          label: 'Escuela *',
          value: state.escuelaId?.isEmpty ?? true ? null : state.escuelaId,
          items: [
            (value: '', label: '-- Seleccionar --'),
            ...escuelas.map((e) => (value: e.id, label: e.nombre)),
          ],
          onChanged: ctrl.setEscuela,
        );
      },
      loading: () => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Escuela *', style: AppTypography.subtitulo),
          const SizedBox(height: 6),
          Container(
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.campo,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
        ],
      ),
      error: (err, st) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Escuela *', style: AppTypography.subtitulo),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.campo,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red, width: 1.5),
            ),
            child: Text(
              'Error al cargar escuelas',
              style: AppTypography.campo.copyWith(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}
