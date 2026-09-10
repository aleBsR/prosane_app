import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_typography.dart';

class AppTheme {
  static ThemeData light() {
    final base = ThemeData.light(useMaterial3: true);
    return base.copyWith(
      colorScheme: base.colorScheme.copyWith(primary: AppColors.primario),
      textTheme: base.textTheme.apply(fontFamily: 'Rubik', bodyColor: AppColors.texto).copyWith(
        titleLarge: AppTypography.titulo,
        titleMedium: AppTypography.subtitulo,
        bodyLarge: AppTypography.campo,
        bodyMedium: AppTypography.texto,
      ),
      scaffoldBackgroundColor: AppColors.blanco,
      // Diálogos del mismo blanco que las tarjetas: sin el gris-lavanda
      // ni el tinte primario que Material 3 aplica por defecto.
      dialogTheme: const DialogThemeData(
        backgroundColor: AppColors.blanco,
        surfaceTintColor: Colors.transparent,
      ),
    );
  }
}
