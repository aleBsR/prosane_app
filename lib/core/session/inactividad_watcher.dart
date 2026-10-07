import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers.dart';
import 'entities.dart';
import 'inactividad_controller.dart';
import 'session_controller.dart';

/// Cierra la sesión tras N minutos sin interacción (Anexo I).
/// Se monta una vez sobre toda la app: cualquier toque/tecla reinicia el
/// conteo. Al volver de segundo plano, si pasó el timeout también cierra.
class InactividadWatcher extends ConsumerStatefulWidget {
  const InactividadWatcher({super.key, required this.child});
  final Widget child;

  @override
  ConsumerState<InactividadWatcher> createState() =>
      _InactividadWatcherState();
}

class _InactividadWatcherState extends ConsumerState<InactividadWatcher>
    with WidgetsBindingObserver {
  Timer? _timer;
  DateTime _ultimaActividad = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _reiniciar();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      final minutos = ref.read(timeoutMinProvider);
      if (DateTime.now().difference(_ultimaActividad) >=
          Duration(minutes: minutos)) {
        _vencer();
      } else {
        _reiniciar();
      }
    }
  }

  void _actividad() {
    _ultimaActividad = DateTime.now();
    _reiniciar();
  }

  void _reiniciar() {
    _timer?.cancel();
    final minutos = ref.read(timeoutMinProvider);
    _timer = Timer(Duration(minutes: minutos), _vencer);
  }

  Future<void> _vencer() async {
    final sesion = ref.read(sessionControllerProvider);
    if (sesion is! SesionAutenticada) return;
    try {
      await ref.read(logoutProvider)();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    // Si cambia el ajuste, el próximo toque usa el nuevo timeout;
    // además se reinicia acá para aplicarlo de inmediato.
    ref.listen<int>(timeoutMinProvider, (_, _) => _reiniciar());
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => _actividad(),
      onPointerSignal: (_) => _actividad(),
      child: widget.child,
    );
  }
}
