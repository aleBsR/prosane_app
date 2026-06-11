import 'package:flutter/material.dart';
import '../theme/app_typography.dart';

/// Estado vacío reutilizable (Acciones sin rol, Pendientes "todo sincronizado").
class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.icon, required this.titulo, this.subtitulo});
  final IconData icon;
  final String titulo;
  final String? subtitulo;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: Colors.white.withValues(alpha: 0.85)),
            const SizedBox(height: 16),
            Text(
              titulo,
              textAlign: TextAlign.center,
              style: AppTypography.titulo.copyWith(fontSize: 18, color: Colors.white),
            ),
            if (subtitulo != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitulo!,
                textAlign: TextAlign.center,
                style: AppTypography.texto.copyWith(color: Colors.white.withValues(alpha: 0.85)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
