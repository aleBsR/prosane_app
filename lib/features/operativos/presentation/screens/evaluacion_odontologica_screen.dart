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
import '../controllers/operativo_detail_controller.dart';
import '../widgets/pieza_dental_widget.dart';

const List<({String value, String label})> _saludBucalItems = [
  (value: 'con_hallazgos', label: 'Con hallazgos'),
  (value: 'sin_hallazgos', label: 'Sin hallazgos'),
  (value: 'no_eval', label: 'No evaluado'),
];

/// Estados posibles por pieza dental.
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
              Text(esNoEditable ? 'Evaluación odontológica — solo lectura' : esBloqueadoPrevio ? 'Evaluación odontológica — no disponible' : 'Evaluación odontológica',
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
                                _cardSaludBucal(state, ctrl),
                                const SizedBox(height: AppSpacing.md),
                                _cardPracticas(state, ctrl),
                                const SizedBox(height: AppSpacing.md),
                                _cardIndices(state, ctrl),
                                const SizedBox(height: AppSpacing.md),
                                _cardOdontograma(context, state, ctrl, enabled: !esNoEditable),
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

  Widget _cardOdontograma(BuildContext context, EvaluacionOdontologicaState state,
      EvaluacionOdontologicaController ctrl, {bool enabled = true}) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Odontograma', style: AppTypography.subtitulo),
          const SizedBox(height: AppSpacing.sm),
          _denticion(context, 'Permanente', state, ctrl, enabled: enabled),
          const SizedBox(height: AppSpacing.md),
          _denticion(context, 'Temporaria', state, ctrl, enabled: enabled),
          const SizedBox(height: AppSpacing.sm),
          const Text('Verde: normal  Azul: tratado  Rojo: pendiente  Gris: ausente',
              style: TextStyle(fontSize: 11)),
        ],
      ),
    );
  }

  Widget _denticion(BuildContext context, String titulo,
      EvaluacionOdontologicaState state,
      EvaluacionOdontologicaController ctrl, {bool enabled = true}) {
    final esPermanente = titulo == 'Permanente';
    final ladoDerechoSuperior = esPermanente
        ? kPiezasPermanentes.sublist(0, 8)
        : kPiezasTemporarias.sublist(0, 5);
    final ladoIzquierdoSuperior = esPermanente
        ? kPiezasPermanentes.sublist(8, 16)
        : kPiezasTemporarias.sublist(5, 10);
    final ladoDerechoInferior = esPermanente
        ? kPiezasPermanentes.sublist(16, 24)
        : kPiezasTemporarias.sublist(10, 15);
    final ladoIzquierdoInferior = esPermanente
        ? kPiezasPermanentes.sublist(24, 32)
        : kPiezasTemporarias.sublist(15, 20);

    Widget ladoDerecho() => _ladoOdontograma(
          context,
          'Lado derecho',
          'Superior (18 → 11)',
          'Inferior (48 → 41)',
          ladoDerechoSuperior,
          ladoDerechoInferior,
          state,
          ctrl,
          temporaria: !esPermanente,
        );
    Widget ladoIzquierdo() => _ladoOdontograma(
          context,
          'Lado izquierdo',
          'Superior (21 → 28)',
          'Inferior (31 → 38)',
          ladoIzquierdoSuperior,
          ladoIzquierdoInferior,
          state,
          ctrl,
          temporaria: !esPermanente,
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Dentición $titulo',
            style: AppTypography.texto.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: AppSpacing.sm),
        LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 520) {
              return Column(
                children: [ladoDerecho(), const SizedBox(height: AppSpacing.sm), ladoIzquierdo()],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: ladoDerecho()),
                const SizedBox(width: AppSpacing.md),
                Expanded(child: ladoIzquierdo()),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _ladoOdontograma(
      BuildContext context,
      String lado,
      String superiorLabel,
      String inferiorLabel,
      List<String> superior,
      List<String> inferior,
      EvaluacionOdontologicaState state,
      EvaluacionOdontologicaController ctrl,
      {required bool temporaria}) {
    final superiorTitulo = temporaria
        ? superiorLabel.replaceFirst('18 → 11', '55 → 51').replaceFirst('21 → 28', '61 → 65')
        : superiorLabel;
    final inferiorTitulo = temporaria
        ? inferiorLabel.replaceFirst('48 → 41', '85 → 81').replaceFirst('31 → 38', '71 → 75')
        : inferiorLabel;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(lado, style: AppTypography.texto.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        _filaCuadrante(context, superiorTitulo, superior, state, ctrl),
        _filaCuadrante(context, inferiorTitulo, inferior, state, ctrl),
      ],
    );
  }

  Widget _filaCuadrante(BuildContext context, String titulo, List<String> piezas,
      EvaluacionOdontologicaState state, EvaluacionOdontologicaController ctrl) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(titulo, style: const TextStyle(fontSize: 12)),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final pieza in piezas)
                PiezaDentalWidget(
                  numero: pieza,
                  pieza: state.odontograma[pieza] ?? const PiezaOdontograma(),
                  onTap: () => _editarPieza(context, pieza, ctrl),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _editarPieza(BuildContext context, String numero,
      EvaluacionOdontologicaController ctrl) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _PiezaEditorSheet(
        numero: numero,
        initial: ctrl.piezaActual(numero),
        onSave: (pieza) {
          ctrl.setEstadoGeneral(numero, pieza.estadoGeneral);
          for (final cara in kCarasPieza) {
            ctrl.setCara(numero, cara, pieza.caras[cara] ?? '');
          }
          ctrl.setRaiz(numero, pieza.raiz);
          ctrl.setNotasPieza(numero, pieza.notas);
        },
      ),
    );
  }
}

