import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers.dart';
import '../../../../core/notificaciones/notificacion_controller.dart';
import '../../data/operativos_repository.dart';

/// Argumentos de identificación de la evaluación: operativo + alumno.
typedef EvaluacionOdontologicaArgs = ({String opId, String alumnoId});

/// Piezas dentales permanentes, agrupadas por cuadrante (orden anatómico).
const List<String> kPiezasPermanentes = [
  // Superior derecho (18-11) e izquierdo (21-28)
  '18', '17', '16', '15', '14', '13', '12', '11',
  '21', '22', '23', '24', '25', '26', '27', '28',
  // Inferior derecho (48-41) e izquierdo (31-38)
  '48', '47', '46', '45', '44', '43', '42', '41',
  '31', '32', '33', '34', '35', '36', '37', '38',
];

/// Piezas dentales temporarias, agrupadas por cuadrante.
const List<String> kPiezasTemporarias = [
  '55', '54', '53', '52', '51',
  '61', '62', '63', '64', '65',
  '85', '84', '83', '82', '81',
  '71', '72', '73', '74', '75',
];

const List<({String value, String label})> kEstadosGeneralesPieza = [
  (value: '', label: 'Normal'),
  (value: 'ausente', label: 'Ausente'),
  (value: 'perdido', label: 'Perdido'),
  (value: 'extraido', label: 'Extraído'),
  (value: 'corona', label: 'Corona'),
  (value: 'protesis', label: 'Prótesis'),
  (value: 'implante', label: 'Implante'),
  (value: 'a_extraer', label: 'Para extraer'),
  (value: 'fractura_total', label: 'Fractura total'),
];

const List<({String value, String label})> kEstadosCara = [
  (value: '', label: 'Sana'),
  (value: 'caries', label: 'Caries'),
  (value: 'restauracion', label: 'Restauración'),
  (value: 'sellador', label: 'Sellador'),
  (value: 'fractura', label: 'Fractura'),
  (value: 'a_tratar', label: 'A tratar'),
  (value: 'tratada', label: 'Tratada'),
];

const List<({String value, String label})> kEstadosRaiz = [
  (value: '', label: 'Normal'),
  (value: 'conducto_realizado', label: 'Conducto realizado'),
  (value: 'conducto_pendiente', label: 'Conducto pendiente'),
];

const List<String> kCarasPieza = [
  'oclusal', 'mesial', 'distal', 'vestibular', 'lingual',
];

class PiezaOdontograma {
  const PiezaOdontograma({
    this.estadoGeneral = '',
    this.caras = const {},
    this.raiz = '',
    this.notas = '',
  });

  final String estadoGeneral;
  final Map<String, String> caras;
  final String raiz;
  final String notas;

  PiezaOdontograma copyWith({
    String? estadoGeneral,
    Map<String, String>? caras,
    String? raiz,
    String? notas,
  }) => PiezaOdontograma(
        estadoGeneral: estadoGeneral ?? this.estadoGeneral,
        caras: caras ?? this.caras,
        raiz: raiz ?? this.raiz,
        notas: notas ?? this.notas,
      );

  Map<String, dynamic> toJson() => {
        'estado_general': estadoGeneral.isEmpty ? null : estadoGeneral,
        'caras': {
          for (final entry in caras.entries)
            if (entry.value.isNotEmpty) entry.key: entry.value,
        },
        'raiz': raiz.isEmpty ? null : raiz,
        'notas': notas,
      };

  factory PiezaOdontograma.fromJson(dynamic raw) {
    if (raw is! Map) return const PiezaOdontograma();
    final rawCaras = raw['caras'];
    return PiezaOdontograma(
      estadoGeneral: raw['estado_general']?.toString() ?? '',
      caras: rawCaras is Map
          ? {
              for (final entry in rawCaras.entries)
                entry.key.toString(): entry.value?.toString() ?? '',
            }
          : const {},
      raiz: raw['raiz']?.toString() ?? '',
      notas: raw['notas']?.toString() ?? '',
    );
  }
}

const _sentinel = Object();

class EvaluacionOdontologicaState {
  const EvaluacionOdontologicaState({
    this.cargando = true,
    this.guardando = false,
    this.error,
    this.paso = 0,
    this.saludBucal = 'no_eval',
    this.lesionesTejidosBlandos = false,
    this.maloclusion = false,
    this.fluorosis = false,
    this.caries = false,
    this.otrosMarcado = false,
    this.otros = '',
    this.topicacionFluor = false,
    this.ensenanzaCepillado = false,
    this.altaBasica = false,
    this.cpoC = false,
    this.cpoP = false,
    this.cpoO = false,
    this.ceoC = false,
    this.ceoE = false,
    this.ceoO = false,
    this.odontograma = const {},
  });

