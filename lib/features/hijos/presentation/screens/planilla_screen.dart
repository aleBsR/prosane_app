import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/design_system/app_button.dart';
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
          // AppBar manual dentro del gradiente
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: AppColors.blanco),
                  onPressed: () => context.pop(),
                ),
                Text(
                  'Planilla familiar',
                  style: AppTypography.titulo.copyWith(color: AppColors.blanco),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Sección 1: Datos del NNA ──────────────────────────────
                  _SectionTitle('Datos del niño/a'),
                  const SizedBox(height: AppSpacing.sm),
                  AppTextField(
                    label: 'Nombre',
                    hint: 'Nombre del niño/a',
                    onChanged: ctrl.setNombre,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    label: 'Apellido',
                    hint: 'Apellido',
                    onChanged: ctrl.setApellido,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    label: 'DNI',
                    hint: 'Número de DNI',
                    keyboardType: TextInputType.number,
                    onChanged: ctrl.setDni,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    label: 'Tipo de documento',
                    hint: 'DNI / Pasaporte...',
                    onChanged: ctrl.setTipoDni,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    label: 'Sexo',
                    hint: 'M / F / X',
                    onChanged: ctrl.setSexo,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    label: 'Fecha de nacimiento',
                    hint: 'AAAA-MM-DD',
                    onChanged: (v) {
                      final d = DateTime.tryParse(v);
                      if (d != null) ctrl.setFechaNacimiento(d);
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    label: 'Edad',
                    hint: 'Años',
                    keyboardType: TextInputType.number,
                    onChanged: (v) {
                      final n = int.tryParse(v);
                      if (n != null) ctrl.setEdad(n);
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    label: 'Parentesco',
                    hint: 'Hijo/a, sobrino/a...',
                    onChanged: ctrl.setParentesco,
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  // ── Sección 2: Domicilio ───────────────────────────────────
                  _SectionTitle('Domicilio'),
                  const SizedBox(height: AppSpacing.sm),
                  AppTextField(
                    label: 'Calle',
                    onChanged: ctrl.setCalle,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    label: 'Número',
                    keyboardType: TextInputType.number,
                    onChanged: ctrl.setNroCalle,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    label: 'Provincia',
                    onChanged: ctrl.setProvincia,
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  // ── Sección 3: Cobertura ───────────────────────────────────
                  _SectionTitle('Cobertura médica'),
                  const SizedBox(height: AppSpacing.sm),
                  AppTextField(
                    label: 'Tipo de cobertura',
                    hint: 'Obra social, prepaga, sin cobertura...',
                    onChanged: ctrl.setTipoCobertura,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    label: 'Nombre de la cobertura',
                    onChanged: ctrl.setNombreCobertura,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    label: 'Tiene CUD',
                    hint: 'Sí / No / En trámite',
                    onChanged: ctrl.setTieneCud,
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  // ── Sección 4: Antecedentes ────────────────────────────────
                  _SectionTitle('Antecedentes personales'),
                  const SizedBox(height: AppSpacing.sm),
                  AppSwitch(
                    label: 'Asma / espasmos bronquiales',
                    value: state.asmaEspasmos,
                    onChanged: ctrl.setAsmaEspasmos,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  AppSwitch(
                    label: 'Diabetes',
                    value: state.diabetes,
                    onChanged: ctrl.setDiabetes,
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  _SectionTitle('Antecedentes familiares'),
                  const SizedBox(height: AppSpacing.sm),
                  AppSwitch(
                    label: 'Asma en familia',
                    value: state.antFamAsma,
                    onChanged: ctrl.setAntFamAsma,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  AppSwitch(
                    label: 'Diabetes en familia',
                    value: state.antFamDiabetes,
                    onChanged: ctrl.setAntFamDiabetes,
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  // ── Sección 5: Consentimiento ──────────────────────────────
                  _SectionTitle('Consentimiento informado'),
                  const SizedBox(height: AppSpacing.sm),
                  AppSwitch(
                    label: 'Acepto el consentimiento informado',
                    value: state.consentimientoAceptado,
                    onChanged: ctrl.setConsentimientoAceptado,
                  ),
                  if (state.consentimientoAceptado) ...[
                    const SizedBox(height: AppSpacing.md),
                    AppTextField(
                      label: 'Nombre del adulto responsable',
                      onChanged: ctrl.setAdultoNombre,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppTextField(
                      label: 'Apellido del adulto responsable',
                      onChanged: ctrl.setAdultoApellido,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppTextField(
                      label: 'Tipo de documento del adulto',
                      hint: 'DNI / Pasaporte...',
                      onChanged: ctrl.setAdultoTipoDocumento,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppTextField(
                      label: 'DNI del adulto',
                      keyboardType: TextInputType.number,
                      onChanged: ctrl.setAdultoDni,
                    ),
                  ],

                  if (state.error != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      state.error!,
                      style: AppTypography.texto.copyWith(color: AppColors.error),
                      textAlign: TextAlign.center,
                    ),
                  ],

                  const SizedBox(height: AppSpacing.lg),

                  // ── Guardar ────────────────────────────────────────────────
                  AppButton(
                    label: 'Guardar',
                    isLoading: state.guardando,
                    onPressed: state.guardando
                        ? null
                        : () async {
                            await ctrl.guardar();
                            if (context.mounted && ref.read(planillaControllerProvider).error == null) {
                              ref.read(syncSchedulerProvider).dispararPorEscritura();
                              context.go('/inicio');
                            }
                          },
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

// ─── Widget auxiliar ──────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: AppTypography.subtitulo.copyWith(color: AppColors.blanco),
      );
}
