import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

class AppLink extends StatelessWidget {
  const AppLink({
    super.key,
    required this.text,
    required this.onTap,
    this.expand = false,
    this.textAlign,
  });
  final String text;
  final VoidCallback onTap;

  /// Si es true, el área tappable ocupa todo el ancho disponible.
  final bool expand;

  /// Alineación del texto (útil con [expand], p. ej. centrado a todo el ancho).
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    final label = Text(
      text,
      textAlign: textAlign,
      style: AppTypography.texto.copyWith(color: AppColors.link, fontWeight: FontWeight.w600),
    );
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque, // todo el área es tappable, no solo el texto
      child: expand ? SizedBox(width: double.infinity, child: label) : label,
    );
  }
}
