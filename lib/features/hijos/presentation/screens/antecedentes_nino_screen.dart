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
import '../controllers/antecedentes_nino_controller.dart';

const _siNoNoSabe = [
  (value: 'si', label: 'Sí'),
  (value: 'no', label: 'No'),
  (value: 'no_sabe', label: 'No sabe'),
];

/// Etiquetas de las preguntas Sí/No/No sabe (orden de la card "Antecedentes").
const _preguntas = <({String campo, String label})>[
  (campo: 'convulsiones_epilepsia', label: '¿Convulsiones a repetición o epilepsia?'),
  (campo: 'mareos_desmayos', label: '¿Mareos, desmayos, dolor de pecho o falta de aire con el ejercicio?'),
  (campo: 'infecciones_urinarias', label: '¿Infecciones urinarias a repetición?'),
  (campo: 'asma_espasmos', label: '¿Asma o espasmos bronquiales a repetición?'),
  (campo: 'tuberculosis', label: '¿Tuberculosis?'),
  (campo: 'diabetes', label: '¿Diabetes?'),
  (campo: 'hipertension', label: '¿Presión arterial alta?'),
  (campo: 'cardiopatia_congenita', label: '¿Cardiopatía congénita u otro problema del corazón?'),
  (campo: 'traumatismo_internacion', label: '¿Traumatismo/accidente que requirió internación?'),
  (campo: 'diarrea_frecuente', label: '¿Diarrea frecuente o a repetición?'),
  (campo: 'infecciones_oido', label: '¿Dolor o infecciones de oído frecuentes?'),
];

class AntecedentesNinoScreen extends ConsumerWidget {
  const AntecedentesNinoScreen({super.key, required this.hijoLocalId});
  final String hijoLocalId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prov = antecedentesNinoControllerProvider(hijoLocalId);
    ref.listen(prov, (prev, next) {
      if (next.exito && !(prev?.exito ?? false)) {
        ref.read(notificacionProvider.notifier).exito('¡Antecedentes guardados!');
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/inicio');
        }
      }
      if (next.error != null && next.error != prev?.error) {
        ref.read(notificacionProvider.notifier).error(next.error!);
      }
    });
    final state = ref.watch(prov);
    final ctrl = ref.read(prov.notifier);

    if (state.cargando) {
      return const AppGradientScaffold(child: Center(child: CircularProgressIndicator()));
    }

    AppDropdownField snns(String campo, String label) => AppDropdownField(
          label: label,
          value: state.respuesta(campo).isEmpty ? null : state.respuesta(campo),
          items: _siNoNoSabe,
          onChanged: (v) => ctrl.setCampo(campo, v),
        );

    return AppGradientScaffold(
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
          child: Row(children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, color: AppColors.blanco),
              onPressed: () => context.canPop() ? context.pop() : context.go('/inicio'),
            ),
            Expanded(
              child: Text('Antecedentes de salud',
                  style: AppTypography.titulo.copyWith(color: AppColors.blanco, fontSize: 22)),
            ),
          ]),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              AppCard(
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Text('Nacimiento', style: AppTypography.subtitulo),
                  const SizedBox(height: AppSpacing.sm),
                  snns('nacio_prematuro', '¿Nació prematuro?'),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    label: 'Peso de nacimiento (kg)',
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    onChanged: ctrl.setPesoNacimiento,
                  ),
                ]),
              ),
              const SizedBox(height: AppSpacing.md),
              AppCard(
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Text('Antecedentes', style: AppTypography.subtitulo),
                  for (final p in _preguntas) ...[
                    const SizedBox(height: AppSpacing.md),
                    snns(p.campo, p.label),
                  ],
                ]),
              ),
              const SizedBox(height: AppSpacing.md),
              AppCard(
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Text('Internación, tratamiento y otros', style: AppTypography.subtitulo),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                      label: 'Causa de internación (si alguna vez estuvo internado)',
                      onChanged: ctrl.setCausaHospitalizacion),
                  const SizedBox(height: AppSpacing.md),
                  snns('rabia_tratamiento', '¿Recibe algún tratamiento (médico, psicológico, fonoaudiológico…)?'),
                  if (state.recibeTratamiento) ...[
                    const SizedBox(height: AppSpacing.md),
                    AppTextField(label: '¿Cuál?', onChanged: ctrl.setDescripcionTratamiento),
                  ],
                  const SizedBox(height: AppSpacing.md),
                  AppDropdownField(
                    label: '¿Última vez que un médico lo pesó, midió y controló vacunas?',
                    value: state.ultimaConsultaMedica.isEmpty ? null : state.ultimaConsultaMedica,
                    items: const [
                      (value: 'menos_1_anio', label: 'Hace menos de 1 año'),
                      (value: 'mas_1_anio', label: 'Hace más de 1 año'),
                      (value: 'no_recuerda', label: 'No recuerda'),
                    ],
                    onChanged: ctrl.setUltimaConsultaMedica,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                      label: 'Otro problema de salud no detallado (¿cuál?)',
                      onChanged: ctrl.setOtrosProblemasSalud),
                ]),
              ),
              if (state.esFemenino) ...[
                const SizedBox(height: AppSpacing.md),
                AppCard(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    Text('Menstruación', style: AppTypography.subtitulo),
                    const SizedBox(height: AppSpacing.md),
                    snns('primera_menstruacion', '¿Tuvo la primera menstruación?'),
                    if (state.tuvoMenstruacion) ...[
                      const SizedBox(height: AppSpacing.md),
                      AppTextField(
                          label: 'Edad (años)',
                          keyboardType: TextInputType.number,
                          onChanged: ctrl.setEdadMenstruacion),
                    ],
                  ]),
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              AppCard(
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  if (state.error != null) ...[
                    Text(state.error!,
                        style: AppTypography.texto.copyWith(color: AppColors.error),
                        textAlign: TextAlign.center),
                    const SizedBox(height: AppSpacing.md),
                  ],
                  AppButton(
                    label: 'Guardar',
                    isLoading: state.guardando,
                    onPressed: state.guardando ? null : ctrl.guardar,
                  ),
                ]),
              ),
              const SizedBox(height: AppSpacing.lg),
            ]),
          ),
        ),
      ]),
    );
  }
}
