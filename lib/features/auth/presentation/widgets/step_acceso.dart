import 'package:flutter/material.dart';
import '../../../../core/design_system/app_text_field.dart';
import '../../../../core/theme/app_spacing.dart';
import '../controllers/signup_controller.dart';

/// Etapa 3: Contraseña y confirmar contraseña.
class StepAcceso extends StatefulWidget {
  const StepAcceso({
    super.key,
    required this.formData,
    required this.controller,
  });

  final SignupFormData formData;
  final SignupController controller;

  @override
  State<StepAcceso> createState() => _StepAccesoState();
}

class _StepAccesoState extends State<StepAcceso> {
  late final TextEditingController _passCtrl;
  late final TextEditingController _confirmPassCtrl;

  @override
  void initState() {
    super.initState();
    _passCtrl = TextEditingController(text: widget.formData.password);
    _confirmPassCtrl = TextEditingController(text: widget.formData.confirmPassword);
  }

  @override
  void dispose() {
    _passCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppTextField(
          key: const Key('signup_password'),
          label: 'Contraseña',
          hint: '••••••••',
          controller: _passCtrl,
          isPassword: true,
          onChanged: widget.controller.setPassword,
        ),
        const SizedBox(height: AppSpacing.md),

        AppTextField(
          key: const Key('signup_confirm_password'),
          label: 'Confirmar Contraseña',
          hint: '••••••••',
          controller: _confirmPassCtrl,
          isPassword: true,
          onChanged: widget.controller.setConfirmPassword,
        ),
      ],
    );
  }
}
