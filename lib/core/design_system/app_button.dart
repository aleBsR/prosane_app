import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_radii.dart';
import '../theme/app_typography.dart';

enum AppButtonState { normal, validado, error }

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.state = AppButtonState.normal,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final AppButtonState state;

  @override
  Widget build(BuildContext context) {
    final disabled = isLoading || onPressed == null;
    // Tono fijo (sin degradado): primario, o rojo de error.
    final color = state == AppButtonState.error
        ? AppColors.errorBoton
        : AppColors.primario;

    return Semantics(
      button: true,
      enabled: !disabled,
      label: label,
      // Opacity atenúa el botón cuando está deshabilitado (sin handler o cargando)
      // para que el estado "no se puede tocar" sea visible, no solo funcional.
      child: Opacity(
        opacity: disabled ? 0.5 : 1.0,
        child: GestureDetector(
          onTap: disabled ? null : onPressed,
          child: Container(
            height: 52,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(AppRadii.boton),
            ),
            child: isLoading
                ?  SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: AppColors.blanco,
                    ),
                  )
                : state == AppButtonState.validado
                ?  Icon(Icons.check, color: AppColors.blanco)
                : state == AppButtonState.error
                ?  Icon(Icons.close, color: AppColors.blanco)
                : Text(label, style: AppTypography.boton),
          ),
        ),
      ),
    );
  }
}
