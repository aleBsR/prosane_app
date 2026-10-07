import 'package:flutter/material.dart';

/// Paleta PROSANE (espejo de index.css en la web).
///
/// Los colores se resuelven según [brillo]: en modo claro devuelven los
/// valores históricos; en modo oscuro la variante dark. La app fija [brillo]
/// al construir [ProsaneApp] según el [ThemeMode] activo, y como el cambio
/// de tema reconstruye todo el árbol, los 300+ usos existentes se adaptan
/// sin tocar cada pantalla.
class AppColors {
  /// Brillo efectivo actual. Lo fija la app al construir el MaterialApp.
  static Brightness brillo = Brightness.light;
  static bool get oscuro => brillo == Brightness.dark;

  static Color get primario => const Color(0xFF7C5CFC);
  // Fondo general de la app (antes degradado): un solo tono fijo.
  static Color get fondoApp =>
      oscuro ? const Color(0xFF251C50) : const Color(0xFF7B5BE0);
  // Rojo fijo para botones de error (antes degradado).
  static Color get errorBoton => const Color(0xFFC0392B);
  static Color get campo =>
      oscuro ? const Color(0xFF262633) : const Color(0xFFF1F0F5);
  static Color get error =>
      oscuro ? const Color(0xFFE57373) : const Color(0xFFC0392B);
  static Color get texto =>
      oscuro ? const Color(0xFFECEAF4) : const Color(0xFF2D2D3A);
  static Color get link =>
      oscuro ? const Color(0xFFB39DF5) : const Color(0xFF6C4DE0);
  static Color get blanco =>
      oscuro ? const Color(0xFF1E1E2A) : const Color(0xFFFFFFFF);
  static Color get gris => const Color(0xFF9CA3AF);
  static Color get fondo =>
      oscuro ? const Color(0xFF14141D) : const Color(0xFFFFFFFF);
  // Semánticos de estado (textos chicos, íconos, píldoras): en oscuro se
  // aclaran para no "borrarse" sobre las superficies dark.
  static Color get ok =>
      oscuro ? const Color(0xFF81C784) : const Color(0xFF2E7D32);
  static Color get okFondo =>
      oscuro ? const Color(0xFF1D2B1F) : const Color(0xFFE8F5E9);
  static Color get aviso =>
      oscuro ? const Color(0xFFFFB74D) : const Color(0xFFE65100);
  static Color get avisoFondo =>
      oscuro ? const Color(0xFF2E2318) : const Color(0xFFFFF3E0);
  static Color get info =>
      oscuro ? const Color(0xFF64B5F6) : const Color(0xFF1976D2);
  static Color get errorTexto =>
      oscuro ? const Color(0xFFE57373) : const Color(0xFFD32F2F);
}
