import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers.dart';
import '../../../../core/notificaciones/notificacion_controller.dart';
import '../../data/operativos_repository.dart';

/// Argumentos de identificación de la evaluación: operativo + alumno.
typedef EvaluacionMedicaArgs = ({String opId, String alumnoId});

/// Sistemas de hallazgos clínicos (claves del contrato de API).
/// `genitourinario` y `fonoaudiologica` son claves históricas: se siguen
/// leyendo en la ficha, pero el formulario usa las nuevas.
const List<String> kHallazgoSistemas = [
  'piel',
  'partes_blandas',
  'cardiovascular',
  'respiratorio',
  'abdominal',
  'genitourinario_ninos',
  'genitourinario_ninas',
  'osteoarticular',
  'neurologico',
  'salud_visual',
  'salud_fonoaudiologica',
  'icv',
];

/// Sistemas sin checks (solo estado): ICV.
const Set<String> kHallazgoSinChecks = {'icv'};

/// Etiquetas de sistemas para mensajes de validación.
const Map<String, String> kHallazgoSistemaLabels = {
  'piel': 'piel y faneras',
  'partes_blandas': 'partes blandas',
  'cardiovascular': 'cardiovascular',
  'respiratorio': 'respiratorio',
  'abdominal': 'abdominal',
  'genitourinario_ninos': 'genitourinario (niños)',
  'genitourinario_ninas': 'genitourinario (niñas)',
  'osteoarticular': 'osteoarticular',
  'neurologico': 'neurológico',
  'salud_visual': 'salud visual',
  'salud_fonoaudiologica': 'salud fonoaudiológica',
  'icv': 'ICV',
};

/// Especialidades sugeridas para derivaciones (claves del contrato de API).
const List<String> kDerivacionEspecialidades = [
  'odontologia',
  'oftalmologia',
  'nutricion',
  'neurologia',
  'cardiologia',
  'fonoaudiologia',
  'psicologia',
  'otros',
];

const _sentinel = Object();

class EvaluacionMedicaState {
  const EvaluacionMedicaState({
    this.cargando = true,
    this.guardando = false,
    this.error,
    this.paso = 0,
    this.examenRealizado = true,
    this.motivoNoExamen = '',
    this.lugarExamen = '',
    this.trajoCarnet = false,
    this.carnetCompleto = false,
    this.vacunasAplicadas = '',
    this.vacunasIndicadas = '',
    this.peso = '',
    this.talla = '',
    this.imc = '',
    this.percentilTalla = '',
    this.percentilImc = '',
    this.antropometriaEvaluada = true,
    this.presionEvaluada = true,
    this.vacunasAplicadasMarcado = '',
    this.vacunasIndicadasMarcado = '',
    this.pas = '',
    this.pad = '',
    this.presionClasificacion = '',
    this.agudezaEvaluada = false,
    this.ojoDerecho = '',
    this.ojoIzquierdo = '',
    this.usaLentes = false,
    this.audiometriaRealizada = false,
    this.audiometriaResultado = '',
    this.hallazgos = const {},
    this.derivaciones = const {},
  });

  final bool cargando;
  final bool guardando;
  final String? error;

  /// Paso actual del wizard (0-6 secciones, 7 = revisión).
  final int paso;

  final bool examenRealizado;
  final String motivoNoExamen;
  final String lugarExamen;

  final bool trajoCarnet;
  final bool carnetCompleto;
  final String vacunasAplicadas;
  final String vacunasIndicadas;

  final String peso;
  final String talla;
  final String imc;
  final String percentilTalla;
  final String percentilImc;

  /// Toggles de sección evaluada (persistidos) y de cadena de vacunación
  /// (transitorios: se derivan del texto guardado al cargar).
  final bool antropometriaEvaluada;
  final bool presionEvaluada;
  final String vacunasAplicadasMarcado; // '', 'si', 'no'
  final String vacunasIndicadasMarcado; // '', 'si', 'no'

