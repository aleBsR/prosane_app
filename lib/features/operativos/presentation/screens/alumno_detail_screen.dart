import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/design_system/app_gradient_scaffold.dart';
import '../../../../core/design_system/detail_post_card.dart';
import '../../../../core/design_system/post_chip_custom.dart';
import '../../../../core/notificaciones/notificacion_controller.dart';
import '../../../../core/providers.dart';
import '../../../../core/session/entities.dart';
import '../../../../core/session/session_controller.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../controllers/operativo_detail_controller.dart';

/// Detalle de un alumno dentro de un operativo, con formato de publicación
/// (igual que el detalle de escuela): asistencia, tildes E/A/M/O y los botones
/// de carga que faltan. La lista del operativo solo muestra nombre + DNI y
/// navega acá.
class AlumnoDetailScreen extends ConsumerStatefulWidget {
  const AlumnoDetailScreen({
    super.key,
    required this.operativoId,
    required this.alumnoId,
  });

  final String operativoId;
  final String alumnoId;

  @override
  ConsumerState<AlumnoDetailScreen> createState() => _AlumnoDetailScreenState();
}

class _AlumnoDetailScreenState extends ConsumerState<AlumnoDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final alumnosAsync = ref.watch(alumnosProvider(widget.operativoId));
    final operativoEstado = ref.watch(operativoDetailProvider(widget.operativoId)).maybeWhen(
          data: (op) => (op['estado'] as String?) ?? '',
          orElse: () => '',
        );
    final sesion = ref.watch(sessionControllerProvider);
    final permisos = sesion is SesionAutenticada
        ? sesion.sesion.permisos
        : const <String>{};
    final rolName =
        sesion is SesionAutenticada ? sesion.sesion.usuario.rolName : '';

    return AppGradientScaffold(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            child: Row(children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: AppColors.blanco),
                onPressed: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go('/operativos/${widget.operativoId}');
                  }
                },
              ),
              Expanded(
                child: Text('Detalle del alumno',
                    style: AppTypography.titulo
                        .copyWith(color: AppColors.blanco, fontSize: 22)),
              ),
            ]),
          ),
          Expanded(
            child: alumnosAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => Center(child: Text('Error: $e')),
              data: (alumnos) {
                Map<String, dynamic>? alumno;
                for (final a in alumnos) {
                  if ('${a['id']}' == widget.alumnoId) {
                    alumno = a;
                    break;
                  }
                }
                if (alumno == null) {
                  return Center(
                    child: Text('Alumno no encontrado',
                        style: AppTypography.texto
                            .copyWith(color: AppColors.texto)),
                  );
                }
                return _contenido(alumno, operativoEstado, permisos, rolName);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _contenido(
      Map<String, dynamic> a, String operativoEstado, Set<String> permisos, String rolName) {
    final id = widget.alumnoId;
    final opId = widget.operativoId;
    final nombre = '${a['nombre'] ?? ''}'.trim();
    final apellido = '${a['apellido'] ?? ''}'.trim();
    final dni = '${a['dni'] ?? ''}';
    final completo = a['completo'] as bool? ?? false;
    final estadoActual = (a['estado'] as String?) ?? 'pendiente';
    final curso = _labelCurso(a);

    final esAusente = estadoActual == 'ausente';
    final esEvaluado = estadoActual == 'evaluado';
    final esPresente = estadoActual == 'presente';

    final puedeEditarEstado =
        (permisos.contains('gestionarEstadoAlumnoEnOperativo') ||
                rolName == 'superadmin') &&
            operativoEstado != 'finalizado' &&
            operativoEstado != 'cancelado';

    final operativoEnCurso = operativoEstado == 'en_curso';

    final acciones = <Widget>[];
    if (esPresente) {
      if (permisos.contains('cargarEvaluacionMedica') && operativoEnCurso) {
        acciones.add(PostActionButton(
          icono: Icons.medical_services_outlined,
          texto: 'Evaluación médica',
          colorFondo: AppColors.primario,
          colorTexto: AppColors.blanco,
          onPressed: () =>
              context.push('/operativos/$opId/alumnos/$id/medica'),
        ));
      }
      if (permisos.contains('cargarEvaluacionOdontologica') && operativoEnCurso) {
        acciones.add(PostActionButton(
          icono: Icons.health_and_safety_outlined,
          texto: 'Eval. odontológica',
          colorFondo: AppColors.primario,
          colorTexto: AppColors.blanco,
          onPressed: () =>
              context.push('/operativos/$opId/alumnos/$id/odontologica'),
        ));
      }
      if (permisos.contains('cargarSeccionEscuela')) {
        acciones.add(PostActionButton(
          icono: Icons.school_outlined,
          texto: 'Sección escuela',
          colorFondo: AppColors.primario,
          colorTexto: AppColors.blanco,
          onPressed: () =>
              context.push('/operativos/$opId/alumnos/$id/escuela'),
        ));
      }
      if (permisos.contains('cargarAntecedentesNino') ||
          rolName == 'superadmin') {
        acciones.add(PostActionButton(
          icono: Icons.family_restroom_outlined,
          texto: 'Datos de Alumno',
          colorFondo: AppColors.primario,
          colorTexto: AppColors.blanco,
          onPressed: () =>
              context.push('/operativos/$opId/alumnos/$id/datos'),
        ));
      }
    }

    final tildes = <Widget>[
      if (a['escuela_completado'] as bool? ?? false)
        const PostChipCustom(texto: 'E ✓', completado: true)
      else
        const PostChipCustom(texto: 'E', completado: false),
      if (a['antecedentes_completado'] as bool? ?? false)
        const PostChipCustom(texto: 'A ✓', completado: true)
      else
        const PostChipCustom(texto: 'A', completado: false),
      if (a['medica_completada'] as bool? ?? false)
        const PostChipCustom(texto: 'M ✓', completado: true)
      else
        const PostChipCustom(texto: 'M', completado: false),
      if (a['odontologica_completada'] as bool? ?? false)
        const PostChipCustom(texto: 'O ✓', completado: true)
      else
        const PostChipCustom(texto: 'O', completado: false),
    ];

    final conMenuFinal =
        operativoEstado == 'finalizado' && (completo || esAusente || esEvaluado);

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        DetailPostCard(
          showAvatar: true,
          avatarLetter:
              nombre.isEmpty ? (apellido.isEmpty ? 'A' : apellido) : nombre,
          title: [if (apellido.isNotEmpty) apellido, if (nombre.isNotEmpty) nombre]
              .join(', '),
          subtitle: [
            if (dni.isNotEmpty) 'DNI $dni',
            if (curso.isNotEmpty) curso,
          ].join(' • '),
          trailing: _badgeEstado(completo),
          bannerIcon: Icons.person_outline,
          menuEntries: [
            if (conMenuFinal &&
                (permisos.contains('verOperativo') ||
                    rolName == 'superadmin'))
              const PostMenuEntry(
                value: 'constancia',
                label: 'Constancia PDF',
                icon: Icons.picture_as_pdf_outlined,
                color: AppColors.primario,
              ),
            if (conMenuFinal &&
                (permisos.contains('verOperativo') ||
                    permisos.contains('cargarAntecedentesNino') ||
                    rolName == 'superadmin'))
              const PostMenuEntry(
                value: 'datos',
                label: 'Ver datos',
                icon: Icons.visibility_outlined,
                color: AppColors.primario,
              ),
          ],
          onMenuSelected: (valor) {
            if (valor == 'constancia') {
              context.push('/operativos/$opId/alumnos/$id/constancia');
            } else if (valor == 'datos') {
              context.push('/operativos/$opId/alumnos/$id/datos');
            }
          },
          bannerTop: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (puedeEditarEstado && !esEvaluado)
                Row(
                  children: [
                    const Icon(Icons.how_to_reg_outlined,
                        size: 14, color: AppColors.texto),
                    const SizedBox(width: 4),
                    Text('Asistencia:',
                        style: AppTypography.texto.copyWith(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.texto.withValues(alpha: 0.8))),
                    const SizedBox(width: 8),
                    SizedBox(
                      height: 32,
                      width: 140,
                      child: DropdownButtonFormField<String>(
                        initialValue: ['pendiente', 'presente', 'ausente']
                                .contains(estadoActual)
                            ? estadoActual
                            : 'pendiente',
                        isExpanded: true,
                        isDense: true,
                        decoration: InputDecoration(
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 6),
                          border: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(AppRadii.boton),
                              borderSide: BorderSide(
                                  color: _colorTextoEstado(estadoActual)
                                      .withValues(alpha: 0.3))),
                          enabledBorder: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(AppRadii.boton),
                              borderSide: BorderSide(
                                  color: _colorTextoEstado(estadoActual)
                                      .withValues(alpha: 0.3))),
                          focusedBorder: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(AppRadii.boton),
                              borderSide: BorderSide(
                                  color: _colorTextoEstado(estadoActual),
                                  width: 1.2)),
                          filled: true,
                          fillColor: _colorFondoEstado(estadoActual),
                        ),
                        style: AppTypography.texto.copyWith(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: _colorTextoEstado(estadoActual)),
                        icon: Icon(Icons.keyboard_arrow_down,
                            size: 16,
                            color: _colorTextoEstado(estadoActual)),
                        items: const [
                          DropdownMenuItem(
                              value: 'pendiente',
                              child: Text('Pendiente',
                                  style: TextStyle(fontSize: 11))),
                          DropdownMenuItem(
                              value: 'presente',
                              child: Text('Presente',
                                  style: TextStyle(fontSize: 11))),
                          DropdownMenuItem(
                              value: 'ausente',
                              child: Text('Ausente',
                                  style: TextStyle(fontSize: 11))),
                        ],
                        onChanged: (v) {
                          if (v != null && v != estadoActual) {
                            _cambiarEstadoAlumno(id, v);
                          }
                        },
                      ),
                    ),
                  ],
                )
              else
                Row(
                  children: [
                    Icon(Icons.how_to_reg_outlined,
                        size: 12, color: _colorTextoEstado(estadoActual)),
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                          color: _colorFondoEstado(estadoActual),
                          borderRadius: BorderRadius.circular(AppRadii.boton),
                          border: Border.all(
                              color: _colorTextoEstado(estadoActual)
                                  .withValues(alpha: 0.3))),
                      child: Text(_labelEstadoAlumno(estadoActual),
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: _colorTextoEstado(estadoActual))),
                    ),
                  ],
                ),
              if (esAusente)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                      'Ausente — no requiere evaluaciones',
                      style: AppTypography.texto.copyWith(
                          fontSize: 11,
                          color: AppColors.texto.withValues(alpha: 0.6),
                          fontStyle: FontStyle.italic)),
                ),
              if (operativoEstado != 'finalizado' &&
                  !esPresente &&
                  !esAusente) ...[
                const SizedBox(height: 4),
                Text('Marcá como Presente para habilitar la carga',
                    style: AppTypography.texto.copyWith(
                        fontSize: 10,
                        color: AppColors.texto.withValues(alpha: 0.5))),
              ],
            ],
          ),
          bannerChips:
              (esPresente || esEvaluado) ? tildes : const <String>[],
          bannerBottom: acciones.isNotEmpty
              ? Wrap(spacing: 8, runSpacing: 8, children: acciones)
              : null,
        ),
      ],
    );
  }

  String _labelCurso(Map<String, dynamic> a) {
    final label = (a['curso_display'] as String?)?.trim() ?? '';
    return label.isEmpty ? '' : label;
  }

  Future<void> _cambiarEstadoAlumno(String alumnoId, String nuevoEstado) async {
    try {
      await ref.read(operativosRepositoryProvider).patchEstadoAlumno(
          widget.operativoId, alumnoId, nuevoEstado);
      ref.invalidate(alumnosProvider(widget.operativoId));
      ref.invalidate(completitudProvider(widget.operativoId));
      ref.invalidate(operativoDetailProvider(widget.operativoId));
      if (mounted) {
        ref.read(notificacionProvider.notifier).exito(
            'Asistencia: ${_labelEstadoAlumno(nuevoEstado)}');
      }
    } catch (e) {
      if (mounted) {
        ref.read(notificacionProvider.notifier).error(
            'No se pudo actualizar asistencia: $e');
      }
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

  Widget _badgeEstado(bool completo) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: completo ? Colors.green : AppColors.gris,
        borderRadius: BorderRadius.circular(AppRadii.campo),
      ),
      child: Text(completo ? 'Completo' : 'Pendiente',
          style: const TextStyle(
              color: AppColors.blanco, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }
}