class _PiezaEditorSheet extends StatefulWidget {
  const _PiezaEditorSheet({required this.numero, required this.initial, required this.onSave});

  final String numero;
  final PiezaOdontograma initial;
  final ValueChanged<PiezaOdontograma> onSave;

  @override
  State<_PiezaEditorSheet> createState() => _PiezaEditorSheetState();
}

class _PiezaEditorSheetState extends State<_PiezaEditorSheet> {
  late String general = widget.initial.estadoGeneral;
  late String raiz = widget.initial.raiz;
  late Map<String, String> caras = Map<String, String>.from(widget.initial.caras);
  late final TextEditingController notasController =
      TextEditingController(text: widget.initial.notas);

  @override
  void dispose() {
    notasController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bloqueada = {'ausente', 'perdido', 'extraido'}.contains(general);
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Pieza ${widget.numero}', style: AppTypography.subtitulo),
            const SizedBox(height: 12),
            _selector('Estado general', general, kEstadosGeneralesPieza, (v) {
              setState(() {
                general = v;
                if ({'ausente', 'perdido', 'extraido'}.contains(v)) {
                  caras = {};
                  raiz = '';
                }
              });
            }),
            if (!bloqueada) ...[
              const SizedBox(height: 12),
              Text('Caras', style: AppTypography.texto.copyWith(fontWeight: FontWeight.w600)),
              for (final cara in kCarasPieza) ...[
                const SizedBox(height: 8),
                _selector(_labelCara(cara), caras[cara] ?? '', kEstadosCara,
                    (v) => setState(() => caras[cara] = v)),
              ],
              const SizedBox(height: 12),
              _selector('Raíz / pulpa', raiz, kEstadosRaiz,
                  (v) => setState(() => raiz = v)),
            ],
            const SizedBox(height: 12),
            AppTextField(label: 'Notas', controller: notasController),
            const SizedBox(height: 16),
            AppButton(
              label: 'Guardar pieza',
              onPressed: () {
                widget.onSave(PiezaOdontograma(
                  estadoGeneral: general,
                  caras: caras,
                  raiz: raiz,
                  notas: notasController.text,
                ));
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _selector(String label, String value,
      List<({String value, String label})> items, ValueChanged<String> onChanged) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: InputDecoration(labelText: label),
      items: [for (final item in items) DropdownMenuItem(value: item.value, child: Text(item.label))],
      onChanged: (v) => onChanged(v ?? ''),
    );
  }

  String _labelCara(String cara) => switch (cara) {
        'oclusal' => 'Oclusal',
        'mesial' => 'Mesial',
        'distal' => 'Distal',
        'vestibular' => 'Vestibular',
        _ => 'Lingual / palatina',
      };
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
