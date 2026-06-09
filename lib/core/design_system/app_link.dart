import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

class AppLink extends StatelessWidget {
  const AppLink({super.key, required this.text, required this.onTap});
  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Text(text, style: AppTypography.texto.copyWith(color: AppColors.link, fontWeight: FontWeight.w600)),
      );
}