  final bool cargando;
  final bool guardando;
  final String? error;

  /// Paso actual del wizard (0-2 secciones, 3 = revisión).
  final int paso;

  final String saludBucal;
  final bool lesionesTejidosBlandos;
  final bool maloclusion;
  final bool fluorosis;
  final bool caries;
  /// El campo de texto "Otros" solo se muestra si este check está marcado.
  final bool otrosMarcado;
  final String otros;

  final bool topicacionFluor;
  final bool ensenanzaCepillado;
  final bool altaBasica;

  /// Índice CPO/ceo como checks (se hizo alguno / no), igual que la
  /// planilla física: sin cantidades.
  final bool cpoC;
  final bool cpoP;
  final bool cpoO;
  final bool ceoC;
  final bool ceoE;
  final bool ceoO;

  /// pieza -> estado general, caras, raíz y notas.
  final Map<String, PiezaOdontograma> odontograma;

  EvaluacionOdontologicaState copyWith({
    bool? cargando,
    bool? guardando,
    Object? error = _sentinel,
    int? paso,
    String? saludBucal,
    bool? lesionesTejidosBlandos,
    bool? maloclusion,
    bool? fluorosis,
    bool? caries,
    bool? otrosMarcado,
    String? otros,
    bool? topicacionFluor,
    bool? ensenanzaCepillado,
    bool? altaBasica,
    bool? cpoC,
    bool? cpoP,
    bool? cpoO,
    bool? ceoC,
    bool? ceoE,
    bool? ceoO,
    Map<String, PiezaOdontograma>? odontograma,
  }) {
    return EvaluacionOdontologicaState(
      cargando: cargando ?? this.cargando,
      guardando: guardando ?? this.guardando,
      error: identical(error, _sentinel) ? this.error : error as String?,
      paso: paso ?? this.paso,
      saludBucal: saludBucal ?? this.saludBucal,
      lesionesTejidosBlandos:
          lesionesTejidosBlandos ?? this.lesionesTejidosBlandos,
      maloclusion: maloclusion ?? this.maloclusion,
      fluorosis: fluorosis ?? this.fluorosis,
      caries: caries ?? this.caries,
      otrosMarcado: otrosMarcado ?? this.otrosMarcado,
      otros: otros ?? this.otros,
      topicacionFluor: topicacionFluor ?? this.topicacionFluor,
      ensenanzaCepillado: ensenanzaCepillado ?? this.ensenanzaCepillado,
      altaBasica: altaBasica ?? this.altaBasica,
      cpoC: cpoC ?? this.cpoC,
      cpoP: cpoP ?? this.cpoP,
      cpoO: cpoO ?? this.cpoO,
      ceoC: ceoC ?? this.ceoC,
      ceoE: ceoE ?? this.ceoE,
      ceoO: ceoO ?? this.ceoO,
      odontograma: odontograma ?? this.odontograma,
    );
  }
}

