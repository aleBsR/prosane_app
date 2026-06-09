import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

const _titulos = [
  'Documento',
  'Datos Personales',
  'Contacto',
  'Acceso',
];

class WizardProgress extends StatelessWidget {
  const WizardProgress({super.key, required this.currentStep});

  final int currentStep;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'Etapa ${currentStep + 1} de 4',
          style: AppTypography.subtitulo.copyWith(color: AppColors.primario),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          _titulos[currentStep],
          style: AppTypography.titulo,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.sm),
        _StepIndicator(currentStep: currentStep),
      ],
    );
  }
}

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.currentStep});

  final int currentStep;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(4, (i) {
        final active = i <= currentStep;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          height: 6,
          width: active ? 24 : 12,
          decoration: BoxDecoration(
            color: active ? AppColors.primario : AppColors.campo,
            borderRadius: BorderRadius.circular(3),
          ),
        );
      }),
    );
  }
}
