import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/design_system/app_button.dart';
import '../../../../core/design_system/app_card.dart';
import '../../../../core/design_system/app_date_field.dart';
import '../../../../core/design_system/app_dropdown_field.dart';
import '../../../../core/design_system/app_gradient_scaffold.dart';
import '../../../../core/design_system/app_text_field.dart';
import '../../../../core/notificaciones/notificacion_controller.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/providers.dart';
import '../../../../core/session/entities.dart';
import '../../../../core/session/session_controller.dart';
import '../controllers/operativo_detail_controller.dart';

const Map<String, String> _motivoNoExamenLabels = {
  'negativa_familiar': 'Negativa familiar',
  'negativa_nino': 'Negativa del niño',
  'ausente': 'Ausente',
  'otros': 'Otros',
};

const Map<String, String> _lugarExamenLabels = {
  'escuela': 'En la escuela',
  'centro_salud': 'En el centro de salud',
};

const Map<String, String> _percentilTallaLabels = {
  'menor_3': 'Menor a 3',
  'mayor_igual_3': 'Mayor o igual a 3',
};

const Map<String, String> _percentilImcLabels = {
  'menor_3': 'Menor a 3 (emaciación)',
  'entre_3_9': 'Entre 3 y 9 (riesgo de bajo peso)',
  'entre_10_84': 'Entre 10 y 84 (normal)',
  'entre_85_97': 'Entre 85 y 97 (sobrepeso)',
  'mayor_97': 'Mayor a 97 (obesidad)',
};

const Map<String, String> _audiometriaLabels = {
  'pasa': 'Pasa',
  'no_pasa': 'No pasa',
};

const Map<String, String> _saludBucalLabels = {
  'con_hallazgos': 'Con hallazgos',
  'sin_hallazgos': 'Sin hallazgos',
  'no_eval': 'No evaluado',
};

const Map<String, String> _hallazgoLabels = {
  'piel': 'Piel',
  'partes_blandas': 'Partes blandas',
  'cardiovascular': 'Cardiovascular',
  'respiratorio': 'Respiratorio',
  'abdominal': 'Abdominal',
  'genitourinario': 'Genitourinario',
  'osteoarticular': 'Osteoarticular',
  'neurologico': 'Neurológico',
  'salud_visual': 'Salud visual',
  'fonoaudiologica': 'Fonoaudiológica',
  'icv': 'ICV',
};

const List<String> _sistemasHallazgo = [
  'piel', 'partes_blandas', 'cardiovascular', 'respiratorio', 'abdominal',
  'genitourinario', 'osteoarticular', 'neurologico', 'salud_visual',
  'fonoaudiologica', 'icv',
];

const Map<String, String> _hallazgoEstadoLabels = {
  'con': 'Con hallazgos',
  'sin': 'Sin hallazgos',
  'no_eval': 'No evaluado',
};

const Map<String, String> _derivacionLabels = {
  'odontologia': 'Odontología',
  'oftalmologia': 'Oftalmología',
  'nutricion': 'Nutrición',
  'neurologia': 'Neurología',
  'cardiologia': 'Cardiología',
  'fonoaudiologia': 'Fonoaudiología',
  'psicologia': 'Psicología',
  'otros': 'Otros',
};

const Map<String, String> _estadoPiezaLabels = {
  '': 'Normal',
  'ausente': 'Ausente',
  'perdido': 'Perdido',
  'extraido': 'Extraído',
  'corona': 'Corona',
  'protesis': 'Prótesis',
  'implante': 'Implante',
  'a_extraer': 'Para extraer',
  'fractura_total': 'Fractura total',
};

const Map<String, String> _estadoCaraLabels = {
  '': 'Sana',
  'caries': 'Caries',
  'restauracion': 'Restauración',
  'sellador': 'Sellador',
  'fractura': 'Fractura',
  'a_tratar': 'A tratar',
  'tratada': 'Tratada',
};

const Map<String, String> _estadoRaizLabels = {
  '': 'Normal',
  'conducto_realizado': 'Conducto realizado',
  'conducto_pendiente': 'Conducto pendiente',
};

const Map<String, String> _caraLabels = {
  'oclusal': 'Oclusal',
  'mesial': 'Mesial',
  'distal': 'Distal',
  'vestibular': 'Vestibular',
  'lingual': 'Lingual / palatina',
};

const Map<String, String> _siNoLabels = {
  'SI': 'Sí',
  'NO': 'No',
  'NO_SABE': 'No sabe',
};

const Map<String, String> _sexoLabels = {
  'masculino': 'Masculino',
  'femenino': 'Femenino',
  'otro': 'Otro',
};

