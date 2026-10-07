import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/design_system/app_card.dart';
import '../../../../core/design_system/app_gradient_scaffold.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../controllers/escuelas_list_controller.dart';

class EscuelasListScreen extends ConsumerWidget {
  const EscuelasListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final escuelasAsync = ref.watch(escuelasListControllerProvider);

    return AppGradientScaffold(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            child: Row(
              children: [
                IconButton(
                  icon:  Icon(Icons.arrow_back, color: AppColors.blanco),
                  onPressed: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go('/inicio');
                    }
                  },
                ),
                Expanded(
                  child: Text('Escuelas',
                      style: AppTypography.titulo.copyWith(
                          color: AppColors.blanco, fontSize: 24)),
                ),
              ],
            ),
          ),
          Expanded(
            child: escuelasAsync.when(
              data: (escuelas) {
                if (escuelas.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.school_outlined,
                            size: 64,
                            color: AppColors.blanco.withValues(alpha: 0.3)),
                        const SizedBox(height: AppSpacing.md),
                        Text('No hay escuelas registradas',
                            style: AppTypography.subtitulo
                                .copyWith(color: AppColors.blanco)),
                        const SizedBox(height: AppSpacing.sm),
                        Text('Creá una para comenzar',
                            style: AppTypography.texto.copyWith(
                                color:
                                    AppColors.blanco.withValues(alpha: 0.7))),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  itemCount: escuelas.length,
                  itemBuilder: (context, i) {
                    final e = escuelas[i];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: AppCard(
                        child: InkWell(
                          onTap: () => context.push('/escuelas/${e.id}'),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(e.nombre,
                                  style: AppTypography.subtitulo,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 4),
                              Text(
                                [
                                  if (e.cue != null && e.cue!.isNotEmpty)
                                    'CUE ${e.cue}',
                                  if (e.localidad != null &&
                                      e.localidad!.isNotEmpty)
                                    e.localidad!,
                                ].join(' • '),
                                style: AppTypography.texto.copyWith(
                                    fontSize: 12,
                                    color: AppColors.texto
                                        .withValues(alpha: 0.6)),
                              ),
                              Builder(builder: (context) {
                                // Solo cuentan los usuarios activos: con todos
                                // inactivos la escuela queda sin acceso.
                                final asociados = e.usuariosAsociados
                                    .where((u) => u['is_active'] != false)
                                    .toList();
                                if (asociados.isEmpty) {
                                  return Container(
                                    margin: const EdgeInsets.only(top: 6),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppColors.aviso.withValues(
                                          alpha: 0.15),
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                          color: AppColors.aviso.withValues(
                                              alpha: 0.4)),
                                    ),
                                    child: Text(
                                      'Sin usuario asociado',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.aviso,
                                      ),
                                    ),
                                  );
                                }
                                final texto = asociados.map((u) {
                                  final nombre =
                                      (u['nombre'] ?? '').toString();
                                  final email =
                                      (u['email'] ?? '').toString();
                                  return nombre.trim().isNotEmpty
                                      ? nombre.trim()
                                      : email;
                                }).join(' • ');
                                return Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    'Usuario: $texto',
                                    style: AppTypography.texto.copyWith(
                                        fontSize: 12,
                                        color: AppColors.texto
                                            .withValues(alpha: 0.6)),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                );
                              }),
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

}