  final String pas;
  final String pad;
  final String presionClasificacion;

  final bool agudezaEvaluada;
  final String ojoDerecho;
  final String ojoIzquierdo;
  final bool usaLentes;
  final bool audiometriaRealizada;
  final String audiometriaResultado;

  /// sistema -> {estado, detalle, checks}
  /// checks: ids de los checks marcados cuando estado == 'con';
  /// detalle lleva el texto de "otro".
  final Map<String, ({String estado, String detalle, List<String> checks})> hallazgos;

  /// especialidad -> {deriva, motivo}
  final Map<String, ({bool deriva, String motivo})> derivaciones;

  EvaluacionMedicaState copyWith({
    bool? cargando,
    bool? guardando,
    Object? error = _sentinel,
    int? paso,
    bool? examenRealizado,
    String? motivoNoExamen,
    String? lugarExamen,
    bool? trajoCarnet,
    bool? carnetCompleto,
    String? vacunasAplicadas,
    String? vacunasIndicadas,
    String? peso,
    String? talla,
    String? imc,
    String? percentilTalla,
    String? percentilImc,
    bool? antropometriaEvaluada,
    bool? presionEvaluada,
    String? vacunasAplicadasMarcado,
    String? vacunasIndicadasMarcado,
    String? pas,
    String? pad,
    String? presionClasificacion,
    bool? agudezaEvaluada,
    String? ojoDerecho,
    String? ojoIzquierdo,
    bool? usaLentes,
    bool? audiometriaRealizada,
    String? audiometriaResultado,
    Map<String, ({String estado, String detalle, List<String> checks})>? hallazgos,
    Map<String, ({bool deriva, String motivo})>? derivaciones,
  }) {
    return EvaluacionMedicaState(
      cargando: cargando ?? this.cargando,
      guardando: guardando ?? this.guardando,
      error: identical(error, _sentinel) ? this.error : error as String?,
      paso: paso ?? this.paso,
      examenRealizado: examenRealizado ?? this.examenRealizado,
      motivoNoExamen: motivoNoExamen ?? this.motivoNoExamen,
      lugarExamen: lugarExamen ?? this.lugarExamen,
      trajoCarnet: trajoCarnet ?? this.trajoCarnet,
      carnetCompleto: carnetCompleto ?? this.carnetCompleto,
      vacunasAplicadas: vacunasAplicadas ?? this.vacunasAplicadas,
      vacunasIndicadas: vacunasIndicadas ?? this.vacunasIndicadas,
      peso: peso ?? this.peso,
      talla: talla ?? this.talla,
      imc: imc ?? this.imc,
      percentilTalla: percentilTalla ?? this.percentilTalla,
      percentilImc: percentilImc ?? this.percentilImc,
      antropometriaEvaluada: antropometriaEvaluada ?? this.antropometriaEvaluada,
      presionEvaluada: presionEvaluada ?? this.presionEvaluada,
      vacunasAplicadasMarcado: vacunasAplicadasMarcado ?? this.vacunasAplicadasMarcado,
      vacunasIndicadasMarcado: vacunasIndicadasMarcado ?? this.vacunasIndicadasMarcado,
      pas: pas ?? this.pas,
      pad: pad ?? this.pad,
      presionClasificacion: presionClasificacion ?? this.presionClasificacion,
      agudezaEvaluada: agudezaEvaluada ?? this.agudezaEvaluada,
      ojoDerecho: ojoDerecho ?? this.ojoDerecho,
      ojoIzquierdo: ojoIzquierdo ?? this.ojoIzquierdo,
      usaLentes: usaLentes ?? this.usaLentes,
      audiometriaRealizada: audiometriaRealizada ?? this.audiometriaRealizada,
      audiometriaResultado: audiometriaResultado ?? this.audiometriaResultado,
      hallazgos: hallazgos ?? this.hallazgos,
      derivaciones: derivaciones ?? this.derivaciones,
    );
  }
}

