import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers.dart';
import '../../data/escuelas_repository.dart';

class CursosListState {
  final bool guardando;
  final String? error;

  CursosListState({this.guardando = false, this.error});
}

class CursosController extends StateNotifier<CursosListState> {
  final EscuelasRepository _repo;
  final String escuelaId;

  CursosController(this._repo, this.escuelaId) : super(CursosListState());

  Future<bool> crear({
    required String grado,
    required String division,
    int? cicloLectivo,
  }) async {
    if (grado.isEmpty || division.isEmpty) return false;
    return _ejecutar(() => _repo.crearCurso(
          escuelaId,
          {'sala_grado_anio': grado, 'division': division, 'ciclo_lectivo': ?cicloLectivo},
        ));
  }

  Future<bool> editar({
    required String cursoId,
    required String grado,
    required String division,
    int? cicloLectivo,
  }) async {
    if (grado.isEmpty || division.isEmpty) return false;
    return _ejecutar(() => _repo.editarCurso(
          escuelaId,
          cursoId,
          {'sala_grado_anio': grado, 'division': division, 'ciclo_lectivo': ?cicloLectivo},
        ));
  }

  Future<bool> eliminar(String cursoId) async {
    return _ejecutar(() => _repo.eliminarCurso(escuelaId, cursoId));
  }

  Future<bool> _ejecutar(Future<void> Function() accion) async {
    if (state.guardando) return false;
    state = CursosListState(guardando: true);
    try {
      await accion();
      state = CursosListState();
      return true;
    } catch (e) {
      state = CursosListState(error: e.toString());
      return false;
    }
  }
}

final cursosProvider = FutureProvider.family<List<Curso>, String>((ref, escuelaId) async {
  final repo = ref.watch(escuelasRepositoryProvider);
  return repo.listarCursos(escuelaId);
});

final cursosControllerProvider =
    StateNotifierProvider.family<CursosController, CursosListState, String>(
  (ref, escuelaId) => CursosController(
    ref.watch(escuelasRepositoryProvider),
    escuelaId,
  ),
);
