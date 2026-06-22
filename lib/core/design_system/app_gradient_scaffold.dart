import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class AppGradientScaffold extends StatelessWidget {
  const AppGradientScaffold({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Scaffold(
        // Tocar fuera de un input cierra el teclado. translucent: el gesto se
        // detecta en el fondo vacío sin robarle taps a los hijos (botones, campos).
        body: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () => FocusScope.of(context).unfocus(),
          child: Container(
            decoration: const BoxDecoration(gradient: AppColors.gradienteFondo),
            child: SafeArea(child: child),
          ),
        ),
      );
}