class EvaluacionMedicaController extends StateNotifier<EvaluacionMedicaState> {
  EvaluacionMedicaController({
    required this.repo,
    required this.args,
    required this.notificacionController,
  }) : super(const EvaluacionMedicaState()) {
    _cargar();
  }

  final OperativosRepository repo;
  final EvaluacionMedicaArgs args;
  final NotificacionController notificacionController;

  Future<void> _cargar() async {
    try {
      final data = await repo.getEvaluacionMedica(args.opId, args.alumnoId);
      if (!mounted) return;
      final aplicadasTxt = _asStr(data['vacunas_aplicadas']);
      final indicadasTxt = _asStr(data['vacunas_indicadas']);
      state = state.copyWith(
        cargando: false,
        examenRealizado: _asBool(data['examen_realizado'], fallback: true),
        motivoNoExamen: _asStr(data['motivo_no_examen']),
        lugarExamen: _asStr(data['lugar_examen']),
        trajoCarnet: _asBool(data['trajo_carnet']),
        carnetCompleto: _asBool(data['carnet_completo']),
        vacunasAplicadas: aplicadasTxt,
        vacunasIndicadas: indicadasTxt,
        vacunasAplicadasMarcado: aplicadasTxt.isEmpty ? '' : 'si',
        vacunasIndicadasMarcado: indicadasTxt.isEmpty ? '' : 'si',
        antropometriaEvaluada: _asBool(data['antropometria_evaluada'], fallback: true),
        presionEvaluada: _asBool(data['presion_evaluada'], fallback: true),
        peso: _asStr(data['peso']),
        talla: _asStr(data['talla']),
        imc: _asStr(data['imc']),
        percentilTalla: _asStr(data['percentil_talla']),
        percentilImc: _asStr(data['percentil_imc']),
        pas: _asStr(data['pas']),
        pad: _asStr(data['pad']),
        presionClasificacion: _asStr(data['presion_clasificacion']),
        agudezaEvaluada: _asBool(data['agudeza_evaluada']),
        ojoDerecho: _asStr(data['ojo_derecho']),
        ojoIzquierdo: _asStr(data['ojo_izquierdo']),
        usaLentes: _asBool(data['usa_lentes']),
        audiometriaRealizada: _asBool(data['audiometria_realizada']),
        audiometriaResultado: _asStr(data['audiometria_resultado']),
        hallazgos: _parseHallazgos(data['hallazgos']),
        derivaciones: _parseDerivaciones(data['derivaciones']),
      );
    } catch (_) {
      if (!mounted) return;
      // Si la evaluación aún no existe / falla la carga, partimos de un estado
      // vacío editable en lugar de bloquear la pantalla.
      state = state.copyWith(
        cargando: false,
        hallazgos: _parseHallazgos(null),
        derivaciones: _parseDerivaciones(null),
      );
    }
    if (mounted) _firmaGuardada = _firma();
  }

  // --- Setters de campos simples ---
  // Al alternar cada condición se limpian los dependientes para no guardar
  // datos contradictorios (ej. examen no realizado + lugar, o presión no
  // evaluada + PAS/PAD).
  void setExamenRealizado(bool v) => state = state.copyWith(
        examenRealizado: v,
        motivoNoExamen: v ? '' : state.motivoNoExamen,
        lugarExamen: v ? state.lugarExamen : '',
        error: null,
      );
  void setMotivoNoExamen(String v) =>
      state = state.copyWith(motivoNoExamen: v, error: null);
  void setLugarExamen(String v) =>
      state = state.copyWith(lugarExamen: v, error: null);

