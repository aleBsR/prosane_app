import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/design_system/app_button.dart';
import '../../../../core/design_system/app_card.dart';
import '../../../../core/design_system/app_dialog.dart';
import '../../../../core/design_system/app_gradient_scaffold.dart';
import '../../../../core/design_system/detail_post_card.dart';
import '../../../../core/design_system/app_text_field.dart';
import '../../../../core/notificaciones/notificacion_controller.dart';
import '../../../../core/providers.dart';
import '../../../../core/session/entities.dart';
import '../../../../core/session/session_controller.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../pendientes/pendientes_count_provider.dart';
import '../../../escuelas/presentation/controllers/alumnos_escuela_controller.dart';
import '../controllers/operativo_detail_controller.dart';
import '../controllers/operativos_list_controller.dart';
import 'widgets/operativo_dialogs.dart';

class OperativoDetailScreen extends ConsumerStatefulWidget {
  const OperativoDetailScreen({super.key, required this.operativoId});
  final String operativoId;

  @override
  ConsumerState<OperativoDetailScreen> createState() => _OperativoDetailScreenState();
}

class _OperativoDetailScreenState extends ConsumerState<OperativoDetailScreen> {
  bool _importandoCsv = false;
  bool _exportando = false;
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
    // Importar nómina CSV: solo quien tenga el permiso (rol escuela + superadmin).
    final sesion = ref.watch(sessionControllerProvider);
    final puedeImportarCsv = sesion is SesionAutenticada &&
        sesion.sesion.permisos.contains('importarNominaOperativo');
    // Permisos para los botones de estado (solo administrativo/superadmin los tienen).
    final permisos = sesion is SesionAutenticada
        ? sesion.sesion.permisos
        : const <String>{};
    final rolName =
        sesion is SesionAutenticada ? sesion.sesion.usuario.rolName : '';
    // Gating de Finalizar para el banner: mientras carga o falla, deshabilitado.
    final puedeFinalizar = ref.watch(completitudProvider(widget.operativoId)).maybeWhen(
          data: (c) => (c['puede_finalizar'] as bool?) ?? false,
          orElse: () => false,
        );

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
                icon:  Icon(Icons.arrow_back, color: AppColors.blanco),
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
                    // Editar/Eliminar (igual que en escuelas): solo con permiso
                    // y si el operativo sigue editable (el backend responde 409
                    // en finalizado o cancelado). Eliminar cancela el operativo.
                    Builder(builder: (context) {
                      final estado = '${op['estado'] ?? ''}';
                      final editable =
                          estado != 'finalizado' && estado != 'cancelado';
                      final puedeEditar =
                          (permisos.contains('editarOperativo') ||
                                  rolName == 'superadmin') &&
                              editable;
                      final puedeEliminar =
                          (permisos.contains('cancelarOperativo') ||
                                  rolName == 'superadmin') &&
                              editable;
                      return DetailPostCard(
                      avatarLetter:
                          '${op['nombre'] ?? op['escuela']['nombre'] ?? 'Operativo'}',
                      title:
                          '${op['nombre'] ?? op['escuela']['nombre'] ?? 'Operativo'}',
                      subtitle:
                          '${op['fecha']} • ${op['lugar_realizacion']}',
                      bannerIcon: Icons.event_note_outlined,
                      bannerChips: [
                        _labelEstado(op['estado']),
                        _contar(op['alumnos_count'], 'alumno'),
                        _contar(
                            (op['profesionales_asignados'] as List?)
                                    ?.length ??
                                0,
                            'profesional',
                            'profesionales'),
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
                          await mostrarEditarOperativoDialog(
                              context, ref, op);
                          ref.invalidate(
                              operativoDetailProvider(widget.operativoId));
                        } else if (valor == 'eliminar') {
                          final titulo =
                              '${op['nombre'] ?? op['escuela']['nombre'] ?? 'el operativo'}';
                          final ok = await confirmarEliminarOperativo(
                              context, ref, widget.operativoId, titulo);
                          // Si se canceló, el backend pudo rechazarlo
                          // con 409 (el motivo ya se notificó): solo
                          // se vuelve si realmente se eliminó.
                          if (ok && context.mounted) {
                            if (context.canPop()) {
                              context.pop();
                            } else {
                              context.go('/operativos');
                            }
                          }
                        }
                      },
                      bannerBottom: _botonesEstadoBanner(
                          (op['estado'] as String?) ?? '',
                          ctrl,
                          puedeFinalizar,
                          permisos,
                          rolName),
                    );
                    }),
                    const SizedBox(height: AppSpacing.md),
                    if (op['estado'] == 'en_curso') ...[
                      _tarjetaCompletitud(),
                      const SizedBox(height: AppSpacing.md),
                    ],
                    AppCard(
                      child: PostActionButton(
                        icono: Icons.medical_services_outlined,
                        texto: 'Ver derivaciones',
                        colorFondo: AppColors.campo,
                        colorTexto: AppColors.primario,
                        onPressed: () => context.push(
                            '/operativos/${widget.operativoId}/derivaciones'),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    if (op['estado'] == 'finalizado') ...[
                      _tarjetaDescargas(),
                      const SizedBox(height: AppSpacing.md),
                    ],
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
                          // Asignar sigue en esta tarjeta (es contextual a
                          // profesionales); Confirmar vive en el banner superior.
                          if (op['estado'] == 'borrador') ...[
                            const SizedBox(height: AppSpacing.md),
                            Wrap(
                              spacing: AppSpacing.sm,
                              runSpacing: AppSpacing.sm,
                              children: [
                                PostActionButton(
                                  icono: Icons.person_add_outlined,
                                  texto: 'Asignar profesional',
                                  colorFondo: AppColors.campo,
                                  colorTexto: AppColors.primario,
                                  onPressed: () =>
                                      _asignarProfesionalDialog(context),
                                ),
                              ],
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
                          if (puedeImportarCsv) ...[
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
                                        borderRadius: BorderRadius.circular(AppRadii.campo),
                                      ),
                                      child:  Center(
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

  /// `'3 alumnos'`, `'1 profesional'` (plural configurable).
  String _contar(int n, String singular, [String? plural]) =>
      '$n ${n == 1 ? singular : (plural ?? '${singular}s')}';

  Future<void> _accionEstado(Future<void> Function() accion) async {
    await accion();
    ref.invalidate(operativoDetailProvider(widget.operativoId));
    // El estado cambió (p.ej. borrador → confirmado): refrescar la lista y los pendientes.
    ref.invalidate(operativosListControllerProvider);
    ref.invalidate(operativosPendientesProvider);
  }

  /// Botones de cambio de estado dentro de la tarjeta de detalle
  /// (compactos estilo PostActionButton, como en el detalle de alumno,
  /// solo texto). Piden confirmación antes de ejecutar.
  /// Solo visibles con el permiso de la acción (administrativo/superadmin).
  /// En borrador solo Confirmar: Asignar sigue en la tarjeta de profesionales.
  Widget? _botonesEstadoBanner(
      String estado,
      OperativoDetailController ctrl,
      bool puedeFinalizar,
      Set<String> permisos,
      String rolName) {
    bool puede(String accion) =>
        permisos.contains(accion) || rolName == 'superadmin';

    PostActionButton primario(String texto, _AccionEstado accion,
            {VoidCallback? onPressed}) =>
        PostActionButton(
          texto: texto,
          colorFondo: AppColors.primario,
          colorTexto: AppColors.blanco,
          onPressed: onPressed ?? () => _pedirConfirmacionEstado(accion, ctrl),
        );

    final botones = <Widget>[];
    switch (estado) {
      case 'borrador':
        if (puede('confirmarOperativo')) {
          botones.add(primario('Confirmar operativo', _AccionEstado.confirmar));
        }
      case 'confirmado':
        if (puede('iniciarOperativo')) {
          botones.add(primario('Iniciar', _AccionEstado.iniciar));
        }
        if (puede('cancelarOperativo')) {
          botones.add(primario('Cancelar', _AccionEstado.cancelar));
        }
      case 'en_curso':
        if (puede('finalizarOperativo')) {
          botones.add(primario('Finalizar', _AccionEstado.finalizar,
              onPressed: puedeFinalizar
                  ? () => _pedirConfirmacionEstado(
                      _AccionEstado.finalizar, ctrl)
                  : null));
        }
        if (puede('cancelarOperativo')) {
          botones.add(primario('Cancelar', _AccionEstado.cancelar));
        }
    }
    if (botones.isEmpty) return null;
    return Wrap(spacing: 8, runSpacing: 8, children: botones);
  }

  /// Modal de confirmación para las acciones de estado del operativo
  /// (mismo formato que confirmarEliminarEscuela).
  Future<void> _pedirConfirmacionEstado(
      _AccionEstado accion, OperativoDetailController ctrl) async {    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text(accion.titulo),
        content: Text(accion.mensaje),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogCtx, false),
              child: const Text('No')),
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, true),
            child: Text('Sí',
                style: TextStyle(
                    color: accion == _AccionEstado.cancelar
                        ? AppColors.error
                        : AppColors.primario)),
          ),
        ],
      ),
    );
    if (confirmar != true || !mounted) return;
    _accionEstado(() => accion.ejecutar(ctrl));
  }

  /// Tarjeta de descargas (finalizado), con botones estilo detalle de alumno.
  Widget _tarjetaDescargas() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Operativo finalizado — Descargas', style: AppTypography.subtitulo),
          const SizedBox(height: 4),
          Text('Constancias y resúmenes disponibles', style: AppTypography.texto.copyWith(fontSize: 12, color: AppColors.texto.withValues(alpha: 0.6))),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              PostActionButton(
                icono: Icons.picture_as_pdf_outlined,
                texto: 'Exportar PDF',
                colorFondo: AppColors.primario,
                colorTexto: AppColors.blanco,
                onPressed: _exportando ? null : () => _exportar('pdf'),
              ),
              PostActionButton(
                icono: Icons.table_chart_outlined,
                texto: 'Exportar Excel',
                colorFondo: AppColors.primario,
                colorTexto: AppColors.blanco,
                onPressed: _exportando ? null : () => _exportar('excel'),
              ),
              PostActionButton(
                icono: Icons.description_outlined,
                texto: 'Exportar CSV',
                colorFondo: AppColors.primario,
                colorTexto: AppColors.blanco,
                onPressed: _exportando ? null : () => _exportar('csv'),
              ),
            ],
          ),
          if (_exportando) ...[
            const SizedBox(height: AppSpacing.sm),
            const LinearProgressIndicator(),
          ],
        ],
      ),
    );
  }

  Future<void> _exportar(String formato) async {
    setState(() => _exportando = true);
    try {
      final bytes = await ref.read(operativosRepositoryProvider).exportOperativo(widget.operativoId, formato);
      final dir = await getTemporaryDirectory();
      final ext = formato == 'pdf' ? 'pdf' : formato == 'csv' ? 'csv' : 'xlsx';
      final file = File('${dir.path}/operativo-${widget.operativoId}.$ext');
      await file.writeAsBytes(Uint8List.fromList(bytes), flush: true);
      if (formato == 'pdf') {
        await OpenFilex.open(file.path);
      } else {
        await Share.shareXFiles([XFile(file.path)], text: 'Resumen operativo $formato');
      }
      if (mounted) ref.read(notificacionProvider.notifier).exito('Exportado $formato');
    } catch (e) {
      if (mounted) ref.read(notificacionProvider.notifier).error('No se pudo exportar: $e');
    } finally {
      if (mounted) setState(() => _exportando = false);
    }
  }

  /// Tarjeta informativa de completitud (en_curso). Los botones
  /// Finalizar/Cancelar viven en el banner de la tarjeta de detalle.
  Widget _tarjetaCompletitud() {
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
      error: (e, _) => const SizedBox.shrink(),
      data: (c) {
        final total = (c['total_alumnos'] as num?)?.toInt() ?? 0;
        final completos = (c['completos'] as num?)?.toInt() ?? 0;
        final puedeFinalizar = c['puede_finalizar'] as bool? ?? false;
        return AppCard(
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
        );
      },
    );
  }

  Widget _listaAlumnos() {
    final alumnosAsync = ref.watch(alumnosProvider(widget.operativoId));

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
                final completo = '$nombre $apellido $dni $apellido $nombre';
                return completo.contains(query);
              }).toList();

        if (filtrados.isEmpty) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _filtrosAlumnos(listaCursos),
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
            _filtrosAlumnos(listaCursos),
            if (query.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text('${filtrados.length} resultado(s) para "$_busqueda"', style: AppTypography.texto.copyWith(fontSize: 11, color: AppColors.texto.withValues(alpha: 0.6))),
            ],
            const SizedBox(height: AppSpacing.sm),
            for (final clave in claves) ...[
              _encabezadoCurso(clave, grupos[clave]!.length),
              for (final a in grupos[clave]!) _filaAlumno(a),
            ],
          ],
        );
      },
    );
  }

  /// Búsqueda + filtro por curso uno al lado del otro (como en la web).
  Widget _filtrosAlumnos(List<String> listaCursos) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: AppTextField(
            label: 'Buscar alumno',
            hint: 'Nombre, apellido o DNI',
            controller: _busquedaCtrl,
            onChanged: (v) => setState(() => _busqueda = v),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Curso', style: AppTypography.subtitulo),
              const SizedBox(height: 6),
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
            ],
          ),
        ),
      ],
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
        borderRadius: BorderRadius.circular(AppRadii.campo),
      ),
      child: Row(
        children: [
           Icon(Icons.menu_book_outlined, size: 16, color: AppColors.texto),
          const SizedBox(width: 6),
          Text('$curso ($cantidad)',
              style: AppTypography.subtitulo.copyWith(fontSize: 14)),
        ],
      ),
    );
  }

  Widget _filaAlumno(Map<String, dynamic> a) {
    final id = '${a['id']}';
    final apellido = '${a['apellido'] ?? ''}'.trim();
    final nombre = '${a['nombre'] ?? ''}'.trim();
    final dni = '${a['dni'] ?? ''}';
    final completo = a['completo'] as bool? ?? false;
    final opId = widget.operativoId;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: AppCard(
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadii.campo),
          onTap: () => context.push('/operativos/$opId/alumnos/$id'),
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        [if (apellido.isNotEmpty) apellido, if (nombre.isNotEmpty) nombre]
                            .join(', '),
                        style: AppTypography.subtitulo,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (dni.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text('DNI $dni',
                            style: AppTypography.texto.copyWith(
                                fontSize: 12,
                                color: AppColors.texto.withValues(alpha: 0.6))),
                      ],
                    ],
                  ),
                ),
                _badgeEstado(completo),
                const SizedBox(width: AppSpacing.sm),
                 Icon(Icons.chevron_right, color: AppColors.texto),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _badgeEstado(bool completo) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: completo ? Colors.green : AppColors.gris,
        borderRadius: BorderRadius.circular(AppRadii.campo),
      ),
      child: Text(completo ? 'Completo' : 'Pendiente',
          style:  TextStyle(
              color: AppColors.blanco, fontSize: 11, fontWeight: FontWeight.bold)),
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
    ref.invalidate(alumnosEscuelaProvider);
  }

  Future<void> _asignarProfesionalDialog(BuildContext context) async {
    String? profId;
    String rol = 'medico';
    await showDialog<void>(
      context: context,
      builder: (dialogCtx) => WideFormDialog(
        title: 'Asignar profesional',
        saveLabel: 'Asignar',
        onSave: () async {
          if (profId == null) return;
          Navigator.pop(dialogCtx);
          final ctrl = ref.read(
              operativoDetailControllerProvider(widget.operativoId).notifier);
          await ctrl.asignarProfesional(profId!, rol);
          ref.invalidate(operativoDetailProvider(widget.operativoId));
          ref.invalidate(operativosListControllerProvider);
          ref.invalidate(profesionalesDisponiblesProvider);
        },
        onCancel: () => Navigator.pop(dialogCtx),
        children: [
          Consumer(
            builder: (c, dialogRef, _) {
              final async = dialogRef.watch(profesionalesDisponiblesProvider);
              return async.when(
                loading: () => const SizedBox(
                    height: 80,
                    child: Center(child: CircularProgressIndicator())),
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
                                '${p['nombre'] ?? ''} ${p['apellido'] ?? ''}'
                                    .trim();
                            final label =
                                nom.isEmpty ? (p['email'] ?? '') : nom;
                            return DropdownMenuItem(
                                value: p['id'] as String,
                                child: Text('$label'));
                          }).toList(),
                          onChanged: (v) => setLocal(() => profId = v),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        DropdownButton<String>(
                          isExpanded: true,
                          value: rol,
                          items: const [
                            DropdownMenuItem(
                                value: 'medico', child: Text('Médico')),
                            DropdownMenuItem(
                                value: 'odontologo',
                                child: Text('Odontólogo')),
                            DropdownMenuItem(
                                value: 'administrativo', child: Text('Administrativo')),
                          ],
                          onChanged: (v) =>
                              setLocal(() => rol = v ?? 'medico'),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
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

/// Acciones de estado del operativo con sus textos de confirmación.
enum _AccionEstado {
  confirmar(
    titulo: '¿Confirmar operativo?',
    mensaje: 'El operativo pasará a Confirmado y quedará listo para iniciar.',
  ),
  iniciar(
    titulo: '¿Iniciar operativo?',
    mensaje:
        'El operativo pasará a En curso y se habilitará la carga de evaluaciones.',
  ),
  finalizar(
    titulo: '¿Finalizar operativo?',
    mensaje:
        'El operativo se cerrará y ya no se podrán cargar evaluaciones.',
  ),
  cancelar(
    titulo: '¿Cancelar operativo?',
    mensaje: 'El operativo se cancelará. Esta acción no se puede deshacer.',
  );

  const _AccionEstado({
    required this.titulo,
    required this.mensaje,
  });

  final String titulo;
  final String mensaje;

  Future<void> Function(OperativoDetailController) get ejecutar {
    switch (this) {
      case _AccionEstado.confirmar:
        return (ctrl) => ctrl.confirmar();
      case _AccionEstado.iniciar:
        return (ctrl) => ctrl.iniciar();
      case _AccionEstado.finalizar:
        return (ctrl) => ctrl.finalizar();
      case _AccionEstado.cancelar:
        return (ctrl) => ctrl.cancelar();
    }
  }
}
