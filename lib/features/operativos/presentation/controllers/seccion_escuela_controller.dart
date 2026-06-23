import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers.dart';
import '../../../../core/notificaciones/notificacion_controller.dart';
import '../../data/operativos_repository.dart';

/// Argumentos de identificación de la sección escuela: operativo + alumno.
typedef SeccionEscuelaArgs = ({String opId, String alumnoId});

const _sentinel = Object();

class SeccionEscuelaState {
  const SeccionEscuelaState({
    this.cargando = true,
    this.guardando = false,
    this.error,
    this.preocupaSalud = false,
    this.preocupaDetalle = '',
    this.dificultadLenguaje = false,
    this.bajoTratamiento = false,
  });

  final bool cargando;
  final bool guardando;
  final String? error;

  final bool preocupaSalud;
  final String preocupaDetalle;
  final bool dificultadLenguaje;
  final bool bajoTratamiento;

  SeccionEscuelaState copyWith({
    bool? cargando,
    bool? guardando,
    Object? error = _sentinel,
    bool? preocupaSalud,
    String? preocupaDetalle,
    bool? dificultadLenguaje,
    bool? bajoTratamiento,
  }) =>
      SeccionEscuelaState(
        cargando: cargando ?? this.cargando,
        guardando: guardando ?? this.guardando,
        error: identical(error, _sentinel) ? this.error : error as String?,
        preocupaSalud: preocupaSalud ?? this.preocupaSalud,
        preocupaDetalle: preocupaDetalle ?? this.preocupaDetalle,
        dificultadLenguaje: dificultadLenguaje ?? this.dificultadLenguaje,
        bajoTratamiento: bajoTratamiento ?? this.bajoTratamiento,
      );
}

class SeccionEscuelaController extends StateNotifier<SeccionEscuelaState> {
  SeccionEscuelaController({
    required this.repo,
    required this.args,
    required this.notificacionController,
  }) : super(const SeccionEscuelaState()) {
    _cargar();
  }

  final OperativosRepository repo;
  final SeccionEscuelaArgs args;
  final NotificacionController notificacionController;

  /// No existe GET propio de la sección: precargamos desde el alumno de la lista.
  Future<void> _cargar() async {
    try {
      final alumnos = await repo.listarAlumnos(args.opId);
      final alumno = alumnos.firstWhere(
        (a) => a['id'].toString() == args.alumnoId,
        orElse: () => const {},
      );
      if (!mounted) return;
      state = state.copyWith(
        cargando: false,
        preocupaSalud: _asBool(alumno['escuela_preocupa_salud']),
        preocupaDetalle: _asStr(alumno['escuela_preocupa_detalle']),
        dificultadLenguaje: _asBool(alumno['escuela_dificultad_lenguaje']),
        bajoTratamiento: _asBool(alumno['escuela_bajo_tratamiento']),
      );
    } catch (_) {
      if (!mounted) return;
      // Si falla la carga arrancamos vacío editable.
      state = state.copyWith(cargando: false);
    }
  }

  // --- Setters ---
  void setPreocupaSalud(bool v) =>
      state = state.copyWith(preocupaSalud: v, error: null);
  void setPreocupaDetalle(String v) =>
      state = state.copyWith(preocupaDetalle: v, error: null);
  void setDificultadLenguaje(bool v) =>
      state = state.copyWith(dificultadLenguaje: v, error: null);
  void setBajoTratamiento(bool v) =>
      state = state.copyWith(bajoTratamiento: v, error: null);

  Future<bool> guardar() async {
    state = state.copyWith(guardando: true, error: null);
    try {
      final payload = <String, dynamic>{
        'escuela_preocupa_salud': state.preocupaSalud,
        'escuela_preocupa_detalle': state.preocupaDetalle,
        'escuela_dificultad_lenguaje': state.dificultadLenguaje,
        'escuela_bajo_tratamiento': state.bajoTratamiento,
        'escuela_completado': true,
      };

      await repo.patchSeccionEscuela(args.opId, args.alumnoId, payload);
      if (!mounted) return true;
      state = state.copyWith(guardando: false);
      notificacionController.exito('Sección escuela guardada');
      return true;
    } on DioException catch (e) {
      if (!mounted) return false;
      final msg = _extractErrorMessage(e.response?.data) ??
          'No se pudo guardar la sección escuela.';
      state = state.copyWith(guardando: false, error: msg);
      notificacionController.error(msg);
      return false;
    } catch (_) {
      if (!mounted) return false;
      const msg = 'No se pudo guardar la sección escuela.';
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

final seccionEscuelaControllerProvider = StateNotifierProvider.autoDispose
    .family<SeccionEscuelaController, SeccionEscuelaState, SeccionEscuelaArgs>(
        (ref, args) {
  return SeccionEscuelaController(
    repo: ref.watch(operativosRepositoryProvider),
    args: args,
    notificacionController: ref.watch(notificacionProvider.notifier),
  );
});
