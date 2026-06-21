import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/design_system/app_card.dart';
import '../../../../core/design_system/app_gradient_scaffold.dart';
import '../../../../core/design_system/app_link.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../controllers/signup_controller.dart';
import '../widgets/step_acceso.dart';
import '../widgets/step_contacto.dart';
import '../widgets/step_datos_personales.dart';
import '../widgets/step_documento.dart';
import '../widgets/wizard_nav_buttons.dart';
import '../widgets/wizard_progress.dart';

class SignupWizardScreen extends ConsumerWidget {
  const SignupWizardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ref.listen en build es el patrón soportado por Riverpod (no re-registra
    // entre rebuilds del mismo widget). El guard de transición false→true evita
    // navegar más de una vez ante rebuilds posteriores.
    ref.listen<SignupState>(signupControllerProvider, (prev, next) {
      if (next.registrado && !(prev?.registrado ?? false)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Registro exitoso! Podés iniciar sesión.'),
            backgroundColor: AppColors.primario,
          ),
        );
        // El router redirige /signup → /inicio automáticamente al detectar
        // la sesión autenticada; no es necesario navegar explícitamente.
      }
    });

    final state = ref.watch(signupControllerProvider);
    final controller = ref.read(signupControllerProvider.notifier);

    return AppGradientScaffold(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          child: AppCard(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                WizardProgress(currentStep: state.currentStep),
                const SizedBox(height: AppSpacing.lg),

                // IndexedStack mantiene vivos los 4 steps → TextEditingControllers
                // no se destruyen al cambiar de etapa, conservando los datos.
                IndexedStack(
                  index: state.currentStep,
                  children: [
                    StepDocumento(
                      formData: state.formData,
                      controller: controller,
                    ),
                    StepDatosPersonales(
                      formData: state.formData,
                      controller: controller,
                    ),
                    StepContacto(
                      formData: state.formData,
                      controller: controller,
                    ),
                    StepAcceso(
                      formData: state.formData,
                      controller: controller,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),

                // Mensaje de error
                if (state.error != null) ...[
                  Text(
                    state.error!,
                    key: const Key('wizard_error'),
                    style: AppTypography.texto.copyWith(color: AppColors.error),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ],

                WizardNavButtons(
                  currentStep: state.currentStep,
                  puedeAvanzar: controller.etapaValida(state.currentStep),
                  isSubmitting: state.isSubmitting,
                  onAnterior: controller.anterior,
                  onSiguiente: controller.siguiente,
                  onRegistrarse: controller.enviar,
                ),

                // Link a login solo en etapa 0
                if (state.currentStep == 0) ...[
                  const SizedBox(height: AppSpacing.md),
                  Center(
                    child: AppLink(
                      text: '¿Ya tienes una cuenta? Ingrese aquí',
                      onTap: () => context.go('/login'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
