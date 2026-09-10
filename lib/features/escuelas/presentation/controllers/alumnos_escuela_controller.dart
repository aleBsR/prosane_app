import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers.dart';
import '../../data/alumnos_escuela_repository.dart';

final alumnosEscuelaProvider = FutureProvider<List<AlumnoEscuela>>((ref) async {
  return ref.watch(alumnosEscuelaRepositoryProvider).listar();
});

/// Alumnos de una escuela puntual (detalle de escuela, solo lectura).
final alumnosPorEscuelaProvider =
    FutureProvider.family<List<AlumnoEscuela>, String>((ref, escuelaId) async {
  return ref.watch(alumnosEscuelaRepositoryProvider).listarPorEscuela(escuelaId);
});

class AlumnosEscuelaState {
  const AlumnosEscuelaState({this.guardando = false, this.error});
  final bool guardando;
  final String? error;
}

class AlumnosEscuelaController extends StateNotifier<AlumnosEscuelaState> {
  AlumnosEscuelaController(this._repo) : super(const AlumnosEscuelaState());
  final AlumnosEscuelaRepository _repo;

  Future<bool> crear(Map<String, dynamic> payload) async {
    if (state.guardando) return false;
    state = const AlumnosEscuelaState(guardando: true);
    try {
      await _repo.crear(payload);
      state = const AlumnosEscuelaState();
      return true;
    } catch (e) {
      state = AlumnosEscuelaState(error: e.toString());
      return false;
    }
  }

  Future<bool> actualizarAntecedentes(String alumnoId, Map<String, dynamic> payload) async {
    if (state.guardando) return false;
    state = const AlumnosEscuelaState(guardando: true);
    try {
      await _repo.patchAntecedentes(alumnoId, payload);
      state = const AlumnosEscuelaState();
      return true;
    } catch (e) {
      state = AlumnosEscuelaState(error: e.toString());
      return false;
    }
  }
}

final alumnosEscuelaControllerProvider =
    StateNotifierProvider<AlumnosEscuelaController, AlumnosEscuelaState>(
  (ref) => AlumnosEscuelaController(
    ref.watch(alumnosEscuelaRepositoryProvider),
  ),
);