  void setTrajoCarnet(bool v) => state = state.copyWith(
        trajoCarnet: v,
        carnetCompleto: v ? state.carnetCompleto : false,
        vacunasAplicadasMarcado: v ? state.vacunasAplicadasMarcado : '',
        vacunasIndicadasMarcado: v ? state.vacunasIndicadasMarcado : '',
        vacunasAplicadas: v ? state.vacunasAplicadas : '',
        vacunasIndicadas: v ? state.vacunasIndicadas : '',
        error: null,
      );
  void setCarnetCompleto(bool v) => state = state.copyWith(
        carnetCompleto: v,
        vacunasAplicadasMarcado: v ? '' : state.vacunasAplicadasMarcado,
        vacunasIndicadasMarcado: v ? '' : state.vacunasIndicadasMarcado,
        vacunasAplicadas: v ? '' : state.vacunasAplicadas,
        vacunasIndicadas: v ? '' : state.vacunasIndicadas,
        error: null,
      );
  void setVacunasAplicadas(String v) =>
      state = state.copyWith(vacunasAplicadas: v, error: null);
  void setVacunasIndicadas(String v) =>
      state = state.copyWith(vacunasIndicadas: v, error: null);

  void setPeso(String v) => _actualizarAntropometria(peso: v);
  void setTalla(String v) => _actualizarAntropometria(talla: v);

  void _actualizarAntropometria({String? peso, String? talla}) {
    final nuevoPeso = peso ?? state.peso;
    final nuevaTalla = talla ?? state.talla;
    final pesoKg = double.tryParse(nuevoPeso.replaceAll(',', '.'));
    final tallaCm = double.tryParse(nuevaTalla.replaceAll(',', '.'));
    final imc = pesoKg != null && tallaCm != null && pesoKg > 0 && tallaCm > 0
        ? (pesoKg / ((tallaCm / 100) * (tallaCm / 100))).toStringAsFixed(2)
        : '';
    state = state.copyWith(peso: nuevoPeso, talla: nuevaTalla, imc: imc, error: null);
  }
  void setPercentilTalla(String v) =>
      state = state.copyWith(percentilTalla: v, error: null);
  void setPercentilImc(String v) =>
      state = state.copyWith(percentilImc: v, error: null);
  void setAntropometriaEvaluada(bool v) => state = state.copyWith(
        antropometriaEvaluada: v,
        peso: v ? state.peso : '',
        talla: v ? state.talla : '',
        imc: v ? state.imc : '',
        percentilTalla: v ? state.percentilTalla : '',
        percentilImc: v ? state.percentilImc : '',
        error: null,
      );
  void setPresionEvaluada(bool v) => state = state.copyWith(
        presionEvaluada: v,
        pas: v ? state.pas : '',
        pad: v ? state.pad : '',
        presionClasificacion: v ? state.presionClasificacion : '',
        error: null,
      );

  /// Cadena de vacunación: al marcar 'no' se limpia el detalle de texto
  /// para mantener consistencia con lo guardado.
  void setVacunasAplicadasMarcado(String v) {
    var aplicadas = state.vacunasAplicadas;
    var indicadasMarcado = state.vacunasIndicadasMarcado;
    var indicadas = state.vacunasIndicadas;
    if (v == 'no') {
      aplicadas = '';
      indicadasMarcado = '';
      indicadas = '';
    }
    state = state.copyWith(
      vacunasAplicadasMarcado: v,
      vacunasAplicadas: aplicadas,
      vacunasIndicadasMarcado: indicadasMarcado,
      vacunasIndicadas: indicadas,
      error: null,
    );
  }

  void setVacunasIndicadasMarcado(String v) {
    var indicadas = state.vacunasIndicadas;
    if (v == 'no') indicadas = '';
    state = state.copyWith(
      vacunasIndicadasMarcado: v,
      vacunasIndicadas: indicadas,
      error: null,
    );
  }

  void setPas(String v) => state = state.copyWith(pas: v, error: null);
  void setPad(String v) => state = state.copyWith(pad: v, error: null);
  void setPresionClasificacion(String v) =>
      state = state.copyWith(presionClasificacion: v, error: null);

