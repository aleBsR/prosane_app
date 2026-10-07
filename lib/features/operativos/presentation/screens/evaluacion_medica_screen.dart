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

/// Etiquetas legibles en español para los sistemas de hallazgos.
const Map<String, String> _hallazgoLabels = {
  'piel': 'Piel y faneras',
  'partes_blandas': 'Partes blandas',
  'cardiovascular': 'Cardiovascular',
  'respiratorio': 'Respiratorio',
  'abdominal': 'Abdominal',
  'genitourinario_ninos': 'Genitourinario (Niños)',
  'genitourinario_ninas': 'Genitourinario (Niñas)',
  'osteoarticular': 'Osteoarticular',
  'neurologico': 'Neurológico',
  'salud_visual': 'Salud visual',
  'salud_fonoaudiologica': 'Salud fonoaudiológica',
  'icv': 'ICV',
};

/// Checks disponibles por sistema cuando se marca "con hallazgos".
/// El id 'otro' habilita el campo de texto para detallar cuál.
const Map<String, List<({String id, String label})>> _hallazgoChecks = {
  'piel': [
    (id: 'nevo_derivacion', label: 'Nevos con criterio de derivación (Asimetría, bordes, color, diámetro, evolución)'),
    (id: 'escabiosis', label: 'Escabiosis'),
    (id: 'piodermitis', label: 'Piodermitis'),
    (id: 'pediculosis', label: 'Pediculosis'),
    (id: 'otro', label: 'Otro'),
  ],
  'partes_blandas': [
    (id: 'adenomegalia_localizada', label: 'Adenomegalia localizada'),
    (id: 'adenomegalias_generalizada', label: 'Adenomegalias generalizadas'),
    (id: 'otro', label: 'Otro'),
  ],
  'cardiovascular': [
    (id: 'presion_elevada', label: 'Presión arterial elevada'),
    (id: 'pulso_alterado', label: 'Ausencia o alteración del pulso humeral, radial o femoral (uni o bilateral)'),
    (id: 'soplo', label: 'Soplo'),
    (id: 'arritmia', label: 'Arritmia'),
    (id: 'otro', label: 'Otro'),
  ],
  'respiratorio': [
    (id: 'hallazgo_auscultatorio', label: 'Hallazgo auscultatorio'),
    (id: 'respiracion_bucal', label: 'Respiración bucal'),
    (id: 'otro', label: 'Otro'),
  ],
  'abdominal': [
    (id: 'hepatomegalia', label: 'Hepatomegalia'),
    (id: 'masa_palpable', label: 'Masa palpable'),
    (id: 'esplenomegalia', label: 'Esplenomegalia'),
    (id: 'hernias', label: 'Hernias'),
    (id: 'otro', label: 'Otro'),
  ],
  'genitourinario_ninos': [
    (id: 'pubertad_precoz', label: 'Signos de pubertad precoz (en niños menores de 9 años)'),
    (id: 'testiculo_no_descendido', label: 'Testículo/s no descendido/s'),
    (id: 'hernia', label: 'Hernia'),
    (id: 'fimosis', label: 'Fimosis'),
    (id: 'asimetria_testicular', label: 'Asimetría testicular'),
    (id: 'varicocele', label: 'Varicocele'),
    (id: 'otro', label: 'Otro'),
  ],
  'genitourinario_ninas': [
    (id: 'pubertad_precoz', label: 'Signos de pubertad precoz (en niñas menores de 8 años)'),
    (id: 'otro', label: 'Otro'),
  ],
  'osteoarticular': [
    (id: 'adams_positiva', label: 'Maniobra de Adams positiva'),
    (id: 'alteracion_marcha', label: 'Alteraciones de la marcha'),
    (id: 'otro', label: 'Otro'),
  ],
  'neurologico': [
    (id: 'paresias_focales', label: 'Paresias o signos focales'),
    (id: 'movimientos_anormales', label: 'Movimientos anormales'),
    (id: 'otro', label: 'Otro'),
  ],
  'salud_visual': [
    (id: 'disminucion_agudeza', label: 'Disminución de agudeza visual'),
    (id: 'estrabismo', label: 'Estrabismo'),
    (id: 'posicion_cabeza', label: 'Posición anormal de la cabeza'),
    (id: 'ojo_externo', label: 'Alteraciones del ojo externo'),
    (id: 'otro', label: 'Otro'),
  ],
  'salud_fonoaudiologica': [
    (id: 'audiometria_no_pasa', label: "'No pasa' Audiometría/barrido tonal"),
    (id: 'alteracion_lenguaje', label: 'Alteraciones en el lenguaje, habla y/o comunicación'),
    (id: 'otro', label: 'Otro'),
  ],
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

  static const _titulosPasos = [
    'Examen clínico',
    'Antropometría',
    'Presión arterial',
    'Agudeza y audiometría',
    'Hallazgos',
    'Vacunación',
    'Derivaciones',
    'Revisión',
  ];

  Future<void> _salir(BuildContext context, bool hayCambios) async {
    if (!hayCambios) {
      _pop(context);
      return;
    }
    final salir = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Salir sin guardar'),
        content: const Text(
            'Tenés cambios sin guardar. Si salís ahora se pierden.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogCtx, false),
              child: const Text('Seguir editando')),
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, true),
            child:  Text('Salir sin guardar',
                style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (salir == true && context.mounted) _pop(context);
  }

  void _pop(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/operativos');
    }
  }

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
                icon:  Icon(Icons.arrow_back, color: AppColors.blanco),
                onPressed: () => _salir(
                    context, ctrl.tieneCambiosSinGuardar && esEnCurso),
              ),
              Expanded(
                child: Text(esNoEditable ? 'Evaluación médica — solo lectura' : esBloqueadoPrevio ? 'Evaluación médica — no disponible' : 'Evaluación médica',
                    style: AppTypography.titulo
                        .copyWith(color: AppColors.blanco, fontSize: 22)),
              ),
            ]),
          ),
          Expanded(
            child: state.cargando
                ?  Center(
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
                                color: AppColors.okFondo,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: AppColors.ok),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                   Icon(Icons.lock_outline, size: 14, color: AppColors.ok),
                                  const SizedBox(width: 6),
                                  Flexible(child: Text('Operativo finalizado — solo lectura', style: AppTypography.texto.copyWith(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.ok))),
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
                                color: AppColors.avisoFondo,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: AppColors.aviso),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                   Icon(Icons.info_outline, size: 14, color: AppColors.aviso),
                                  const SizedBox(width: 6),
                                  Flexible(child: Text('Solo se puede cargar cuando el operativo está en curso', style: AppTypography.texto.copyWith(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.aviso))),
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
                                _cabeceraPasos(state, ctrl),
                                const SizedBox(height: AppSpacing.md),
                                _pasoActual(state, ctrl),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _botonesNavegacion(context, ref, state, ctrl,
                            editable: esEnCurso),
                        if (state.error != null) ...[
                          const SizedBox(height: AppSpacing.md),
                          AppCard(
                            child: Text(state.error!,
                                style: AppTypography.texto
                                    .copyWith(color: AppColors.error),
                                textAlign: TextAlign.center),
                          ),
                        ],
                        const SizedBox(height: AppSpacing.lg),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  /// Cabecera del wizard: "Paso X de 8 · título" + progreso + salto directo.
  Widget _cabeceraPasos(EvaluacionMedicaState state,
      EvaluacionMedicaController ctrl) {
    final paso = state.paso.clamp(0, 7);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Paso ${paso + 1} de 8 · ${_titulosPasos[paso]}',
              style: AppTypography.subtitulo),
          const SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (paso + 1) / 8,
              minHeight: 6,
              backgroundColor: AppColors.campo,
              valueColor:
                   AlwaysStoppedAnimation<Color>(AppColors.primario),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (var i = 0; i < 8; i++)
                InkWell(
                  onTap: () => ctrl.setPaso(i),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 26,
                    height: 26,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: i == paso
                          ? AppColors.primario
                          : AppColors.primario.withValues(alpha: 0.15),
                    ),
                    child: Text(
                      '${i + 1}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: i == paso
                            ? AppColors.blanco
                            : AppColors.primario,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  /// Muestra solo la tarjeta del paso actual (7 = revisión).
  Widget _pasoActual(EvaluacionMedicaState state,
      EvaluacionMedicaController ctrl) {
    switch (state.paso) {
      case 0:
        return _cardExamenClinico(state, ctrl);
      case 1:
        return _cardAntropometria(state, ctrl);
      case 2:
        return _cardPresion(state, ctrl);
      case 3:
        return _cardAgudezaAudiometria(state, ctrl);
      case 4:
        return _cardHallazgos(state, ctrl);
      case 5:
        return _cardVacunacion(state, ctrl);
      case 6:
        return _cardDerivaciones(state, ctrl);
      default:
        return _cardRevision(state, ctrl);
    }
  }

  /// Resumen por sección con estado + Guardar final.
  Widget _cardRevision(EvaluacionMedicaState state,
      EvaluacionMedicaController ctrl) {
    const secciones = [
      'Examen clínico',
      'Antropometría',
      'Presión arterial',
      'Agudeza y audiometría',
      'Hallazgos',
      'Vacunación',
      'Derivaciones',
    ];
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Revisión', style: AppTypography.subtitulo),
          const SizedBox(height: AppSpacing.sm),
          for (var i = 0; i < secciones.length; i++)
            Builder(builder: (context) {
              final ok = ctrl.validarPaso(i) == null;
              return InkWell(
                onTap: () => ctrl.setPaso(i),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Icon(
                        ok ? Icons.check_circle_outline : Icons.error_outline,
                        size: 20,
                        color: ok ? Colors.green : Colors.orange,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(secciones[i], style: AppTypography.texto),
                      ),
                       Icon(Icons.chevron_right,
                          size: 18, color: AppColors.gris),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  /// Atrás / Siguiente con autoguardado (o Guardar final en revisión).
  /// Siguiente valida la sección y persiste el avance antes de avanzar.
  /// En solo lectura solo navega (sin validar ni guardar).
  Widget _botonesNavegacion(BuildContext context, WidgetRef ref,
      EvaluacionMedicaState state, EvaluacionMedicaController ctrl,
      {required bool editable}) {
    final paso = state.paso.clamp(0, 7);
    final esRevision = paso == 7;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              if (paso > 0)
                Expanded(
                  child: OutlinedButton(
                    onPressed: state.guardando
                        ? null
                        : () => ctrl.setPaso(paso - 1),
                    child: const Text('Atrás'),
                  ),
                ),
              if (paso > 0) const SizedBox(width: AppSpacing.sm),
              // En revisión solo se guarda si es editable; si no, solo Atrás.
              if (!esRevision || editable)
                Expanded(
                  child: AppButton(
                    label: esRevision ? 'Guardar' : 'Siguiente',
                  isLoading: state.guardando,
                  onPressed: state.guardando
                      ? null
                      : () async {
                          if (esRevision) {
                            await _guardarFinal(context, ref, ctrl);
                            return;
                          }
                          if (editable) {
                            await ctrl.intentarAvanzar();
                          } else {
                            ctrl.setPaso(paso + 1);
                          }
                        },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _guardarFinal(BuildContext context, WidgetRef ref,
      EvaluacionMedicaController ctrl) async {
    final ok = await ctrl.guardar();
    if (ok && context.mounted) {
      ref.invalidate(alumnosProvider(operativoId));
      ref.invalidate(completitudProvider(operativoId));
      ref.invalidate(operativoDetailProvider(operativoId));
      context.pop();
    }
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
              label: 'Motivo de no examen *',
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
          if (state.examenRealizado) ...[
            const SizedBox(height: AppSpacing.md),
            AppDropdownField(
              label: 'Lugar del examen *',
              value: state.lugarExamen.isEmpty ? null : state.lugarExamen,
              items: const [
                (value: 'escuela', label: 'Escuela'),
                (value: 'centro_salud', label: 'Centro de salud'),
              ],
              onChanged: ctrl.setLugarExamen,
            ),
          ],
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
          _CheckRow(
            label: 'Sección evaluada',
            value: state.antropometriaEvaluada,
            onChanged: ctrl.setAntropometriaEvaluada,
          ),
          if (!state.antropometriaEvaluada) ...[
            const SizedBox(height: AppSpacing.sm),
            Text('Sección no evaluada.',
                style: AppTypography.texto.copyWith(fontSize: 12, color: AppColors.texto.withValues(alpha: 0.6), fontStyle: FontStyle.italic)),
          ],
          if (state.antropometriaEvaluada) ...[
          const SizedBox(height: AppSpacing.sm),
          AppTextField(
            label: 'Peso (kg) *',
            controller: TextEditingController(text: state.peso)
              ..selection =
                  TextSelection.collapsed(offset: state.peso.length),
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            onChanged: ctrl.setPeso,
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            label: 'Talla (cm) *',
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
            label: 'Percentil talla *',
            value: state.percentilTalla.isEmpty ? null : state.percentilTalla,
            items: const [
              (value: 'menor_3', label: 'Menor a 3'),
              (value: 'mayor_igual_3', label: 'Mayor o igual a 3'),
            ],
            onChanged: ctrl.setPercentilTalla,
          ),
          const SizedBox(height: AppSpacing.md),
          AppDropdownField(
            label: 'Percentil IMC *',
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
        ],
      ),
    );
  }

  /// Checks automáticos de PAS/PAD según los umbrales del equipo de salud.
  /// Se marcan solos al escribir el número (uno por par: PC y mmHg).
  List<Widget> _checksAutomaticos(String valor, int umbralMmHg) {
    final v = int.tryParse(valor.trim());
    final pcMenor = v != null && v < 90;
    final pcMayor = v != null && v >= 90;
    final mmMenor = v != null && v < umbralMmHg;
    final mmMayor = v != null && v >= umbralMmHg;
    return [
      _CheckFijo(label: 'PC Menor a 90', value: pcMenor),
      _CheckFijo(label: 'PC Mayor a 90', value: pcMayor),
      _CheckFijo(label: 'Menor a $umbralMmHg mmHg', value: mmMenor),
      _CheckFijo(label: 'Mayor o igual a $umbralMmHg mmHg', value: mmMayor),
    ];
  }

  Widget _cardPresion(
      EvaluacionMedicaState state, EvaluacionMedicaController ctrl) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Presión arterial', style: AppTypography.subtitulo),
          const SizedBox(height: AppSpacing.sm),
          _CheckRow(
            label: 'Sección evaluada',
            value: state.presionEvaluada,
            onChanged: ctrl.setPresionEvaluada,
          ),
          if (!state.presionEvaluada) ...[
            const SizedBox(height: AppSpacing.sm),
            Text('Sección no evaluada.',
                style: AppTypography.texto.copyWith(fontSize: 12, color: AppColors.texto.withValues(alpha: 0.6), fontStyle: FontStyle.italic)),
          ],
          if (state.presionEvaluada) ...[
          const SizedBox(height: AppSpacing.sm),
          AppTextField(
            label: 'PAS (sistólica) *',
            controller: TextEditingController(text: state.pas)
              ..selection = TextSelection.collapsed(offset: state.pas.length),
            keyboardType: TextInputType.number,
            onChanged: ctrl.setPas,
          ),
          const SizedBox(height: AppSpacing.sm),
          ..._checksAutomaticos(state.pas, 130),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            label: 'PAD (diastólica) *',
            controller: TextEditingController(text: state.pad)
              ..selection = TextSelection.collapsed(offset: state.pad.length),
            keyboardType: TextInputType.number,
            onChanged: ctrl.setPad,
          ),
          const SizedBox(height: AppSpacing.sm),
          ..._checksAutomaticos(state.pad, 80),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            label: 'Clasificación',
            controller: TextEditingController(text: state.presionClasificacion)
              ..selection = TextSelection.collapsed(
                  offset: state.presionClasificacion.length),
            onChanged: ctrl.setPresionClasificacion,
          ),
          ],
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
          if (state.agudezaEvaluada) ...[
            const SizedBox(height: AppSpacing.sm),
            AppDropdownField(
              label: 'Ojo derecho *',
              value: state.ojoDerecho.isEmpty ? null : state.ojoDerecho,
              items: [
                for (var i = 1; i <= 10; i++)
                  (value: '$i/10', label: '$i/10'),
              ],
              onChanged: ctrl.setOjoDerecho,
            ),
            const SizedBox(height: AppSpacing.md),
            AppDropdownField(
              label: 'Ojo izquierdo *',
              value: state.ojoIzquierdo.isEmpty ? null : state.ojoIzquierdo,
              items: [
                for (var i = 1; i <= 10; i++)
                  (value: '$i/10', label: '$i/10'),
              ],
              onChanged: ctrl.setOjoIzquierdo,
            ),
          ],
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
          if (state.audiometriaRealizada) ...[
            const SizedBox(height: AppSpacing.sm),
            AppDropdownField(
              label: 'Resultado audiometría *',
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
            if ((state.hallazgos[sistema]?.estado ?? '') == 'con' &&
                (_hallazgoChecks[sistema] ?? const []).isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              for (final check in _hallazgoChecks[sistema]!) ...[
                _CheckRow(
                  label: check.label,
                  value: (state.hallazgos[sistema]?.checks ?? const <String>[])
                      .contains(check.id),
                  onChanged: (v) =>
                      ctrl.setHallazgoCheck(sistema, check.id, v),
                ),
              ],
            ],
            if ((state.hallazgos[sistema]?.estado ?? '') == 'con' &&
                (state.hallazgos[sistema]?.checks ?? const <String>[])
                    .contains('otro')) ...[
              const SizedBox(height: AppSpacing.sm),
              AppTextField(
                label: '¿Cuál? *',
                controller: TextEditingController(
                    text: state.hallazgos[sistema]?.detalle ?? '')
                  ..selection = TextSelection.collapsed(
                      offset: (state.hallazgos[sistema]?.detalle ?? '').length),
                onChanged: (v) => ctrl.setHallazgoDetalle(sistema, v),
              ),
            ],
          ],
        ],
      ),
    );
  }

  /// Selector Sí/No con valor vacío inicial (obliga a marcar una opción).
  Widget _siNoSelector({
    required String label,
    required String value,
    required ValueChanged<String> onChanged,
  }) {
    return AppDropdownField(
      label: label,
      value: value.isEmpty ? null : value,
      items: const [
        (value: 'si', label: 'Sí'),
        (value: 'no', label: 'No'),
      ],
      onChanged: onChanged,
    );
  }

  Widget _cardVacunacion(
      EvaluacionMedicaState state, EvaluacionMedicaController ctrl) {
    final mostrarCarnet = state.trajoCarnet;
    final mostrarAplicadas =
        state.trajoCarnet && !state.carnetCompleto;
    final mostrarDetalleAplicadas =
        mostrarAplicadas && state.vacunasAplicadasMarcado == 'si';
    final mostrarIndicadas =
        mostrarAplicadas && state.vacunasAplicadasMarcado == 'no';
    final mostrarDetalleIndicadas =
        mostrarIndicadas && state.vacunasIndicadasMarcado == 'si';
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
          if (!mostrarCarnet) ...[
            const SizedBox(height: AppSpacing.sm),
            Text('Sin carnet: no se cargan más datos de vacunación.',
                style: AppTypography.texto.copyWith(fontSize: 12, color: AppColors.texto.withValues(alpha: 0.6), fontStyle: FontStyle.italic)),
          ],
          if (mostrarCarnet) ...[
            _CheckRow(
              label: 'Carnet completo',
              value: state.carnetCompleto,
              onChanged: ctrl.setCarnetCompleto,
            ),
          ],
          if (mostrarAplicadas) ...[
            const SizedBox(height: AppSpacing.sm),
            _siNoSelector(
              label: '¿Se aplicaron vacunas? *',
              value: state.vacunasAplicadasMarcado,
              onChanged: ctrl.setVacunasAplicadasMarcado,
            ),
          ],
          if (mostrarDetalleAplicadas) ...[
            const SizedBox(height: AppSpacing.sm),
            AppTextField(
              label: '¿Cuáles? *',
              controller: TextEditingController(text: state.vacunasAplicadas)
                ..selection = TextSelection.collapsed(
                    offset: state.vacunasAplicadas.length),
              onChanged: ctrl.setVacunasAplicadas,
            ),
          ],
          if (mostrarIndicadas) ...[
            const SizedBox(height: AppSpacing.sm),
            _siNoSelector(
              label: '¿Se indicaron vacunas faltantes? *',
              value: state.vacunasIndicadasMarcado,
              onChanged: ctrl.setVacunasIndicadasMarcado,
            ),
          ],
          if (mostrarDetalleIndicadas) ...[
            const SizedBox(height: AppSpacing.sm),
            AppTextField(
              label: '¿Cuáles? *',
              controller: TextEditingController(text: state.vacunasIndicadas)
                ..selection = TextSelection.collapsed(
                    offset: state.vacunasIndicadas.length),
              onChanged: ctrl.setVacunasIndicadas,
            ),
          ],
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

/// Check de solo lectura para los valores automáticos (PAS/PAD).
class _CheckFijo extends StatelessWidget {
  const _CheckFijo({required this.label, required this.value});

  final String label;
  final bool value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Checkbox(value: value, onChanged: null),
        Expanded(
          child: Text(label, style: AppTypography.texto),
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
