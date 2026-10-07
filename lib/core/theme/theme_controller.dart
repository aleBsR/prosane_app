import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Modo claro/oscuro elegido por el usuario (espejo del toggle web).
/// Se persiste en SharedPreferences ('prosane_tema': 'claro' | 'oscuro').
/// Sin preferencia guardada se usa el brillo del sistema al arrancar.
final themeModeProvider =
    StateNotifierProvider<ThemeController, ThemeMode>((ref) {
      return ThemeController();
    });

class ThemeController extends StateNotifier<ThemeMode> {
  ThemeController() : super(_inicial()) {
    _cargar();
  }

  static ThemeMode _inicial() {
    final platform =
        WidgetsBinding.instance.platformDispatcher.platformBrightness;
    return platform == Brightness.dark ? ThemeMode.dark : ThemeMode.light;
  }

  Future<void> _cargar() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final guardado = prefs.getString('prosane_tema');
      if (guardado == 'oscuro') {
        state = ThemeMode.dark;
      } else if (guardado == 'claro') {
        state = ThemeMode.light;
      }
    } catch (_) {
      // Sin persistencia se mantiene el brillo del sistema.
    }
  }

  Future<void> fijar(ThemeMode modo) async {
    state = modo;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'prosane_tema',
        modo == ThemeMode.dark ? 'oscuro' : 'claro',
      );
    } catch (_) {}
  }

  Future<void> alternar() =>
      fijar(state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark);
}
