import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class AppGradientScaffold extends StatelessWidget {
  const AppGradientScaffold({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Container(
          decoration: const BoxDecoration(gradient: AppColors.gradienteFondo),
          child: SafeArea(child: child),
        ),
      );
}
