import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/design_system/app_card.dart';
import '../../../core/design_system/app_gradient_scaffold.dart';
import '../../../core/session/inactividad_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

/// Hub de configuración: botones a "Datos personales" y "Cambiar contraseña"
/// (antes todo se mostraba junto en esta pantalla).
class ConfiguracionScreen extends ConsumerWidget {
  const ConfiguracionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppGradientScaffold(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            child: Row(children: [
              IconButton(
                icon:  Icon(Icons.arrow_back, color: AppColors.blanco),
                onPressed: () => context.pop(),
              ),
              Expanded(
                child: Text('Configuración',
                    style: AppTypography.titulo.copyWith(color: AppColors.blanco, fontSize: 22)),
              ),
            ]),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                _OpcionCard(
                  icon: Icons.person_outline,
                  titulo: 'Datos personales',
                  subtitulo: 'Actualizá tu nombre y apellido',
                  onTap: () => context.push('/usuario/configuracion/datos'),
                ),
                const SizedBox(height: AppSpacing.md),
                _OpcionCard(
                  icon: Icons.lock_outline,
                  titulo: 'Cambiar contraseña',
                  subtitulo: 'Usá tu contraseña actual para confirmar el cambio',
                  onTap: () => context.push('/usuario/configuracion/password'),
                ),
                const SizedBox(height: AppSpacing.md),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('Cierre por inactividad',
                          style: AppTypography.subtitulo),
                      const SizedBox(height: 4),
                      Text(
                        'La sesión se cierra sola tras este tiempo sin usar la app',
                        style: AppTypography.texto.copyWith(
                          fontSize: 12,
                          color: AppColors.texto.withValues(alpha: 0.6),
                        ),
                      ),
                      const SizedBox(height: 8),
                      _TimeoutChips(),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('Acerca de', style: AppTypography.subtitulo),
                      const SizedBox(height: 4),
                      Text('PROSANE Salta — v1.0.0', style: AppTypography.texto.copyWith(fontSize: 12, color: AppColors.texto.withValues(alpha: 0.6))),
                      const SizedBox(height: 2),
                      Text('Si necesitás ayuda contactá a soporte.', style: AppTypography.texto.copyWith(fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OpcionCard extends StatelessWidget {  const _OpcionCard({
    required this.icon,
    required this.titulo,
    required this.subtitulo,
    required this.onTap,
  });

  final IconData icon;
  final String titulo;
  final String subtitulo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.primario.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.primario, size: 28),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(titulo, style: AppTypography.subtitulo),
                    const SizedBox(height: 4),
                    Text(
                      subtitulo,
                      style: AppTypography.texto.copyWith(
                        fontSize: 12,
                        color: AppColors.texto.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Selector del timeout de inactividad (5/15/30/60 min).
class _TimeoutChips extends ConsumerWidget {
  const _TimeoutChips();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final actual = ref.watch(timeoutMinProvider);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final min in TimeoutController.opciones)
          ChoiceChip(
            label: Text('$min min'),
            selected: actual == min,
            onSelected: (_) =>
                ref.read(timeoutMinProvider.notifier).fijar(min),
          ),
      ],
    );
  }
}
