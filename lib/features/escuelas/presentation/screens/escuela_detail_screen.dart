import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/design_system/app_gradient_scaffold.dart';
import '../../../../core/design_system/detail_post_card.dart';
import '../../../../core/session/entities.dart';
import '../../../../core/session/session_controller.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../data/escuelas_repository.dart';
import '../controllers/escuelas_list_controller.dart';
import 'widgets/escuela_dialogs.dart';

/// Detalle de una escuela con formato de publicación. La lista solo muestra
/// tarjetas que navegan acá.
class EscuelaDetailScreen extends ConsumerWidget {
  const EscuelaDetailScreen({super.key, required this.escuelaId});

  final String escuelaId;

  static String _etiqueta(
      List<({String value, String label})> opciones, String? valor) {
    if (valor == null || valor.isEmpty) return '—';
    for (final o in opciones) {
      if (o.value == valor) return o.label;
    }
    return valor;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detalleAsync = ref.watch(escuelaDetalleProvider(escuelaId));
    final sesion = ref.watch(sessionControllerProvider);
    final acciones = sesion is SesionAutenticada
        ? sesion.sesion.acciones.map((a) => a.name).toSet()
        : const <String>{};
    final puedeEditar = acciones.contains('editarEscuela');
    final puedeEliminar = acciones.contains('eliminarEscuela');
    final puedeVerAlumnos = acciones.contains('verAlumnosEscuela');

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
                    context.go('/escuelas');
                  }
                },
              ),
               Expanded(
                child: Text('Detalle de escuela',
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.blanco)),
              ),
            ]),
          ),
          Expanded(
            child: detalleAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Text('No se pudo cargar la escuela',
                    style: AppTypography.texto
                        .copyWith(color: AppColors.blanco)),
              ),
              data: (escuela) {
                final esPlurigrado = escuela.plurigradoRural;
                return ListView(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  children: [
                    DetailPostCard(
                      avatarLetter: escuela.nombre,
                      title: escuela.nombre,
                      bannerIcon: Icons.school_outlined,
                      bannerChips: [
                        _etiqueta(
                            sectoresGestion, escuela.sectorGestion),
                        _etiqueta(modalidadesEducativas,
                            escuela.modalidadEducativa),
                        if (esPlurigrado) 'Plurigrado rural',
                        if (escuela.interculturalBilingue)
                          'Intercultural bilingüe',
                      ],
                      menuEntries: [
                        if (puedeEditar)
                           PostMenuEntry(
                            value: 'editar',
                            label: 'Editar',
                            icon: Icons.edit_outlined,
                            color: AppColors.primario,
                          ),
                        if (puedeEliminar)
                           PostMenuEntry(
                            value: 'eliminar',
                            label: 'Eliminar',
                            icon: Icons.delete_outline,
                            color: AppColors.error,
                          ),
                      ],
                      onMenuSelected: (valor) async {
                        if (valor == 'editar') {
                          await mostrarEditarEscuelaDialog(
                              context, ref, escuela);
                          ref.invalidate(
                              escuelaDetalleProvider(escuela.id));
                        } else if (valor == 'eliminar') {
                          final ok = await confirmarEliminarEscuela(
                              context, ref, escuela);
                          // Si se eliminó, el backend pudo rechazarla
                          // con 409 (el motivo ya se notificó): solo
                          // se vuelve si realmente se eliminó.
                          if (ok && context.mounted) {
                            if (context.canPop()) {
                              context.pop();
                            } else {
                              context.go('/escuelas');
                            }
                          }
                        }
                      },
                      body: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _Dato(
                              titulo: 'CUE',
                              valor: (escuela.cue?.isNotEmpty == true)
                                  ? escuela.cue!
                                  : '—'),
                          _Dato(
                              titulo: 'Localidad',
                              valor: (escuela.localidad?.isNotEmpty == true)
                                  ? escuela.localidad!
                                  : '—'),
                          _Dato(
                              titulo: 'Ámbito',
                              valor: (escuela.ambito?.isNotEmpty == true)
                                  ? escuela.ambito!
                                  : '—'),
                          _Dato(
                              titulo: 'Teléfono',
                              valor: (escuela.telefono?.isNotEmpty == true)
                                  ? escuela.telefono!
                                  : '—'),
                          if (esPlurigrado)
                            Padding(
                              padding:
                                  const EdgeInsets.only(top: AppSpacing.sm),
                              child: Text(
                                'Escuela plurigrado rural: no necesita cursos. Los alumnos se registran sin curso.',
                                style: AppTypography.texto.copyWith(
                                    fontSize: 12,
                                    fontStyle: FontStyle.italic,
                                    color: AppColors.texto
                                        .withValues(alpha: 0.7)),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    // Acciones debajo de la tarjeta, como en el operativo.
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: [
                        if (!esPlurigrado)
                          PostActionButton(
                            icono: Icons.menu_book_outlined,
                            texto: 'Ver cursos',
                            colorFondo: AppColors.primario,
                            colorTexto: AppColors.blanco,
                            onPressed: () => context.push(
                                '/escuelas/${escuela.id}/cursos?nombre=${Uri.encodeComponent(escuela.nombre)}'),
                          ),
                        if (puedeVerAlumnos)
                          PostActionButton(
                            icono: Icons.people_outline,
                            texto: 'Ver alumnos',
                            colorFondo: AppColors.primario,
                            colorTexto: AppColors.blanco,
                            onPressed: () => context.push(
                                '/escuelas/${escuela.id}/alumnos?nombre=${Uri.encodeComponent(escuela.nombre)}'),
                          ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _Dato extends StatelessWidget {
  const _Dato({required this.titulo, required this.valor});

  final String titulo;
  final String valor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: RichText(
        text: TextSpan(
          style: AppTypography.texto.copyWith(fontSize: 13),
          children: [
            TextSpan(
                text: '$titulo: ',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            TextSpan(text: valor),
          ],
        ),
      ),
    );
  }
}
