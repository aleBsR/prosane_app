import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers.dart';
import '../../data/escuelas_repository.dart';

class EscuelaCreateState {
  final String nombre;
  final String cue;
  final String ambito;
  final String sectorGestion;
  final String modalidadEducativa;
  final String telefono;
  final bool interculturalBilingue;
  final bool plurigradoRural;
  final String domicilioProvincia;
  final String domicilioLocalidad;
  final String domicilioCalle;
  final String domicilioNroCalle;
  final bool guardando;
  final String? error;

  EscuelaCreateState({
    this.nombre = '',
    this.cue = '',
    this.ambito = '',
    this.sectorGestion = '',
    this.modalidadEducativa = '',
    this.telefono = '',
    this.interculturalBilingue = false,
    this.plurigradoRural = false,
    this.domicilioProvincia = '',
    this.domicilioLocalidad = '',
    this.domicilioCalle = '',
    this.domicilioNroCalle = '',
    this.guardando = false,
    this.error,
  });

  EscuelaCreateState copyWith({
    String? nombre,
    String? cue,
    String? ambito,
    String? sectorGestion,
    String? modalidadEducativa,
    String? telefono,
    bool? interculturalBilingue,
    bool? plurigradoRural,
    String? domicilioProvincia,
    String? domicilioLocalidad,
    String? domicilioCalle,
    String? domicilioNroCalle,
    bool? guardando,
    String? error,
  }) {
    return EscuelaCreateState(
      nombre: nombre ?? this.nombre,
      cue: cue ?? this.cue,
      ambito: ambito ?? this.ambito,
      sectorGestion: sectorGestion ?? this.sectorGestion,
      modalidadEducativa: modalidadEducativa ?? this.modalidadEducativa,
      telefono: telefono ?? this.telefono,
      interculturalBilingue:
          interculturalBilingue ?? this.interculturalBilingue,
      plurigradoRural: plurigradoRural ?? this.plurigradoRural,
      domicilioProvincia: domicilioProvincia ?? this.domicilioProvincia,
      domicilioLocalidad: domicilioLocalidad ?? this.domicilioLocalidad,
      domicilioCalle: domicilioCalle ?? this.domicilioCalle,
      domicilioNroCalle: domicilioNroCalle ?? this.domicilioNroCalle,
      guardando: guardando ?? this.guardando,
      error: error,
    );
  }

  bool get puedeGuardar => nombre.isNotEmpty && !guardando;
}

class EscuelaCreateController extends StateNotifier<EscuelaCreateState> {
  final EscuelasRepository _repo;

  EscuelaCreateController(this._repo) : super(EscuelaCreateState());

  void setNombre(String v) => state = state.copyWith(nombre: v, error: null);
  void setCue(String v) => state = state.copyWith(cue: v, error: null);
  void setAmbito(String v) => state = state.copyWith(ambito: v, error: null);
  void setSectorGestion(String v) =>
      state = state.copyWith(sectorGestion: v, error: null);
  void setModalidadEducativa(String v) =>
      state = state.copyWith(modalidadEducativa: v, error: null);
  void setTelefono(String v) =>
      state = state.copyWith(telefono: v, error: null);
  void setInterculturalBilingue(bool v) =>
      state = state.copyWith(interculturalBilingue: v, error: null);
  void setPlurigradoRural(bool v) =>
      state = state.copyWith(plurigradoRural: v, error: null);
  void setProvincia(String v) =>
      state = state.copyWith(domicilioProvincia: v, error: null);
  void setLocalidad(String v) =>
      state = state.copyWith(domicilioLocalidad: v, error: null);
  void setCalle(String v) =>
      state = state.copyWith(domicilioCalle: v, error: null);
  void setNroCalle(String v) =>
      state = state.copyWith(domicilioNroCalle: v, error: null);

  void resetear() {
    state = EscuelaCreateState();
  }

  Future<bool> guardar() async {
    if (!puedeGuardar) return false;

    state = state.copyWith(guardando: true);

    try {
      final payload = {
        'nombre': state.nombre.trim(),
        if (state.cue.isNotEmpty) 'cue': state.cue,
        if (state.ambito.isNotEmpty) 'ambito': state.ambito,
        if (state.sectorGestion.isNotEmpty)
          'sector_gestion': state.sectorGestion,
        if (state.modalidadEducativa.isNotEmpty)
          'modalidad_educativa': state.modalidadEducativa,
        if (state.telefono.isNotEmpty) 'telefono': state.telefono,
        'intercultural_bilingue': state.interculturalBilingue,
        'plurigrado_rural': state.plurigradoRural,
        if (state.domicilioProvincia.isNotEmpty ||
            state.domicilioLocalidad.isNotEmpty ||
            state.domicilioCalle.isNotEmpty ||
            state.domicilioNroCalle.isNotEmpty)
          'domicilio': {
            if (state.domicilioProvincia.isNotEmpty)
              'provincia': state.domicilioProvincia,
            if (state.domicilioLocalidad.isNotEmpty)
              'localidad': state.domicilioLocalidad,
            if (state.domicilioCalle.isNotEmpty) 'calle': state.domicilioCalle,
            if (state.domicilioNroCalle.isNotEmpty)
              'nro_calle': state.domicilioNroCalle,
          },
      };

      await _repo.crear(payload);
      state = EscuelaCreateState();
      return true;
    } catch (e) {
      state = state.copyWith(
        guardando: false,
        error: e.toString().contains('409')
            ? 'CUE duplicado'
            : 'Error: ${e.toString()}',
      );
      return false;
    }
  }

  bool get puedeGuardar => state.puedeGuardar;
}

final escuelaCreateControllerProvider =
    StateNotifierProvider<EscuelaCreateController, EscuelaCreateState>(
  (ref) => EscuelaCreateController(ref.watch(escuelasRepositoryProvider)),
);