const Map<String, String> _coberturaLabels = {
  'obra_social': 'Obra Social (incluye PAMI)',
  'estatal': 'Programas o planes estatales',
  'prepaga': 'Plan privado o Prepaga',
  'sin_cobertura': 'No tiene',
};

const Map<String, String> _ultimaConsultaLabels = {
  'menos_1_anio': 'Hace menos de 1 año',
  'mas_1_anio': 'Hace más de 1 año',
  'no_recuerda': 'No recuerda',
  'NINGUNA': 'Ninguna',
};

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
  DateTime? _fechaNacimiento;
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
  Map<String, dynamic>? _evalMedica;
  Map<String, dynamic>? _evalOdontologica;
  Map<String, dynamic>? _operativoAlumno;
  Map<String, dynamic>? _persona;
  Map<String, dynamic>? _paciente;
  Map<String, dynamic>? _domicilio;
  Map<String, dynamic>? _antecedentes;

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
        final fechaStr = (persona?['fecha_nacimiento'] ?? opAl['fecha_nacimiento'] ?? '').toString();
        _fechaNacimiento = fechaStr.isNotEmpty ? DateTime.tryParse(fechaStr) : null;
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
        _evalMedica = data['evaluacion_medica'] is Map
            ? Map<String, dynamic>.from(data['evaluacion_medica'] as Map)
            : null;