  void setAgudezaEvaluada(bool v) => state = state.copyWith(
        agudezaEvaluada: v,
        ojoDerecho: v ? state.ojoDerecho : '',
        ojoIzquierdo: v ? state.ojoIzquierdo : '',
        usaLentes: v ? state.usaLentes : false,
        error: null,
      );
  void setOjoDerecho(String v) =>
      state = state.copyWith(ojoDerecho: v, error: null);
  void setOjoIzquierdo(String v) =>
      state = state.copyWith(ojoIzquierdo: v, error: null);
  void setUsaLentes(bool v) =>
      state = state.copyWith(usaLentes: v, error: null);
  void setAudiometriaRealizada(bool v) => state = state.copyWith(
        audiometriaRealizada: v,
        audiometriaResultado: v ? state.audiometriaResultado : '',
        error: null,
      );
  void setAudiometriaResultado(String v) =>
      state = state.copyWith(audiometriaResultado: v, error: null);

  // --- Setters de hallazgos ---
  void setHallazgoEstado(String sistema, String estado) {
    final actual = state.hallazgos[sistema] ??
        (estado: 'no_eval', detalle: '', checks: const <String>[]);
    // Al salir de 'con' se limpian checks y detalle de "otro".
    final checks = estado == 'con' ? actual.checks : const <String>[];
    final detalle = estado == 'con' ? actual.detalle : '';
    final nuevo = Map<String, ({String estado, String detalle, List<String> checks})>.from(
        state.hallazgos);
    nuevo[sistema] = (estado: estado, detalle: detalle, checks: checks);
    state = state.copyWith(hallazgos: nuevo, error: null);
  }

  void setHallazgoDetalle(String sistema, String detalle) {
    final actual = state.hallazgos[sistema] ??
        (estado: 'no_eval', detalle: '', checks: const <String>[]);
    final nuevo = Map<String, ({String estado, String detalle, List<String> checks})>.from(
        state.hallazgos);
    nuevo[sistema] = (estado: actual.estado, detalle: detalle, checks: actual.checks);
    state = state.copyWith(hallazgos: nuevo, error: null);
  }

  void setHallazgoCheck(String sistema, String checkId, bool seleccionado) {
    final actual = state.hallazgos[sistema] ??
        (estado: 'no_eval', detalle: '', checks: const <String>[]);
    final checks = List<String>.from(actual.checks);
    if (seleccionado) {
      if (!checks.contains(checkId)) checks.add(checkId);
    } else {
      checks.remove(checkId);
    }
    final detalle =
        checks.contains('otro') ? actual.detalle : '';
    final nuevo = Map<String, ({String estado, String detalle, List<String> checks})>.from(
        state.hallazgos);
    nuevo[sistema] = (estado: actual.estado, detalle: detalle, checks: checks);
    state = state.copyWith(hallazgos: nuevo, error: null);
  }

  // --- Setter de derivaciones ---
  // Al desmarcar se borra el motivo para no guardarlo huérfano.
  void setDerivacion(String esp, {bool? deriva, String? motivo}) {
    final actual = state.derivaciones[esp] ?? (deriva: false, motivo: '');
    final nuevoDeriva = deriva ?? actual.deriva;
    final nuevo =
        Map<String, ({bool deriva, String motivo})>.from(state.derivaciones);
    nuevo[esp] = (
      deriva: nuevoDeriva,
      motivo: nuevoDeriva ? (motivo ?? actual.motivo) : '',
    );
    state = state.copyWith(derivaciones: nuevo, error: null);
  }

  /// Pasos del wizard (7 secciones + revisión). Deben coincidir con la
  /// pantalla: 0 examen, 1 antropometría, 2 presión, 3 agudeza/audiometría,
  /// 4 hallazgos, 5 vacunación, 6 derivaciones, 7 revisión.
  static const int totalPasos = 8;

  void setPaso(int v) {
    if (v < 0 || v >= totalPasos) return;
    state = state.copyWith(paso: v, error: null);
  }

