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
    this.nombre = '',
    this.apellido = '',
    this.dni = '',
    this.tipoDni = 'DNI',
    this.sexo = '',
    this.fechaNacimiento,
    this.calle = '',
    this.nroCalle = '',
    this.provincia = '',
    this.tieneCud = '',
    this.tipoCobertura = '',
    this.nombreCobertura = '',
    this.parentesco = '',
    this.asmaEspasmos = false,
    this.diabetes = false,
    this.guardando = false,
    this.error,
  });

  final String nombre, apellido, dni, tipoDni, sexo;
  final DateTime? fechaNacimiento;
  final String calle, nroCalle, provincia;
  final String tieneCud, tipoCobertura, nombreCobertura;
  final String parentesco;
  final bool asmaEspasmos, diabetes;
  final bool guardando;
  final String? error;

  /// Habilita "Guardar": requeridos del niño.
  bool get puedeGuardar =>
      nombre.trim().isNotEmpty &&
      apellido.trim().isNotEmpty &&
      dni.trim().isNotEmpty &&
      sexo.isNotEmpty &&
      fechaNacimiento != null;

  PlanillaState copyWith({
    String? nombre,
    String? apellido,
    String? dni,
    String? tipoDni,
    String? sexo,
    DateTime? fechaNacimiento,
    String? calle,
    String? nroCalle,
    String? provincia,
    String? tieneCud,
    String? tipoCobertura,
    String? nombreCobertura,
    String? parentesco,
    bool? asmaEspasmos,
    bool? diabetes,
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
      calle: calle ?? this.calle,
      nroCalle: nroCalle ?? this.nroCalle,
      provincia: provincia ?? this.provincia,
      tieneCud: tieneCud ?? this.tieneCud,
      tipoCobertura: tipoCobertura ?? this.tipoCobertura,
      nombreCobertura: nombreCobertura ?? this.nombreCobertura,
      parentesco: parentesco ?? this.parentesco,
      asmaEspasmos: asmaEspasmos ?? this.asmaEspasmos,
      diabetes: diabetes ?? this.diabetes,
      guardando: guardando ?? this.guardando,
      error: identical(error, _sentinel) ? this.error : error as String?,
    );
  }
}

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

  void setNombre(String v) => state = state.copyWith(nombre: v);
  void setApellido(String v) => state = state.copyWith(apellido: v);
  void setDni(String v) => state = state.copyWith(dni: v);
  void setTipoDni(String v) => state = state.copyWith(tipoDni: v);
  void setSexo(String v) => state = state.copyWith(sexo: v);
  void setFechaNacimiento(DateTime v) => state = state.copyWith(fechaNacimiento: v);
  void setCalle(String v) => state = state.copyWith(calle: v);
  void setNroCalle(String v) => state = state.copyWith(nroCalle: v);
  void setProvincia(String v) => state = state.copyWith(provincia: v);
  void setTieneCud(String v) => state = state.copyWith(tieneCud: v);
  void setTipoCobertura(String v) => state = state.copyWith(tipoCobertura: v);
  void setNombreCobertura(String v) => state = state.copyWith(nombreCobertura: v);
  void setParentesco(String v) => state = state.copyWith(parentesco: v);
  void setAsmaEspasmos(bool v) => state = state.copyWith(asmaEspasmos: v);
  void setDiabetes(bool v) => state = state.copyWith(diabetes: v);

  /// Edad en años cumplidos a partir de la fecha de nacimiento.
  int? _edadEnAnios(DateTime? f) {
    if (f == null) return null;
    final now = DateTime.now();
    var edad = now.year - f.year;
    if (now.month < f.month || (now.month == f.month && now.day < f.day)) {
      edad--;
    }
    return edad < 0 ? null : edad;
  }

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
        'edad': _edadEnAnios(s.fechaNacimiento),
        'tiene_cud': s.tieneCud,
        'tipo_cobertura': s.tipoCobertura,
        'nombre_cobertura': s.nombreCobertura,
        'parentesco': s.parentesco,
        'antecedentes_personales': {
          'asma_espasmos': s.asmaEspasmos,
          'diabetes': s.diabetes,
        },
      };
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
