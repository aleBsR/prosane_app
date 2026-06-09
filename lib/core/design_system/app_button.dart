import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_radii.dart';
import '../theme/app_typography.dart';

enum AppButtonState { normal, validado, error }

class AppButton extends StatelessWidget {
  const AppButton({
    super.key, required this.label, this.onPressed,
    this.isLoading = false, this.state = AppButtonState.normal,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final AppButtonState state;

  @override
  Widget build(BuildContext context) {
    final disabled = isLoading || onPressed == null;
    final gradient = state == AppButtonState.error
        ? AppColors.gradienteError
        : AppColors.gradienteFondo;

    return Semantics(
      button: true,
      enabled: !disabled,
      label: label,
      child: GestureDetector(
        onTap: disabled ? null : onPressed,
        child: Container(
          height: 52,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(AppRadii.boton),
          ),
          child: isLoading
              ? const SizedBox(
                  height: 22, width: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.blanco))
              : state == AppButtonState.validado
                  ? const Icon(Icons.check, color: AppColors.blanco)
                  : state == AppButtonState.error
                      ? const Icon(Icons.close, color: AppColors.blanco)
                      : Text(label, style: AppTypography.boton),
        ),
      ),
    );
  }
}
