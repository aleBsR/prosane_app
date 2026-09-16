import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'app_button.dart';
import 'app_card.dart';

/// Ancho máximo estándar para los modales de formulario (mismo que editar escuela).
const double kWideDialogMaxWidth = 640;

/// Márgenes laterales angostos para que el modal ocupe casi todo el ancho.
const EdgeInsets kWideDialogInset =
    EdgeInsets.symmetric(horizontal: 12, vertical: 24);

/// Ancho a usar dentro del `content` de un [AlertDialog] de formulario:
/// pantalla casi completa en móvil, hasta 640px en tablet/desktop.
double wideDialogWidth(BuildContext context) {
  final ancho = MediaQuery.of(context).size.width;
  return ancho > kWideDialogMaxWidth + 24 ? kWideDialogMaxWidth : ancho - 24;
}

/// Contenedor unificado para los modales de formulario: mismo formato que los
/// diálogos de usuarios/profesionales (fondo transparente + [AppCard] blanca,
/// título de 20px, botón primario [AppButton] y cancelar en link).
///
/// Recibe los campos ([children]) y el manejo de guardado; el llamador conserva
/// su lógica dentro de [onSave].
class WideFormDialog extends StatelessWidget {
  const WideFormDialog({
    super.key,
    required this.title,
    required this.children,
    this.error,
    this.saveLabel = 'Guardar',
    this.saving = false,
    this.canSave = true,
    required this.onSave,
    required this.onCancel,
  });

  final String title;
  final List<Widget> children;
  final String? error;
  final String saveLabel;
  final bool saving;
  final bool canSave;
  final VoidCallback onSave;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: kWideDialogInset,
      child: SingleChildScrollView(
        child: SizedBox(
          width: wideDialogWidth(context),
          child: AppCard(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(title,
                    style: AppTypography.titulo.copyWith(fontSize: 20)),
                const SizedBox(height: AppSpacing.md),
                ...children,
                if (error != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  Text(error!,
                      style:
                          AppTypography.texto.copyWith(color: AppColors.error),
                      textAlign: TextAlign.center),
                ],
                const SizedBox(height: AppSpacing.md),
                AppButton(
                  label: saveLabel,
                  isLoading: saving,
                  onPressed: canSave ? onSave : null,
                ),
                const SizedBox(height: AppSpacing.sm),
                TextButton(
                  onPressed: saving ? null : onCancel,
                  child: Text('Cancelar',
                      style:
                          AppTypography.texto.copyWith(color: AppColors.link)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
