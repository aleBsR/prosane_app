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
import '../controllers/evaluacion_odontologica_controller.dart';

const List<({String value, String label})> _saludBucalItems = [
  (value: 'con_hallazgos', label: 'Con hallazgos'),
  (value: 'sin_hallazgos', label: 'Sin hallazgos'),
  (value: 'no_eval', label: 'No evaluado'),
];

/// Estados posibles por pieza dental.
const List<({String value, String label})> _piezaEstadoItems = [
  (value: 'sano', label: 'Sano'),
  (value: 'caries', label: 'Caries'),
  (value: 'obturado', label: 'Obturado'),
  (value: 'ausente', label: 'Ausente'),
  (value: 'a_realizar', label: 'A realizar'),
  (value: 'realizado', label: 'Realizado'),
];

class EvaluacionOdontologicaScreen extends ConsumerWidget {
  const EvaluacionOdontologicaScreen({
    super.key,
    required this.operativoId,
    required this.alumnoId,
  });

  final String operativoId;
  final String alumnoId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final args = (opId: operativoId, alumnoId: alumnoId);
    final state = ref.watch(evaluacionOdontologicaControllerProvider(args));
    final ctrl =
        ref.read(evaluacionOdontologicaControllerProvider(args).notifier);

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
              Text('Evaluación odontológica',
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
                        _cardSaludBucal(state, ctrl),
                        const SizedBox(height: AppSpacing.md),
                        _cardPracticas(state, ctrl),
                        const SizedBox(height: AppSpacing.md),
                        _cardIndices(state, ctrl),
                        const SizedBox(height: AppSpacing.md),
                        _cardOdontograma(state, ctrl),
                        const SizedBox(height: AppSpacing.md),
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
                                          context.pop();
                                        }
                                      },
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

  Widget _cardSaludBucal(EvaluacionOdontologicaState state,
      EvaluacionOdontologicaController ctrl) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Salud bucal', style: AppTypography.subtitulo),
          const SizedBox(height: AppSpacing.sm),
          AppDropdownField(
            label: 'Estado',
            value: state.saludBucal.isEmpty ? null : state.saludBucal,
            items: _saludBucalItems,
            onChanged: ctrl.setSaludBucal,
          ),
          const SizedBox(height: AppSpacing.sm),
          _CheckRow(
            label: 'Lesiones en tejidos blandos',
            value: state.lesionesTejidosBlandos,
            onChanged: ctrl.setLesionesTejidosBlandos,
          ),
          _CheckRow(
            label: 'Maloclusión',
            value: state.maloclusion,
            onChanged: ctrl.setMaloclusion,
          ),
          _CheckRow(
            label: 'Fluorosis',
            value: state.fluorosis,
            onChanged: ctrl.setFluorosis,
          ),
          _CheckRow(
            label: 'Caries',
            value: state.caries,
            onChanged: ctrl.setCaries,
          ),
          const SizedBox(height: AppSpacing.sm),
          AppTextField(
            label: 'Otros',
            controller: TextEditingController(text: state.otros)
              ..selection =
                  TextSelection.collapsed(offset: state.otros.length),
            onChanged: ctrl.setOtros,
          ),
        ],
      ),
    );
  }

  Widget _cardPracticas(EvaluacionOdontologicaState state,
      EvaluacionOdontologicaController ctrl) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Prácticas', style: AppTypography.subtitulo),
          const SizedBox(height: AppSpacing.sm),
          _CheckRow(
            label: 'Topicación de flúor',
            value: state.topicacionFluor,
            onChanged: ctrl.setTopicacionFluor,
          ),
          _CheckRow(
            label: 'Enseñanza de cepillado',
            value: state.ensenanzaCepillado,
            onChanged: ctrl.setEnsenanzaCepillado,
          ),
          _CheckRow(
            label: 'Alta básica',
            value: state.altaBasica,
            onChanged: ctrl.setAltaBasica,
          ),
        ],
      ),
    );
  }

  Widget _cardIndices(EvaluacionOdontologicaState state,
      EvaluacionOdontologicaController ctrl) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Índice CPO/ceo', style: AppTypography.subtitulo),
          const SizedBox(height: AppSpacing.sm),
          Text('CPO (dentición permanente)',
              style:
                  AppTypography.texto.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: AppSpacing.sm),
          _numField('Cariados (C)', state.cpoC, ctrl.setCpoC),
          const SizedBox(height: AppSpacing.md),
          _numField('Perdidos (P)', state.cpoP, ctrl.setCpoP),
          const SizedBox(height: AppSpacing.md),
          _numField('Obturados (O)', state.cpoO, ctrl.setCpoO),
          const SizedBox(height: AppSpacing.md),
          Text('ceo (dentición temporaria)',
              style:
                  AppTypography.texto.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: AppSpacing.sm),
          _numField('Cariados (c)', state.ceoC, ctrl.setCeoC),
          const SizedBox(height: AppSpacing.md),
          _numField('Con extracción indicada (e)', state.ceoE, ctrl.setCeoE),
          const SizedBox(height: AppSpacing.md),
          _numField('Obturados (o)', state.ceoO, ctrl.setCeoO),
        ],
      ),
    );
  }

  Widget _numField(String label, String value, ValueChanged<String> onChanged) {
    return AppTextField(
      label: label,
      controller: TextEditingController(text: value)
        ..selection = TextSelection.collapsed(offset: value.length),
      keyboardType: TextInputType.number,
      onChanged: onChanged,
    );
  }

  Widget _cardOdontograma(EvaluacionOdontologicaState state,
      EvaluacionOdontologicaController ctrl) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Odontograma', style: AppTypography.subtitulo),
          const SizedBox(height: AppSpacing.sm),
          Text('Dentición permanente',
              style:
                  AppTypography.texto.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: AppSpacing.sm),
          _grillaPiezas(kPiezasPermanentes, state, ctrl),
          const SizedBox(height: AppSpacing.md),
          Text('Dentición temporaria',
              style:
                  AppTypography.texto.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: AppSpacing.sm),
          _grillaPiezas(kPiezasTemporarias, state, ctrl),
        ],
      ),
    );
  }

  Widget _grillaPiezas(List<String> piezas, EvaluacionOdontologicaState state,
      EvaluacionOdontologicaController ctrl) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        for (final pieza in piezas)
          SizedBox(
            width: 150,
            child: AppDropdownField(
              label: 'Pieza $pieza',
              value: state.odontograma[pieza],
              items: _piezaEstadoItems,
              onChanged: (v) => ctrl.setPieza(pieza, v),
            ),
          ),
      ],
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
