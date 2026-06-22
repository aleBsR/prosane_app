import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/design_system/app_button.dart';
import '../../../../core/design_system/app_card.dart';
import '../../../../core/design_system/app_date_field.dart';
import '../../../../core/design_system/app_dropdown_field.dart';
import '../../../../core/design_system/app_gradient_scaffold.dart';
import '../../../../core/design_system/app_switch.dart';
import '../../../../core/design_system/app_text_field.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/providers.dart';
import '../controllers/planilla_controller.dart';

class PlanillaScreen extends ConsumerWidget {
  const PlanillaScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(planillaControllerProvider);
    final ctrl = ref.read(planillaControllerProvider.notifier);

    return AppGradientScaffold(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            child: Row(children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: AppColors.blanco),
                onPressed: () => context.pop(),
              ),
              Text('Evaluación de tu hijo/a',
                  style: AppTypography.titulo.copyWith(color: AppColors.blanco, fontSize: 22)),
            ]),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppCard(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                      Text('Datos del niño/a', style: AppTypography.subtitulo),
                      const SizedBox(height: AppSpacing.sm),
                      AppTextField(label: 'Nombre', onChanged: ctrl.setNombre),
                      const SizedBox(height: AppSpacing.md),
                      AppTextField(label: 'Apellido', onChanged: ctrl.setApellido),
                      const SizedBox(height: AppSpacing.md),
                      AppTextField(label: 'DNI', keyboardType: TextInputType.number, onChanged: ctrl.setDni),
                      const SizedBox(height: AppSpacing.md),
                      AppDropdownField(
                        label: 'Tipo de documento',
                        value: state.tipoDni,
                        items: const [(value: 'DNI', label: 'DNI'), (value: 'Pasaporte', label: 'Pasaporte')],
                        onChanged: ctrl.setTipoDni,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AppDropdownField(
                        label: 'Sexo',
                        value: state.sexo.isEmpty ? null : state.sexo,
                        items: const [
                          (value: 'F', label: 'Femenino'),
                          (value: 'M', label: 'Masculino'),
                          (value: 'X', label: 'Otro'),
                        ],
                        onChanged: ctrl.setSexo,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AppDateField(
                        label: 'Fecha de nacimiento',
                        value: state.fechaNacimiento,
                        onChanged: ctrl.setFechaNacimiento,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AppDropdownField(
                        label: 'Parentesco',
                        value: state.parentesco.isEmpty ? null : state.parentesco,
                        items: const [
                          (value: 'Hijo/a', label: 'Hijo/a'),
                          (value: 'Hijastro/a', label: 'Hijastro/a'),
                          (value: 'Nieto/a', label: 'Nieto/a'),
                          (value: 'Sobrino/a', label: 'Sobrino/a'),
                          (value: 'Tutelado/a', label: 'Tutelado/a'),
                          (value: 'Otro', label: 'Otro'),
                        ],
                        onChanged: ctrl.setParentesco,
                      ),
                    ]),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppCard(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                      Text('Domicilio', style: AppTypography.subtitulo),
                      const SizedBox(height: AppSpacing.sm),
                      AppTextField(label: 'Calle', onChanged: ctrl.setCalle),
                      const SizedBox(height: AppSpacing.md),
                      AppTextField(label: 'Número', keyboardType: TextInputType.number, onChanged: ctrl.setNroCalle),
                      const SizedBox(height: AppSpacing.md),
                      AppTextField(label: 'Provincia', onChanged: ctrl.setProvincia),
                    ]),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppCard(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                      Text('Cobertura médica', style: AppTypography.subtitulo),
                      const SizedBox(height: AppSpacing.sm),
                      AppDropdownField(
                        label: 'Tipo de cobertura',
                        value: state.tipoCobertura.isEmpty ? null : state.tipoCobertura,
                        items: const [
                          (value: 'Obra social', label: 'Obra social'),
                          (value: 'Prepaga', label: 'Prepaga'),
                          (value: 'Sin cobertura', label: 'Sin cobertura'),
                        ],
                        onChanged: ctrl.setTipoCobertura,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AppTextField(label: 'Nombre de la cobertura', onChanged: ctrl.setNombreCobertura),
                      const SizedBox(height: AppSpacing.md),
                      AppDropdownField(
                        label: 'Tiene CUD',
                        value: state.tieneCud.isEmpty ? null : state.tieneCud,
                        items: const [
                          (value: 'Sí', label: 'Sí'),
                          (value: 'No', label: 'No'),
                          (value: 'En trámite', label: 'En trámite'),
                        ],
                        onChanged: ctrl.setTieneCud,
                      ),
                    ]),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppCard(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Antecedentes del niño/a', style: AppTypography.subtitulo),
                      const SizedBox(height: AppSpacing.sm),
                      AppSwitch(label: 'Asma / espasmos bronquiales', value: state.asmaEspasmos, onChanged: ctrl.setAsmaEspasmos),
                      const SizedBox(height: AppSpacing.sm),
                      AppSwitch(label: 'Diabetes', value: state.diabetes, onChanged: ctrl.setDiabetes),
                    ]),
                  ),
                  if (state.error != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    Text(state.error!,
                        style: AppTypography.texto.copyWith(color: AppColors.error),
                        textAlign: TextAlign.center),
                  ],
                  const SizedBox(height: AppSpacing.lg),
                  AppButton(
                    label: 'Guardar',
                    isLoading: state.guardando,
                    onPressed: (state.puedeGuardar && !state.guardando)
                        ? () async {
                            await ctrl.guardar();
                            if (context.mounted &&
                                ref.read(planillaControllerProvider).error == null) {
                              ref.read(syncSchedulerProvider).dispararPorEscritura();
                              context.go('/inicio');
                            }
                          }
                        : null,
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