  /// Valida el paso actual y, si está completo, lo persiste antes de
  /// avanzar (autoguardado al Siguiente). Si falla la red se queda en el
  /// paso con el error para reintentar.
  Future<bool> intentarAvanzar() async {
    final msg = validarPaso(state.paso);
    if (msg != null) {
      state = state.copyWith(error: msg);
      notificacionController.error(msg);
      return false;
    }
    final ok = await guardarAvance();
    if (!ok || !mounted) return false;
    setPaso(state.paso + 1);
    return true;
  }

  /// Valida solo una sección (para el botón Siguiente bloqueante).
  /// Devuelve el mensaje de faltantes o null si está completa.
  String? validarPaso(int paso) {
    final faltantes = <String>[];
    switch (paso) {
      case 0:
        // 1. Examen clínico.
        if (state.examenRealizado) {
          if (state.lugarExamen.isEmpty) faltantes.add('lugar del examen');
        } else {
          if (state.motivoNoExamen.isEmpty) faltantes.add('motivo de no examen');
        }
      case 1:
        // 2. Antropometría (toda obligatoria si se evaluó).
        if (state.antropometriaEvaluada) {
          if (state.peso.trim().isEmpty) faltantes.add('peso');
          if (state.talla.trim().isEmpty) faltantes.add('talla');
          if (state.percentilTalla.isEmpty) faltantes.add('percentil de talla');
          if (state.percentilImc.isEmpty) faltantes.add('percentil de IMC');
        }
      case 2:
        // 3. Presión arterial.
        if (state.presionEvaluada) {
          if (state.pas.trim().isEmpty) faltantes.add('PAS');
          if (state.pad.trim().isEmpty) faltantes.add('PAD');
        }
      case 3:
        // 4. Agudeza / audiometría.
        if (state.agudezaEvaluada) {
          if (state.ojoDerecho.isEmpty) faltantes.add('ojo derecho');
          if (state.ojoIzquierdo.isEmpty) faltantes.add('ojo izquierdo');
        }
        if (state.audiometriaRealizada && state.audiometriaResultado.isEmpty) {
          faltantes.add('resultado de audiometría');
        }
      case 4:
        // 5. Hallazgos: con 'con' hay que marcar al menos un check (salvo ICV);
        // con 'otro' hay que detallar cuál.
        for (final e in state.hallazgos.entries) {
          if (e.value.estado != 'con') continue;
          if (kHallazgoSinChecks.contains(e.key)) continue;
          final etiqueta = kHallazgoSistemaLabels[e.key] ?? e.key;
          if (e.value.checks.isEmpty) {
            faltantes.add('al menos un hallazgo en $etiqueta');
          } else if (e.value.checks.contains('otro') &&
              e.value.detalle.trim().isEmpty) {
            faltantes.add('detalle de "otro" en $etiqueta');
          }
        }
      case 5:
        // 6. Vacunación (cadena condicional).
        if (state.trajoCarnet && !state.carnetCompleto) {
          if (state.vacunasAplicadasMarcado.isEmpty) {
            faltantes.add('si se aplicaron vacunas');
          } else if (state.vacunasAplicadasMarcado == 'si' &&
              state.vacunasAplicadas.trim().isEmpty) {
            faltantes.add('detalle de vacunas aplicadas');
          } else if (state.vacunasAplicadasMarcado == 'no' &&
              state.vacunasIndicadasMarcado.isEmpty) {
            faltantes.add('si se indicaron vacunas faltantes');
          } else if (state.vacunasAplicadasMarcado == 'no' &&
              state.vacunasIndicadasMarcado == 'si' &&
              state.vacunasIndicadas.trim().isEmpty) {
            faltantes.add('detalle de vacunas faltantes');
          }
        }
      case 6:
        // 7. Derivaciones: sin obligatorios (el motivo es opcional).
        break;
      default:
        break;
    }
    if (faltantes.isEmpty) return null;
    return 'Faltan campos obligatorios: ${faltantes.join(', ')}.';
  }

