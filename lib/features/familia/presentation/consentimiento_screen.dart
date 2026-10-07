import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/design_system/app_button.dart';
import '../../../core/design_system/app_card.dart';
import '../../../core/design_system/app_gradient_scaffold.dart';
import '../../../core/design_system/app_link.dart';
import '../../../core/design_system/app_switch.dart';
import '../../../core/notificaciones/notificacion_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import 'controllers/consentimiento_controller.dart';

class ConsentimientoScreen extends ConsumerWidget {
  const ConsentimientoScreen({super.key});

  void _verTerminos(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Términos del consentimiento'),
        content: SingleChildScrollView(
          child: Text.rich(TextSpan(style: AppTypography.texto, children: const [
            TextSpan(text: 'Autorizo que el equipo de salud le realice a mi/s hijo/s un '),
            TextSpan(
              text: 'examen clínico y odontológico',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            TextSpan(text: ' y le aplique las '),
            TextSpan(text: 'vacunas', style: TextStyle(fontWeight: FontWeight.bold)),
            TextSpan(
              text: ' correspondientes para completar el calendario si fuese necesario. Los datos brindados serán tratados con ',
            ),
            TextSpan(
              text: 'máxima confidencialidad',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            TextSpan(
              text: '. Ante cualquier duda puedo acercarme a la escuela o al centro de salud.',
            ),
          ])),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<ConsentimientoState>(consentimientoControllerProvider, (prev, next) {
      if (next.exito && !(prev?.exito ?? false)) {
        ref.read(notificacionProvider.notifier).exito('¡Consentimiento registrado!');
        context.go('/inicio');
      }
      if (next.error != null && next.error != prev?.error) {
        ref.read(notificacionProvider.notifier).error(next.error!);
      }
    });

    final state = ref.watch(consentimientoControllerProvider);
    final ctrl = ref.read(consentimientoControllerProvider.notifier);

    return AppGradientScaffold(
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Row(children: [
            IconButton(
              icon:  Icon(Icons.arrow_back, color: AppColors.blanco),
              onPressed: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go('/inicio');
                  }
                },
            ),
            Text(
              'Consentimiento',
              style: AppTypography.titulo.copyWith(color: AppColors.blanco, fontSize: 22),
            ),
          ]),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Para registrar a tus hijos necesitás aceptar el consentimiento del programa.',
                    style: AppTypography.texto,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppSwitch(
                    label: 'Acepto los términos del consentimiento',
                    value: state.aceptado,
                    onChanged: ctrl.setAceptado,
                  ),
                  const SizedBox(height: 4),
                  AppLink(
                    text: 'Ver términos de consentimiento',
                    onTap: () => _verTerminos(context),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AppButton(
                    label: 'Confirmar',
                    isLoading: state.enviando,
                    onPressed: (state.aceptado && !state.enviando) ? ctrl.confirmar : null,
                  ),
                ],
              ),
            ),
          ),
        ),
      ]),
    );
  }
}
