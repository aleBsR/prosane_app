import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/design_system/app_card.dart';
import '../../../../core/design_system/app_gradient_scaffold.dart';
import '../../../../core/session/permission_gate.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

class GestionUsuariosScreen extends ConsumerWidget {
  const GestionUsuariosScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppGradientScaffold(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: AppColors.blanco),
                  onPressed: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go('/inicio');
                    }
                  },
                ),
                Expanded(
                  child: Text('Gestión de usuarios',
                      style: AppTypography.titulo.copyWith(
                          color: AppColors.blanco, fontSize: 24)),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                PermissionGate(
                  permiso: 'gestionarUsuariosEscuela',
                  child: _OpcionCard(
                    icon: Icons.school_outlined,
                    titulo: 'Usuarios de escuelas',
                    subtitulo: 'Asignar escuelas y gestionar cuentas de escuela',
                    onTap: () => context.push('/usuarios-escuela'),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                PermissionGate(
                  permiso: 'gestionarAyudantes',
                  child: _OpcionCard(
                    icon: Icons.support_agent_outlined,
                    titulo: 'Ayudantes',
                    subtitulo: 'Crear y gestionar usuarios ayudantes',
                    onTap: () => context.push('/usuarios-ayudantes'),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                PermissionGate(
                  permiso: 'gestionarProfesionales',
                  child: _OpcionCard(
                    icon: Icons.medical_services_outlined,
                    titulo: 'Profesionales',
                    subtitulo: 'Médicos y odontólogos del sistema',
                    onTap: () => context.push('/profesionales'),
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

class _OpcionCard extends StatelessWidget {
  const _OpcionCard({
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
              const Icon(Icons.chevron_right, color: AppColors.texto),
            ],
          ),
        ),
      ),
    );
  }
}