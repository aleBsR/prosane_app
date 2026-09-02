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
    this.saludBucal = '',
    this.lesionesTejidosBlandos = false,
    this.maloclusion = false,
    this.fluorosis = false,
    this.caries = false,
    this.otros = '',
    this.topicacionFluor = false,
    this.ensenanzaCepillado = false,
    this.altaBasica = false,
    this.cpoC = '',
    this.cpoP = '',
    this.cpoO = '',
    this.ceoC = '',
    this.ceoE = '',
    this.ceoO = '',
    this.odontograma = const {},
  });

  final bool cargando;
  final bool guardando;
  final String? error;

  final String saludBucal;
  final bool lesionesTejidosBlandos;
  final bool maloclusion;
  final bool fluorosis;
  final bool caries;
  final String otros;

  final bool topicacionFluor;
  final bool ensenanzaCepillado;
  final bool altaBasica;

  final String cpoC;
  final String cpoP;
  final String cpoO;
  final String ceoC;
  final String ceoE;
  final String ceoO;

  /// pieza -> estado general, caras, raíz y notas.
  final Map<String, PiezaOdontograma> odontograma;

  EvaluacionOdontologicaState copyWith({
    bool? cargando,
    bool? guardando,
    Object? error = _sentinel,
    String? saludBucal,
    bool? lesionesTejidosBlandos,
    bool? maloclusion,
    bool? fluorosis,
    bool? caries,
    String? otros,
    bool? topicacionFluor,
    bool? ensenanzaCepillado,
    bool? altaBasica,
    String? cpoC,
    String? cpoP,
    String? cpoO,
    String? ceoC,
    String? ceoE,
    String? ceoO,
    Map<String, PiezaOdontograma>? odontograma,
  }) {
    return EvaluacionOdontologicaState(
      cargando: cargando ?? this.cargando,
      guardando: guardando ?? this.guardando,
      error: identical(error, _sentinel) ? this.error : error as String?,
      saludBucal: saludBucal ?? this.saludBucal,
      lesionesTejidosBlandos:
          lesionesTejidosBlandos ?? this.lesionesTejidosBlandos,
      maloclusion: maloclusion ?? this.maloclusion,
      fluorosis: fluorosis ?? this.fluorosis,
      caries: caries ?? this.caries,
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
        saludBucal: _asStr(data['salud_bucal']),
        lesionesTejidosBlandos: _asBool(data['lesiones_tejidos_blandos']),
        maloclusion: _asBool(data['maloclusion']),
        fluorosis: _asBool(data['fluorosis']),
        caries: _asBool(data['caries']),
        otros: _asStr(data['otros']),
        topicacionFluor: _asBool(data['topicacion_fluor']),
        ensenanzaCepillado: _asBool(data['ensenanza_cepillado']),
        altaBasica: _asBool(data['alta_basica']),
        cpoC: _asStr(data['cpo_c']),
        cpoP: _asStr(data['cpo_p']),
        cpoO: _asStr(data['cpo_o']),
        ceoC: _asStr(data['ceo_c']),
        ceoE: _asStr(data['ceo_e']),
        ceoO: _asStr(data['ceo_o']),
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
  }

  // --- Setters de campos simples ---
  void setSaludBucal(String v) =>
      state = state.copyWith(saludBucal: v, error: null);
  void setLesionesTejidosBlandos(bool v) =>
      state = state.copyWith(lesionesTejidosBlandos: v, error: null);
  void setMaloclusion(bool v) =>
      state = state.copyWith(maloclusion: v, error: null);
  void setFluorosis(bool v) => state = state.copyWith(fluorosis: v, error: null);
  void setCaries(bool v) => state = state.copyWith(caries: v, error: null);
  void setOtros(String v) => state = state.copyWith(otros: v, error: null);

  void setTopicacionFluor(bool v) =>
      state = state.copyWith(topicacionFluor: v, error: null);
  void setEnsenanzaCepillado(bool v) =>
      state = state.copyWith(ensenanzaCepillado: v, error: null);
  void setAltaBasica(bool v) =>
      state = state.copyWith(altaBasica: v, error: null);

  void setCpoC(String v) => state = state.copyWith(cpoC: v, error: null);
  void setCpoP(String v) => state = state.copyWith(cpoP: v, error: null);
  void setCpoO(String v) => state = state.copyWith(cpoO: v, error: null);
  void setCeoC(String v) => state = state.copyWith(ceoC: v, error: null);
  void setCeoE(String v) => state = state.copyWith(ceoE: v, error: null);
  void setCeoO(String v) => state = state.copyWith(ceoO: v, error: null);

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

  Future<bool> guardar() async {
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
        'cpo_c': _intOrNull(state.cpoC),
        'cpo_p': _intOrNull(state.cpoP),
        'cpo_o': _intOrNull(state.cpoO),
        'ceo_c': _intOrNull(state.ceoC),
        'ceo_e': _intOrNull(state.ceoE),
        'ceo_o': _intOrNull(state.ceoO),
        'odontograma': {
          for (final entry in state.odontograma.entries)
            entry.key: entry.value.toJson(),
        },
      };

      await repo.putEvaluacionOdontologica(args.opId, args.alumnoId, payload);
      if (!mounted) return true;
      state = state.copyWith(guardando: false);
      notificacionController.exito('Evaluación guardada');
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

  static Map<String, PiezaOdontograma> _parseOdontograma(dynamic raw) {
    final map = raw is Map ? raw : const {};
    final result = <String, PiezaOdontograma>{};
    for (final entry in map.entries) {
      result[entry.key.toString()] = PiezaOdontograma.fromJson(entry.value);
    }
    return result;
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

final evaluacionOdontologicaControllerProvider = StateNotifierProvider
    .autoDispose.family<EvaluacionOdontologicaController,
        EvaluacionOdontologicaState, EvaluacionOdontologicaArgs>((ref, args) {
  return EvaluacionOdontologicaController(
    repo: ref.watch(operativosRepositoryProvider),
    args: args,
    notificacionController: ref.watch(notificacionProvider.notifier),
  );
});