  /// Valida los obligatorios según lo dictado por el equipo de salud.
  /// Devuelve el mensaje de faltantes o null si está completo.
  String? validar() {
    final faltantes = <String>[];
    for (var paso = 0; paso < totalPasos - 1; paso++) {
      final msg = validarPaso(paso);
      if (msg == null) continue;
      // Extrae solo la lista ("Faltan campos obligatorios: a, b.").
      final detalle = msg
          .replaceFirst('Faltan campos obligatorios: ', '')
          .replaceAll(RegExp(r'\.$'), '');
      faltantes.addAll(detalle.split(', '));
    }
    if (faltantes.isEmpty) return null;
    return 'Faltan campos obligatorios: ${faltantes.join(', ')}.';
  }

  Future<bool> guardar() async {
    final faltantes = validar();
    if (faltantes != null) {
      state = state.copyWith(error: faltantes);
      notificacionController.error(faltantes);
      return false;
    }
    return _enviar(completar: true, exitoMsg: 'Evaluación guardada');
  }

  /// Guarda el avance sin validar todo (wizard): persiste lo cargado hasta
  /// ahora sin marcar la evaluación como completada. No notifica el éxito
  /// para no spamear en cada paso (los errores sí se notifican).
  Future<bool> guardarAvance() {
    return _enviar(completar: false, exitoMsg: '');
  }

  /// Firma de lo último persistido: si difiere hay cambios sin guardar
  /// (dirty guard al salir). Se actualiza al cargar y en cada guardado ok.
  String _firmaGuardada = '';

  bool get tieneCambiosSinGuardar => _firma() != _firmaGuardada;

  String _firma() {
    final h = state.hallazgos.entries
        .map((e) => '${e.key}=${e.value.estado}|${e.value.detalle}|${e.value.checks.join('+')}')
        .join(';');
    final d = state.derivaciones.entries
        .map((e) => '${e.key}=${e.value.deriva}|${e.value.motivo}')
        .join(';');
    return [
      state.examenRealizado, state.motivoNoExamen, state.lugarExamen,
      state.trajoCarnet, state.carnetCompleto,
      state.vacunasAplicadasMarcado, state.vacunasIndicadasMarcado,
      state.vacunasAplicadas, state.vacunasIndicadas,
      state.peso, state.talla, state.imc,
      state.percentilTalla, state.percentilImc,
      state.antropometriaEvaluada, state.presionEvaluada,
      state.pas, state.pad, state.presionClasificacion,
      state.agudezaEvaluada, state.ojoDerecho, state.ojoIzquierdo,
      state.usaLentes, state.audiometriaRealizada, state.audiometriaResultado,
      h, d,
    ].join('~');
  }

  Future<bool> _enviar({required bool completar, required String exitoMsg}) async {
    state = state.copyWith(guardando: true, error: null);
    try {
      final payload = <String, dynamic>{
        'examen_realizado': state.examenRealizado,
        'motivo_no_examen': state.motivoNoExamen,
        'lugar_examen': state.lugarExamen,
        'trajo_carnet': state.trajoCarnet,
        'carnet_completo': state.carnetCompleto,
        'vacunas_aplicadas': state.vacunasAplicadas,
        'vacunas_indicadas': state.vacunasIndicadas,
        'peso': _numOrNull(state.peso),
        'talla': _numOrNull(state.talla),
        'imc': _numOrNull(state.imc),
        'percentil_talla': state.percentilTalla,
        'percentil_imc': state.percentilImc,
        'antropometria_evaluada': state.antropometriaEvaluada,
        'presion_evaluada': state.presionEvaluada,
        'pas': _intOrNull(state.pas),
        'pad': _intOrNull(state.pad),
        'presion_clasificacion': state.presionClasificacion,
        'agudeza_evaluada': state.agudezaEvaluada,
        'ojo_derecho': state.ojoDerecho,
        'ojo_izquierdo': state.ojoIzquierdo,
        'usa_lentes': state.usaLentes,
        'audiometria_realizada': state.audiometriaRealizada,
        'audiometria_resultado': state.audiometriaResultado,
        'hallazgos': {
          for (final e in state.hallazgos.entries)
            e.key: {
              'estado': e.value.estado,
              'detalle': e.value.detalle,
              'checks': e.value.checks,
            },
        },
        'derivaciones': {
          for (final e in state.derivaciones.entries)
            e.key: {'deriva': e.value.deriva, 'motivo': e.value.motivo},
        },
        'completar': completar,
      };

      await repo.putEvaluacionMedica(args.opId, args.alumnoId, payload);
      if (!mounted) return true;
      state = state.copyWith(guardando: false);
      _firmaGuardada = _firma();
      if (exitoMsg.isNotEmpty) notificacionController.exito(exitoMsg);
      return true;
    } on DioException catch (e) {
      if (!mounted) return false;
      final msg = _extractErrorMessage(e.response?.data) ??
          'No se pudo guardar la evaluación.';
      state = state.copyWith(guardando: false, error: msg);
      notificacionController.error(msg);
      return false;
    } catch (_) {
      if (!mounted) return false;
      const msg = 'No se pudo guardar la evaluación.';
      state = state.copyWith(guardando: false, error: msg);
      notificacionController.error(msg);
      return false;
    }
  }

