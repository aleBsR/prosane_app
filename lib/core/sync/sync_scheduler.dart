import 'dart:async';

/// Decide cuándo correr un ciclo de sync: al recuperar conexión y tras cada
/// escritura local. Debounce para coalescer ráfagas.
class SyncScheduler {
  SyncScheduler({
    required this.onlineStream,
    required this.ejecutarCiclo,
    this.debounce = const Duration(seconds: 2),
  });

  final Stream<bool> onlineStream;
  final Future<void> Function() ejecutarCiclo;
  final Duration debounce;

  Timer? _timer;
  StreamSubscription<bool>? _sub;

  void iniciar() {
    _sub = onlineStream.where((online) => online).listen((_) => _agendar());
  }

  /// Llamar tras una escritura local para empujar pendientes cuando convenga.
  void dispararPorEscritura() => _agendar();

  void _agendar() {
    _timer?.cancel();
    _timer = Timer(debounce, ejecutarCiclo);
  }

  void dispose() {
    _timer?.cancel();
    _sub?.cancel();
  }
}
