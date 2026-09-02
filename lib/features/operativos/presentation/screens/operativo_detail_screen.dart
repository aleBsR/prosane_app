import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/design_system/app_button.dart';
import '../../../../core/design_system/app_card.dart';
import '../../../../core/design_system/app_gradient_scaffold.dart';
import '../../../../core/design_system/app_text_field.dart';
import '../../../../core/notificaciones/notificacion_controller.dart';
import '../../../../core/providers.dart';
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
  String _busqueda = '';
  final _busquedaCtrl = TextEditingController();

  @override
  void dispose() {
    _busquedaCtrl.dispose();
    super.dispose();
  }

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

        final filtradosPorCurso = _filtroCurso == 'Todos'
            ? alumnos
            : alumnos.where((a) => _labelCurso(a) == _filtroCurso).toList();
        final query = _busqueda.trim().toLowerCase();
        final filtrados = query.isEmpty
            ? filtradosPorCurso
            : filtradosPorCurso.where((a) {
                final nombre = ('${a['nombre'] ?? ''}').toLowerCase();
                final apellido = ('${a['apellido'] ?? ''}').toLowerCase();
                final dni = ('${a['dni'] ?? ''}').toLowerCase();
                final completo = '$nombre $apellido $dni ${apellido} ${nombre}';
                return completo.contains(query);
              }).toList();

        if (filtrados.isEmpty) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppTextField(
                label: 'Buscar alumno',
                hint: 'Nombre, apellido o DNI',
                controller: _busquedaCtrl,
                onChanged: (v) => setState(() => _busqueda = v),
              ),
              const SizedBox(height: AppSpacing.sm),
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
              const SizedBox(height: AppSpacing.md),
              Text(
                query.isNotEmpty ? 'Sin resultados para "$_busqueda"' : 'Sin alumnos en este filtro',
                style: AppTypography.texto.copyWith(color: AppColors.texto.withValues(alpha: 0.6)),
                textAlign: TextAlign.center,
              ),
              if (query.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                TextButton(
                    onPressed: () {
                      _busquedaCtrl.clear();
                      setState(() => _busqueda = '');
                    },
                    child: const Text('Limpiar búsqueda')),
              ],
            ],
          );
        }

        final grupos = <String, List<Map<String, dynamic>>>{};
        for (final a in filtrados) {
          grupos.putIfAbsent(_labelCurso(a), () => []).add(a);
        }
        // Orden estable dentro de cada curso para que un cambio de estado no mueva al alumno al final
        for (final lista in grupos.values) {
          lista.sort((a, b) {
            final cmpApellido = ('${a['apellido'] ?? ''}').compareTo('${b['apellido'] ?? ''}');
            if (cmpApellido != 0) return cmpApellido;
            final cmpNombre = ('${a['nombre'] ?? ''}').compareTo('${b['nombre'] ?? ''}');
            if (cmpNombre != 0) return cmpNombre;
            return ('${a['dni'] ?? ''}').compareTo('${b['dni'] ?? ''}');
          });
        }
        final claves = grupos.keys.toList()..sort(_compararCursos);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppTextField(
              label: 'Buscar alumno',
              hint: 'Nombre, apellido o DNI',
              controller: _busquedaCtrl,
              onChanged: (v) => setState(() => _busqueda = v),
            ),
            const SizedBox(height: AppSpacing.sm),
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
            if (query.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text('${filtrados.length} resultado(s) para "$_busqueda"', style: AppTypography.texto.copyWith(fontSize: 11, color: AppColors.texto.withValues(alpha: 0.6))),
            ],
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
    final sesion = ref.watch(sessionControllerProvider);
    final rolName = sesion is SesionAutenticada ? sesion.sesion.usuario.rolName : '';
    final operativoEstado = ref.watch(operativoDetailProvider(widget.operativoId)).maybeWhen(
          data: (op) => (op['estado'] as String?) ?? '',
          orElse: () => '',
        );
    final puedeEditarEstado = (permisos.contains('gestionarEstadoAlumnoEnOperativo') || rolName == 'superadmin') &&
        operativoEstado != 'finalizado' &&
        operativoEstado != 'cancelado';
    final estadoActual = (a['estado'] as String?) ?? 'pendiente';

    final esAusente = estadoActual == 'ausente';
    final esEvaluado = estadoActual == 'evaluado';
    final esPresente = estadoActual == 'presente';
    final acciones = <Widget>[];
    // Solo si está presente se muestran botones de carga.
    // Pendiente y ausente no permiten carga; ausente queda completo automático.
    // Evaluado es estado automático (no seleccionable) cuando E+A+M+O están completos.
    if (esPresente) {
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
      // A = Datos personales y familia (escuela carga todos los datos del alumno)
      // Permiso data-driven: cargarAntecedentesNino (solo rol escuela + superadmin)
      if (permisos.contains('cargarAntecedentesNino') || rolName == 'superadmin') {
        acciones.add(_botonAccion(
            'Datos personales y familia', () => context.push('/operativos/$opId/alumnos/$id/datos')));
      }
    }

    return Container(
      key: ValueKey('alumno-$id'),
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
          // Selector de asistencia compacto — evaluado es automático, no seleccionable
          if (puedeEditarEstado && !esEvaluado)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  const Icon(Icons.how_to_reg_outlined, size: 14, color: AppColors.texto),
                  const SizedBox(width: 4),
                  Text('Asistencia:', style: AppTypography.texto.copyWith(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.texto.withValues(alpha: 0.8))),
                  const SizedBox(width: 8),
                  SizedBox(
                    height: 32,
                    width: 140,
                    child: DropdownButtonFormField<String>(
                      initialValue: ['pendiente', 'presente', 'ausente'].contains(estadoActual) ? estadoActual : 'pendiente',
                      isExpanded: true,
                      isDense: true,
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: _colorTextoEstado(estadoActual).withValues(alpha: 0.3))),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: _colorTextoEstado(estadoActual).withValues(alpha: 0.3))),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: _colorTextoEstado(estadoActual), width: 1.2)),
                        filled: true,
                        fillColor: _colorFondoEstado(estadoActual),
                      ),
                      style: AppTypography.texto.copyWith(fontSize: 11, fontWeight: FontWeight.bold, color: _colorTextoEstado(estadoActual)),
                      icon: Icon(Icons.keyboard_arrow_down, size: 16, color: _colorTextoEstado(estadoActual)),
                      items: const [
                        DropdownMenuItem(value: 'pendiente', child: Text('Pendiente', style: TextStyle(fontSize: 11))),
                        DropdownMenuItem(value: 'presente', child: Text('Presente', style: TextStyle(fontSize: 11))),
                        DropdownMenuItem(value: 'ausente', child: Text('Ausente', style: TextStyle(fontSize: 11))),
                      ],
                      onChanged: (v) {
                        if (v != null && v != estadoActual) _cambiarEstadoAlumno(id, v);
                      },
                    ),
                  ),
                ],
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Icon(Icons.how_to_reg_outlined, size: 12, color: _colorTextoEstado(estadoActual)),
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: _colorFondoEstado(estadoActual), borderRadius: BorderRadius.circular(6), border: Border.all(color: _colorTextoEstado(estadoActual).withValues(alpha: 0.3))),
                    child: Text(_labelEstadoAlumno(estadoActual), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: _colorTextoEstado(estadoActual))),
                  ),
                ],
              ),
            ),
          if (esPresente || esEvaluado)
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                if (a['escuela_completado'] as bool? ?? false) _chip('E ✓'),
                if (a['antecedentes_completado'] as bool? ?? false) _chip('A ✓'),
                if (a['medica_completada'] as bool? ?? false) _chip('M ✓'),
                if (a['odontologica_completada'] as bool? ?? false) _chip('O ✓'),
              ],
            )
          else if (esAusente)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text('Ausente — no requiere evaluaciones', style: AppTypography.texto.copyWith(fontSize: 11, color: AppColors.texto.withValues(alpha: 0.6), fontStyle: FontStyle.italic)),
            ),
          if (acciones.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Wrap(spacing: 8, runSpacing: 8, children: acciones),
          ] else if (esEvaluado) ...[
            const SizedBox(height: 4),
            Text('Evaluado — completo', style: AppTypography.texto.copyWith(fontSize: 10, color: Colors.green.shade700, fontWeight: FontWeight.w600)),
          ] else if (!esPresente) ...[
            const SizedBox(height: 4),
            Text('Marcá como Presente para habilitar la carga', style: AppTypography.texto.copyWith(fontSize: 10, color: AppColors.texto.withValues(alpha: 0.5))),
          ],
        ],
      ),
    );
  }

  Future<void> _cambiarEstadoAlumno(String alumnoId, String nuevoEstado) async {
    try {
      await ref.read(operativosRepositoryProvider).patchEstadoAlumno(widget.operativoId, alumnoId, nuevoEstado);
      ref.invalidate(alumnosProvider(widget.operativoId));
      ref.invalidate(completitudProvider(widget.operativoId));
      ref.invalidate(operativoDetailProvider(widget.operativoId));
      if (mounted) ref.read(notificacionProvider.notifier).exito('Asistencia: ${_labelEstadoAlumno(nuevoEstado)}');
    } catch (e) {
      if (mounted) ref.read(notificacionProvider.notifier).error('No se pudo actualizar asistencia: $e');
    }
  }

  Color _colorFondoEstado(String estado) {
    switch (estado) {
      case 'presente':
        return Colors.green.withValues(alpha: 0.12);
      case 'ausente':
        return Colors.red.withValues(alpha: 0.10);
      case 'evaluado':
        return Colors.blue.withValues(alpha: 0.10);
      default:
        return AppColors.gris.withValues(alpha: 0.10);
    }
  }

  Color _colorTextoEstado(String estado) {
    switch (estado) {
      case 'presente':
        return Colors.green.shade700;
      case 'ausente':
        return Colors.red.shade700;
      case 'evaluado':
        return Colors.blue.shade700;
      default:
        return AppColors.texto;
    }
  }

  String _labelEstadoAlumno(String estado) {
    switch (estado) {
      case 'presente':
        return 'Presente';
      case 'ausente':
        return 'Ausente';
      case 'evaluado':
        return 'Evaluado';
      default:
        return 'Pendiente';
    }
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