  // --- Helpers ---
  static bool _asBool(dynamic v, {bool fallback = false}) {
    if (v is bool) return v;
    return fallback;
  }

  static String _asStr(dynamic v) => v == null ? '' : v.toString();

  static Map<String, ({String estado, String detalle, List<String> checks})> _parseHallazgos(
      dynamic raw) {
    final map = raw is Map ? raw : const {};
    return {
      for (final s in kHallazgoSistemas)
        s: () {
          final item = map[s];
          if (item is Map) {
            final estado = (item['estado'] ?? 'no_eval').toString();
            // Sanea datos legacy contradictorios (estado != con + checks).
            if (estado != 'con') {
              return (estado: estado, detalle: '', checks: const <String>[]);
            }
            final rawChecks = item['checks'];
            return (
              estado: estado,
              detalle: (item['detalle'] ?? '').toString(),
              checks: rawChecks is List
                  ? rawChecks.map((e) => e.toString()).toList()
                  : const <String>[],
            );
          }
          return (estado: 'no_eval', detalle: '', checks: const <String>[]);
        }(),
    };
  }

  static Map<String, ({bool deriva, String motivo})> _parseDerivaciones(
      dynamic raw) {
    final map = raw is Map ? raw : const {};
    return {
      for (final esp in kDerivacionEspecialidades)
        esp: () {
          final item = map[esp];
          if (item is Map) {
            final deriva =
                item['deriva'] is bool ? item['deriva'] as bool : false;
            // Sanea motivo huérfano legacy.
            return (
              deriva: deriva,
              motivo: deriva ? (item['motivo'] ?? '').toString() : '',
            );
          }
          return (deriva: false, motivo: '');
        }(),
    };
  }

  static num? _numOrNull(String v) {
    if (v.trim().isEmpty) return null;
    return num.tryParse(v.replaceAll(',', '.'));
  }

  static int? _intOrNull(String v) {
    if (v.trim().isEmpty) return null;
    return int.tryParse(v.trim());
  }

  static String? _extractErrorMessage(dynamic data) {
    if (data is Map<String, dynamic>) {
      if (data.containsKey('detail')) return data['detail'].toString();
      if (data.containsKey('message')) return data['message'].toString();
      if (data.containsKey('error')) return data['error'].toString();
      for (final value in data.values) {
        if (value is List && value.isNotEmpty) return value.first.toString();
      }
    }
    return null;
  }
}

final evaluacionMedicaControllerProvider = StateNotifierProvider.autoDispose
    .family<EvaluacionMedicaController, EvaluacionMedicaState,
        EvaluacionMedicaArgs>((ref, args) {
  return EvaluacionMedicaController(
    repo: ref.watch(operativosRepositoryProvider),
    args: args,
    notificacionController: ref.watch(notificacionProvider.notifier),
  );
});
