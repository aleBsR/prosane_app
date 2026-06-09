import 'package:flutter/material.dart';
import '../../../../core/design_system/app_text_field.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../controllers/signup_controller.dart';

/// Etapa 1: Nombre, Apellido, Sexo, Fecha de Nacimiento, Lugar de Nacimiento.
class StepDatosPersonales extends StatefulWidget {
  const StepDatosPersonales({
    super.key,
    required this.formData,
    required this.controller,
  });

  final SignupFormData formData;
  final SignupController controller;

  @override
  State<StepDatosPersonales> createState() => _StepDatosPersonalesState();
}

class _StepDatosPersonalesState extends State<StepDatosPersonales> {
  late final TextEditingController _nombreCtrl;
  late final TextEditingController _apellidoCtrl;
  late final TextEditingController _lugarCtrl;

  @override
  void initState() {
    super.initState();
    _nombreCtrl = TextEditingController(text: widget.formData.nombre);
    _apellidoCtrl = TextEditingController(text: widget.formData.apellido);
    _lugarCtrl = TextEditingController(text: widget.formData.lugarNacimiento);
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _apellidoCtrl.dispose();
    _lugarCtrl.dispose();
    super.dispose();
  }

  Future<void> _seleccionarFecha() async {
    final ahora = DateTime.now();
    final inicial = widget.formData.fechaNacimiento ??
        DateTime(ahora.year - 18, ahora.month, ahora.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: inicial,
      firstDate: DateTime(1900),
      lastDate: ahora,
      helpText: 'Fecha de nacimiento',
    );
    if (picked != null) widget.controller.setFechaNacimiento(picked);
  }

  @override
  Widget build(BuildContext context) {
    final f = widget.formData;
    final fechaTexto = f.fechaNacimiento != null
        ? '${f.fechaNacimiento!.day.toString().padLeft(2, '0')}/'
            '${f.fechaNacimiento!.month.toString().padLeft(2, '0')}/'
            '${f.fechaNacimiento!.year}'
        : 'Seleccionar fecha';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Nombre
        AppTextField(
          key: const Key('signup_nombre'),
          label: 'Nombre',
          hint: 'Tu nombre',
          controller: _nombreCtrl,
          onChanged: widget.controller.setNombre,
        ),
        const SizedBox(height: AppSpacing.md),

        // Apellido
        AppTextField(
          key: const Key('signup_apellido'),
          label: 'Apellido',
          hint: 'Tu apellido',
          controller: _apellidoCtrl,
          onChanged: widget.controller.setApellido,
        ),
        const SizedBox(height: AppSpacing.md),

        // Dropdown Sexo
        Text('Sexo', style: AppTypography.subtitulo),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          key: const Key('signup_sexo'),
          initialValue: f.sexo.isEmpty ? null : f.sexo,
          hint: const Text('Seleccioná'),
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.campo,
            contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: 14),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadii.campo),
              borderSide: const BorderSide(color: Colors.transparent),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadii.campo),
              borderSide:
                  const BorderSide(color: AppColors.primario, width: 1.5),
            ),
          ),
          items: const [
            DropdownMenuItem(value: 'F', child: Text('Femenino')),
            DropdownMenuItem(value: 'M', child: Text('Masculino')),
            DropdownMenuItem(value: 'X', child: Text('Otro')),
          ],
          onChanged: (v) {
            if (v != null) widget.controller.setSexo(v);
          },
        ),
        const SizedBox(height: AppSpacing.md),

        // Fecha de Nacimiento
        Text('Fecha de Nacimiento', style: AppTypography.subtitulo),
        const SizedBox(height: 6),
        GestureDetector(
          key: const Key('signup_fecha_nacimiento'),
          onTap: _seleccionarFecha,
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.campo,
              borderRadius: BorderRadius.circular(AppRadii.campo),
              border: Border.all(color: Colors.transparent),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(fechaTexto, style: AppTypography.campo),
                const Icon(Icons.calendar_today_outlined,
                    size: 18, color: AppColors.link),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // Lugar de Nacimiento
        AppTextField(
          key: const Key('signup_lugar_nacimiento'),
          label: 'Lugar de Nacimiento',
          hint: 'Ciudad o localidad',
          controller: _lugarCtrl,
          onChanged: widget.controller.setLugarNacimiento,
        ),
      ],
    );
  }
}
