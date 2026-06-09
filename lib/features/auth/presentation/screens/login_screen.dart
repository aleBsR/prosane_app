import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/design_system/app_button.dart';
import '../../../../core/design_system/app_card.dart';
import '../../../../core/design_system/app_gradient_scaffold.dart';
import '../../../../core/design_system/app_link.dart';
import '../../../../core/design_system/app_switch.dart';
import '../../../../core/design_system/app_text_field.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../controllers/login_controller.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _recordarme = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(loginControllerProvider);
    final controller = ref.read(loginControllerProvider.notifier);

    return AppGradientScaffold(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: AppCard(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Título
                Text('Bienvenido', style: AppTypography.titulo, textAlign: TextAlign.center),
                const SizedBox(height: 6),
                Text(
                  'Ingresá con tu cuenta para continuar',
                  style: AppTypography.texto.copyWith(color: AppColors.texto),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.lg),

                // Campo email
                AppTextField(
                  label: 'Correo electrónico',
                  hint: 'ejemplo@correo.com',
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: AppSpacing.md),

                // Campo contraseña
                AppTextField(
                  label: 'Contraseña',
                  hint: '••••••••',
                  controller: _passwordCtrl,
                  isPassword: true,
                  // El error se muestra una sola vez, en el mensaje dedicado de
                  // abajo (sirve para credenciales, red y server por igual).
                ),
                const SizedBox(height: AppSpacing.sm),

                // Fila: Recordarme + Olvidaste contraseña
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    AppSwitch(
                      value: _recordarme,
                      onChanged: (v) => setState(() => _recordarme = v),
                      label: 'Recordarme',
                    ),
                    AppLink(
                      text: '¿Olvidaste tu contraseña?',
                      onTap: () {}, // sin navegación por ahora
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),

                // Mensaje de error visible sobre el botón
                if (state.error != null) ...[
                  Text(
                    state.error!,
                    style: AppTypography.texto.copyWith(color: AppColors.error),
                    textAlign: TextAlign.center,
                    key: const Key('login_error_text'),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ],

                // Botón principal
                AppButton(
                  // En error se mantiene el label (no el ícono X) para conservar
                  // la affordance de reintentar; el error se comunica por el mensaje.
                  label: 'INICIAR SESIÓN',
                  isLoading: state.isLoading,
                  onPressed: state.isLoading
                      ? null
                      : () => controller.enviar(
                            _emailCtrl.text.trim(),
                            _passwordCtrl.text,
                          ),
                ),
                const SizedBox(height: AppSpacing.md),

                // Link de registro
                Center(
                  child: AppLink(
                    text: 'Regístrese aquí',
                    onTap: () => context.go('/signup'),
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
