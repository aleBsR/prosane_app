import 'package:flutter/material.dart';
import '../../../../core/design_system/app_text_field.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../controllers/signup_controller.dart';

/// Etapa 2: País de Residencia, Correo electrónico, Confirmar correo.
class StepContacto extends StatefulWidget {
  const StepContacto({
    super.key,
    required this.formData,
    required this.controller,
  });

  final SignupFormData formData;
  final SignupController controller;

  @override
  State<StepContacto> createState() => _StepContactoState();
}

class _StepContactoState extends State<StepContacto> {
  late final TextEditingController _emailCtrl;
  late final TextEditingController _confirmEmailCtrl;

  @override
  void initState() {
    super.initState();
    _emailCtrl = TextEditingController(text: widget.formData.email);
    _confirmEmailCtrl = TextEditingController(text: widget.formData.confirmEmail);
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _confirmEmailCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final f = widget.formData;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Dropdown País de Residencia
        Text('País de Residencia', style: AppTypography.subtitulo),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          key: const Key('signup_pais_residencia'),
          initialValue: f.paisResidencia.isEmpty ? null : f.paisResidencia,
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
                  const BorderSide(color: AppColors.primario, width: 1.5),
            ),
          ),
          items: const [
            DropdownMenuItem(value: 'Argentina', child: Text('Argentina')),
            DropdownMenuItem(value: 'Otro', child: Text('Otro')),
          ],
          onChanged: (v) {
            if (v != null) widget.controller.setPaisResidencia(v);
          },
        ),
        const SizedBox(height: AppSpacing.md),

        // Correo electrónico
        AppTextField(
          key: const Key('signup_email'),
          label: 'Correo Electrónico',
          hint: 'ejemplo@correo.com',
          controller: _emailCtrl,
          keyboardType: TextInputType.emailAddress,
          onChanged: widget.controller.setEmail,
        ),
        const SizedBox(height: AppSpacing.md),

        // Confirmar correo electrónico
        AppTextField(
          key: const Key('signup_confirm_email'),
          label: 'Confirmar Correo Electrónico',
          hint: 'ejemplo@correo.com',
          controller: _confirmEmailCtrl,
          keyboardType: TextInputType.emailAddress,
          onChanged: widget.controller.setConfirmEmail,
        ),
      ],
    );
  }
}
