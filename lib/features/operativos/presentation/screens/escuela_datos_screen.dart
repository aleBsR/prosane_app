import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/design_system/app_button.dart';
import '../../../../core/design_system/app_card.dart';
import '../../../../core/design_system/app_dropdown_field.dart';
import '../../../../core/design_system/app_gradient_scaffold.dart';
import '../../../../core/design_system/app_text_field.dart';
import '../../../../core/notificaciones/notificacion_controller.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/providers.dart';
import '../controllers/operativo_detail_controller.dart';

class EscuelaDatosScreen extends ConsumerStatefulWidget {
  const EscuelaDatosScreen({super.key, required this.operativoId, required this.alumnoId});
  final String operativoId;
  final String alumnoId;
  @override
  ConsumerState<EscuelaDatosScreen> createState() => _EscuelaDatosScreenState();
}

class _EscuelaDatosScreenState extends ConsumerState<EscuelaDatosScreen> {
  bool _cargando = true;
  bool _guardando = false;
  String? _error;
  final _nombre = TextEditingController();
  final _apellido = TextEditingController();
  final _dni = TextEditingController();
  final _fecha = TextEditingController();
  final _sexo = TextEditingController();
  final _edad = TextEditingController();
  final _localidad = TextEditingController();
  final _telefono = TextEditingController();
  final _telefonoFijo = TextEditingController();
  final _tieneCud = TextEditingController();
  final _tipoCobertura = TextEditingController();
  final _nombreCobertura = TextEditingController();
  final _nacioPrematuro = TextEditingController();
  final _pesoNacimiento = TextEditingController();
  final _convulsiones = TextEditingController();
  final _mareos = TextEditingController();
  final _infeccionesUr = TextEditingController();
  final _asma = TextEditingController();
  final _tuberculosis = TextEditingController();
  final _diabetes = TextEditingController();
  final _hipertension = TextEditingController();
  final _cardiopatia = TextEditingController();
  final _traumatismo = TextEditingController();
  final _diarrea = TextEditingController();
  final _infeccionesOido = TextEditingController();
  final _internacionPrevia = TextEditingController();
  final _causaHosp = TextEditingController();
  final _tratamientoActual = TextEditingController();
  final _descTrat = TextEditingController();
  final _ultimaConsulta = TextEditingController();
  final _otros = TextEditingController();
  final _primeraMenst = TextEditingController();
  final _edadPrimeraMenst = TextEditingController();

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  @override
  void dispose() {
    _nombre.dispose();
    _apellido.dispose();
    _dni.dispose();
    _fecha.dispose();
    _sexo.dispose();
    _edad.dispose();
    _localidad.dispose();
    _telefono.dispose();
    _telefonoFijo.dispose();
    _tieneCud.dispose();
    _tipoCobertura.dispose();
    _nombreCobertura.dispose();
    _nacioPrematuro.dispose();
    _pesoNacimiento.dispose();
    _convulsiones.dispose();
    _mareos.dispose();
    _infeccionesUr.dispose();
    _asma.dispose();
    _tuberculosis.dispose();
    _diabetes.dispose();
    _hipertension.dispose();
    _cardiopatia.dispose();
    _traumatismo.dispose();
    _diarrea.dispose();
    _infeccionesOido.dispose();
    _internacionPrevia.dispose();
    _causaHosp.dispose();
    _tratamientoActual.dispose();
    _descTrat.dispose();
    _ultimaConsulta.dispose();
    _otros.dispose();
    _primeraMenst.dispose();
    _edadPrimeraMenst.dispose();
    super.dispose();
  }

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final repo = ref.read(operativosRepositoryProvider);
      final data = await repo.getDatosAlumno(widget.operativoId, widget.alumnoId);
      final opAl = data['operativo_alumno'] as Map<String, dynamic>? ?? {};
      final paciente = data['paciente'] as Map<String, dynamic>?;
      final persona = data['persona'] as Map<String, dynamic>?;
      final domicilio = data['domicilio'] as Map<String, dynamic>?;
      final ant = data['antecedentes'] as Map<String, dynamic>?;
      if (!mounted) return;
      setState(() {
        _nombre.text = (persona?['nombre'] ?? opAl['nombre'] ?? '').toString();
        _apellido.text = (persona?['apellido'] ?? opAl['apellido'] ?? '').toString();
        _dni.text = (persona?['dni'] ?? opAl['dni'] ?? '').toString();
        _fecha.text = (persona?['fecha_nacimiento'] ?? opAl['fecha_nacimiento'] ?? '').toString();
        _sexo.text = (persona?['sexo'] ?? opAl['sexo'] ?? '').toString();
        _edad.text = (paciente?['edad'] ?? '').toString();
        _localidad.text = (domicilio?['localidad'] ?? '').toString();
        _telefono.text = (paciente?['celular'] ?? '').toString();
        _telefonoFijo.text = (paciente?['telefono_fijo'] ?? '').toString();
        _tieneCud.text = (paciente?['tiene_cud'] ?? '').toString();
        _tipoCobertura.text = (paciente?['tipo_cobertura'] ?? '').toString();
        _nombreCobertura.text = (paciente?['nombre_cobertura'] ?? '').toString();
        _nacioPrematuro.text = (ant?['nacio_prematuro'] ?? 'NO').toString();
        _pesoNacimiento.text = (ant?['peso_nacimiento'] ?? '0').toString();
        _convulsiones.text = (ant?['convulsiones_epilepsia'] ?? 'NO').toString();
        _mareos.text = (ant?['mareos_desmayos'] ?? 'NO').toString();
        _infeccionesUr.text = (ant?['infecciones_urinarias'] ?? 'NO').toString();
        _asma.text = (ant?['asma_espasmos'] ?? 'NO').toString();
        _tuberculosis.text = (ant?['tuberculosis'] ?? 'NO').toString();
        _diabetes.text = (ant?['diabetes'] ?? 'NO').toString();
        _hipertension.text = (ant?['hipertension'] ?? 'NO').toString();
        _cardiopatia.text = (ant?['cardiopatia_congenita'] ?? 'NO').toString();
        _traumatismo.text = (ant?['traumatismo_internacion'] ?? 'NO').toString();
        _diarrea.text = (ant?['diarrea_frecuente'] ?? 'NO').toString();
        _infeccionesOido.text = (ant?['infecciones_oido'] ?? 'NO').toString();
        _internacionPrevia.text = (ant?['internacion_previa'] ?? 'NO').toString();
        _causaHosp.text = (ant?['causa_hospitalizacion'] ?? 'NO').toString();
        _tratamientoActual.text = (ant?['tratamiento_actual'] ?? 'NO').toString();
        _descTrat.text = (ant?['descripcion_tratamiento'] ?? 'NINGUNO').toString();
        _ultimaConsulta.text = (ant?['ultima_consulta_medica'] ?? 'NINGUNA').toString();
        _otros.text = (ant?['otros_problemas_salud'] ?? 'NINGUNO').toString();
        _primeraMenst.text = (ant?['primera_menstruacion'] ?? 'NO').toString();
        _edadPrimeraMenst.text = (ant?['edad_primera_menstruacion'] ?? '0').toString();
        _cargando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _cargando = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _guardar() async {
    if (_nombre.text.trim().isEmpty || _apellido.text.trim().isEmpty || _dni.text.trim().isEmpty) {
      setState(() => _error = 'Nombre, apellido y DNI son obligatorios');
      return;
    }
    setState(() {
      _guardando = true;
      _error = null;
    });
    try {
      final repo = ref.read(operativosRepositoryProvider);
      final payload = {
        'nombre': _nombre.text.trim(),
        'apellido': _apellido.text.trim(),
        'dni': _dni.text.trim(),
        'fecha_nacimiento': _fecha.text.trim(),
        'sexo': _sexo.text.trim(),
        'edad': int.tryParse(_edad.text.trim()) ?? 0,
        'localidad': _localidad.text.trim(),
        'celular': _telefono.text.trim(),
        'telefono_fijo': _telefonoFijo.text.trim(),
        'tiene_cud': _tieneCud.text.trim(),
        'tipo_cobertura': _tipoCobertura.text.trim(),
        'nombre_cobertura': _nombreCobertura.text.trim(),
        'antecedentes': {
          'nacio_prematuro': _nacioPrematuro.text.trim(),
          'peso_nacimiento': _pesoNacimiento.text.trim(),
          'convulsiones_epilepsia': _convulsiones.text.trim(),
          'mareos_desmayos': _mareos.text.trim(),
          'infecciones_urinarias': _infeccionesUr.text.trim(),
          'asma_espasmos': _asma.text.trim(),
          'tuberculosis': _tuberculosis.text.trim(),
          'diabetes': _diabetes.text.trim(),
          'hipertension': _hipertension.text.trim(),
          'cardiopatia_congenita': _cardiopatia.text.trim(),
          'traumatismo_internacion': _traumatismo.text.trim(),
          'diarrea_frecuente': _diarrea.text.trim(),
          'infecciones_oido': _infeccionesOido.text.trim(),
          'internacion_previa': _internacionPrevia.text.trim(),
          'causa_hospitalizacion': _causaHosp.text.trim(),
          'tratamiento_actual': _tratamientoActual.text.trim(),
          'descripcion_tratamiento': _descTrat.text.trim(),
          'ultima_consulta_medica': _ultimaConsulta.text.trim(),
          'otros_problemas_salud': _otros.text.trim(),
          'primera_menstruacion': _primeraMenst.text.trim(),
          'edad_primera_menstruacion': int.tryParse(_edadPrimeraMenst.text.trim()) ?? 0,
        },
      };
      await repo.patchDatosAlumno(widget.operativoId, widget.alumnoId, payload);
      if (!mounted) return;
      setState(() => _guardando = false);
      ref.read(notificacionProvider.notifier).exito('Datos guardados');
      ref.invalidate(alumnosProvider(widget.operativoId));
      ref.invalidate(operativoDetailProvider(widget.operativoId));
      context.pop();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _guardando = false;
      });
      ref.read(notificacionProvider.notifier).error(_error!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final operativoAsync = ref.watch(operativoDetailProvider(widget.operativoId));
    final esNoEditable = operativoAsync.maybeWhen(
      data: (op) => op['estado'] == 'finalizado' || op['estado'] == 'cancelado',
      orElse: () => false,
    );
    return AppGradientScaffold(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            child: Row(children: [
              IconButton(icon: const Icon(Icons.arrow_back, color: AppColors.blanco), onPressed: () => context.pop()),
              Expanded(child: Text(esNoEditable ? 'Datos del alumno — solo lectura' : 'Datos del alumno', style: AppTypography.titulo.copyWith(color: AppColors.blanco, fontSize: 20))),
            ]),
          ),
          Expanded(
            child: _cargando
                ? const Center(child: CircularProgressIndicator(color: AppColors.blanco))
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (esNoEditable) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6), border: Border.all(color: Colors.green.withValues(alpha: 0.3))),
                            child: Row(children: [const Icon(Icons.lock_outline, size: 14, color: Colors.green), const SizedBox(width: 6), Expanded(child: Text('Operativo finalizado — solo lectura', style: AppTypography.texto.copyWith(fontSize: 12, color: Colors.green)))]),
                          ),
                          const SizedBox(height: AppSpacing.md),
                        ],
                        AbsorbPointer(
                          absorbing: esNoEditable,
                          child: Opacity(
                            opacity: esNoEditable ? 0.85 : 1,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                AppCard(
                                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                                    Text('Datos personales', style: AppTypography.subtitulo),
                                    const SizedBox(height: AppSpacing.md),
                                    AppTextField(label: 'Nombre *', controller: _nombre),
                                    const SizedBox(height: AppSpacing.sm),
                                    AppTextField(label: 'Apellido *', controller: _apellido),
                                    const SizedBox(height: AppSpacing.sm),
                                    AppTextField(label: 'DNI *', controller: _dni, keyboardType: TextInputType.number),
                                    const SizedBox(height: AppSpacing.sm),
                                    AppTextField(label: 'Fecha nacimiento (AAAA-MM-DD)', controller: _fecha),
                                    const SizedBox(height: AppSpacing.sm),
                                    AppDropdownField(
                                      label: 'Sexo',
                                      value: _sexo.text.isEmpty ? null : _sexo.text,
                                      items: const [
                                        (value: 'masculino', label: 'Masculino'),
                                        (value: 'femenino', label: 'Femenino'),
                                        (value: 'otro', label: 'Otro'),
                                      ],
                                      onChanged: (v) => setState(() => _sexo.text = v),
                                    ),
                                    const SizedBox(height: AppSpacing.sm),
                                    AppTextField(label: 'Edad', controller: _edad, keyboardType: TextInputType.number),
                                    const SizedBox(height: AppSpacing.sm),
                                    AppTextField(label: 'Localidad', controller: _localidad),
                                  ]),
                                ),
                                const SizedBox(height: AppSpacing.md),
                                AppCard(
                                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                                    Text('Cobertura y contacto', style: AppTypography.subtitulo),
                                    const SizedBox(height: AppSpacing.md),
                                    AppTextField(label: 'Celular', controller: _telefono, keyboardType: TextInputType.phone),
                                    const SizedBox(height: AppSpacing.sm),
                                    AppTextField(label: 'Teléfono fijo', controller: _telefonoFijo, keyboardType: TextInputType.phone),
                                    const SizedBox(height: AppSpacing.sm),
                                    AppDropdownField(
                                      label: '¿Tiene CUD?',
                                      value: _tieneCud.text.isEmpty ? null : _tieneCud.text,
                                      items: const [(value: 'SI', label: 'Sí'), (value: 'NO', label: 'No')],
                                      onChanged: (v) => setState(() => _tieneCud.text = v),
                                    ),
                                    const SizedBox(height: AppSpacing.sm),
                                    AppDropdownField(
                                      label: 'Tipo cobertura',
                                      value: _tipoCobertura.text.isEmpty ? null : _tipoCobertura.text,
                                      items: const [
                                        (value: 'obra_social', label: 'Obra Social (incluye PAMI)'),
                                        (value: 'estatal', label: 'Programas o planes estatales'),
                                        (value: 'prepaga', label: 'Plan privado o Prepaga'),
                                        (value: 'sin_cobertura', label: 'No tiene'),
                                      ],
                                      onChanged: (v) => setState(() => _tipoCobertura.text = v),
                                    ),
                                    const SizedBox(height: AppSpacing.sm),
                                    AppTextField(label: 'Nombre cobertura', controller: _nombreCobertura),
                                  ]),
                                ),
                                const SizedBox(height: AppSpacing.md),
                                AppCard(
                                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                                    Text('Antecedentes personales — tabla antecedentespersonales', style: AppTypography.subtitulo),
                                    const SizedBox(height: 4),
                                    Text('Todos los campos de la tabla se pueden cargar aquí.', style: AppTypography.texto.copyWith(fontSize: 11, color: AppColors.texto.withValues(alpha: 0.6))),
                                    const SizedBox(height: AppSpacing.sm),
                                    AppDropdownField(
                                      label: 'Nació prematuro',
                                      value: _nacioPrematuro.text.isEmpty ? null : _nacioPrematuro.text,
                                      items: const [(value: 'SI', label: 'Sí'), (value: 'NO', label: 'No'), (value: 'NO_SABE', label: 'No sabe')],
                                      onChanged: (v) => setState(() => _nacioPrematuro.text = v),
                                    ),
                                    const SizedBox(height: AppSpacing.sm),
                                    AppTextField(label: 'Peso al nacer', controller: _pesoNacimiento),
                                    const SizedBox(height: AppSpacing.sm),
                                    AppDropdownField(
                                      label: 'Convulsiones/Epilepsia',
                                      value: _convulsiones.text.isEmpty ? null : _convulsiones.text,
                                      items: const [(value: 'SI', label: 'Sí'), (value: 'NO', label: 'No'), (value: 'NO_SABE', label: 'No sabe')],
                                      onChanged: (v) => setState(() => _convulsiones.text = v),
                                    ),
                                    const SizedBox(height: AppSpacing.sm),
                                    AppDropdownField(
                                      label: 'Mareos/Desmayos',
                                      value: _mareos.text.isEmpty ? null : _mareos.text,
                                      items: const [(value: 'SI', label: 'Sí'), (value: 'NO', label: 'No'), (value: 'NO_SABE', label: 'No sabe')],
                                      onChanged: (v) => setState(() => _mareos.text = v),
                                    ),
                                    const SizedBox(height: AppSpacing.sm),
                                    AppDropdownField(
                                      label: 'Infecciones urinarias',
                                      value: _infeccionesUr.text.isEmpty ? null : _infeccionesUr.text,
                                      items: const [(value: 'SI', label: 'Sí'), (value: 'NO', label: 'No'), (value: 'NO_SABE', label: 'No sabe')],
                                      onChanged: (v) => setState(() => _infeccionesUr.text = v),
                                    ),
                                    const SizedBox(height: AppSpacing.sm),
                                    AppDropdownField(
                                      label: 'Asma/Espasmos',
                                      value: _asma.text.isEmpty ? null : _asma.text,
                                      items: const [(value: 'SI', label: 'Sí'), (value: 'NO', label: 'No'), (value: 'NO_SABE', label: 'No sabe')],
                                      onChanged: (v) => setState(() => _asma.text = v),
                                    ),
                                    const SizedBox(height: AppSpacing.sm),
                                    AppDropdownField(
                                      label: 'Tuberculosis',
                                      value: _tuberculosis.text.isEmpty ? null : _tuberculosis.text,
                                      items: const [(value: 'SI', label: 'Sí'), (value: 'NO', label: 'No'), (value: 'NO_SABE', label: 'No sabe')],
                                      onChanged: (v) => setState(() => _tuberculosis.text = v),
                                    ),
                                    const SizedBox(height: AppSpacing.sm),
                                    AppDropdownField(
                                      label: 'Diabetes',
                                      value: _diabetes.text.isEmpty ? null : _diabetes.text,
                                      items: const [(value: 'SI', label: 'Sí'), (value: 'NO', label: 'No'), (value: 'NO_SABE', label: 'No sabe')],
                                      onChanged: (v) => setState(() => _diabetes.text = v),
                                    ),
                                    const SizedBox(height: AppSpacing.sm),
                                    AppDropdownField(
                                      label: 'Hipertensión',
                                      value: _hipertension.text.isEmpty ? null : _hipertension.text,
                                      items: const [(value: 'SI', label: 'Sí'), (value: 'NO', label: 'No'), (value: 'NO_SABE', label: 'No sabe')],
                                      onChanged: (v) => setState(() => _hipertension.text = v),
                                    ),
                                    const SizedBox(height: AppSpacing.sm),
                                    AppDropdownField(
                                      label: 'Cardiopatía congénita',
                                      value: _cardiopatia.text.isEmpty ? null : _cardiopatia.text,
                                      items: const [(value: 'SI', label: 'Sí'), (value: 'NO', label: 'No'), (value: 'NO_SABE', label: 'No sabe')],
                                      onChanged: (v) => setState(() => _cardiopatia.text = v),
                                    ),
                                    const SizedBox(height: AppSpacing.sm),
                                    AppDropdownField(
                                      label: 'Traumatismo/Internación',
                                      value: _traumatismo.text.isEmpty ? null : _traumatismo.text,
                                      items: const [(value: 'SI', label: 'Sí'), (value: 'NO', label: 'No'), (value: 'NO_SABE', label: 'No sabe')],
                                      onChanged: (v) => setState(() => _traumatismo.text = v),
                                    ),
                                    const SizedBox(height: AppSpacing.sm),
                                    AppDropdownField(
                                      label: 'Diarrea frecuente',
                                      value: _diarrea.text.isEmpty ? null : _diarrea.text,
                                      items: const [(value: 'SI', label: 'Sí'), (value: 'NO', label: 'No'), (value: 'NO_SABE', label: 'No sabe')],
                                      onChanged: (v) => setState(() => _diarrea.text = v),
                                    ),
                                    const SizedBox(height: AppSpacing.sm),
                                    AppDropdownField(
                                      label: 'Infecciones oído',
                                      value: _infeccionesOido.text.isEmpty ? null : _infeccionesOido.text,
                                      items: const [(value: 'SI', label: 'Sí'), (value: 'NO', label: 'No'), (value: 'NO_SABE', label: 'No sabe')],
                                      onChanged: (v) => setState(() => _infeccionesOido.text = v),
                                    ),
                                    const SizedBox(height: AppSpacing.sm),
                                    AppDropdownField(
                                      label: '¿Alguna vez estuvo internado?',
                                      value: _internacionPrevia.text.isEmpty ? null : _internacionPrevia.text,
                                      items: const [(value: 'SI', label: 'Sí'), (value: 'NO', label: 'No'), (value: 'NO_SABE', label: 'No sabe')],
                                      onChanged: (v) => setState(() => _internacionPrevia.text = v),
                                    ),
                                    const SizedBox(height: AppSpacing.sm),
                                    AppTextField(label: 'Causa hospitalización', controller: _causaHosp),
                                    const SizedBox(height: AppSpacing.sm),
                                    AppDropdownField(
                                      label: 'Tratamiento actual',
                                      value: _tratamientoActual.text.isEmpty ? null : _tratamientoActual.text,
                                      items: const [(value: 'SI', label: 'Sí'), (value: 'NO', label: 'No'), (value: 'NO_SABE', label: 'No sabe')],
                                      onChanged: (v) => setState(() => _tratamientoActual.text = v),
                                    ),
                                    const SizedBox(height: AppSpacing.sm),
                                    AppTextField(label: 'Descripción tratamiento', controller: _descTrat),
                                    const SizedBox(height: AppSpacing.sm),
                                    AppDropdownField(
                                      label: 'Última consulta médica',
                                      value: _ultimaConsulta.text.isEmpty ? null : _ultimaConsulta.text,
                                      items: const [
                                        (value: 'menos_1_anio', label: 'Hace menos de 1 año'),
                                        (value: 'mas_1_anio', label: 'Hace más de 1 año'),
                                        (value: 'no_recuerda', label: 'No recuerda'),
                                        (value: 'NINGUNA', label: 'Ninguna'),
                                      ],
                                      onChanged: (v) => setState(() => _ultimaConsulta.text = v),
                                    ),
                                    const SizedBox(height: AppSpacing.sm),
                                    AppTextField(label: 'Otros problemas salud', controller: _otros),
                                    const SizedBox(height: AppSpacing.sm),
                                    AppDropdownField(
                                      label: 'Primera menstruación',
                                      value: _primeraMenst.text.isEmpty ? null : _primeraMenst.text,
                                      items: const [(value: 'SI', label: 'Sí'), (value: 'NO', label: 'No'), (value: 'NO_SABE', label: 'No sabe')],
                                      onChanged: (v) => setState(() => _primeraMenst.text = v),
                                    ),
                                    const SizedBox(height: AppSpacing.sm),
                                    AppTextField(label: 'Edad primera menstruación', controller: _edadPrimeraMenst, keyboardType: TextInputType.number),
                                  ]),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        if (_error != null) Text(_error!, style: AppTypography.texto.copyWith(color: AppColors.error), textAlign: TextAlign.center),
                        const SizedBox(height: AppSpacing.sm),
                        if (!esNoEditable) AppButton(label: 'Guardar', isLoading: _guardando, onPressed: _guardando ? null : _guardar),
                        const SizedBox(height: AppSpacing.lg),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

