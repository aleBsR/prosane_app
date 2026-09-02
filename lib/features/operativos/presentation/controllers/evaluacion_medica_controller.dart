import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers.dart';
import '../../../../core/notificaciones/notificacion_controller.dart';
import '../../data/operativos_repository.dart';

/// Argumentos de identificación de la evaluación: operativo + alumno.
typedef EvaluacionMedicaArgs = ({String opId, String alumnoId});

/// Los 11 sistemas de hallazgos clínicos (claves del contrato de API).
const List<String> kHallazgoSistemas = [
  'piel',
  'partes_blandas',
  'cardiovascular',
  'respiratorio',
  'abdominal',
  'genitourinario',
  'osteoarticular',
  'neurologico',
  'salud_visual',
  'fonoaudiologica',
  'icv',
];

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

  final String pas;
  final String pad;
  final String presionClasificacion;

  final bool agudezaEvaluada;
  final String ojoDerecho;
  final String ojoIzquierdo;
  final bool usaLentes;
  final bool audiometriaRealizada;
  final String audiometriaResultado;

  /// sistema -> {estado, detalle}
  final Map<String, ({String estado, String detalle})> hallazgos;

  /// especialidad -> {deriva, motivo}
  final Map<String, ({bool deriva, String motivo})> derivaciones;

  EvaluacionMedicaState copyWith({
    bool? cargando,
    bool? guardando,
    Object? error = _sentinel,
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
    String? pas,
    String? pad,
    String? presionClasificacion,
    bool? agudezaEvaluada,
    String? ojoDerecho,
    String? ojoIzquierdo,
    bool? usaLentes,
    bool? audiometriaRealizada,
    String? audiometriaResultado,
    Map<String, ({String estado, String detalle})>? hallazgos,
    Map<String, ({bool deriva, String motivo})>? derivaciones,
  }) {
    return EvaluacionMedicaState(
      cargando: cargando ?? this.cargando,
      guardando: guardando ?? this.guardando,
      error: identical(error, _sentinel) ? this.error : error as String?,
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
      state = state.copyWith(
        cargando: false,
        examenRealizado: _asBool(data['examen_realizado'], fallback: true),
        motivoNoExamen: _asStr(data['motivo_no_examen']),
        lugarExamen: _asStr(data['lugar_examen']),
        trajoCarnet: _asBool(data['trajo_carnet']),
        carnetCompleto: _asBool(data['carnet_completo']),
        vacunasAplicadas: _asStr(data['vacunas_aplicadas']),
        vacunasIndicadas: _asStr(data['vacunas_indicadas']),
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
  }

  // --- Setters de campos simples ---
  void setExamenRealizado(bool v) =>
      state = state.copyWith(examenRealizado: v, error: null);
  void setMotivoNoExamen(String v) =>
      state = state.copyWith(motivoNoExamen: v, error: null);
  void setLugarExamen(String v) =>
      state = state.copyWith(lugarExamen: v, error: null);

  void setTrajoCarnet(bool v) =>
      state = state.copyWith(trajoCarnet: v, error: null);
  void setCarnetCompleto(bool v) =>
      state = state.copyWith(carnetCompleto: v, error: null);
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

  void setPas(String v) => state = state.copyWith(pas: v, error: null);
  void setPad(String v) => state = state.copyWith(pad: v, error: null);
  void setPresionClasificacion(String v) =>
      state = state.copyWith(presionClasificacion: v, error: null);

  void setAgudezaEvaluada(bool v) =>
      state = state.copyWith(agudezaEvaluada: v, error: null);
  void setOjoDerecho(String v) =>
      state = state.copyWith(ojoDerecho: v, error: null);
  void setOjoIzquierdo(String v) =>
      state = state.copyWith(ojoIzquierdo: v, error: null);
  void setUsaLentes(bool v) =>
      state = state.copyWith(usaLentes: v, error: null);
  void setAudiometriaRealizada(bool v) =>
      state = state.copyWith(audiometriaRealizada: v, error: null);
  void setAudiometriaResultado(String v) =>
      state = state.copyWith(audiometriaResultado: v, error: null);

  // --- Setters de hallazgos ---
  void setHallazgoEstado(String sistema, String estado) {
    final actual = state.hallazgos[sistema] ?? (estado: 'no_eval', detalle: '');
    final nuevo = Map<String, ({String estado, String detalle})>.from(
        state.hallazgos);
    nuevo[sistema] = (estado: estado, detalle: actual.detalle);
    state = state.copyWith(hallazgos: nuevo, error: null);
  }

  void setHallazgoDetalle(String sistema, String detalle) {
    final actual = state.hallazgos[sistema] ?? (estado: 'no_eval', detalle: '');
    final nuevo = Map<String, ({String estado, String detalle})>.from(
        state.hallazgos);
    nuevo[sistema] = (estado: actual.estado, detalle: detalle);
    state = state.copyWith(hallazgos: nuevo, error: null);
  }

  // --- Setter de derivaciones ---
  void setDerivacion(String esp, {bool? deriva, String? motivo}) {
    final actual = state.derivaciones[esp] ?? (deriva: false, motivo: '');
    final nuevo =
        Map<String, ({bool deriva, String motivo})>.from(state.derivaciones);
    nuevo[esp] = (
      deriva: deriva ?? actual.deriva,
      motivo: motivo ?? actual.motivo,
    );
    state = state.copyWith(derivaciones: nuevo, error: null);
  }

  Future<bool> guardar() async {
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
            e.key: {'estado': e.value.estado, 'detalle': e.value.detalle},
        },
        'derivaciones': {
          for (final e in state.derivaciones.entries)
            e.key: {'deriva': e.value.deriva, 'motivo': e.value.motivo},
        },
      };

      await repo.putEvaluacionMedica(args.opId, args.alumnoId, payload);
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

  static Map<String, ({String estado, String detalle})> _parseHallazgos(
      dynamic raw) {
    final map = raw is Map ? raw : const {};
    return {
      for (final s in kHallazgoSistemas)
        s: () {
          final item = map[s];
          if (item is Map) {
            return (
              estado: (item['estado'] ?? 'no_eval').toString(),
              detalle: (item['detalle'] ?? '').toString(),
            );
          }
          return (estado: 'no_eval', detalle: '');
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
            return (
              deriva: item['deriva'] is bool ? item['deriva'] as bool : false,
              motivo: (item['motivo'] ?? '').toString(),
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
