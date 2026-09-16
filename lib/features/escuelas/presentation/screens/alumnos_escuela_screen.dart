import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/design_system/app_button.dart';
import '../../../../core/design_system/app_card.dart';
import '../../../../core/design_system/app_dialog.dart';
import '../../../../core/design_system/app_date_field.dart';
import '../../../../core/design_system/app_dropdown_field.dart';
import '../../../../core/design_system/app_gradient_scaffold.dart';
import '../../../../core/design_system/app_text_field.dart';
import '../../../../core/notificaciones/notificacion_controller.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../controllers/alumnos_escuela_controller.dart';
import '../controllers/mi_escuela_controller.dart';
import '../../../operativos/presentation/controllers/operativos_list_controller.dart';

class AlumnosEscuelaScreen extends ConsumerStatefulWidget {
  const AlumnosEscuelaScreen(
      {super.key, this.escuelaId, this.escuelaNombre, this.abrirRegistro = false});

  /// Si viene [escuelaId], muestra los alumnos de esa escuela en modo solo
  /// lectura (detalle de escuela). Si no, funciona como "mi escuela" con
  /// registro incluido.
  final String? escuelaId;
  final String? escuelaNombre;

  /// Si es true (tile "Registrar alumno" del inicio), abre el formulario
  /// de alta automáticamente al entrar.
  final bool abrirRegistro;

  @override
  ConsumerState<AlumnosEscuelaScreen> createState() =>
      _AlumnosEscuelaScreenState();
}

