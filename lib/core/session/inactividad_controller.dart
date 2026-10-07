import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Minutos de inactividad antes de cerrar la sesión (Anexo I: cierre por
/// inactividad). Persistido en SharedPreferences ('prosane_timeout_min').
/// Default 30.
final timeoutMinProvider =
    StateNotifierProvider<TimeoutController, int>((ref) {
      return TimeoutController();
    });

class TimeoutController extends StateNotifier<int> {
  TimeoutController() : super(30) {
    _cargar();
  }

  static const opciones = [5, 15, 30, 60];

  Future<void> _cargar() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final guardado = prefs.getInt('prosane_timeout_min');
      if (guardado != null && opciones.contains(guardado)) {
        state = guardado;
      }
    } catch (_) {}
  }

  Future<void> fijar(int minutos) async {
    if (!opciones.contains(minutos)) return;
    state = minutos;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('prosane_timeout_min', minutos);
    } catch (_) {}
  }
}
