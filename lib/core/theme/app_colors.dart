import 'package:flutter/material.dart';

class AppColors {
  static const primario = Color(0xFF7C5CFC);
  static const gradienteFondoInicio = Color(0xFF9B7DF0);
  static const gradienteFondoFin = Color(0xFF7B5BE0);
  static const campo = Color(0xFFF1F0F5);
  static const error = Color(0xFFC0392B);
  static const texto = Color(0xFF2D2D3A);
  static const link = Color(0xFF6C4DE0);
  static const blanco = Color(0xFFFFFFFF);

  static const gradienteFondo = LinearGradient(
    begin: Alignment.topCenter, end: Alignment.bottomCenter,
    colors: [gradienteFondoInicio, gradienteFondoFin],
  );
}
