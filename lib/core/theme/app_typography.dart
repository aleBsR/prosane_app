import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Tipografías PROSANE. Son getters (no const) porque los colores dependen
/// del brillo actual ([AppColors.brillo]).
class AppTypography {
  static TextStyle get titulo => const TextStyle(
    fontFamily: 'Nunito',
    fontWeight: FontWeight.w900,
    fontSize: 28,
  ).copyWith(color: AppColors.primario);
  static TextStyle get subtitulo => const TextStyle(
    fontFamily: 'Rubik',
    fontWeight: FontWeight.w600,
    fontSize: 16,
  ).copyWith(color: AppColors.texto);
  static TextStyle get campo => const TextStyle(
    fontFamily: 'Rubik',
    fontWeight: FontWeight.w400,
    fontSize: 15,
  ).copyWith(color: AppColors.texto);
  static TextStyle get texto => const TextStyle(
    fontFamily: 'Rubik',
    fontWeight: FontWeight.w400,
    fontSize: 13,
  ).copyWith(color: AppColors.texto);
  static TextStyle get boton => const TextStyle(
    fontFamily: 'Rubik',
    fontWeight: FontWeight.w600,
    fontSize: 15,
  ).copyWith(color: Colors.white);
}
