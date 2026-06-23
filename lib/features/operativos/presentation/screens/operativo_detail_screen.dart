import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/design_system/app_button.dart';
import '../../../../core/design_system/app_card.dart';
import '../../../../core/design_system/app_gradient_scaffold.dart';
import '../../../../core/notificaciones/notificacion_controller.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../controllers/operativo_detail_controller.dart';

class OperativoDetailScreen extends ConsumerStatefulWidget {
  const OperativoDetailScreen({super.key, required this.operativoId});
  final String operativoId;

  @override
  ConsumerState<OperativoDetailScreen> createState() => _OperativoDetailScreenState();
}

class _OperativoDetailScreenState extends ConsumerState<OperativoDetailScreen> {
  bool _importandoCsv = false;

  @override
  Widget build(BuildContext context) {
    final operativoAsync = ref.watch(operativoDetailProvider(widget.operativoId));
    final ctrl = ref.read(operativoDetailControllerProvider(widget.operativoId).notifier);

    ref.listen(operativoDetailControllerProvider(widget.operativoId), (prev, next) {
      if (next.operativoActualizado && !(prev?.operativoActualizado ?? false)) {
        ref.read(notificacionProvider.notifier).exito('¡Operativo actualizado!');
      }
      if (next.error != null && next.error != prev?.error) {
        ref.read(notificacionProvider.notifier).error(next.error!);
      }
    });

    // Escucha cambios de estado de importación
    ref.listen(operativoDetailControllerProvider(widget.operativoId), (prev, next) {
      if (prev?.procesando == true && next.procesando == false) {
        setState(() => _importandoCsv = false);
      }
    });

    return AppGradientScaffold(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            child: Row(children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: AppColors.blanco),
                onPressed: () => context.pop(),
              ),
              Expanded(
                child: Text('Detalle del operativo',
                    style: AppTypography.titulo.copyWith(color: AppColors.blanco, fontSize: 22)),
              ),
            ]),
          ),
          Expanded(
            child: operativoAsync.when(
              data: (op) => SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${op['nombre'] ?? op['escuela']['nombre'] ?? 'Operativo'}',
                              style: AppTypography.subtitulo),
                          const SizedBox(height: 8),
                          Text('${op['fecha']} • ${op['lugar_realizacion']}',
                              style: AppTypography.texto.copyWith(fontSize: 12, color: AppColors.texto.withValues(alpha: 0.6))),
                          const SizedBox(height: AppSpacing.md),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: _colorEstado(op['estado']),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(_labelEstado(op['estado']),
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.blanco)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    // Botones de acción según estado
                    ..._botonesPorEstado(op['estado'], ctrl),
                    const SizedBox(height: AppSpacing.md),
                    // Profesionales
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Profesionales (${op['profesionales_asignados']?.length ?? 0})',
                              style: AppTypography.subtitulo),
                          if ((op['profesionales_asignados'] as List?)?.isEmpty ?? true)
                            Padding(
                              padding: const EdgeInsets.only(top: AppSpacing.md),
                              child: Text('Sin profesionales asignados',
                                  style: AppTypography.texto.copyWith(color: AppColors.texto.withValues(alpha: 0.6))),
                            )
                          else
                            ...(op['profesionales_asignados'] as List).map((p) => Padding(
                              padding: const EdgeInsets.only(top: AppSpacing.sm),
                              child: Text('${p['profesional_nombre']} ${p['profesional_apellido']} (${p['rol_en_operativo']})',
                                  style: AppTypography.texto),
                            )),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    // Alumnos
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Alumnos (${op['alumnos_count'] ?? 0})',
                              style: AppTypography.subtitulo),
                          const SizedBox(height: AppSpacing.md),
                          Text('Importar nómina desde CSV', style: AppTypography.texto),
                          const SizedBox(height: AppSpacing.md),
                          Stack(
                            children: [
                              AppButton(
                                label: 'Seleccionar archivo CSV',
                                onPressed: _importandoCsv ? null : () => _importarCsv(context),
                              ),
                              if (_importandoCsv)
                                Positioned.fill(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: AppColors.gris.withValues(alpha: 0.5),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Center(
                                      child: SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.blanco),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _botonesPorEstado(String estado, OperativoDetailController ctrl) {
    switch (estado) {
      case 'borrador':
        return [
          AppCard(child: AppButton(label: 'Confirmar operativo', onPressed: ctrl.confirmar)),
        ];
      case 'confirmado':
        return [
          Row(
            children: [
              Expanded(child: AppCard(child: AppButton(label: 'Iniciar', onPressed: ctrl.iniciar))),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: AppCard(child: AppButton(label: 'Cancelar', onPressed: ctrl.cancelar))),
            ],
          ),
        ];
      case 'en_curso':
        return [
          Row(
            children: [
              Expanded(child: AppCard(child: AppButton(label: 'Finalizar', onPressed: ctrl.finalizar))),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: AppCard(child: AppButton(label: 'Cancelar', onPressed: ctrl.cancelar))),
            ],
          ),
        ];
      default:
        return [];
    }
  }

  Future<void> _importarCsv(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );

    if (result == null || result.files.isEmpty) return;

    final path = result.files.single.path;
    if (path == null) return;

    final file = File(path);
    if (!await file.exists()) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Archivo no encontrado')),
        );
      }
      return;
    }

    setState(() => _importandoCsv = true);

    final ctrl = ref.read(operativoDetailControllerProvider(widget.operativoId).notifier);
    await ctrl.importarCsv(file);
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