class _AlumnosEscuelaScreenState
    extends ConsumerState<AlumnosEscuelaScreen> {
  bool _autoAbierto = false;

  bool get _soloLectura =>
      widget.escuelaId != null && widget.escuelaId!.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    // Apertura automática una sola vez (no se reabre al volver del formulario).
    if (widget.abrirRegistro && !_soloLectura && !_autoAbierto) {
      _autoAbierto = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _mostrarFormulario(context, ref);
      });
    }
    final alumnosAsync = _soloLectura
        ? ref.watch(alumnosPorEscuelaProvider(widget.escuelaId!))
        : ref.watch(alumnosEscuelaProvider);
    final state = ref.watch(alumnosEscuelaControllerProvider);
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
                    context.go('/inicio');
                  }
                },
              ),
              Expanded(
                child: Text(
                    _soloLectura
                        ? 'Alumnos de ${widget.escuelaNombre ?? 'la escuela'}'
                        : 'Alumnos de mi escuela',
                    style: AppTypography.titulo.copyWith(
                        color: AppColors.blanco, fontSize: 22),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ),
            ]),
          ),
          Expanded(
            child: alumnosAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (alumnos) => ListView.builder(
                padding: const EdgeInsets.all(AppSpacing.md),
                itemCount: alumnos.length,
                itemBuilder: (context, index) {
                  final alumno = alumnos[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${alumno.apellido}, ${alumno.nombre}',
                              style: AppTypography.subtitulo),
                          const SizedBox(height: 4),
                          Text('DNI ${alumno.dni} • ${alumno.edad} años • ${alumno.sexo}',
                              style: AppTypography.texto.copyWith(fontSize: 12)),
                          if (alumno.localidad.isNotEmpty)
                            Text(alumno.localidad,
                                style: AppTypography.texto.copyWith(
                                    fontSize: 12,
                                    color: AppColors.texto.withValues(alpha: 0.6))),
                          if (alumno.celular.isNotEmpty || alumno.telefonoFijo.isNotEmpty)
                            Text([if (alumno.celular.isNotEmpty) 'Cel: ${alumno.celular}', if (alumno.telefonoFijo.isNotEmpty) 'Tel: ${alumno.telefonoFijo}'].join(' • '),
                                style: AppTypography.texto.copyWith(fontSize: 11, color: AppColors.texto.withValues(alpha: 0.6))),
                          if (alumno.operativos.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text('Operativos: ${alumno.operativos.map((o) => o['nombre'] ?? o['id']).join(', ')}',
                                  style: AppTypography.texto.copyWith(fontSize: 11, color: AppColors.primario)),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          if (_soloLectura)
            const SizedBox(height: AppSpacing.md)
          else
            Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: AppButton(
              label: 'Registrar alumno',
              isLoading: state.guardando,
              onPressed: state.guardando
                  ? null
                  : () => _mostrarFormulario(context, ref),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _mostrarFormulario(BuildContext context, WidgetRef ref) async {
    late final Map<String, dynamic> escuela;
    late final List<Map<String, dynamic>> operativos;
    try {
      escuela = await ref.read(miEscuelaProvider.future);
      operativos = await ref.read(operativosListControllerProvider.future);
    } catch (e) {
      if (context.mounted) {
        ref.read(notificacionProvider.notifier).error('No se pudieron cargar cursos y operativos.');
      }
      return;
    }
    if (!context.mounted) return;
    final escuelaId = (escuela['id'] ?? '').toString();
    final cursos = (escuela['cursos'] as List?)
            ?.whereType<Map>()
            .map((e) => e.cast<String, dynamic>())
            .toList() ??
        <Map<String, dynamic>>[];
    final esPlurigrado = escuela['plurigrado_rural'] == true;
    final permiteSinCurso = esPlurigrado;
    // El formulario abre directo: si faltan cursos, el aviso va adentro
    // del propio formulario (sin diálogos intermedios).
    if (cursos.isEmpty && permiteSinCurso && context.mounted) {
      ref.read(notificacionProvider.notifier).exito('Escuela plurigrado sin cursos: podés registrar sin curso (se usará "Plurigrado" por defecto).');
    }
    final nombre = TextEditingController();
    final apellido = TextEditingController();
    final dni = TextEditingController();
    DateTime? fechaNacimiento;
    final sexo = TextEditingController();
    final edad = TextEditingController();
    final localidad = TextEditingController();
    final telefono = TextEditingController();
    final telefonoFijo = TextEditingController();
    final tieneCud = TextEditingController();
    final tipoCobertura = TextEditingController();
    final nombreCobertura = TextEditingController();
    String? cursoId;
    String? operativoId;
    // antecedentes básicos
    final nacioPrematuro = TextEditingController(text: 'NO');
    final pesoNacimiento = TextEditingController(text: '0');
    final asma = TextEditingController(text: 'NO');
    final otrosProblemas = TextEditingController(text: 'NINGUNO');
    String? dialogError;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => WideFormDialog(
          title: 'Registrar alumno',
          error: dialogError,
          onSave: () async {
            if ([nombre, apellido, dni, sexo, edad].any((c) => c.text.trim().isEmpty) || fechaNacimiento == null) {
              setDialogState(() => dialogError = 'Faltan campos obligatorios (*)');
              return;
            }
            if (cursoId == null && !esPlurigrado) {
              setDialogState(() => dialogError = 'Elegí un curso');
              return;
            }
            if (operativoId == null) {
              setDialogState(() => dialogError = 'Elegí un operativo');
              return;
            }
            // Plurigrado sin curso: usar curso por defecto (null → backend lo trata como Plurigrado)
            String? cursoIdFinal = cursoId;
            if (esPlurigrado && cursoId == null && cursos.isEmpty) {
              // No hay curso creado: se enviará sin curso_id y el backend lo dejará como plurigrado por defecto
              cursoIdFinal = null;
            }
            final fechaIso = fechaNacimiento != null
                ? '${fechaNacimiento!.year.toString().padLeft(4, '0')}-${fechaNacimiento!.month.toString().padLeft(2, '0')}-${fechaNacimiento!.day.toString().padLeft(2, '0')}'
                : '';
            final payload = {
              'persona': {
                'nombre': nombre.text.trim(),
                'apellido': apellido.text.trim(),
                'dni': dni.text.trim(),
                'tipo_dni': 'DNI',
                'sexo': sexo.text.trim(),
                'fecha_nacimiento': fechaIso,
              },
              'edad': int.tryParse(edad.text.trim()) ?? 0,
              'domicilio': {'localidad': localidad.text.trim()},
              'curso_id': ?cursoIdFinal,
              'operativo_id': ?operativoId,
              if (telefono.text.trim().isNotEmpty) 'celular': telefono.text.trim(),
              if (telefonoFijo.text.trim().isNotEmpty) 'telefono_fijo': telefonoFijo.text.trim(),
              if (tieneCud.text.trim().isNotEmpty) 'tiene_cud': tieneCud.text.trim(),
              if (tipoCobertura.text.trim().isNotEmpty) 'tipo_cobertura': tipoCobertura.text.trim(),
              if (nombreCobertura.text.trim().isNotEmpty) 'nombre_cobertura': nombreCobertura.text.trim(),
              'antecedentes': {
                if (nacioPrematuro.text.trim().isNotEmpty) 'nacio_prematuro': nacioPrematuro.text.trim(),
                if (pesoNacimiento.text.trim().isNotEmpty) 'peso_nacimiento': pesoNacimiento.text.trim(),
                if (asma.text.trim().isNotEmpty) 'asma_espasmos': asma.text.trim(),
                if (otrosProblemas.text.trim().isNotEmpty) 'otros_problemas_salud': otrosProblemas.text.trim(),
              },
            };
            final ctrl = ref.read(alumnosEscuelaControllerProvider.notifier);
            final ok = await ctrl.crear(payload);
            if (!ok) {
              final err = ref.read(alumnosEscuelaControllerProvider).error ?? 'Error al registrar alumno';
              String friendly = err;
              if (err.contains('persona.dni') && err.contains('Ya existe')) {
                friendly = 'Ya existe una persona con este DNI. Verificá el DNI o usá otro.';
              } else if (err.contains('fecha_nacimiento') || err.contains('Fecha con formato')) {
                friendly = 'Fecha de nacimiento inválida. Usá el calendario (dd/mm/aaaa) y revisá el año.';
              } else if (err.contains('persona.')) {
                friendly = err.replaceAll('persona.', '').replaceAll('_', ' ');
              }
              setDialogState(() => dialogError = friendly);
              return;
            }
            if (dialogContext.mounted) Navigator.pop(dialogContext);
            ref.invalidate(alumnosEscuelaProvider);
            if (context.mounted) {
              ref.read(notificacionProvider.notifier).exito('¡Alumno registrado!');
            }
          },
          onCancel: () => Navigator.pop(dialogContext),
          children: [
              AppTextField(label: 'Nombre *', controller: nombre),
              const SizedBox(height: AppSpacing.sm),
              AppTextField(label: 'Apellido *', controller: apellido),
              const SizedBox(height: AppSpacing.sm),
              AppTextField(label: 'DNI *', controller: dni,
                  keyboardType: TextInputType.number),
              const SizedBox(height: AppSpacing.sm),
              AppDateField(
                label: 'Fecha de nacimiento *',
                value: fechaNacimiento,
                hint: 'dd/mm/aaaa',
                onChanged: (v) => setDialogState(() => fechaNacimiento = v),
              ),
              const SizedBox(height: AppSpacing.sm),
              AppDropdownField(
                label: 'Sexo *',
                value: sexo.text.isEmpty ? null : sexo.text,
                items: const [
                  (value: 'masculino', label: 'Masculino'),
                  (value: 'femenino', label: 'Femenino'),
                  (value: 'otro', label: 'Otro'),
                ],
                onChanged: (v) => setDialogState(() => sexo.text = v),
              ),
              const SizedBox(height: AppSpacing.sm),
              AppTextField(label: 'Edad *', controller: edad,
                  keyboardType: TextInputType.number),
              const SizedBox(height: AppSpacing.sm),
              if (cursos.isEmpty && !esPlurigrado)
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3E0),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFFFB74D)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, size: 16, color: Color(0xFFE65100)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text('Todavía no hay cursos. Creá uno para poder guardar.',
                            style: AppTypography.texto.copyWith(fontSize: 12, color: Color(0xFFE65100))),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(dialogContext);
                          if (escuelaId.isNotEmpty && context.mounted) {
                            context.push('/escuelas/$escuelaId/cursos');
                          }
                        },
                        child: const Text('Crear curso'),
                      ),
                    ],
                  ),
                )
              else if (esPlurigrado && cursos.isEmpty)
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.campo,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.primario.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, size: 16, color: AppColors.primario),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text('Curso: Plurigrado (por defecto) — no hace falta seleccionar',
                            style: AppTypography.texto.copyWith(fontSize: 12, color: AppColors.primario)),
                      ),
                    ],
                  ),
                )
              else
                DropdownButtonFormField<String>(
                  key: ValueKey('curso-$cursoId'),
                  initialValue: cursoId,
                  isExpanded: true,
                  decoration: InputDecoration(labelText: esPlurigrado ? 'Curso (opcional - plurigrado)' : 'Curso *'),
                  hint: Text(esPlurigrado ? 'Seleccioná o dejá vacío para "Plurigrado"' : 'Seleccioná un curso'),
                  items: cursos.map((curso) {
                    final id = '${curso['id']}';
                    return DropdownMenuItem<String>(
                      value: id,
                      child: Text('${curso['sala_grado_anio'] ?? ''} ${curso['division'] ?? ''}'),
                    );
                  }).toList(),
                  onChanged: (value) => setDialogState(() => cursoId = value),
                ),
              const SizedBox(height: AppSpacing.sm),
              DropdownButtonFormField<String>(
                key: ValueKey('operativo-$operativoId'),
                initialValue: operativoId,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Operativo'),
                hint: const Text('Seleccioná un operativo'),
                items: operativos.map((operativo) {
                  final id = '${operativo['id']}';
                  final nombre = '${operativo['nombre'] ?? 'Operativo'}';
                  final fecha = '${operativo['fecha'] ?? ''}';
                  return DropdownMenuItem<String>(
                    value: id,
                    child: Text('$nombre • $fecha', overflow: TextOverflow.ellipsis),
                  );
                }).toList(),
                onChanged: (value) => setDialogState(() => operativoId = value),
              ),
              const SizedBox(height: AppSpacing.sm),
              AppTextField(label: 'Localidad', controller: localidad),
              const SizedBox(height: AppSpacing.sm),
              AppTextField(label: 'Celular', controller: telefono,
                  keyboardType: TextInputType.phone),
              const SizedBox(height: AppSpacing.sm),
              AppTextField(label: 'Teléfono fijo', controller: telefonoFijo,
                  keyboardType: TextInputType.phone),
              const SizedBox(height: AppSpacing.sm),
              AppDropdownField(
                label: '¿Tiene CUD?',
                value: tieneCud.text.isEmpty ? null : tieneCud.text,
                items: const [(value: 'SI', label: 'Sí'), (value: 'NO', label: 'No')],
                onChanged: (v) => setDialogState(() => tieneCud.text = v),
              ),
              const SizedBox(height: AppSpacing.sm),
              AppDropdownField(
                label: 'Tipo cobertura',
                value: tipoCobertura.text.isEmpty ? null : tipoCobertura.text,
                items: const [
                  (value: 'obra_social', label: 'Obra Social (incluye PAMI)'),
                  (value: 'estatal', label: 'Programas o planes estatales'),
                  (value: 'prepaga', label: 'Plan privado o Prepaga'),
                  (value: 'sin_cobertura', label: 'No tiene'),
                ],
                onChanged: (v) => setDialogState(() => tipoCobertura.text = v),
              ),
              const SizedBox(height: AppSpacing.sm),
              AppTextField(label: 'Nombre cobertura', controller: nombreCobertura),
              const SizedBox(height: AppSpacing.md),
              Text('Antecedentes (opcional)', style: AppTypography.subtitulo.copyWith(fontSize: 14)),
              const SizedBox(height: AppSpacing.sm),
              AppDropdownField(
                label: 'Nació prematuro',
                value: nacioPrematuro.text.isEmpty ? null : nacioPrematuro.text,
                items: const [(value: 'SI', label: 'Sí'), (value: 'NO', label: 'No'), (value: 'NO_SABE', label: 'No sabe')],
                onChanged: (v) => setDialogState(() => nacioPrematuro.text = v),
              ),
              const SizedBox(height: AppSpacing.sm),
              AppTextField(label: 'Peso al nacer', controller: pesoNacimiento),
              const SizedBox(height: AppSpacing.sm),
              AppDropdownField(
                label: 'Asma/Espasmos',
                value: asma.text.isEmpty ? null : asma.text,
                items: const [(value: 'SI', label: 'Sí'), (value: 'NO', label: 'No'), (value: 'NO_SABE', label: 'No sabe')],
                onChanged: (v) => setDialogState(() => asma.text = v),
              ),
              const SizedBox(height: AppSpacing.sm),
              AppTextField(label: 'Otros problemas de salud', controller: otrosProblemas),
          ],
        ),
      ),
    );
  }
}

