import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/design_system/app_button.dart';
import '../../../../core/design_system/app_card.dart';
import '../../../../core/design_system/app_gradient_scaffold.dart';
import '../../../../core/design_system/app_link.dart';
import '../../../../core/design_system/app_text_field.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../controllers/reset_password_controller.dart';

class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key, this.email});

  final String? email;

  @override
  ConsumerState<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  late final TextEditingController _emailCtrl;
  final _codeCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _emailCtrl = TextEditingController(text: widget.email ?? '');
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _codeCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _confirmar() async {
    final ok = await ref
        .read(resetPasswordControllerProvider.notifier)
        .confirmar(
          _emailCtrl.text.trim(),
          _codeCtrl.text.trim(),
          _passwordCtrl.text,
        );
    if (!mounted || !ok) return;
    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(resetPasswordControllerProvider);

    final codeOk = _codeCtrl.text.trim().length == 6;
    final passwordOk = _passwordCtrl.text.length >= 6;

    return AppGradientScaffold(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: AppCard(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Restablecer contraseña',
                    style: AppTypography.titulo, textAlign: TextAlign.center),
                const SizedBox(height: 6),
                Text(
                  'Ingresá el código que recibiste por correo y tu nueva contraseña.',
                  style: AppTypography.texto.copyWith(color: AppColors.texto),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.lg),
                AppTextField(
                  label: 'Correo electrónico',
                  hint: 'ejemplo@correo.com',
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  label: 'Código (6 dígitos)',
                  hint: '••••••',
                  controller: _codeCtrl,
                  keyboardType: TextInputType.number,
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  label: 'Nueva contraseña',
                  hint: 'Mínimo 6 caracteres',
                  controller: _passwordCtrl,
                  isPassword: true,
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: AppSpacing.lg),
                if (state.error != null) ...[
                  Text(
                    state.error!,
                    style: AppTypography.texto.copyWith(color: AppColors.error),
                    textAlign: TextAlign.center,
                    key: const Key('reset_error_text'),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ],
                AppButton(
                  label: 'RESTABLECER CONTRASEÑA',
                  isLoading: state.isLoading,
                  onPressed: state.isLoading || !codeOk || !passwordOk
                      ? null
                      : _confirmar,
                ),
                const SizedBox(height: AppSpacing.md),
                Center(
                  child: AppLink(
                    text: 'Volver al inicio de sesión',
                    onTap: () => context.go('/login'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}