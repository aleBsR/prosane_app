import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers.dart';
import '../../data/operativos_repository.dart';
import '../../data/escuelas_repository.dart';

class OperativoCreateState {
  const OperativoCreateState({
    this.nombre,
    this.escuelaId,
    this.fecha,
    this.lugar,
    this.notas,
    this.escuelasAsync = const AsyncValue.loading(),
    this.guardando = false,
    this.exito = false,
    this.error,
    this.operativoId,
  });

  final String? nombre;
  final String? escuelaId;
  final DateTime? fecha;
  final String? lugar;
  final String? notas;
  final AsyncValue<List<Escuela>> escuelasAsync;
  final bool guardando, exito;
  final String? error;
  final String? operativoId;

  bool get puedeGuardar => escuelaId != null && escuelaId!.isNotEmpty && fecha != null && lugar != null;

  OperativoCreateState copyWith({
    String? nombre,
    String? escuelaId,
    DateTime? fecha,
    String? lugar,
    String? notas,
    AsyncValue<List<Escuela>>? escuelasAsync,
    bool? guardando,
    bool? exito,
    Object? error = _sentinel,
    String? operativoId,
  }) =>
      OperativoCreateState(
        nombre: nombre ?? this.nombre,
        escuelaId: escuelaId ?? this.escuelaId,
        fecha: fecha ?? this.fecha,
        lugar: lugar ?? this.lugar,
        notas: notas ?? this.notas,
        escuelasAsync: escuelasAsync ?? this.escuelasAsync,
        guardando: guardando ?? this.guardando,
        exito: exito ?? this.exito,
        error: identical(error, _sentinel) ? this.error : error as String?,
        operativoId: operativoId ?? this.operativoId,
      );
}

const _sentinel = Object();

class OperativoCreateController extends StateNotifier<OperativoCreateState> {
  OperativoCreateController({required this.repo, required this.escuelasRepo}) : super(const OperativoCreateState()) {
    _cargarEscuelas();
  }

  final OperativosRepository repo;
  final EscuelasRepository escuelasRepo;

  void _cargarEscuelas() async {
    state = state.copyWith(escuelasAsync: const AsyncValue.loading());
    try {
      final escuelas = await escuelasRepo.listar();
      if (!mounted) return;
      state = state.copyWith(escuelasAsync: AsyncValue.data(escuelas));
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(escuelasAsync: AsyncValue.error(e, StackTrace.current));
    }
  }

  void setNombre(String v) => state = state.copyWith(nombre: v);
  void setEscuela(String? v) => state = state.copyWith(escuelaId: v);
  void setFecha(DateTime v) => state = state.copyWith(fecha: v);
  void setLugar(String? v) => state = state.copyWith(lugar: v);
  void setNotas(String v) => state = state.copyWith(notas: v);

  Future<void> guardar() async {
    if (!state.puedeGuardar) return;
    state = state.copyWith(guardando: true, error: null);
    try {
      final datos = {
        'nombre': state.nombre,
        'escuela': state.escuelaId,
        'fecha': state.fecha?.toIso8601String(),
        'lugar_realizacion': state.lugar,
        'notas': state.notas,
      };
      final resultado = await repo.crear(datos);
      if (!mounted) return;
      state = state.copyWith(
        guardando: false,
        exito: true,
        operativoId: resultado['id'] as String?,
      );
    } catch (_) {
      if (!mounted) return;
      state = state.copyWith(
        guardando: false,
        error: 'No se pudo crear el operativo. Probá de nuevo.',
      );
    }
  }
}

final operativoCreateControllerProvider =
    StateNotifierProvider.autoDispose<OperativoCreateController, OperativoCreateState>((ref) {
  return OperativoCreateController(
    repo: ref.watch(operativosRepositoryProvider),
    escuelasRepo: ref.watch(escuelasRepositoryProvider),
  );
});
