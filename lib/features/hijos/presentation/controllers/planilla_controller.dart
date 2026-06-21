import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/database/database_provider.dart';
import '../../../../core/session/entities.dart';
import '../../../../core/session/session_controller.dart';

// ─── Estado ────────────────────────────────────────────────────────────────────

class PlanillaState {
  const PlanillaState({
    // persona
    this.nombre = '',
    this.apellido = '',
    this.dni = '',
    this.tipoDni = 'DNI',
    this.sexo = '',
    this.fechaNacimiento,
    this.edad,
    // domicilio
    this.calle = '',
    this.nroCalle = '',
    this.provincia = '',
    // cobertura
    this.tieneCud = '',
    this.tipoCobertura = '',
    this.nombreCobertura = '',
    // parentesco
    this.parentesco = '',
    // antecedentes personales
    this.asmaEspasmos = false,
    this.diabetes = false,
    // antecedentes familiares
    this.antFamAsma = false,
    this.antFamDiabetes = false,
    // consentimiento
    this.adultoNombre = '',
    this.adultoApellido = '',
    this.adultoTipoDocumento = 'DNI',
    this.adultoDni = '',
    this.consentimientoAceptado = false,
    // control
    this.guardando = false,
    this.error,
  });

  final String nombre;
  final String apellido;
  final String dni;
  final String tipoDni;
  final String sexo;
  final DateTime? fechaNacimiento;
  final int? edad;

  final String calle;
  final String nroCalle;
  final String provincia;

  final String tieneCud;
  final String tipoCobertura;
  final String nombreCobertura;

  final String parentesco;

  final bool asmaEspasmos;
  final bool diabetes;

  final bool antFamAsma;
  final bool antFamDiabetes;

  final String adultoNombre;
  final String adultoApellido;
  final String adultoTipoDocumento;
  final String adultoDni;
  final bool consentimientoAceptado;

  final bool guardando;
  final String? error;

  PlanillaState copyWith({
    String? nombre,
    String? apellido,
    String? dni,
    String? tipoDni,
    String? sexo,
    DateTime? fechaNacimiento,
    int? edad,
    String? calle,
    String? nroCalle,
    String? provincia,
    String? tieneCud,
    String? tipoCobertura,
    String? nombreCobertura,
    String? parentesco,
    bool? asmaEspasmos,
    bool? diabetes,
    bool? antFamAsma,
    bool? antFamDiabetes,
    String? adultoNombre,
    String? adultoApellido,
    String? adultoTipoDocumento,
    String? adultoDni,
    bool? consentimientoAceptado,
    bool? guardando,
    Object? error = _sentinel,
  }) {
    return PlanillaState(
      nombre: nombre ?? this.nombre,
      apellido: apellido ?? this.apellido,
      dni: dni ?? this.dni,
      tipoDni: tipoDni ?? this.tipoDni,
      sexo: sexo ?? this.sexo,
      fechaNacimiento: fechaNacimiento ?? this.fechaNacimiento,
      edad: edad ?? this.edad,
      calle: calle ?? this.calle,
      nroCalle: nroCalle ?? this.nroCalle,
      provincia: provincia ?? this.provincia,
      tieneCud: tieneCud ?? this.tieneCud,
      tipoCobertura: tipoCobertura ?? this.tipoCobertura,
      nombreCobertura: nombreCobertura ?? this.nombreCobertura,
      parentesco: parentesco ?? this.parentesco,
      asmaEspasmos: asmaEspasmos ?? this.asmaEspasmos,
      diabetes: diabetes ?? this.diabetes,
      antFamAsma: antFamAsma ?? this.antFamAsma,
      antFamDiabetes: antFamDiabetes ?? this.antFamDiabetes,
      adultoNombre: adultoNombre ?? this.adultoNombre,
      adultoApellido: adultoApellido ?? this.adultoApellido,
      adultoTipoDocumento: adultoTipoDocumento ?? this.adultoTipoDocumento,
      adultoDni: adultoDni ?? this.adultoDni,
      consentimientoAceptado: consentimientoAceptado ?? this.consentimientoAceptado,
      guardando: guardando ?? this.guardando,
      error: identical(error, _sentinel) ? this.error : error as String?,
    );
  }
}

// Sentinel para diferenciar "no pasado" de null en copyWith(error:)
const _sentinel = Object();

// ─── Controller ────────────────────────────────────────────────────────────────

class PlanillaController extends StateNotifier<PlanillaState> {
  PlanillaController({
    required AppDatabase db,
    required String? tutorId,
    String Function()? generarId,
  })  : _db = db,
        _tutorId = tutorId,
        _generarId = generarId ?? (() => const Uuid().v4()),
        super(const PlanillaState());

