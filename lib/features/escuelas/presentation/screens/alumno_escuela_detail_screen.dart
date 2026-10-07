import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/design_system/app_gradient_scaffold.dart';
import '../../../../core/design_system/detail_post_card.dart';
import '../../../../core/design_system/post_chip_custom.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../controllers/alumnos_escuela_controller.dart';
import '../../data/alumnos_escuela_repository.dart';
import 'widgets/tutor_dialog.dart';

/// Detalle de un alumno de escuela, espejo de AlumnoDetailScreen del
/// operativo: post de cabecera con los datos en la franja y carga de
/// pendientes (tutor) adentro.
class AlumnoEscuelaDetailScreen extends ConsumerWidget {
  const AlumnoEscuelaDetailScreen({
    super.key,
    required this.alumnoId,
    this.escuelaId,
  });

  final String alumnoId;

  /// Solo lectura (detalle de escuela de superadmin): igual muestra todo,
  /// el backend valida los permisos de escritura.
  final String? escuelaId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alumnosAsync = (escuelaId != null && escuelaId!.isNotEmpty)
        ? ref.watch(alumnosPorEscuelaProvider(escuelaId!))
        : ref.watch(alumnosEscuelaProvider);

    return AppGradientScaffold(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            child: Row(children: [
              IconButton(
                icon:  Icon(Icons.arrow_back, color: AppColors.blanco),
                onPressed: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go('/escuelas/alumnos');
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
                AlumnoEscuela? alumno;
                for (final a in alumnos) {
                  if (a.id == alumnoId) {
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
                return _contenido(context, ref, alumno);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _contenido(
      BuildContext context, WidgetRef ref, AlumnoEscuela alumno) {
    final tieneTutor = alumno.tutorDni.isNotEmpty;
    final tieneAntecedentes = alumno.antecedentes != null;

    void recargar() {
      ref.invalidate(alumnosEscuelaProvider);
      if (escuelaId != null && escuelaId!.isNotEmpty) {
        ref.invalidate(alumnosPorEscuelaProvider(escuelaId!));
      }
    }

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        DetailPostCard(
          showAvatar: true,
          avatarLetter: alumno.nombre.isEmpty
              ? (alumno.apellido.isEmpty ? 'A' : alumno.apellido)
              : alumno.nombre,
          title: [if (alumno.apellido.isNotEmpty) alumno.apellido, if (alumno.nombre.isNotEmpty) alumno.nombre]
              .join(', '),
          subtitle: [
            if (alumno.dni.isNotEmpty) '${alumno.tipoDni} ${alumno.dni}',
          ].join(' • '),
          trailing: _badgeEstado(tieneTutor),
          bannerIcon: Icons.person_outline,
          bannerTop: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Fecha de nacimiento: ${alumno.fechaNacimiento}',
                  style: AppTypography.texto.copyWith(fontSize: 12)),
              const SizedBox(height: 2),
              Text('Edad: ${alumno.edad} • Sexo: ${alumno.sexo}',
                  style: AppTypography.texto.copyWith(fontSize: 12)),
              if (alumno.localidad.isNotEmpty)
                Text('Localidad: ${alumno.localidad}',
                    style: AppTypography.texto.copyWith(fontSize: 12)),
              if (alumno.celular.isNotEmpty || alumno.telefonoFijo.isNotEmpty)
                Text(
                    [
                      if (alumno.celular.isNotEmpty) 'Cel: ${alumno.celular}',
                      if (alumno.telefonoFijo.isNotEmpty)
                        'Tel: ${alumno.telefonoFijo}'
                    ].join(' • '),
                    style: AppTypography.texto.copyWith(fontSize: 12)),
              if (alumno.tipoCobertura.isNotEmpty || alumno.nombreCobertura.isNotEmpty)
                Text(
                    'Cobertura: ${[alumno.tipoCobertura, alumno.nombreCobertura].where((s) => s.isNotEmpty).join(' — ')}',
                    style: AppTypography.texto.copyWith(fontSize: 12)),
              if (alumno.tieneCud.isNotEmpty)
                Text('CUD: ${alumno.tieneCud}',
                    style: AppTypography.texto.copyWith(fontSize: 12)),
              if (tieneTutor) ...[
                const SizedBox(height: 2),
                Text('Tutor: ${alumno.tutorApellido}, ${alumno.tutorNombre} (${alumno.tutorDni})',
                    style: AppTypography.texto.copyWith(fontSize: 12)),
              ],
            ],
          ),
          bannerChips: [
            PostChipCustom(
                texto: tieneTutor ? 'T ✓' : 'T', completado: tieneTutor),
            PostChipCustom(
                texto: tieneAntecedentes ? 'A ✓' : 'A',
                completado: tieneAntecedentes),
          ],
          bannerBottom: tieneTutor
              ? null
              : Wrap(spacing: 8, runSpacing: 8, children: [
                  PostActionButton(
                    icono: Icons.family_restroom_outlined,
                    texto: 'Agregar tutor',
                    colorFondo: AppColors.primario,
                    colorTexto: AppColors.blanco,
                    onPressed: () => mostrarTutorDialog(
                      context,
                      ref,
                      alumnoId: alumno.id,
                      alumnoNombre:
                          '${alumno.apellido}, ${alumno.nombre}',
                      onGuardado: recargar,
                    ),
                  ),
                ]),
        ),
      ],
    );
  }

  Widget _badgeEstado(bool completo) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: completo ? Colors.green : AppColors.gris,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(completo ? 'Completo' : 'Pendiente',
          style:  TextStyle(
              color: AppColors.blanco, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }
}
