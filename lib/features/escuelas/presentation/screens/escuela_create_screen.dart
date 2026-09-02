import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/design_system/app_button.dart';
import '../../../../core/design_system/app_card.dart';
import '../../../../core/design_system/app_dropdown_field.dart';
import '../../../../core/design_system/app_gradient_scaffold.dart';
import '../../../../core/design_system/app_text_field.dart';
import '../../../../core/notificaciones/notificacion_controller.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../controllers/escuela_create_controller.dart';
import '../controllers/escuelas_list_controller.dart';

class EscuelaCreateScreen extends ConsumerWidget {
  const EscuelaCreateScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(escuelaCreateControllerProvider);
    final ctrl = ref.read(escuelaCreateControllerProvider.notifier);

    return AppGradientScaffold(
      child: Column(
        children: [
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
                },
              ),
              Text('Crear escuela',
                  style: AppTypography.titulo.copyWith(
                      color: AppColors.blanco, fontSize: 22)),
            ]),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text('Datos básicos', style: AppTypography.subtitulo),
                        const SizedBox(height: 4),
                        Text('Los campos con * son obligatorios. El resto es opcional.',
                            style: AppTypography.texto.copyWith(
                                fontSize: 12,
                                color: AppColors.texto.withValues(alpha: 0.6))),
                        const SizedBox(height: AppSpacing.sm),
                        AppTextField(
                          label: 'Nombre *',
                          onChanged: ctrl.setNombre,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        AppTextField(
                          label: 'CUE',
                          onChanged: ctrl.setCue,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        AppDropdownField(
                          label: 'Sector de gestión',
                          value: state.sectorGestion.isEmpty
                              ? null
                              : state.sectorGestion,
                          items: const [
                            (value: 'obra_social', label: 'Obra Social'),
                            (value: 'estatal', label: 'Estatal'),
                            (value: 'privado', label: 'Privado'),
                            (value: 'otro', label: 'Otro'),
                          ],
                          onChanged: ctrl.setSectorGestion,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        AppTextField(
                          label: 'Modalidad educativa',
                          onChanged: ctrl.setModalidadEducativa,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text('Contacto', style: AppTypography.subtitulo),
                        const SizedBox(height: AppSpacing.sm),
                        AppTextField(
                          label: 'Teléfono',
                          keyboardType: TextInputType.phone,
                          onChanged: ctrl.setTelefono,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text('Características',
                            style: AppTypography.subtitulo),
                        const SizedBox(height: AppSpacing.sm),
                        _CheckRow(
                          label: 'Intercultural bilingüe',
                          value: state.interculturalBilingue,
                          onChanged: ctrl.setInterculturalBilingue,
                        ),
                        _CheckRow(
                          label: 'Plurigrado rural',
                          value: state.plurigradoRural,
                          onChanged: ctrl.setPlurigradoRural,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text('Domicilio (opcional)',
                            style: AppTypography.subtitulo),
                        const SizedBox(height: AppSpacing.sm),
                        AppTextField(
                          label: 'Provincia',
                          onChanged: ctrl.setProvincia,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        AppTextField(
                          label: 'Localidad',
                          onChanged: ctrl.setLocalidad,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        AppTextField(
                          label: 'Calle',
                          onChanged: ctrl.setCalle,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        AppTextField(
                          label: 'Nº de calle',
                          keyboardType: TextInputType.number,
                          onChanged: ctrl.setNroCalle,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (state.error != null) ...[
                          Text(state.error!,
                              style: AppTypography.texto.copyWith(
                                  color: AppColors.error),
                              textAlign: TextAlign.center),
                          const SizedBox(height: AppSpacing.md),
                        ],
                        AppButton(
                          label: 'Guardar',
                          isLoading: state.guardando,
                          onPressed: (state.puedeGuardar && !state.guardando)
                              ? () async {
                                  final ok = await ctrl.guardar();
                                  if (ok && context.mounted) {
                                    ref.invalidate(escuelasListControllerProvider);
                                    ref
                                        .read(notificacionProvider.notifier)
                                        .exito('¡Escuela creada!');
                                    context.go('/inicio');
                                  }
                                }
                              : null,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CheckRow extends StatelessWidget {
  const _CheckRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!value),
      child: Row(
        children: [
          Checkbox(
            value: value,
            onChanged: (v) => onChanged(v ?? false),
          ),
          Expanded(
            child: Text(label, style: AppTypography.texto),
          ),
        ],
      ),
    );
  }
}
