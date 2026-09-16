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
                    DetailPostCard(
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
                            Wrap(
                              spacing: AppSpacing.sm,
                              runSpacing: AppSpacing.sm,
                              children: [
                                PostActionButton(
                                  icono: Icons.check_circle_outline,
                                  texto: 'Confirmar operativo',
                                  colorFondo: AppColors.primario,
                                  colorTexto: AppColors.blanco,
                                  onPressed: () => _accionEstado(ctrl.confirmar),
                                ),
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

  List<Widget> _botonesPorEstado(String estado, OperativoDetailController ctrl) {
    switch (estado) {
      // En borrador, Confirmar va junto a Asignar dentro de la tarjeta
      // de profesionales (compactos, uno al lado del otro).
      case 'borrador':
        return [];
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
      case 'finalizado':
        return [
          AppCard(
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
                    _botonDescarga('Exportar PDF', Icons.picture_as_pdf_outlined, () => _exportar('pdf')),
                    _botonDescarga('Exportar Excel', Icons.table_chart_outlined, () => _exportar('excel')),
                    _botonDescarga('Exportar CSV', Icons.description_outlined, () => _exportar('csv')),
                  ],
                ),
                if (_exportando) ...[
                  const SizedBox(height: AppSpacing.sm),
                  const LinearProgressIndicator(),
                ],
              ],
            ),
          ),
        ];
      default:
        return [];
    }
  }

  Widget _botonDescarga(String label, IconData icon, VoidCallback onTap) {
    return ElevatedButton.icon(
      onPressed: _exportando ? null : onTap,
      icon: Icon(icon, size: 16),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.boton)),
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
              for (final a in grupos[clave]!) _filaAlumno(a),
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
        borderRadius: BorderRadius.circular(AppRadii.campo),
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
                const Icon(Icons.chevron_right, color: AppColors.texto),
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
          style: const TextStyle(
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
                                value: 'ayudante', child: Text('Ayudante')),
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
