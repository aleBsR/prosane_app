import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/design_system/app_button.dart';
import '../../../../core/design_system/app_card.dart';
import '../../../../core/design_system/app_gradient_scaffold.dart';
import '../../../../core/design_system/app_text_field.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../controllers/seccion_escuela_controller.dart';
import '../controllers/operativo_detail_controller.dart';

class SeccionEscuelaScreen extends ConsumerWidget {
  const SeccionEscuelaScreen({
    super.key,
    required this.operativoId,
    required this.alumnoId,
  });

  final String operativoId;
  final String alumnoId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final args = (opId: operativoId, alumnoId: alumnoId);
    final state = ref.watch(seccionEscuelaControllerProvider(args));
    final ctrl = ref.read(seccionEscuelaControllerProvider(args).notifier);
    final operativoAsync = ref.watch(operativoDetailProvider(operativoId));
    final esNoEditable = operativoAsync.maybeWhen(
      data: (op) => op['estado'] == 'finalizado' || op['estado'] == 'cancelado',
      orElse: () => false,
    );

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
                    context.go('/operativos/$operativoId');
                  }
                },
              ),
              Text(esNoEditable ? 'Sección escuela — solo lectura' : 'Sección escuela',
                  style: AppTypography.titulo
                      .copyWith(color: AppColors.blanco, fontSize: 22)),
            ]),
          ),
          Expanded(
            child: state.cargando
                ?  Center(
                    child: CircularProgressIndicator(color: AppColors.blanco))
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (esNoEditable) ...[
                          Center(
                            child: Container(
                              constraints: const BoxConstraints(maxWidth: 300),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.green.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.green.withValues(alpha: 0.35)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                   Icon(Icons.lock_outline, size: 14, color: AppColors.ok),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text('Operativo finalizado — solo lectura',
                                        style: AppTypography.texto.copyWith(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.ok)),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                        ],
                        AbsorbPointer(
                          absorbing: esNoEditable,
                          child: Opacity(
                            opacity: esNoEditable ? 0.85 : 1,
                            child: AppCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text('Sección escuela',
                                      style: AppTypography.subtitulo),
                                  const SizedBox(height: AppSpacing.sm),
                                  _CheckRow(
                                    label:
                                        'La escuela manifiesta preocupación por la salud',
                                    value: state.preocupaSalud,
                                    onChanged: ctrl.setPreocupaSalud,
                                  ),
                                  if (state.preocupaSalud) ...[
                                    const SizedBox(height: AppSpacing.sm),
                                    AppTextField(
                                      label: 'Detalle de la preocupación',
                                      controller: TextEditingController(text: state.preocupaDetalle)
                                        ..selection = TextSelection.collapsed(offset: state.preocupaDetalle.length),
                                      onChanged: ctrl.setPreocupaDetalle,
                                      readOnly: esNoEditable,
                                    ),
                                    const SizedBox(height: AppSpacing.sm),
                                  ],
                                  _CheckRow(
                                    label: 'Dificultad en el lenguaje',
                                    value: state.dificultadLenguaje,
                                    onChanged: ctrl.setDificultadLenguaje,
                                  ),
                                  _CheckRow(
                                    label: 'Bajo tratamiento',
                                    value: state.bajoTratamiento,
                                    onChanged: ctrl.setBajoTratamiento,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        if (!esNoEditable)
                          AppCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                if (state.error != null) ...[
                                  Text(state.error!,
                                      style: AppTypography.texto
                                          .copyWith(color: AppColors.error),
                                      textAlign: TextAlign.center),
                                  const SizedBox(height: AppSpacing.md),
                                ],
                                AppButton(
                                  label: 'Guardar',
                                  isLoading: state.guardando,
                                  onPressed: state.guardando
                                      ? null
                                      : () async {
                                          final ok = await ctrl.guardar();
                                          if (ok && context.mounted) {
                                            ref.invalidate(
                                                alumnosProvider(operativoId));
                                            ref.invalidate(
                                                completitudProvider(operativoId));
                                            ref.invalidate(
                                                operativoDetailProvider(operativoId));
                                            context.pop();
                                          }
                                        },
                                ),
                              ],
                            ),
                          )
                        else if (state.error != null)
                          AppCard(
                            child: Text(state.error!,
                                style: AppTypography.texto
                                    .copyWith(color: AppColors.error),
                                textAlign: TextAlign.center),
                          ),
                        const SizedBox(height: AppSpacing.lg),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
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
