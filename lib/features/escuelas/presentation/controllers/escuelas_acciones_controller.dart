import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers.dart';
import '../../data/escuelas_repository.dart';

class EscuelasAccionesState {
  final bool guardando;
  final String? error;

  EscuelasAccionesState({this.guardando = false, this.error});
}

class EscuelasAccionesController extends StateNotifier<EscuelasAccionesState> {
  final EscuelasRepository _repo;

  EscuelasAccionesController(this._repo) : super(EscuelasAccionesState());

  Future<Escuela?> obtener(String id) async {
    try {
      return await _repo.obtener(id);
    } catch (e) {
      state = EscuelasAccionesState(error: e.toString());
      return null;
    }
  }

  Future<bool> editar(String id, Map<String, dynamic> payload) async {
    return _ejecutar(() => _repo.editar(id, payload));
  }

  Future<bool> eliminar(String id) async {
    return _ejecutar(() => _repo.eliminar(id));
  }

  Future<bool> _ejecutar(Future<void> Function() accion) async {
    if (state.guardando) return false;
    state = EscuelasAccionesState(guardando: true);
    try {
      await accion();
      state = EscuelasAccionesState();
      return true;
    } catch (e) {
      state = EscuelasAccionesState(
        error: e.toString().contains('409')
            ? 'CUE duplicado'
            : 'Error: ${e.toString()}',
      );
      return false;
    }
  }
}

final escuelasAccionesControllerProvider =
    StateNotifierProvider<EscuelasAccionesController, EscuelasAccionesState>(
  (ref) => EscuelasAccionesController(ref.watch(escuelasRepositoryProvider)),
);