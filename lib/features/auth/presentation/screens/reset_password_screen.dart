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
import '../../../../core/notificaciones/notificacion_controller.dart';
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
  final _confirmCtrl = TextEditingController();

  bool get _largoOk => _passwordCtrl.text.length >= 8;
  bool get _noSoloNumeros {
    final v = _passwordCtrl.text;
    if (v.isEmpty) return false;
    return !RegExp(r'^\d+$').hasMatch(v);
  }

  bool get _coinciden =>
      _passwordCtrl.text.isNotEmpty && _passwordCtrl.text == _confirmCtrl.text;

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
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _confirmar() async {
    if (_passwordCtrl.text != _confirmCtrl.text) {
      ref.read(notificacionProvider.notifier).error('La contraseña y la confirmación no coinciden');
      return;
    }
    final ok = await ref
        .read(resetPasswordControllerProvider.notifier)
        .confirmar(
          _emailCtrl.text.trim(),
          _codeCtrl.text.trim(),
          _passwordCtrl.text,
        );
    if (!mounted || !ok) return;
    ref.read(notificacionProvider.notifier).exito('Contraseña restablecida. Ingresá con tu nueva clave.');
    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(resetPasswordControllerProvider);

    final codeOk = _codeCtrl.text.trim().length == 6;
    final passwordOk = _largoOk && _noSoloNumeros && _coinciden;

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
                  hint: 'Mínimo 8 caracteres',
                  controller: _passwordCtrl,
                  isPassword: true,
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  label: 'Confirmar nueva contraseña',
                  hint: 'Repetí la contraseña',
                  controller: _confirmCtrl,
                  isPassword: true,
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: AppSpacing.md),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.campo,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.info_outline, size: 18, color: AppColors.primario),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text('Requisitos de la nueva contraseña',
                                style: AppTypography.texto.copyWith(fontWeight: FontWeight.bold, fontSize: 13)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _RequisitoRow(cumple: _largoOk, texto: 'Mínimo 8 caracteres'),
                      _RequisitoRow(cumple: _noSoloNumeros, texto: 'No puede ser solo números'),
                      _RequisitoRow(
                          cumple: _passwordCtrl.text.isEmpty ? false : true,
                          texto: 'No uses una clave común (ej: 12345678, password)'),
                      _RequisitoRow(cumple: _coinciden, texto: 'La confirmación debe coincidir'),
                      Text('El código vence en 30 minutos. Revisá también spam.',
                          style: AppTypography.texto.copyWith(fontSize: 11, color: AppColors.texto.withValues(alpha: 0.6))),
                    ],
                  ),
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

class _RequisitoRow extends StatelessWidget {
  const _RequisitoRow({required this.cumple, required this.texto});
  final bool cumple;
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(cumple ? Icons.check_circle : Icons.radio_button_unchecked,
              size: 16, color: cumple ? Colors.green : AppColors.gris),
          const SizedBox(width: 8),
          Expanded(
            child: Text(texto,
                style: AppTypography.texto.copyWith(
                    fontSize: 12,
                    color: cumple ? AppColors.texto : AppColors.texto.withValues(alpha: 0.7))),
          ),
        ],
      ),
    );
  }
}