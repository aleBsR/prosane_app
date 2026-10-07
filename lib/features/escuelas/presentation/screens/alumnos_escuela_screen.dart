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
import '../../../../core/providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../controllers/alumnos_escuela_controller.dart';
import '../controllers/mi_escuela_controller.dart';
import '../../data/alumnos_escuela_repository.dart';
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
              data: (alumnos) {
                final pendientes =
                    alumnos.where((a) => a.tutorDni.isEmpty).toList();
                final resto =
                    alumnos.where((a) => a.tutorDni.isNotEmpty).toList();
                return ListView(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  children: [
                    if (pendientes.isNotEmpty) ...[
                      _SeccionTitulo('Datos pendientes'),
                      for (final alumno in pendientes)
                        _filaAlumno(context, ref, alumno, pendiente: true),
                    ],
                    _SeccionTitulo('Alumnos'),
                    for (final alumno in resto)
                      _filaAlumno(context, ref, alumno),
                  ],
                );
              },
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

  Widget _filaAlumno(
      BuildContext context, WidgetRef ref, AlumnoEscuela alumno,
      {bool pendiente = false}) {
    final escuelaId = widget.escuelaId;
    final completo = !pendiente;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: AppCard(
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadii.campo),
          onTap: () {
            final ruta = escuelaId != null && escuelaId.isNotEmpty
                ? '/escuelas/alumnos/${alumno.id}?escuelaId=$escuelaId'
                : '/escuelas/alumnos/${alumno.id}';
            context.push(ruta);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${alumno.apellido}, ${alumno.nombre}',
                          style: AppTypography.subtitulo,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 2),
                      Text('${alumno.tipoDni} ${alumno.dni}',
                          style: AppTypography.texto.copyWith(
                              fontSize: 12,
                              color: AppColors.texto.withValues(alpha: 0.6))),
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

  Future<void> _mostrarFormulario(BuildContext context, WidgetRef ref) async {
    late final Map<String, dynamic> escuela;    late final List<Map<String, dynamic>> operativos;
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
    final tipoDoc = TextEditingController(text: 'DNI');
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
    // tutor (adulto responsable, opcional en esta etapa)
    final tutorNombre = TextEditingController();
    final tutorApellido = TextEditingController();
    final tutorDni = TextEditingController();
    final tutorTipoDoc = TextEditingController(text: 'DNI');
    final tutorParentesco = TextEditingController();
    final tutorSexo = TextEditingController();
    DateTime? tutorFechaNacimiento;
    String? dialogError;
    var validandoDni = false;
    var validandoTutorDni = false;
    // null = pendiente de validar (campos bloqueados), 'ok' | 'manual'.
    String? renaperA;
    String? renaperT;

    /// Autocompleta desde RENAPER (vía SAFESA). Solo pisa campos con datos.
    Future<void> validarRena(
        bool esTutor, void Function(void Function()) setSt) async {
      final dniCtrl = esTutor ? tutorDni : dni;
      final sexoCtrl = esTutor ? tutorSexo : sexo;
      if (dniCtrl.text.trim().isEmpty) {
        setSt(() => dialogError = 'Ingresá el DNI primero');
        return;
      }
      setSt(() {
        dialogError = null;
        if (esTutor) {
          validandoTutorDni = true;
        } else {
          validandoDni = true;
        }
      });
      try {
        final data = await ref.read(alumnosEscuelaRepositoryProvider).validarDni(
              dniCtrl.text.trim(),
              sexo: sexoCtrl.text.trim().isEmpty ? null : sexoCtrl.text.trim(),
            );
        final d = data['persona'] is Map
            ? Map<String, dynamic>.from(data['persona'] as Map)
            : data;
        String txt(dynamic v) => '${v ?? ''}'.trim();
        final apellidoTxt = txt(d['apellido'] ?? d['apellidos'] ?? d['lastName']);
        final nombresTxt = txt(d['nombres'] ?? d['nombre'] ?? d['firstName']);
        final fechaTxt = txt(d['fecha_nacimiento'] ?? d['fechaNacimiento'] ?? d['fecha_nac'] ?? d['f_nac']);
        final sx = txt(d['sexo'] ?? d['idSexo']).toUpperCase();
        final sexoUi = sx == 'M' || sx == 'MASCULINO' || sx == '1'
            ? 'masculino'
            : sx == 'F' || sx == 'FEMENINO' || sx == '2'
                ? 'femenino'
                : '';
        final localidadTxt = txt(d['ciudad'] ?? d['municipio'] ?? d['localidad']);
        DateTime? fechaDt;
        if (fechaTxt.isNotEmpty) {
          try {
            fechaDt = DateTime.parse(
                fechaTxt.length >= 10 ? fechaTxt.substring(0, 10) : fechaTxt);
          } catch (_) {}
        }
        setSt(() {
          if (esTutor) {
            if (apellidoTxt.isNotEmpty) tutorApellido.text = apellidoTxt;
            if (nombresTxt.isNotEmpty) tutorNombre.text = nombresTxt;
            if (sexoUi.isNotEmpty) tutorSexo.text = sexoUi;
            if (fechaDt != null) tutorFechaNacimiento = fechaDt;
            validandoTutorDni = false;
            renaperT = 'ok';
          } else {
            if (apellidoTxt.isNotEmpty) apellido.text = apellidoTxt;
            if (nombresTxt.isNotEmpty) nombre.text = nombresTxt;
            if (sexoUi.isNotEmpty) sexo.text = sexoUi;
            if (localidadTxt.isNotEmpty && localidad.text.trim().isEmpty) {
              localidad.text = localidadTxt;
            }
            if (fechaDt != null) fechaNacimiento = fechaDt;
            validandoDni = false;
            renaperA = 'ok';
          }
        });
        ref.read(notificacionProvider.notifier).exito('Datos de RENAPER cargados');
      } catch (e) {
        final noEncontrado = e.toString().contains('404');
        setSt(() {
          validandoDni = false;
          validandoTutorDni = false;
          if (esTutor) {
            renaperT = 'manual';
          } else {
            renaperA = 'manual';
          }
          dialogError = noEncontrado
              ? null
              : e.toString().replaceFirst('Exception: ', '');
        });
        ref.read(notificacionProvider.notifier).info(noEncontrado
            ? 'No está en RENAPER: cargá los datos manual'
            : 'Sin conexión con RENAPER: cargá manual');
      }
    }

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => WideFormDialog(
          title: 'Registrar alumno',
          error: dialogError,
          onSave: () async {
            if (dni.text.trim().isEmpty || operativoId == null) {
              setDialogState(() => dialogError = 'Completá DNI y operativo');
              return;
            }
            if (renaperA == null) {
              setDialogState(() => dialogError = 'Validá el DNI del alumno primero');
              return;
            }
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
            final tutorCampos = [tutorNombre, tutorApellido, tutorDni, tutorParentesco, tutorSexo];
            final tutorCompleto = tutorCampos.every((c) => c.text.trim().isNotEmpty) && tutorFechaNacimiento != null;
            if (renaperT == null) {
              setDialogState(() => dialogError = 'Validá el DNI del tutor primero');
              return;
            }
            if (!tutorCompleto) {
              setDialogState(() => dialogError = 'Completá los datos del tutor (obligatorio)');
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
                'tipo_dni': tipoDoc.text.trim().isEmpty ? 'DNI' : tipoDoc.text.trim(),
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
              if (tutorCompleto)
                'tutor': {
                  'persona': {
                    'nombre': tutorNombre.text.trim(),
                    'apellido': tutorApellido.text.trim(),
                    'dni': tutorDni.text.trim(),
                    'tipo_dni': tutorTipoDoc.text.trim().isEmpty ? 'DNI' : tutorTipoDoc.text.trim(),
                    'sexo': tutorSexo.text.trim(),
                    'fecha_nacimiento':
                        '${tutorFechaNacimiento!.year.toString().padLeft(4, '0')}-${tutorFechaNacimiento!.month.toString().padLeft(2, '0')}-${tutorFechaNacimiento!.day.toString().padLeft(2, '0')}',
                  },
                  'parentesco': tutorParentesco.text.trim(),
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
              AppDropdownField(
                label: 'Tipo de documento *',
                value: tipoDoc.text.isEmpty ? null : tipoDoc.text,
                items: const [
                  (value: 'DNI', label: 'DNI'),
                  (value: 'Pasaporte', label: 'Pasaporte'),
                ],
                onChanged: (v) => setDialogState(() => tipoDoc.text = v),
              ),
              const SizedBox(height: AppSpacing.sm),
              AppTextField(label: 'DNI *', controller: dni,
                  keyboardType: TextInputType.number,
                  onChanged: (_) => setDialogState(() => renaperA = null)),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: validandoDni
                      ? null
                      : () => validarRena(false, setDialogState),
                  child: Text(validandoDni ? 'Validando…' : 'Validar en RENAPER'),
                ),
              ),
              if (renaperA == null)
                Text('Validá el DNI para autocompletar. Si no está en RENAPER, igual podés cargar manual.',
                    style: AppTypography.texto.copyWith(
                        fontSize: 12,
                        color: AppColors.texto.withValues(alpha: 0.6))),
              if (renaperA == null) const SizedBox(height: AppSpacing.sm),
              AppTextField(label: 'Nombre *', controller: nombre,
                  readOnly: renaperA == null),
              const SizedBox(height: AppSpacing.sm),
              AppTextField(label: 'Apellido *', controller: apellido,
                  readOnly: renaperA == null),
              const SizedBox(height: AppSpacing.sm),
              IgnorePointer(
                ignoring: renaperA == null,
                child: Opacity(
                  opacity: renaperA == null ? 0.5 : 1,
                  child: AppDateField(
                    label: 'Fecha de nacimiento *',
                    value: fechaNacimiento,
                    hint: 'dd/mm/aaaa',
                    onChanged: (v) => setDialogState(() => fechaNacimiento = v),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              AppDropdownField(
                label: 'Sexo *',
                enabled: renaperA != null,
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
                  keyboardType: TextInputType.number,
                  readOnly: renaperA == null),
              const SizedBox(height: AppSpacing.sm),
              if (cursos.isEmpty && !esPlurigrado)
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.avisoFondo,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.aviso),
                  ),
                  child: Row(
                    children: [
                       Icon(Icons.info_outline, size: 16, color: AppColors.aviso),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text('Todavía no hay cursos. Creá uno para poder guardar.',
                            style: AppTypography.texto.copyWith(fontSize: 12, color: AppColors.aviso)),
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
                       Icon(Icons.info_outline, size: 16, color: AppColors.primario),
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
              Text('Adulto responsable - tutor (obligatorio)', style: AppTypography.subtitulo.copyWith(fontSize: 14)),
              const SizedBox(height: AppSpacing.sm),
              AppDropdownField(
                label: 'Tipo de documento del tutor',
                value: tutorTipoDoc.text.isEmpty ? null : tutorTipoDoc.text,
                items: const [
                  (value: 'DNI', label: 'DNI'),
                  (value: 'Pasaporte', label: 'Pasaporte'),
                ],
                onChanged: (v) => setDialogState(() => tutorTipoDoc.text = v),
              ),
              const SizedBox(height: AppSpacing.sm),
              AppTextField(label: 'DNI del tutor', controller: tutorDni,
                  keyboardType: TextInputType.number,
                  onChanged: (_) => setDialogState(() => renaperT = null)),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: validandoTutorDni
                      ? null
                      : () => validarRena(true, setDialogState),
                  child: Text(validandoTutorDni ? 'Validando…' : 'Validar en RENAPER'),
                ),
              ),
              if (renaperT == null)
                Text('Validá el DNI para autocompletar. Si no está en RENAPER, igual podés cargar manual.',
                    style: AppTypography.texto.copyWith(
                        fontSize: 12,
                        color: AppColors.texto.withValues(alpha: 0.6))),
              if (renaperT == null) const SizedBox(height: AppSpacing.sm),
              AppTextField(label: 'Nombre del tutor', controller: tutorNombre,
                  readOnly: renaperT == null),
              const SizedBox(height: AppSpacing.sm),
              AppTextField(label: 'Apellido del tutor', controller: tutorApellido,
                  readOnly: renaperT == null),
              const SizedBox(height: AppSpacing.sm),
              AppDropdownField(
                label: 'Parentesco',
                enabled: renaperT != null,
                value: tutorParentesco.text.isEmpty ? null : tutorParentesco.text,
                items: const [
                  (value: 'madre', label: 'Madre'),
                  (value: 'padre', label: 'Padre'),
                  (value: 'tutor_legal', label: 'Tutor/a legal'),
                  (value: 'otro', label: 'Otro'),
                ],
                onChanged: (v) => setDialogState(() => tutorParentesco.text = v),
              ),
              const SizedBox(height: AppSpacing.sm),
              AppDropdownField(
                label: 'Sexo del tutor',
                enabled: renaperT != null,
                value: tutorSexo.text.isEmpty ? null : tutorSexo.text,
                items: const [
                  (value: 'masculino', label: 'Masculino'),
                  (value: 'femenino', label: 'Femenino'),
                  (value: 'otro', label: 'Otro'),
                ],
                onChanged: (v) => setDialogState(() => tutorSexo.text = v),
              ),
              const SizedBox(height: AppSpacing.sm),
              IgnorePointer(
                ignoring: renaperT == null,
                child: Opacity(
                  opacity: renaperT == null ? 0.5 : 1,
                  child: AppDateField(
                    label: 'Fecha de nacimiento del tutor',
                    value: tutorFechaNacimiento,
                    hint: 'dd/mm/aaaa',
                    onChanged: (v) => setDialogState(() => tutorFechaNacimiento = v),
                  ),
                ),
              ),
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

/// Título de sección de la lista (espejo de .group-title web).
class _SeccionTitulo extends StatelessWidget {
  const _SeccionTitulo(this.texto);
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 12, 4, 8),
      child: Text(texto.toUpperCase(),
          style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
              color: Colors.white)),
    );
  }
}

