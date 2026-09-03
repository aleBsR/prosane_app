import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/design_system/app_button.dart';
import '../../../../core/design_system/app_card.dart';
import '../../../../core/design_system/app_dropdown_field.dart';
import '../../../../core/design_system/app_gradient_scaffold.dart';
import '../../../../core/design_system/app_text_field.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../controllers/evaluacion_medica_controller.dart';
import '../controllers/operativo_detail_controller.dart';

/// Etiquetas legibles en español para los 11 sistemas de hallazgos.
const Map<String, String> _hallazgoLabels = {
  'piel': 'Piel',
  'partes_blandas': 'Partes blandas',
  'cardiovascular': 'Cardiovascular',
  'respiratorio': 'Respiratorio',
  'abdominal': 'Abdominal',
  'genitourinario': 'Genitourinario',
  'osteoarticular': 'Osteoarticular',
  'neurologico': 'Neurológico',
  'salud_visual': 'Salud visual',
  'fonoaudiologica': 'Fonoaudiológica',
  'icv': 'ICV',
};

/// Etiquetas legibles en español para las especialidades de derivación.
const Map<String, String> _derivacionLabels = {
  'odontologia': 'Odontología',
  'oftalmologia': 'Oftalmología',
  'nutricion': 'Nutrición',
  'neurologia': 'Neurología',
  'cardiologia': 'Cardiología',
  'fonoaudiologia': 'Fonoaudiología',
  'psicologia': 'Psicología',
  'otros': 'Otros',
};

const List<({String value, String label})> _hallazgoEstadoItems = [
  (value: 'con', label: 'Con hallazgos'),
  (value: 'sin', label: 'Sin hallazgos'),
  (value: 'no_eval', label: 'No evaluado'),
];

class EvaluacionMedicaScreen extends ConsumerWidget {
  const EvaluacionMedicaScreen({
    super.key,
    required this.operativoId,
    required this.alumnoId,
  });

