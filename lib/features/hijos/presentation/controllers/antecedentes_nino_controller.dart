import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/database/database_provider.dart';

/// Las 14 preguntas Sí/No/No sabe (clave = campo del backend).
const camposSiNoNoSabe = <String>[
  'nacio_prematuro',
  'convulsiones_epilepsia',
  'mareos_desmayos',
  'infecciones_urinarias',
  'asma_espasmos',
  'tuberculosis',
  'diabetes',
  'hipertension',
  'cardiopatia_congenita',
  'traumatismo_internacion',
  'diarrea_frecuente',
  'infecciones_oido',
  'internacion_previa',
  'tratamiento_actual',
  'primera_menstruacion',
];

class AntecedentesNinoState {
  const AntecedentesNinoState({
    this.respuestas = const {},
    this.pesoNacimiento = '',
    this.causaHospitalizacion = '',
    this.descripcionTratamiento = '',
    this.ultimaConsultaMedica = '',
    this.otrosProblemasSalud = '',
    this.edadMenstruacion = '',
    this.esFemenino = false,
    this.cargando = true,
    this.guardando = false,
    this.exito = false,
    this.error,
  });

  final Map<String, String> respuestas; // campo Sí/No/No sabe -> 'si'|'no'|'no_sabe'
  final String pesoNacimiento, causaHospitalizacion, descripcionTratamiento,
      ultimaConsultaMedica, otrosProblemasSalud, edadMenstruacion;
  final bool esFemenino, cargando, guardando, exito;
  final String? error;

  String respuesta(String campo) => respuestas[campo] ?? '';
  bool get tieneInternacionPrevia => respuesta('internacion_previa') == 'si';
  bool get recibeTratamiento => respuesta('tratamiento_actual') == 'si';
  bool get tuvoMenstruacion => respuesta('primera_menstruacion') == 'si';

  AntecedentesNinoState copyWith({
    Map<String, String>? respuestas,
    String? pesoNacimiento,
    String? causaHospitalizacion,
    String? descripcionTratamiento,
    String? ultimaConsultaMedica,
    String? otrosProblemasSalud,
    String? edadMenstruacion,
    bool? esFemenino,
    bool? cargando,
    bool? guardando,
    bool? exito,
    Object? error = _sentinel,
  }) =>
      AntecedentesNinoState(
        respuestas: respuestas ?? this.respuestas,
        pesoNacimiento: pesoNacimiento ?? this.pesoNacimiento,
        causaHospitalizacion: causaHospitalizacion ?? this.causaHospitalizacion,
        descripcionTratamiento: descripcionTratamiento ?? this.descripcionTratamiento,
        ultimaConsultaMedica: ultimaConsultaMedica ?? this.ultimaConsultaMedica,
        otrosProblemasSalud: otrosProblemasSalud ?? this.otrosProblemasSalud,
        edadMenstruacion: edadMenstruacion ?? this.edadMenstruacion,
        esFemenino: esFemenino ?? this.esFemenino,
        cargando: cargando ?? this.cargando,
        guardando: guardando ?? this.guardando,
        exito: exito ?? this.exito,
        error: identical(error, _sentinel) ? this.error : error as String?,
      );
}

const _sentinel = Object();

class AntecedentesNinoController extends StateNotifier<AntecedentesNinoState> {
  AntecedentesNinoController({
    required AppDatabase db,
    required this.hijoLocalId,
    String Function()? generarId,
  })  : _db = db,
        _generarId = generarId ?? (() => const Uuid().v4()),
        super(const AntecedentesNinoState()) {
    listo = _cargar();
  }

  final AppDatabase _db;
  final String hijoLocalId;
  final String Function() _generarId;

  /// Future de la precarga inicial (para tests).
  late final Future<void> listo;

  void setCampo(String campo, String valor) {
    if (!mounted) return;
    state = state.copyWith(respuestas: {...state.respuestas, campo: valor});
  }

  void setPesoNacimiento(String v) => state = state.copyWith(pesoNacimiento: v);
  void setCausaHospitalizacion(String v) => state = state.copyWith(causaHospitalizacion: v);
  void setDescripcionTratamiento(String v) => state = state.copyWith(descripcionTratamiento: v);
  void setUltimaConsultaMedica(String v) => state = state.copyWith(ultimaConsultaMedica: v);
  void setOtrosProblemasSalud(String v) => state = state.copyWith(otrosProblemasSalud: v);
  void setEdadMenstruacion(String v) => state = state.copyWith(edadMenstruacion: v);

  Future<void> _cargar() async {
    final hijo = await _db.hijoPorId(hijoLocalId);
    var esF = false;
    if (hijo != null) {
      final p = jsonDecode(hijo.payloadJson) as Map<String, dynamic>;
      esF = ((p['persona'] as Map?)?['sexo'] as String?) == 'F';
    }
    final draft = await _db.antecedenteNinoPorHijo(hijoLocalId);
    if (!mounted) return;
    if (draft == null) {
      state = state.copyWith(esFemenino: esF, cargando: false);
      return;
    }
    final body = jsonDecode(draft.payloadJson) as Map<String, dynamic>;
    final respuestas = <String, String>{
      for (final c in camposSiNoNoSabe)
        if (body[c] is String) c: body[c] as String,
    };
    state = state.copyWith(
      esFemenino: esF,
      respuestas: respuestas,
      pesoNacimiento: (body['peso_nacimiento'] as String?) ?? '',
      causaHospitalizacion: (body['causa_hospitalizacion'] as String?) ?? '',
      descripcionTratamiento: (body['descripcion_tratamiento'] as String?) ?? '',
      ultimaConsultaMedica: (body['ultima_consulta_medica'] as String?) ?? '',
      otrosProblemasSalud: (body['otros_problemas_salud'] as String?) ?? '',
      edadMenstruacion: (body['edad_primera_menstruacion'] is int)
          ? '${body['edad_primera_menstruacion']}'
          : '',
      cargando: false,
    );
  }

  Map<String, dynamic> _payload() {
    final s = state;
    String resp(String c) => s.respuesta(c).isEmpty ? 'no_sabe' : s.respuesta(c);
    return {
      for (final c in camposSiNoNoSabe) c: resp(c),
      'peso_nacimiento': s.pesoNacimiento,
      'causa_hospitalizacion': s.tieneInternacionPrevia ? s.causaHospitalizacion : '',
      'descripcion_tratamiento': s.recibeTratamiento ? s.descripcionTratamiento : '',
      'ultima_consulta_medica': s.ultimaConsultaMedica,
      'otros_problemas_salud': s.otrosProblemasSalud,
      'edad_primera_menstruacion': int.tryParse(s.edadMenstruacion) ?? 0,
    };
  }

  Future<void> guardar() async {
    state = state.copyWith(guardando: true, error: null);
    try {
      await _db.upsertAntecedenteNinoDraft(
        id: _generarId(),
        hijoLocalId: hijoLocalId,
        payloadJson: jsonEncode(_payload()),
      );
      if (!mounted) return;
      state = state.copyWith(guardando: false, exito: true);
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(guardando: false, error: 'No se pudieron guardar. Probá de nuevo.');
    }
  }
}

final antecedentesNinoControllerProvider = StateNotifierProvider.autoDispose
    .family<AntecedentesNinoController, AntecedentesNinoState, String>(
  (ref, hijoLocalId) =>
      AntecedentesNinoController(db: ref.watch(databaseProvider), hijoLocalId: hijoLocalId),
);
