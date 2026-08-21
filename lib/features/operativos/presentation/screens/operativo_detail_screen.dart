import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/design_system/app_button.dart';
import '../../../../core/design_system/app_card.dart';
import '../../../../core/design_system/app_gradient_scaffold.dart';
import '../../../../core/notificaciones/notificacion_controller.dart';
import '../../../../core/session/entities.dart';
import '../../../../core/session/session_controller.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../pendientes/pendientes_count_provider.dart';
import '../controllers/operativo_detail_controller.dart';
import '../controllers/operativos_list_controller.dart';

class OperativoDetailScreen extends ConsumerStatefulWidget {
  const OperativoDetailScreen({super.key, required this.operativoId});
  final String operativoId;

  @override
  ConsumerState<OperativoDetailScreen> createState() => _OperativoDetailScreenState();
}

class _OperativoDetailScreenState extends ConsumerState<OperativoDetailScreen> {
  bool _importandoCsv = false;
  String _filtroCurso = 'Todos';

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
                onPressed: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go('/operativos');
                  }
                },
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
                            ...(op['profesionales_asignados'] as List).map((p) {
                              final nom = '${p['profesional_nombre'] ?? ''} ${p['profesional_apellido'] ?? ''}'.trim();
                              final display = nom.isEmpty ? (p['profesional_email'] ?? 'Profesional') : nom;
                              return Padding(
                                padding: const EdgeInsets.only(top: AppSpacing.sm),
                                child: Text('$display (${p['rol_en_operativo']})',
                                    style: AppTypography.texto),
                              );
                            }),
                          if (op['estado'] == 'borrador') ...[
                            const SizedBox(height: AppSpacing.md),
                            AppButton(
                              label: 'Asignar profesional',
                              onPressed: () => _asignarProfesionalDialog(context),
                            ),
                          ],
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
                          const SizedBox(height: AppSpacing.md),
                          _listaAlumnos(),
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

  Future<void> _accionEstado(Future<void> Function() accion) async {
    await accion();
    ref.invalidate(operativoDetailProvider(widget.operativoId));
    // El estado cambió (p.ej. borrador → confirmado): refrescar la lista y los pendientes.
    ref.invalidate(operativosListControllerProvider);
    ref.invalidate(operativosPendientesProvider);
  }

  List<Widget> _botonesPorEstado(String estado, OperativoDetailController ctrl) {
    switch (estado) {
      case 'borrador':
        return [
          AppCard(child: AppButton(label: 'Confirmar operativo', onPressed: () => _accionEstado(ctrl.confirmar))),
        ];
      case 'confirmado':
        return [
          Row(
            children: [
              Expanded(child: AppCard(child: AppButton(label: 'Iniciar', onPressed: () => _accionEstado(ctrl.iniciar)))),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: AppCard(child: AppButton(label: 'Cancelar', onPressed: () => _accionEstado(ctrl.cancelar)))),
            ],
          ),
        ];
      case 'en_curso':
        return [
          _gatingFinalizacion(ctrl),
        ];
      default:
        return [];
    }
  }

  Widget _gatingFinalizacion(OperativoDetailController ctrl) {
    final completitudAsync = ref.watch(completitudProvider(widget.operativoId));
    return completitudAsync.when(
      loading: () => const AppCard(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(AppSpacing.md),
            child: CircularProgressIndicator(),
          ),
        ),
      ),
      error: (e, _) => Row(
        children: [
          Expanded(
              child: AppCard(
                  child: AppButton(label: 'Cancelar', onPressed: () => _accionEstado(ctrl.cancelar)))),
        ],
      ),
      data: (c) {
        final total = (c['total_alumnos'] as num?)?.toInt() ?? 0;
        final completos = (c['completos'] as num?)?.toInt() ?? 0;
        final puedeFinalizar = c['puede_finalizar'] as bool? ?? false;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('$completos/$total alumnos completos', style: AppTypography.subtitulo),
                  if (!puedeFinalizar) ...[
                    const SizedBox(height: 4),
                    Text('Faltan evaluaciones para finalizar',
                        style: AppTypography.texto.copyWith(
                            fontSize: 12, color: AppColors.texto.withValues(alpha: 0.6))),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                    child: AppCard(
                        child: AppButton(
                  label: 'Finalizar',
                  onPressed: puedeFinalizar ? () => _accionEstado(ctrl.finalizar) : null,
                ))),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                    child: AppCard(
                        child: AppButton(
                            label: 'Cancelar', onPressed: () => _accionEstado(ctrl.cancelar)))),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _listaAlumnos() {
    final alumnosAsync = ref.watch(alumnosProvider(widget.operativoId));
    final sesion = ref.watch(sessionControllerProvider);
    final permisos = sesion is SesionAutenticada ? sesion.sesion.permisos : const <String>{};

    return alumnosAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(AppSpacing.md),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Text('No se pudo cargar la lista de alumnos.',
          style: AppTypography.texto.copyWith(color: AppColors.texto.withValues(alpha: 0.6))),
      data: (alumnos) {
        if (alumnos.isEmpty) {
          return Text('Aún no hay alumnos cargados.',
              style: AppTypography.texto.copyWith(color: AppColors.texto.withValues(alpha: 0.6)));
        }

        final cursos = <String>{};
        for (final a in alumnos) {
          cursos.add(_labelCurso(a));
        }
        final listaCursos = cursos.toList()..sort(_compararCursos);

        final filtrados = _filtroCurso == 'Todos'
            ? alumnos
            : alumnos.where((a) => _labelCurso(a) == _filtroCurso).toList();

        final grupos = <String, List<Map<String, dynamic>>>{};
        for (final a in filtrados) {
          grupos.putIfAbsent(_labelCurso(a), () => []).add(a);
        }
        final claves = grupos.keys.toList()..sort(_compararCursos);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownButton<String>(
              value: _filtroCurso,
              isExpanded: true,
              items: [
                DropdownMenuItem(value: 'Todos', child: Text('Todos los cursos')),
                for (final c in listaCursos)
                  DropdownMenuItem(value: c, child: Text(c)),
              ],
              onChanged: (v) => setState(() => _filtroCurso = v ?? 'Todos'),
            ),
            const SizedBox(height: AppSpacing.sm),
            for (final clave in claves) ...[
              _encabezadoCurso(clave, grupos[clave]!.length),
              for (final a in grupos[clave]!) _filaAlumno(a, permisos),
            ],
          ],
        );
      },
    );
  }

  String _labelCurso(Map<String, dynamic> a) {
    final label = (a['curso_display'] as String?)?.trim() ?? '';
    return label.isEmpty ? 'Sin curso' : label;
  }

  int _numeroGrado(String label) {
    final match = RegExp(r'\d+').firstMatch(label);
    if (match == null) return 0;
    return int.tryParse(match.group(0)!) ?? 0;
  }

  int _compararCursos(String a, String b) {
    if (a == 'Sin curso') return 1;
    if (b == 'Sin curso') return -1;
    final diff = _numeroGrado(a).compareTo(_numeroGrado(b));
    if (diff != 0) return diff;
    return a.compareTo(b);
  }

  Widget _encabezadoCurso(String curso, int cantidad) {
    return Container(
      margin: const EdgeInsets.only(top: AppSpacing.sm, bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.gris.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          const Icon(Icons.menu_book_outlined, size: 16, color: AppColors.texto),
          const SizedBox(width: 6),
          Text('$curso ($cantidad)',
              style: AppTypography.subtitulo.copyWith(fontSize: 14)),
        ],
      ),
    );
  }

  Widget _filaAlumno(Map<String, dynamic> a, Set<String> permisos) {
    final id = '${a['id']}';
    final nombre = '${a['nombre'] ?? ''} ${a['apellido'] ?? ''}'.trim();
    final dni = '${a['dni'] ?? ''}';
    final completo = a['completo'] as bool? ?? false;
    final opId = widget.operativoId;

    final acciones = <Widget>[];
    if (permisos.contains('cargarEvaluacionMedica')) {
      acciones.add(_botonAccion(
          'Evaluación médica', () => context.push('/operativos/$opId/alumnos/$id/medica')));
    }
    if (permisos.contains('cargarEvaluacionOdontologica')) {
      acciones.add(_botonAccion(
          'Eval. odontológica', () => context.push('/operativos/$opId/alumnos/$id/odontologica')));
    }
    if (permisos.contains('cargarSeccionEscuela')) {
      acciones.add(_botonAccion(
          'Sección escuela', () => context.push('/operativos/$opId/alumnos/$id/escuela')));
    }

    return Container(
      margin: const EdgeInsets.only(top: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.gris.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(nombre.isEmpty ? 'Alumno' : nombre,
                        style: AppTypography.texto.copyWith(fontWeight: FontWeight.bold)),
                    if (dni.isNotEmpty)
                      Text('DNI $dni',
                          style: AppTypography.texto.copyWith(
                              fontSize: 12, color: AppColors.texto.withValues(alpha: 0.6))),
                  ],
                ),
              ),
              _badgeEstado(completo),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              if (a['medica_completada'] as bool? ?? false) _chip('M ✓'),
              if (a['odontologica_completada'] as bool? ?? false) _chip('O ✓'),
              if (a['escuela_completado'] as bool? ?? false) _chip('E ✓'),
            ],
          ),
          if (acciones.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Wrap(spacing: 8, runSpacing: 8, children: acciones),
          ],
        ],
      ),
    );
  }

  Widget _botonAccion(String label, VoidCallback onTap) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        backgroundColor: AppColors.gris.withValues(alpha: 0.15),
        foregroundColor: AppColors.texto,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
      child: Text(label, style: AppTypography.texto.copyWith(fontSize: 12)),
    );
  }

  Widget _badgeEstado(bool completo) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: completo ? Colors.green : AppColors.gris,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(completo ? 'Completo' : 'Pendiente',
          style: const TextStyle(
              color: AppColors.blanco, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }

  Widget _chip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(label,
          style: const TextStyle(
              color: Colors.green, fontSize: 11, fontWeight: FontWeight.bold)),
    );
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
    ref.invalidate(operativoDetailProvider(widget.operativoId));
    ref.invalidate(alumnosProvider(widget.operativoId));
    ref.invalidate(completitudProvider(widget.operativoId));
    ref.invalidate(operativosListControllerProvider);
  }

  Future<void> _asignarProfesionalDialog(BuildContext context) async {
    String? profId;
    String rol = 'medico';
    await showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Asignar profesional'),
        content: Consumer(
          builder: (c, dialogRef, _) {
            final async = dialogRef.watch(profesionalesDisponiblesProvider);
            return async.when(
              loading: () => const SizedBox(
                  height: 80, child: Center(child: CircularProgressIndicator())),
              error: (e, _) => const Text('Error al cargar profesionales'),
              data: (profs) {
                if (profs.isEmpty) {
                  return const Text(
                      'No hay profesionales disponibles. Creá médicos u odontólogos primero.');
                }
                return StatefulBuilder(
                  builder: (c, setLocal) => Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButton<String>(
                        isExpanded: true,
                        hint: const Text('Elegí un profesional'),
                        value: profId,
                        items: profs.map((p) {
                          final nom =
                              '${p['nombre'] ?? ''} ${p['apellido'] ?? ''}'.trim();
                          final label = nom.isEmpty ? (p['email'] ?? '') : nom;
                          return DropdownMenuItem(
                              value: p['id'] as String, child: Text('$label'));
                        }).toList(),
                        onChanged: (v) => setLocal(() => profId = v),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      DropdownButton<String>(
                        isExpanded: true,
                        value: rol,
                        items: const [
                          DropdownMenuItem(value: 'medico', child: Text('Médico')),
                          DropdownMenuItem(
                              value: 'odontologo', child: Text('Odontólogo')),
                          DropdownMenuItem(
                              value: 'ayudante', child: Text('Ayudante')),
                        ],
                        onChanged: (v) => setLocal(() => rol = v ?? 'medico'),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Cancelar')),
          TextButton(
            onPressed: () async {
              if (profId == null) return;
              Navigator.pop(dialogCtx);
              final ctrl = ref.read(
                  operativoDetailControllerProvider(widget.operativoId).notifier);
              await ctrl.asignarProfesional(profId!, rol);
              ref.invalidate(operativoDetailProvider(widget.operativoId));
              ref.invalidate(operativosListControllerProvider);
              ref.invalidate(profesionalesDisponiblesProvider);
            },
            child: const Text('Asignar'),
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