  final String operativoId;
  final String alumnoId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final args = (opId: operativoId, alumnoId: alumnoId);
    final state = ref.watch(evaluacionMedicaControllerProvider(args));
    final ctrl = ref.read(evaluacionMedicaControllerProvider(args).notifier);
    final operativoAsync = ref.watch(operativoDetailProvider(operativoId));
    final esNoEditable = operativoAsync.maybeWhen(
      data: (op) => op['estado'] == 'finalizado' || op['estado'] == 'cancelado',
      orElse: () => false,
    );
    final esEnCurso = operativoAsync.maybeWhen(
      data: (op) => op['estado'] == 'en_curso',
      orElse: () => false,
    );
    final esBloqueadoPrevio = !esEnCurso && !esNoEditable;

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
                    context.go('/operativos');
                  }
                },
              ),
              Text(esNoEditable ? 'Evaluación médica — solo lectura' : esBloqueadoPrevio ? 'Evaluación médica — no disponible' : 'Evaluación médica',
                  style: AppTypography.titulo
                      .copyWith(color: AppColors.blanco, fontSize: 22)),
            ]),
          ),
          Expanded(
            child: state.cargando
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.blanco),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (esNoEditable) ...[
                          Center(
                            child: Container(
                              constraints: const BoxConstraints(maxWidth: 300),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE8F5E9),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: const Color(0xFF66BB6A)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.lock_outline, size: 14, color: Color(0xFF2E7D32)),
                                  const SizedBox(width: 6),
                                  Flexible(child: Text('Operativo finalizado — solo lectura', style: AppTypography.texto.copyWith(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF2E7D32)))),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                        ] else if (esBloqueadoPrevio) ...[
                          Center(
                            child: Container(
                              constraints: const BoxConstraints(maxWidth: 320),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF3E0),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: const Color(0xFFFFB74D)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.info_outline, size: 14, color: Color(0xFFE65100)),
                                  const SizedBox(width: 6),
                                  Flexible(child: Text('Solo se puede cargar cuando el operativo está en curso', style: AppTypography.texto.copyWith(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFFE65100)))),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                        ],
                        AbsorbPointer(
                          absorbing: !esEnCurso,
                          child: Opacity(
                            opacity: esEnCurso ? 1 : 0.85,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _cardExamenClinico(state, ctrl),
                                const SizedBox(height: AppSpacing.md),
                                _cardAntropometria(state, ctrl),
                                const SizedBox(height: AppSpacing.md),
                                _cardPresion(state, ctrl),
                                const SizedBox(height: AppSpacing.md),
                                _cardAgudezaAudiometria(state, ctrl),
                                const SizedBox(height: AppSpacing.md),
                                _cardHallazgos(state, ctrl),
                                const SizedBox(height: AppSpacing.md),
                                _cardVacunacion(state, ctrl),
                                const SizedBox(height: AppSpacing.md),
                                _cardDerivaciones(state, ctrl),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        if (esEnCurso)
                          AppCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                if (state.error != null) ...[
                                  Text(state.error!,
                                      style: AppTypography.texto
                                          .copyWith(color: AppColors.error),
                                      textAlign: TextAlign.center),
                                  const SizedBox(height: AppSpacing.md),
                                ],
                                AppButton(
                                  label: 'Guardar',
                                  isLoading: state.guardando,
                                  onPressed: state.guardando
                                      ? null
                                      : () async {
                                          final ok = await ctrl.guardar();
                                          if (ok && context.mounted) {
                                            ref.invalidate(
                                                alumnosProvider(operativoId));
                                            ref.invalidate(
                                                completitudProvider(operativoId));
                                            ref.invalidate(
                                                operativoDetailProvider(operativoId));
                                            context.pop();
                                          }
                                        },
                                ),
                              ],
                            ),
                          )
                        else if (state.error != null)
                          AppCard(
                            child: Text(state.error!,
                                style: AppTypography.texto
                                    .copyWith(color: AppColors.error),
                                textAlign: TextAlign.center),
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

  Widget _cardExamenClinico(
      EvaluacionMedicaState state, EvaluacionMedicaController ctrl) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Examen clínico', style: AppTypography.subtitulo),
          const SizedBox(height: AppSpacing.sm),
          _CheckRow(
            label: 'Examen realizado',
            value: state.examenRealizado,
            onChanged: ctrl.setExamenRealizado,
          ),
          if (!state.examenRealizado) ...[
            const SizedBox(height: AppSpacing.sm),
            AppDropdownField(
              label: 'Motivo de no examen',
              value: state.motivoNoExamen.isEmpty ? null : state.motivoNoExamen,
              items: const [
                (value: 'negativa_familiar', label: 'Negativa familiar'),
                (value: 'negativa_nino', label: 'Negativa del niño'),
                (value: 'ausente', label: 'Ausente'),
                (value: 'otros', label: 'Otros'),
              ],
              onChanged: ctrl.setMotivoNoExamen,
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          AppDropdownField(
            label: 'Lugar del examen',
            value: state.lugarExamen.isEmpty ? null : state.lugarExamen,
            items: const [
              (value: 'escuela', label: 'Escuela'),
              (value: 'centro_salud', label: 'Centro de salud'),
            ],
            onChanged: ctrl.setLugarExamen,
          ),
        ],
      ),
    );
  }

  Widget _cardAntropometria(
      EvaluacionMedicaState state, EvaluacionMedicaController ctrl) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Antropometría', style: AppTypography.subtitulo),
          const SizedBox(height: AppSpacing.sm),
          AppTextField(
            label: 'Peso (kg)',
            controller: TextEditingController(text: state.peso)
              ..selection =
                  TextSelection.collapsed(offset: state.peso.length),
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            onChanged: ctrl.setPeso,
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            label: 'Talla (cm)',
            controller: TextEditingController(text: state.talla)
              ..selection =
                  TextSelection.collapsed(offset: state.talla.length),
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            onChanged: ctrl.setTalla,
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            label: 'IMC',
            controller: TextEditingController(text: state.imc)
              ..selection = TextSelection.collapsed(offset: state.imc.length),
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            readOnly: true,
            helperText: 'Se calcula automáticamente con peso y talla',
          ),
          const SizedBox(height: AppSpacing.md),
          AppDropdownField(
            label: 'Percentil talla',
            value: state.percentilTalla.isEmpty ? null : state.percentilTalla,
            items: const [
              (value: 'menor_3', label: 'Menor a 3'),
              (value: 'mayor_igual_3', label: 'Mayor o igual a 3'),
            ],
            onChanged: ctrl.setPercentilTalla,
          ),
          const SizedBox(height: AppSpacing.md),
          AppDropdownField(
            label: 'Percentil IMC',
            value: state.percentilImc.isEmpty ? null : state.percentilImc,
            items: const [
              (value: 'menor_3', label: 'Menor a 3'),
              (value: 'entre_3_9', label: 'Entre 3 y 9'),
              (value: 'entre_10_84', label: 'Entre 10 y 84'),
              (value: 'entre_85_97', label: 'Entre 85 y 97'),
              (value: 'mayor_97', label: 'Mayor a 97'),
            ],
            onChanged: ctrl.setPercentilImc,
          ),
        ],
      ),
    );
  }

  Widget _cardPresion(
      EvaluacionMedicaState state, EvaluacionMedicaController ctrl) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Presión arterial', style: AppTypography.subtitulo),
          const SizedBox(height: AppSpacing.sm),
          AppTextField(
            label: 'PAS (sistólica)',
            controller: TextEditingController(text: state.pas)
              ..selection = TextSelection.collapsed(offset: state.pas.length),
            keyboardType: TextInputType.number,
            onChanged: ctrl.setPas,
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            label: 'PAD (diastólica)',
            controller: TextEditingController(text: state.pad)
              ..selection = TextSelection.collapsed(offset: state.pad.length),
            keyboardType: TextInputType.number,
            onChanged: ctrl.setPad,
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            label: 'Clasificación',
            controller: TextEditingController(text: state.presionClasificacion)
              ..selection = TextSelection.collapsed(
                  offset: state.presionClasificacion.length),
            onChanged: ctrl.setPresionClasificacion,
          ),
        ],
      ),
    );
  }

  Widget _cardAgudezaAudiometria(
      EvaluacionMedicaState state, EvaluacionMedicaController ctrl) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Agudeza visual / Audiometría',
              style: AppTypography.subtitulo),
          const SizedBox(height: AppSpacing.sm),
          _CheckRow(
            label: 'Agudeza evaluada',
            value: state.agudezaEvaluada,
            onChanged: ctrl.setAgudezaEvaluada,
          ),
          const SizedBox(height: AppSpacing.sm),
          AppTextField(
            label: 'Ojo derecho',
            controller: TextEditingController(text: state.ojoDerecho)
              ..selection =
                  TextSelection.collapsed(offset: state.ojoDerecho.length),
            onChanged: ctrl.setOjoDerecho,
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            label: 'Ojo izquierdo',
            controller: TextEditingController(text: state.ojoIzquierdo)
              ..selection =
                  TextSelection.collapsed(offset: state.ojoIzquierdo.length),
            onChanged: ctrl.setOjoIzquierdo,
          ),
          const SizedBox(height: AppSpacing.sm),
          _CheckRow(
            label: 'Usa lentes',
            value: state.usaLentes,
            onChanged: ctrl.setUsaLentes,
          ),
          _CheckRow(
            label: 'Audiometría realizada',
            value: state.audiometriaRealizada,
            onChanged: ctrl.setAudiometriaRealizada,
          ),
          const SizedBox(height: AppSpacing.sm),
          AppDropdownField(
            label: 'Resultado audiometría',
            value: state.audiometriaResultado.isEmpty
                ? null
                : state.audiometriaResultado,
            items: const [
              (value: 'pasa', label: 'Pasa'),
              (value: 'no_pasa', label: 'No pasa'),
            ],
            onChanged: ctrl.setAudiometriaResultado,
          ),
        ],
      ),
    );
  }

  Widget _cardHallazgos(
      EvaluacionMedicaState state, EvaluacionMedicaController ctrl) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Hallazgos clínicos', style: AppTypography.subtitulo),
          for (final sistema in kHallazgoSistemas) ...[
            const SizedBox(height: AppSpacing.md),
            Text(_hallazgoLabels[sistema] ?? sistema,
                style: AppTypography.texto
                    .copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            AppDropdownField(
              label: 'Estado',
              value: state.hallazgos[sistema]?.estado,
              items: _hallazgoEstadoItems,
              onChanged: (v) => ctrl.setHallazgoEstado(sistema, v),
            ),
            const SizedBox(height: AppSpacing.sm),
            AppTextField(
              label: 'Detalle',
              controller: TextEditingController(
                  text: state.hallazgos[sistema]?.detalle ?? '')
                ..selection = TextSelection.collapsed(
                    offset: (state.hallazgos[sistema]?.detalle ?? '').length),
              onChanged: (v) => ctrl.setHallazgoDetalle(sistema, v),
            ),
          ],
        ],
      ),
    );
  }

  Widget _cardVacunacion(
      EvaluacionMedicaState state, EvaluacionMedicaController ctrl) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Vacunación', style: AppTypography.subtitulo),
          const SizedBox(height: AppSpacing.sm),
          _CheckRow(
            label: 'Trajo carnet',
            value: state.trajoCarnet,
            onChanged: ctrl.setTrajoCarnet,
          ),
          _CheckRow(
            label: 'Carnet completo',
            value: state.carnetCompleto,
            onChanged: ctrl.setCarnetCompleto,
          ),
          const SizedBox(height: AppSpacing.sm),
          AppTextField(
            label: 'Vacunas aplicadas',
            controller: TextEditingController(text: state.vacunasAplicadas)
              ..selection = TextSelection.collapsed(
                  offset: state.vacunasAplicadas.length),
            onChanged: ctrl.setVacunasAplicadas,
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            label: 'Vacunas indicadas',
            controller: TextEditingController(text: state.vacunasIndicadas)
              ..selection = TextSelection.collapsed(
                  offset: state.vacunasIndicadas.length),
            onChanged: ctrl.setVacunasIndicadas,
          ),
        ],
      ),
    );
  }

  Widget _cardDerivaciones(
      EvaluacionMedicaState state, EvaluacionMedicaController ctrl) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Derivaciones', style: AppTypography.subtitulo),
          for (final esp in kDerivacionEspecialidades) ...[
            const SizedBox(height: AppSpacing.sm),
            _CheckRow(
              label: 'Deriva a ${_derivacionLabels[esp] ?? esp}',
              value: state.derivaciones[esp]?.deriva ?? false,
              onChanged: (v) => ctrl.setDerivacion(esp, deriva: v),
            ),
            if (state.derivaciones[esp]?.deriva ?? false) ...[
              AppTextField(
                label: 'Motivo',
                controller: TextEditingController(
                    text: state.derivaciones[esp]?.motivo ?? '')
                  ..selection = TextSelection.collapsed(
                      offset:
                          (state.derivaciones[esp]?.motivo ?? '').length),
                onChanged: (v) => ctrl.setDerivacion(esp, motivo: v),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
          ],
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
