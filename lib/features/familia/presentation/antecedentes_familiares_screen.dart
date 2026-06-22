import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/design_system/app_button.dart';
import '../../../core/design_system/app_card.dart';
import '../../../core/design_system/app_dropdown_field.dart';
import '../../../core/design_system/app_gradient_scaffold.dart';
import '../../../core/design_system/app_text_field.dart';
import '../../../core/notificaciones/notificacion_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import 'controllers/antecedentes_familiares_controller.dart';

class AntecedentesFamiliaresScreen extends ConsumerStatefulWidget {
  const AntecedentesFamiliaresScreen({super.key});

  static const _opciones = [
    (value: 'si', label: 'Sí'),
    (value: 'no', label: 'No'),
    (value: 'no_sabe', label: 'No sabe'),
  ];

  @override
  ConsumerState<AntecedentesFamiliaresScreen> createState() =>
      _AntecedentesFamiliaresScreenState();
}

class _AntecedentesFamiliaresScreenState
    extends ConsumerState<AntecedentesFamiliaresScreen> {
  late final TextEditingController _cualCtrl;

  @override
  void initState() {
    super.initState();
    _cualCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _cualCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AntecedentesFamiliaresState>(
        antecedentesFamiliaresControllerProvider, (prev, next) {
      // Sync precarga into the text field once — only when the loaded value
      // first arrives and the user hasn't typed anything yet.
      if (next.problemaCual != (prev?.problemaCual ?? '') &&
          _cualCtrl.text.isEmpty &&
          next.problemaCual.isNotEmpty) {
        _cualCtrl.text = next.problemaCual;
      }

      if (next.exito && !(prev?.exito ?? false)) {
        ref.read(notificacionProvider.notifier).exito('¡Antecedentes guardados!');
        context.go('/inicio');
      }
      if (next.error != null && next.error != prev?.error) {
        ref.read(notificacionProvider.notifier).error(next.error!);
      }
    });

    final state = ref.watch(antecedentesFamiliaresControllerProvider);
    final ctrl = ref.read(antecedentesFamiliaresControllerProvider.notifier);

    return AppGradientScaffold(
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md, vertical: AppSpacing.sm),
          child: Row(children: [
            IconButton(
                icon: const Icon(Icons.arrow_back, color: AppColors.blanco),
                onPressed: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go('/inicio');
                    }
                  }),
            Expanded(
              child: Text('Antecedentes familiares',
                  style: AppTypography.titulo
                      .copyWith(color: AppColors.blanco, fontSize: 22)),
            ),
          ]),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: AppCard(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                        'Antecedentes de salud del padre/madre y/o hermanos',
                        style: AppTypography.subtitulo),
                    const SizedBox(height: AppSpacing.md),
                    AppDropdownField(
                      label:
                          '¿Tienen o han tenido algún problema de salud importante?',
                      value: state.problemaSalud.isEmpty
                          ? null
                          : state.problemaSalud,
                      items: AntecedentesFamiliaresScreen._opciones,
                      onChanged: ctrl.setProblemaSalud,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppTextField(
                      label: '¿Cuál/es?',
                      controller: _cualCtrl,
                      onChanged: ctrl.setProblemaCual,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppDropdownField(
                      label:
                          '¿Algún familiar directo menor de 50 años sufrió muerte súbita o repentina?',
                      value: state.muerteSubita.isEmpty
                          ? null
                          : state.muerteSubita,
                      items: AntecedentesFamiliaresScreen._opciones,
                      onChanged: ctrl.setMuerteSubita,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    AppButton(
                      label: 'Guardar',
                      isLoading: state.enviando,
                      onPressed: state.enviando ? null : ctrl.guardar,
                    ),
                  ]),
            ),
          ),
        ),
      ]),
    );
  }
}
