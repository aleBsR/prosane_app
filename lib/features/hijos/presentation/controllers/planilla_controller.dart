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
    this.tieneCud = '',
    this.telefonoFijo = '',
    this.celular = '',
    this.parentesco = '',
    this.calle = '',
    this.nroCalle = '',
    this.piso = '',
    this.dpto = '',
    this.manzana = '',
    this.casa = '',
    this.nroCasa = '',
    this.pieza = '',
    this.provincia = '',
    this.departamento = '',
    this.localidad = '',
    this.tipoCobertura = '',
    this.nombreCobertura = '',
    this.guardando = false,
    this.error,
  });

  final String nombre, apellido, dni, tipoDni, sexo;
  final DateTime? fechaNacimiento;
  final String tieneCud, telefonoFijo, celular, parentesco;
  final String calle, nroCalle, piso, dpto, manzana, casa, nroCasa, pieza,
      provincia, departamento, localidad;
  final String tipoCobertura, nombreCobertura;
  final bool guardando;
  final String? error;

  /// Habilita "Guardar": requeridos del niño.
  bool get puedeGuardar =>
      nombre.trim().isNotEmpty &&
      apellido.trim().isNotEmpty &&
      dni.trim().isNotEmpty &&
      sexo.isNotEmpty &&
      fechaNacimiento != null;

  /// `nombre_cobertura` solo aplica a obra social / prepaga.
  bool get pideNombreCobertura =>
      tipoCobertura == 'obra_social' || tipoCobertura == 'prepaga';

  PlanillaState copyWith({
    String? nombre,
    String? apellido,
    String? dni,
    String? tipoDni,
    String? sexo,
    DateTime? fechaNacimiento,
    String? tieneCud,
    String? telefonoFijo,
    String? celular,
    String? parentesco,
    String? calle,
    String? nroCalle,
    String? piso,
    String? dpto,
    String? manzana,
    String? casa,
    String? nroCasa,
    String? pieza,
    String? provincia,
    String? departamento,
    String? localidad,
    String? tipoCobertura,
    String? nombreCobertura,
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
      tieneCud: tieneCud ?? this.tieneCud,
      telefonoFijo: telefonoFijo ?? this.telefonoFijo,
      celular: celular ?? this.celular,
      parentesco: parentesco ?? this.parentesco,
      calle: calle ?? this.calle,
      nroCalle: nroCalle ?? this.nroCalle,
      piso: piso ?? this.piso,
      dpto: dpto ?? this.dpto,
      manzana: manzana ?? this.manzana,
      casa: casa ?? this.casa,
      nroCasa: nroCasa ?? this.nroCasa,
      pieza: pieza ?? this.pieza,
      provincia: provincia ?? this.provincia,
      departamento: departamento ?? this.departamento,
      localidad: localidad ?? this.localidad,
      tipoCobertura: tipoCobertura ?? this.tipoCobertura,
      nombreCobertura: nombreCobertura ?? this.nombreCobertura,
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
  void setTieneCud(String v) => state = state.copyWith(tieneCud: v);
  void setTelefonoFijo(String v) => state = state.copyWith(telefonoFijo: v);
  void setCelular(String v) => state = state.copyWith(celular: v);
  void setParentesco(String v) => state = state.copyWith(parentesco: v);

  void setCalle(String v) => state = state.copyWith(calle: v);
  void setNroCalle(String v) => state = state.copyWith(nroCalle: v);
  void setPiso(String v) => state = state.copyWith(piso: v);
  void setDpto(String v) => state = state.copyWith(dpto: v);
  void setManzana(String v) => state = state.copyWith(manzana: v);
  void setCasa(String v) => state = state.copyWith(casa: v);
  void setNroCasa(String v) => state = state.copyWith(nroCasa: v);
  void setPieza(String v) => state = state.copyWith(pieza: v);
  void setProvincia(String v) => state = state.copyWith(provincia: v);
  void setDepartamento(String v) => state = state.copyWith(departamento: v);
  void setLocalidad(String v) => state = state.copyWith(localidad: v);

  void setNombreCobertura(String v) => state = state.copyWith(nombreCobertura: v);

  /// Al cambiar a una cobertura que no lleva nombre, lo limpia.
  void setTipoCobertura(String v) {
    if (v == 'obra_social' || v == 'prepaga') {
      state = state.copyWith(tipoCobertura: v);
    } else {
      state = state.copyWith(tipoCobertura: v, nombreCobertura: '');
    }
  }

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
    final tutorId = _tutorId; // promovido a String tras el guard
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
          'piso': s.piso,
          'dpto': s.dpto,
          'manzana': s.manzana,
          'casa': s.casa,
          'nro_casa': s.nroCasa,
          'pieza': s.pieza,
          'provincia': s.provincia,
          'departamento': s.departamento,
          'localidad': s.localidad,
        },
        'edad': _edadEnAnios(s.fechaNacimiento),
        'tiene_cud': s.tieneCud,
        'tipo_cobertura': s.tipoCobertura,
        'nombre_cobertura': s.nombreCobertura,
        'telefono_fijo': s.telefonoFijo,
        'celular': s.celular,
        'parentesco': s.parentesco,
      };
      await _db.insertHijoDraft(
        id: _generarId(),
        tutorId: tutorId,
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
