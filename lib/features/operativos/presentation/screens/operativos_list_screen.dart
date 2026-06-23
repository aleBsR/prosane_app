import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/design_system/app_card.dart';
import '../../../../core/design_system/app_gradient_scaffold.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../controllers/operativos_list_controller.dart';

class OperativosListScreen extends ConsumerWidget {
  const OperativosListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final operativosAsync = ref.watch(operativosListControllerProvider);

    return AppGradientScaffold(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            child: Row(
              children: [
                Expanded(
                  child: Text('Operativos',
                      style: AppTypography.titulo.copyWith(color: AppColors.blanco, fontSize: 24)),
                ),
              ],
            ),
          ),
          Expanded(
            child: operativosAsync.when(
              data: (operativos) {
                if (operativos.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.assignment_outlined, size: 64, color: AppColors.blanco.withValues(alpha: 0.3)),
                        const SizedBox(height: AppSpacing.md),
                        Text('No tenés operativos', style: AppTypography.subtitulo.copyWith(color: AppColors.blanco)),
                        const SizedBox(height: AppSpacing.sm),
                        Text('Creá uno para comenzar', style: AppTypography.texto.copyWith(color: AppColors.blanco.withValues(alpha: 0.7))),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  itemCount: operativos.length,
                  itemBuilder: (context, i) {
                    final op = operativos[i];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: GestureDetector(
                        onTap: () => context.push('/operativos/${op['id']}'),
                        child: AppCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(op['nombre'] ?? op['escuela']['nombre'] ?? 'Operativo',
                                            style: AppTypography.subtitulo, maxLines: 1, overflow: TextOverflow.ellipsis),
                                        const SizedBox(height: 4),
                                        Text('${op['fecha']} • ${op['lugar_realizacion']}',
                                            style: AppTypography.texto.copyWith(fontSize: 12, color: AppColors.texto.withValues(alpha: 0.6))),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: _colorEstado(op['estado']),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(_labelEstado(op['estado']),
                                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.blanco)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              Row(
                                children: [
                                  Icon(Icons.people_outline, size: 16, color: AppColors.texto.withValues(alpha: 0.6)),
                                  const SizedBox(width: 4),
                                  Text('${op['cantidad_profesionales'] ?? 0} profesionales', style: const TextStyle(fontSize: 12)),
                                  const SizedBox(width: AppSpacing.md),
                                  Icon(Icons.person_outline, size: 16, color: AppColors.texto.withValues(alpha: 0.6)),
                                  const SizedBox(width: 4),
                                  Text('${op['cantidad_alumnos'] ?? 0} alumnos', style: const TextStyle(fontSize: 12)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
    );
  }

  Color _colorEstado(String estado) {
    switch (estado) {
      case 'borrador':
        return AppColors.gris;
      case 'confirmado':
        return Colors.blue;
      case 'en_curso':
        return Colors.orange;
      case 'finalizado':
        return Colors.green;
      case 'cancelado':
        return Colors.red;
      default:
        return AppColors.gris;
    }
  }

  String _labelEstado(String estado) {
    switch (estado) {
      case 'borrador':
        return 'Borrador';
      case 'confirmado':
        return 'Confirmado';
      case 'en_curso':
        return 'En curso';
      case 'finalizado':
        return 'Finalizado';
      case 'cancelado':
        return 'Cancelado';
      default:
        return estado;
    }
  }
}
