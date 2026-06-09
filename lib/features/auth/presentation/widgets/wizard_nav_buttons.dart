import 'package:flutter/material.dart';
import '../../../../core/design_system/app_button.dart';
import '../../../../core/theme/app_spacing.dart';

class WizardNavButtons extends StatelessWidget {
  const WizardNavButtons({
    super.key,
    required this.currentStep,
    required this.puedeAvanzar,
    required this.isSubmitting,
    required this.onAnterior,
    required this.onSiguiente,
    required this.onRegistrarse,
  });

  final int currentStep;
  final bool puedeAvanzar;
  final bool isSubmitting;
  final VoidCallback onAnterior;
  final VoidCallback onSiguiente;
  final VoidCallback onRegistrarse;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (currentStep == 3)
          AppButton(
            key: const Key('wizard_registrarse'),
            label: 'REGISTRARSE',
            isLoading: isSubmitting,
            onPressed: isSubmitting ? null : onRegistrarse,
          )
        else
          AppButton(
            key: const Key('wizard_siguiente'),
            label: 'SIGUIENTE',
            onPressed: puedeAvanzar ? onSiguiente : null,
          ),
        if (currentStep > 0) ...[
          const SizedBox(height: AppSpacing.sm),
          AppButton(
            key: const Key('wizard_anterior'),
            label: 'ANTERIOR',
            onPressed: onAnterior,
          ),
        ],
      ],
    );
  }
}
