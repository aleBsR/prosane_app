import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_radii.dart';

class PostChipCustom extends StatelessWidget {
  const PostChipCustom({
    super.key,
    required this.texto,
    required this.completado,
  });

  final String texto;
  final bool completado;

  @override
  Widget build(BuildContext context) {
    final color = completado ? Colors.green : AppColors.gris;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppRadii.boton),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        texto,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: completado ? Colors.green.shade700 : AppColors.texto.withValues(alpha: 0.7),
        ),
      ),
    );
  }
}