_evalOdontologica = data['evaluacion_odontologica'] is Map
          ? Map<String, dynamic>.from(data['evaluacion_odontologica'] as Map)
          : null;
        _operativoAlumno = opAl.isEmpty ? null : Map<String, dynamic>.from(opAl);
        _persona = persona;
        _paciente = paciente;
        _domicilio = domicilio;
        _antecedentes = ant;
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
      final fechaIso = _fechaNacimiento != null
          ? '${_fechaNacimiento!.year.toString().padLeft(4, '0')}-${_fechaNacimiento!.month.toString().padLeft(2, '0')}-${_fechaNacimiento!.day.toString().padLeft(2, '0')}'
          : '';
      if (fechaIso.isEmpty) {
        setState(() {
          _error = 'Seleccioná la fecha de nacimiento';
          _guardando = false;
        });
        return;
      }
      final payload = {
        'nombre': _nombre.text.trim(),
        'apellido': _apellido.text.trim(),
        'dni': _dni.text.trim(),
        'fecha_nacimiento': fechaIso,
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
    final operativoBloqueado = operativoAsync.maybeWhen(
      data: (op) => op['estado'] == 'finalizado' || op['estado'] == 'cancelado',
      orElse: () => false,
    );
    final sesion = ref.watch(sessionControllerProvider);
    final puedeEditar = sesion is SesionAutenticada &&
        (sesion.sesion.permisos.contains('cargarAntecedentesNino') ||
            sesion.sesion.usuario.rolName == 'superadmin');
    final esNoEditable = operativoBloqueado || !puedeEditar;
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
                          Center(
                            child: Container(
                              constraints: const BoxConstraints(maxWidth: 300),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE8F5E9),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: const Color(0xFF66BB6A)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.lock_outline, size: 14, color: Color(0xFF2E7D32)),
                                  const SizedBox(width: 6),
                                  Flexible(child: Text(
                                    operativoBloqueado
                                        ? 'Operativo finalizado — solo lectura'
                                        : 'Solo lectura — no tenés permisos de edición',
                                    style: AppTypography.texto.copyWith(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF2E7D32)))),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                        ],
                        if (esNoEditable)
                          ..._fichaSecciones(),
                        if (!esNoEditable)
                          Column(
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
                                    AppDateField(
                                      label: 'Fecha de nacimiento *',
                                      value: _fechaNacimiento,
                                      hint: 'dd/mm/aaaa',
                                      onChanged: (v) => setState(() => _fechaNacimiento = v),
                                    ),
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
                        const SizedBox(height: AppSpacing.md),
                        _seccionEvalMedica(),
                        const SizedBox(height: AppSpacing.md),
                        _seccionEvalOdontologica(),
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

  String _txt(dynamic v) => v?.toString().trim() ?? '';

  String _siNo(dynamic v) => v == true ? 'Sí' : 'No';

  String _mapValue(Map<String, String> labels, dynamic v) {
    final key = _txt(v);
    return labels[key] ?? key;
  }

  Widget _filaValor(String label, dynamic valor) {
    final v = _txt(valor);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 170,
            child: Text(label,
                style: AppTypography.texto.copyWith(
                    fontSize: 12, color: AppColors.texto.withValues(alpha: 0.7))),
          ),
          Expanded(
            child: Text(v.isEmpty ? '—' : v,
                style: AppTypography.texto.copyWith(
                    fontSize: 12, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  List<Widget> _fichaSecciones() => [
        _seccionFichaDatos(),
        const SizedBox(height: AppSpacing.md),
        _seccionFichaCobertura(),
        const SizedBox(height: AppSpacing.md),
        _seccionFichaAntecedentes(),
        const SizedBox(height: AppSpacing.md),
      ];

  Widget _tituloFicha(IconData icono, String titulo) => Row(children: [
        Icon(icono, size: 18, color: AppColors.primario),
        const SizedBox(width: 6),
        Expanded(child: Text(titulo, style: AppTypography.subtitulo)),
      ]);

  String _fmtFecha(DateTime? d) => d == null
      ? ''
      : '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  Widget _seccionFichaDatos() {
    final al = _operativoAlumno;
    final per = _persona;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _tituloFicha(Icons.person_outline, 'Datos personales'),
          const SizedBox(height: AppSpacing.sm),
          _filaValor('Nombre', per?['nombre'] ?? al?['nombre']),
          _filaValor('Apellido', per?['apellido'] ?? al?['apellido']),
          _filaValor('DNI', per?['dni'] ?? al?['dni']),
          _filaValor('Fecha de nacimiento', _fmtFecha(_fechaNacimiento)),
          _filaValor('Sexo',
              _mapValue(_sexoLabels, per?['sexo'] ?? al?['sexo'])),
          _filaValor('Edad', _paciente?['edad']),
          _filaValor('Localidad', _domicilio?['localidad']),
        ],
      ),
    );
  }

  Widget _seccionFichaCobertura() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _tituloFicha(Icons.phone_outlined, 'Cobertura y contacto'),
          const SizedBox(height: AppSpacing.sm),
          _filaValor('Celular', _paciente?['celular']),
          _filaValor('Teléfono fijo', _paciente?['telefono_fijo']),
          _filaValor('¿Tiene CUD?',
              _mapValue(_siNoLabels, _paciente?['tiene_cud'] ?? 'NO')),
          _filaValor('Tipo cobertura',
              _mapValue(_coberturaLabels, _paciente?['tipo_cobertura'] ?? '')),
          _filaValor('Nombre cobertura', _paciente?['nombre_cobertura']),
        ],
      ),
    );
  }

  Widget _seccionFichaAntecedentes() {
    final a = _antecedentes;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _tituloFicha(Icons.assignment_outlined, 'Antecedentes personales'),
          const SizedBox(height: AppSpacing.sm),
          _filaValor('Nació prematuro',
              _mapValue(_siNoLabels, a?['nacio_prematuro'] ?? 'NO')),
          _filaValor('Peso al nacer', a?['peso_nacimiento']),
          _filaValor('Convulsiones/Epilepsia',
              _mapValue(_siNoLabels, a?['convulsiones_epilepsia'] ?? 'NO')),
          _filaValor('Mareos/Desmayos',
              _mapValue(_siNoLabels, a?['mareos_desmayos'] ?? 'NO')),
          _filaValor('Infecciones urinarias',
              _mapValue(_siNoLabels, a?['infecciones_urinarias'] ?? 'NO')),
          _filaValor('Asma/Espasmos',
              _mapValue(_siNoLabels, a?['asma_espasmos'] ?? 'NO')),
          _filaValor('Tuberculosis',
              _mapValue(_siNoLabels, a?['tuberculosis'] ?? 'NO')),
          _filaValor('Diabetes', _mapValue(_siNoLabels, a?['diabetes'] ?? 'NO')),
          _filaValor('Hipertensión',
              _mapValue(_siNoLabels, a?['hipertension'] ?? 'NO')),
          _filaValor('Cardiopatía congénita',
              _mapValue(_siNoLabels, a?['cardiopatia_congenita'] ?? 'NO')),
          _filaValor('Traumatismo/Internación',
              _mapValue(_siNoLabels, a?['traumatismo_internacion'] ?? 'NO')),
          _filaValor('Diarrea frecuente',
              _mapValue(_siNoLabels, a?['diarrea_frecuente'] ?? 'NO')),
          _filaValor('Infecciones de oído',
              _mapValue(_siNoLabels, a?['infecciones_oido'] ?? 'NO')),
          _filaValor('¿Estuvo internado?',
              _mapValue(_siNoLabels, a?['internacion_previa'] ?? 'NO')),
          if (_txt(a?['causa_hospitalizacion']).isNotEmpty)
            _filaValor('Causa de hospitalización', a?['causa_hospitalizacion']),
          _filaValor('Tratamiento actual',
              _mapValue(_siNoLabels, a?['tratamiento_actual'] ?? 'NO')),
          if (_txt(a?['descripcion_tratamiento']).isNotEmpty)
            _filaValor(
                'Descripción del tratamiento', a?['descripcion_tratamiento']),
          _filaValor('Última consulta médica',
              _mapValue(_ultimaConsultaLabels, a?['ultima_consulta_medica'] ?? 'NINGUNA')),
          if (_txt(a?['otros_problemas_salud']).isNotEmpty)
            _filaValor('Otros problemas de salud', a?['otros_problemas_salud']),
          _filaValor('Primera menstruación',
              _mapValue(_siNoLabels, a?['primera_menstruacion'] ?? 'NO')),
          if (_txt(a?['edad_primera_menstruacion']).isNotEmpty)
            _filaValor(
                'Edad primera menstruación', a?['edad_primera_menstruacion']),
        ],
      ),
    );
  }

  Widget _seccionEvalMedica() {
    final em = _evalMedica;
    if (em == null) return const SizedBox.shrink();
    final completada = em['completada'] == true;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(children: [
            const Icon(Icons.medical_services_outlined, size: 16, color: AppColors.primario),
            const SizedBox(width: 6),
            Expanded(child: Text('Evaluación médica', style: AppTypography.subtitulo)),
          ]),
          if (!completada) ...[
            const SizedBox(height: 4),
            Text('Pendiente de completar',
                style: AppTypography.texto.copyWith(
                    fontSize: 11,
                    color: AppColors.texto.withValues(alpha: 0.6),
                    fontStyle: FontStyle.italic)),
          ],
          const SizedBox(height: AppSpacing.sm),
          _filaValor('Profesional', em['profesional']),
          _filaValor('Examen realizado', _siNo(em['examen_realizado'])),
          if (_txt(em['motivo_no_examen']).isNotEmpty)
            _filaValor('Motivo de no examen',
                _mapValue(_motivoNoExamenLabels, em['motivo_no_examen'])),
          if (_txt(em['lugar_examen']).isNotEmpty)
            _filaValor('Lugar del examen',
                _mapValue(_lugarExamenLabels, em['lugar_examen'])),
          _filaValor('Peso (kg)', em['peso']),
          _filaValor('Talla (cm)', em['talla']),
          _filaValor('IMC', em['imc']),
          if (_txt(em['percentil_talla']).isNotEmpty)
            _filaValor('Percentil talla',
                _mapValue(_percentilTallaLabels, em['percentil_talla'])),
          if (_txt(em['percentil_imc']).isNotEmpty)
            _filaValor('Percentil IMC',
                _mapValue(_percentilImcLabels, em['percentil_imc'])),
          _filaValor('PAS (sistólica)', em['pas']),
          _filaValor('PAD (diastólica)', em['pad']),
          if (_txt(em['presion_clasificacion']).isNotEmpty)
            _filaValor(
                'Clasificación presión', em['presion_clasificacion']),
          _filaValor('Agudeza evaluada', _siNo(em['agudeza_evaluada'])),
          _filaValor('Ojo derecho', em['ojo_derecho']),
          _filaValor('Ojo izquierdo', em['ojo_izquierdo']),
          _filaValor('Usa lentes', _siNo(em['usa_lentes'])),
          _filaValor('Audiometría realizada', _siNo(em['audiometria_realizada'])),
          if (_txt(em['audiometria_resultado']).isNotEmpty)
            _filaValor('Resultado audiometría',
                _mapValue(_audiometriaLabels, em['audiometria_resultado'])),
          _filaValor('Trajo carnet', _siNo(em['trajo_carnet'])),
          _filaValor('Carnet completo', _siNo(em['carnet_completo'])),
          if (_txt(em['vacunas_aplicadas']).isNotEmpty)
            _filaValor('Vacunas aplicadas', em['vacunas_aplicadas']),
          if (_txt(em['vacunas_indicadas']).isNotEmpty)
            _filaValor('Vacunas indicadas', em['vacunas_indicadas']),
          ..._hallazgosFilas(em['hallazgos']),
          ..._derivacionesFilas(em['derivaciones']),
        ],
      ),
    );
  }

  List<Widget> _hallazgosFilas(dynamic hallazgos) {
    if (hallazgos is! Map) return const [];
    final filas = <Widget>[];
    for (final sistema in _sistemasHallazgo) {
      final raw = hallazgos[sistema];
      if (raw is! Map) continue;
      final estado = _txt(raw['estado']);
      final detalle = _txt(raw['detalle']);
      if ((estado.isEmpty || estado == 'no_eval') && detalle.isEmpty) continue;
      filas.add(_filaValor(
        _hallazgoLabels[sistema] ?? sistema,
        [
          if (estado.isNotEmpty) _mapValue(_hallazgoEstadoLabels, estado),
          if (detalle.isNotEmpty) detalle,
        ].join(' — '),
      ));
    }
    if (filas.isEmpty) filas.add(_filaValor('Hallazgos', 'Sin hallazgos registrados'));
    return filas;
  }

  List<Widget> _derivacionesFilas(dynamic derivaciones) {
    if (derivaciones is! Map) return const [];
    final filas = <Widget>[];
    derivaciones.forEach((esp, raw) {
      if (raw is Map && raw['deriva'] == true) {
        filas.add(_filaValor(
            'Deriva a ${_derivacionLabels[esp.toString()] ?? esp}', raw['motivo']));
      }
    });
    if (filas.isEmpty) filas.add(_filaValor('Derivaciones', 'Sin derivaciones'));
    return filas;
  }

  Widget _seccionEvalOdontologica() {
    final eo = _evalOdontologica;
    if (eo == null) return const SizedBox.shrink();
    final completada = eo['completada'] == true;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(children: [
            const Icon(Icons.health_and_safety_outlined, size: 16, color: AppColors.primario),
            const SizedBox(width: 6),
            Expanded(child: Text('Evaluación odontológica', style: AppTypography.subtitulo)),
          ]),
          if (!completada) ...[
            const SizedBox(height: 4),
            Text('Pendiente de completar',
                style: AppTypography.texto.copyWith(
                    fontSize: 11,
                    color: AppColors.texto.withValues(alpha: 0.6),
                    fontStyle: FontStyle.italic)),
          ],
          const SizedBox(height: AppSpacing.sm),
          _filaValor('Profesional', eo['profesional']),
          if (_txt(eo['salud_bucal']).isNotEmpty)
            _filaValor('Salud bucal',
                _mapValue(_saludBucalLabels, eo['salud_bucal'])),
          _filaValor('Lesiones en tejidos blandos', _siNo(eo['lesiones_tejidos_blandos'])),
          _filaValor('Maloclusión', _siNo(eo['maloclusion'])),
          _filaValor('Fluorosis', _siNo(eo['fluorosis'])),
          _filaValor('Caries', _siNo(eo['caries'])),
          if (_txt(eo['otros']).isNotEmpty) _filaValor('Otros', eo['otros']),
          _filaValor('Topicación de flúor', _siNo(eo['topicacion_fluor'])),
          _filaValor('Enseñanza de cepillado', _siNo(eo['ensenanza_cepillado'])),
          _filaValor('Alta básica', _siNo(eo['alta_basica'])),
          _filaValor('CPO — Cariados (C)', eo['cpo_c']),
          _filaValor('CPO — Perdidos (P)', eo['cpo_p']),
          _filaValor('CPO — Obturados (O)', eo['cpo_o']),
          _filaValor('ceo — Cariados (c)', eo['ceo_c']),
          _filaValor('ceo — Extracción indicada (e)', eo['ceo_e']),
          _filaValor('ceo — Obturados (o)', eo['ceo_o']),
          ..._odontogramaCompleto(eo['odontograma']),
        ],
      ),
    );
  }

  List<Widget> _odontogramaCompleto(dynamic odontograma) {
    if (odontograma is! Map || odontograma.isEmpty) {
      return [_filaValor('Odontograma', 'Sin piezas cargadas')];
    }
    final filas = <Widget>[];
    odontograma.forEach((pieza, raw) {
      if (raw is! Map) return;
      filas.add(Padding(
        padding: const EdgeInsets.only(top: 4, bottom: 2),
        child: Text('Pieza $pieza',
            style: AppTypography.texto.copyWith(
                fontWeight: FontWeight.bold, fontSize: 12)),
      ));
      filas.add(_filaValor('Estado general',
          _mapValue(_estadoPiezaLabels, raw['estado_general'])));
      final caras = raw['caras'];
      if (caras is Map) {
        caras.forEach((cara, v) {
          filas.add(_filaValor(_caraLabels[cara.toString()] ?? cara.toString(),
              _mapValue(_estadoCaraLabels, v)));
        });
      }
      if (_txt(raw['raiz']).isNotEmpty) {
        filas.add(_filaValor(
            'Raíz / pulpa', _mapValue(_estadoRaizLabels, raw['raiz'])));
      }
      if (_txt(raw['notas']).isNotEmpty) {
        filas.add(_filaValor('Notas', raw['notas']));
      }
    });
    return filas;
  }
}