class EvaluacionOdontologicaController
    extends StateNotifier<EvaluacionOdontologicaState> {
  EvaluacionOdontologicaController({
    required this.repo,
    required this.args,
    required this.notificacionController,
  }) : super(const EvaluacionOdontologicaState()) {
    _cargar();
  }

  final OperativosRepository repo;
  final EvaluacionOdontologicaArgs args;
  final NotificacionController notificacionController;

  Future<void> _cargar() async {
    try {
      final data =
          await repo.getEvaluacionOdontologica(args.opId, args.alumnoId);
      if (!mounted) return;
      state = state.copyWith(
        cargando: false,
        saludBucal: _saludBucal(_asStr(data['salud_bucal'])),
        lesionesTejidosBlandos: _asBool(data['lesiones_tejidos_blandos']),
        maloclusion: _asBool(data['maloclusion']),
        fluorosis: _asBool(data['fluorosis']),
        caries: _asBool(data['caries']),
        otrosMarcado: _asStr(data['otros']).isNotEmpty,
        otros: _asStr(data['otros']),
        topicacionFluor: _asBool(data['topicacion_fluor']),
        ensenanzaCepillado: _asBool(data['ensenanza_cepillado']),
        altaBasica: _asBool(data['alta_basica']),
        cpoC: _asBool(data['cpo_c']),
        cpoP: _asBool(data['cpo_p']),
        cpoO: _asBool(data['cpo_o']),
        ceoC: _asBool(data['ceo_c']),
        ceoE: _asBool(data['ceo_e']),
        ceoO: _asBool(data['ceo_o']),
        odontograma: _parseOdontograma(data['odontograma']),
      );
    } catch (_) {
      if (!mounted) return;
      // Si la evaluación aún no existe / falla la carga, partimos de un estado
      // vacío editable en lugar de bloquear la pantalla.
      state = state.copyWith(
        cargando: false,
        odontograma: _parseOdontograma(null),
      );
    }
    if (mounted) _firmaGuardada = _firma();
  }

  /// Pasos del wizard (3 secciones + revisión). Deben coincidir con la
  /// pantalla: 0 salud bucal, 1 prácticas + CPO/ceo, 2 odontograma,
  /// 3 revisión.
  static const int totalPasos = 4;

  void setPaso(int v) {
    if (v < 0 || v >= totalPasos) return;
    state = state.copyWith(paso: v, error: null);
  }

  /// En odontológica no hay campos obligatorios: Siguiente nunca bloquea.
  /// Se mantiene la forma por paridad con la médica.
  String? validarPaso(int paso) => null;

  /// Avanza al paso siguiente persistiendo el avance (autoguardado al
  /// Siguiente). Si falla la red se queda en el paso con el error.
  Future<bool> intentarAvanzar() async {
    final ok = await guardarAvance();
    if (!ok || !mounted) return false;
    setPaso(state.paso + 1);
    return true;
  }

  // --- Setters de campos simples ---
  // Al salir de "Con hallazgos" se limpian los checks y el texto de Otros
  // para no guardar datos contradictorios (ej. "Sin hallazgos" + caries).
  void setSaludBucal(String v) {
    if (v == 'con_hallazgos') {
      state = state.copyWith(saludBucal: v, error: null);
      return;
    }
    state = state.copyWith(
      saludBucal: v,
      lesionesTejidosBlandos: false,
      maloclusion: false,
      fluorosis: false,
      caries: false,
      otrosMarcado: false,
      otros: '',
      error: null,
    );
  }
  void setLesionesTejidosBlandos(bool v) =>
      state = state.copyWith(lesionesTejidosBlandos: v, error: null);
  void setMaloclusion(bool v) =>
      state = state.copyWith(maloclusion: v, error: null);
  void setFluorosis(bool v) => state = state.copyWith(fluorosis: v, error: null);
  void setCaries(bool v) => state = state.copyWith(caries: v, error: null);
  void setOtrosMarcado(bool v) => state = state.copyWith(
        otrosMarcado: v,
        // Al desmarcar se borra el texto para no guardarlo huérfano.
        otros: v ? state.otros : '',
        error: null,
      );
  void setOtros(String v) => state = state.copyWith(otros: v, error: null);

  void setTopicacionFluor(bool v) =>
      state = state.copyWith(topicacionFluor: v, error: null);
  void setEnsenanzaCepillado(bool v) =>
      state = state.copyWith(ensenanzaCepillado: v, error: null);
  void setAltaBasica(bool v) =>
      state = state.copyWith(altaBasica: v, error: null);

  void setCpoC(bool v) => state = state.copyWith(cpoC: v, error: null);
  void setCpoP(bool v) => state = state.copyWith(cpoP: v, error: null);
  void setCpoO(bool v) => state = state.copyWith(cpoO: v, error: null);
  void setCeoC(bool v) => state = state.copyWith(ceoC: v, error: null);
  void setCeoE(bool v) => state = state.copyWith(ceoE: v, error: null);
  void setCeoO(bool v) => state = state.copyWith(ceoO: v, error: null);

  // --- Setter de odontograma ---
  PiezaOdontograma _pieza(String pieza) =>
      state.odontograma[pieza] ?? const PiezaOdontograma();

  PiezaOdontograma piezaActual(String pieza) => _pieza(pieza);

  void setEstadoGeneral(String pieza, String estado) {
    final actual = _pieza(pieza);
    final nuevo = Map<String, PiezaOdontograma>.from(state.odontograma);
    final esAusente = {'ausente', 'perdido', 'extraido'}.contains(estado);
    nuevo[pieza] = actual.copyWith(
      estadoGeneral: estado,
      caras: esAusente ? const {} : actual.caras,
      raiz: esAusente ? '' : actual.raiz,
    );
    state = state.copyWith(odontograma: nuevo, error: null);
  }

  void setCara(String pieza, String cara, String estado) {
    final actual = _pieza(pieza);
    if ({'ausente', 'perdido', 'extraido'}.contains(actual.estadoGeneral)) return;
    final caras = Map<String, String>.from(actual.caras);
    caras[cara] = estado;
    final nuevo = Map<String, PiezaOdontograma>.from(state.odontograma);
    nuevo[pieza] = actual.copyWith(caras: caras);
    state = state.copyWith(odontograma: nuevo, error: null);
  }

  void setRaiz(String pieza, String estado) {
    final actual = _pieza(pieza);
    if ({'ausente', 'perdido', 'extraido'}.contains(actual.estadoGeneral)) return;
    final nuevo = Map<String, PiezaOdontograma>.from(state.odontograma);
    nuevo[pieza] = actual.copyWith(raiz: estado);
    state = state.copyWith(odontograma: nuevo, error: null);
  }

  void setNotasPieza(String pieza, String notas) {
    final actual = _pieza(pieza);
    final nuevo = Map<String, PiezaOdontograma>.from(state.odontograma);
    nuevo[pieza] = actual.copyWith(notas: notas);
    state = state.copyWith(odontograma: nuevo, error: null);
  }

  Future<bool> guardar() {
    return _enviar(completar: true, exitoMsg: 'Evaluación guardada');
  }

  /// Guarda el avance sin marcar la evaluación como completada (wizard).
  /// No notifica el éxito para no spamear en cada paso.
  Future<bool> guardarAvance() {
    return _enviar(completar: false, exitoMsg: '');
  }

  /// Firma de lo último persistido: si difiere hay cambios sin guardar
  /// (dirty guard al salir). Se actualiza al cargar y en cada guardado ok.
  String _firmaGuardada = '';

  bool get tieneCambiosSinGuardar => _firma() != _firmaGuardada;

  String _firma() {
    final odo = state.odontograma.entries
        .map((e) =>
            '${e.key}=${e.value.estadoGeneral}|${e.value.raiz}|${e.value.notas}|'
            '${e.value.caras.entries.map((c) => '${c.key}:${c.value}').join('+')}')
        .join(';');
    return [
      state.saludBucal,
      state.lesionesTejidosBlandos,
      state.maloclusion,
      state.fluorosis,
      state.caries,
      state.otrosMarcado,
      state.otros,
      state.topicacionFluor,
      state.ensenanzaCepillado,
      state.altaBasica,
      state.cpoC,
      state.cpoP,
      state.cpoO,
      state.ceoC,
      state.ceoE,
      state.ceoO,
      odo,
    ].join('~');
  }

  Future<bool> _enviar({required bool completar, required String exitoMsg}) async {
    state = state.copyWith(guardando: true, error: null);
    try {
      final payload = <String, dynamic>{
        'salud_bucal': state.saludBucal,
        'lesiones_tejidos_blandos': state.lesionesTejidosBlandos,
        'maloclusion': state.maloclusion,
        'fluorosis': state.fluorosis,
        'caries': state.caries,
        'otros': state.otros,
        'topicacion_fluor': state.topicacionFluor,
        'ensenanza_cepillado': state.ensenanzaCepillado,
        'alta_basica': state.altaBasica,
        'cpo_c': state.cpoC,
        'cpo_p': state.cpoP,
        'cpo_o': state.cpoO,
        'ceo_c': state.ceoC,
        'ceo_e': state.ceoE,
        'ceo_o': state.ceoO,
        'odontograma': {
          for (final entry in state.odontograma.entries)
            entry.key: entry.value.toJson(),
        },
        'completar': completar,
      };

      await repo.putEvaluacionOdontologica(args.opId, args.alumnoId, payload);
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
  /// Sin valor guardado (evaluación nueva o legacy) se asume "No evaluado".
  static String _saludBucal(String v) => v.isEmpty ? 'no_eval' : v;

  static bool _asBool(dynamic v, {bool fallback = false}) {
    if (v is bool) return v;
    // Compatibilidad con cantidades legacy (1/0) de caché o API vieja.
    if (v is num) return v != 0;
    if (v is String) {
      final t = v.trim().toLowerCase();
      if (t == 'true' || t == '1') return true;
      if (t == 'false' || t == '0' || t.isEmpty) return false;
    }
    return fallback;
  }

  static String _asStr(dynamic v) => v == null ? '' : v.toString();

  static Map<String, PiezaOdontograma> _parseOdontograma(dynamic raw) {
    final map = raw is Map ? raw : const {};
    final result = <String, PiezaOdontograma>{};
    for (final entry in map.entries) {
      result[entry.key.toString()] = PiezaOdontograma.fromJson(entry.value);
    }
    return result;
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

final evaluacionOdontologicaControllerProvider = StateNotifierProvider
    .autoDispose.family<EvaluacionOdontologicaController,
        EvaluacionOdontologicaState, EvaluacionOdontologicaArgs>((ref, args) {
  return EvaluacionOdontologicaController(
    repo: ref.watch(operativosRepositoryProvider),
    args: args,
    notificacionController: ref.watch(notificacionProvider.notifier),
  );
});
