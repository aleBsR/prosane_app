import 'package:flutter/material.dart';
import '../../../../core/design_system/app_switch.dart';
import '../../../../core/design_system/app_text_field.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../controllers/signup_controller.dart';

/// Etapa 0: Tipo de documento, número de documento, aceptar política.
class StepDocumento extends StatefulWidget {
  const StepDocumento({super.key, required this.formData, required this.controller});

  final SignupFormData formData;
  final SignupController controller;

  @override
  State<StepDocumento> createState() => _StepDocumentoState();
}

class _StepDocumentoState extends State<StepDocumento> {
  late final TextEditingController _numCtrl;

  @override
  void initState() {
    super.initState();
    _numCtrl = TextEditingController(text: widget.formData.numeroDocumento);
  }

  @override
  void dispose() {
    _numCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final f = widget.formData;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Dropdown tipo de documento
        Text('Tipo de Documento', style: AppTypography.subtitulo),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          key: const Key('signup_tipo_documento'),
          initialValue: f.tipoDocumento.isEmpty ? null : f.tipoDocumento,
          hint: const Text('Seleccioná'),
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.campo,
            contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: 14),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadii.campo),
              borderSide: const BorderSide(color: Colors.transparent),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadii.campo),
              borderSide:
                   BorderSide(color: AppColors.primario, width: 1.5),
            ),
          ),
          items: const [
            DropdownMenuItem(value: 'DNI', child: Text('DNI')),
            DropdownMenuItem(value: 'Pasaporte', child: Text('Pasaporte')),
          ],
          onChanged: (v) {
            if (v != null) widget.controller.setTipoDocumento(v);
          },
        ),
        const SizedBox(height: AppSpacing.md),

        // Número de documento
        AppTextField(
          key: const Key('signup_numero_documento'),
          label: 'Número de Documento',
          hint: 'Ej: 12345678',
          controller: _numCtrl,
          keyboardType: TextInputType.number,
          onChanged: widget.controller.setNumeroDocumento,
        ),
        const SizedBox(height: AppSpacing.md),

        // Switch política de privacidad.
        // Usamos el parámetro `label` de AppSwitch para que el texto quede
        // dentro del GestureDetector del widget (hace el tap más confiable
        // en tests, ya que evita caer sobre el IgnorePointer del Switch).
        AppSwitch(
          key: const Key('signup_acepta_politica_row'),
          value: f.aceptaPolitica,
          onChanged: widget.controller.setAceptaPolitica,
          label: 'Acepto la política de privacidad y términos',
        ),
      ],
    );
  }
}