  final AppDatabase _db;
  final String? _tutorId;
  final String Function() _generarId;

  // ── setters ──────────────────────────────────────────────────────────────────

  void setNombre(String v) => state = state.copyWith(nombre: v);
  void setApellido(String v) => state = state.copyWith(apellido: v);
  void setDni(String v) => state = state.copyWith(dni: v);
  void setTipoDni(String v) => state = state.copyWith(tipoDni: v);
  void setSexo(String v) => state = state.copyWith(sexo: v);
  void setFechaNacimiento(DateTime v) => state = state.copyWith(fechaNacimiento: v);
  void setEdad(int v) => state = state.copyWith(edad: v);

  void setCalle(String v) => state = state.copyWith(calle: v);
  void setNroCalle(String v) => state = state.copyWith(nroCalle: v);
  void setProvincia(String v) => state = state.copyWith(provincia: v);

  void setTieneCud(String v) => state = state.copyWith(tieneCud: v);
  void setTipoCobertura(String v) => state = state.copyWith(tipoCobertura: v);
  void setNombreCobertura(String v) => state = state.copyWith(nombreCobertura: v);

  void setParentesco(String v) => state = state.copyWith(parentesco: v);

  void setAsmaEspasmos(bool v) => state = state.copyWith(asmaEspasmos: v);
  void setDiabetes(bool v) => state = state.copyWith(diabetes: v);

  void setAntFamAsma(bool v) => state = state.copyWith(antFamAsma: v);
  void setAntFamDiabetes(bool v) => state = state.copyWith(antFamDiabetes: v);

  void setAdultoNombre(String v) => state = state.copyWith(adultoNombre: v);
  void setAdultoApellido(String v) => state = state.copyWith(adultoApellido: v);
  void setAdultoTipoDocumento(String v) => state = state.copyWith(adultoTipoDocumento: v);
  void setAdultoDni(String v) => state = state.copyWith(adultoDni: v);
  void setConsentimientoAceptado(bool v) => state = state.copyWith(consentimientoAceptado: v);

  // ── guardar ──────────────────────────────────────────────────────────────────

  Future<void> guardar() async {
    if (_tutorId == null || _tutorId.isEmpty) {
      state = state.copyWith(error: 'No hay tutor autenticado');
      return;
    }

    state = state.copyWith(guardando: true, error: null);

    try {
      final s = state;

      final payload = <String, dynamic>{
        'persona': {
          'nombre': s.nombre,
          'apellido': s.apellido,
          'dni': s.dni,
          'tipo_dni': s.tipoDni,
          'sexo': s.sexo,
          'fecha_nacimiento': s.fechaNacimiento?.toIso8601String().split('T').first,
        },
        'domicilio': {
          'calle': s.calle,
          'nro_calle': s.nroCalle,
          'provincia': s.provincia,
        },
        'edad': s.edad,
        'tiene_cud': s.tieneCud,
        'tipo_cobertura': s.tipoCobertura,
        'nombre_cobertura': s.nombreCobertura,
        'parentesco': s.parentesco,
        'antecedentes_personales': {
          'asma_espasmos': s.asmaEspasmos,
          'diabetes': s.diabetes,
        },
        'antecedentes_familiares': {
          'asma': s.antFamAsma,
          'diabetes': s.antFamDiabetes,
        },
      };

      if (s.consentimientoAceptado) {
        payload['consentimiento'] = {
          'adulto_nombre': s.adultoNombre,
          'adulto_apellido': s.adultoApellido,
          'adulto_tipo_documento': s.adultoTipoDocumento,
          'adulto_dni': s.adultoDni,
        };
      }

      await _db.insertHijoDraft(
        id: _generarId(),
        tutorId: _tutorId,
        nombreNna: s.nombre,
        apellidoNna: s.apellido,
        payloadJson: jsonEncode(payload),
      );

      state = state.copyWith(guardando: false);
    } catch (e) {
      state = state.copyWith(guardando: false, error: e.toString());
    }
  }
}

// ─── Provider ─────────────────────────────────────────────────────────────────

final planillaControllerProvider =
    StateNotifierProvider.autoDispose<PlanillaController, PlanillaState>((ref) {
  final s = ref.watch(sessionControllerProvider);
  final tutorId = s is SesionAutenticada ? s.sesion.usuario.tutorId : null;
  return PlanillaController(
    db: ref.watch(databaseProvider),
    tutorId: tutorId,
  );
});
