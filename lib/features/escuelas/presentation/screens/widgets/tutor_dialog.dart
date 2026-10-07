import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/design_system/app_date_field.dart';
import '../../../../../core/design_system/app_dialog.dart';
import '../../../../../core/design_system/app_dropdown_field.dart';
import '../../../../../core/design_system/app_text_field.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/notificaciones/notificacion_controller.dart';
import '../../../../../core/providers.dart';

/// Diálogo compartido para cargar el tutor (adulto responsable) de un
/// alumno existente. Lo usan la lista y el detalle de alumnos de escuela.
Future<void> mostrarTutorDialog(
  BuildContext context,
  WidgetRef ref, {
  required String alumnoId,
  required String alumnoNombre,
  required VoidCallback onGuardado,
}) async {
  final nombre = TextEditingController();
  final apellido = TextEditingController();
  final dni = TextEditingController();
  final tipoDoc = TextEditingController(text: 'DNI');
  final parentesco = TextEditingController();
  final sexo = TextEditingController();
  DateTime? fechaNacimiento;
  String? dialogError;
  var guardando = false;
  var validandoDni = false;
  // null = pendiente de validar (campos bloqueados), 'ok' | 'manual'.
  String? renaper;

  Future<void> validarRena(void Function(void Function()) setSt) async {
    if (dni.text.trim().isEmpty) {
      setSt(() => dialogError = 'Ingresá el DNI primero');
      return;
    }
    setSt(() {
      dialogError = null;
      validandoDni = true;
    });
    try {
      final data = await ref.read(alumnosEscuelaRepositoryProvider).validarDni(
            dni.text.trim(),
            sexo: sexo.text.trim().isEmpty ? null : sexo.text.trim(),
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
      DateTime? fechaDt;
      if (fechaTxt.isNotEmpty) {
        try {
          fechaDt = DateTime.parse(
              fechaTxt.length >= 10 ? fechaTxt.substring(0, 10) : fechaTxt);
        } catch (_) {}
      }
      setSt(() {
        if (apellidoTxt.isNotEmpty) apellido.text = apellidoTxt;
        if (nombresTxt.isNotEmpty) nombre.text = nombresTxt;
        if (sexoUi.isNotEmpty) sexo.text = sexoUi;
        if (fechaDt != null) fechaNacimiento = fechaDt;
        validandoDni = false;
        renaper = 'ok';
      });
      ref.read(notificacionProvider.notifier).exito('Datos de RENAPER cargados');
    } catch (e) {
      final noEncontrado = e.toString().contains('404');
      setSt(() {
        validandoDni = false;
        renaper = 'manual';
        if (!noEncontrado) {
          dialogError = e.toString().replaceFirst('Exception: ', '');
        }
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
        title: 'Tutor — $alumnoNombre',
        error: dialogError,
        saving: guardando,
        saveLabel: 'Vincular',
        onSave: () async {
          if (dni.text.trim().isEmpty) {
            setDialogState(() => dialogError = 'Ingresá el DNI primero');
            return;
          }
          if (renaper == null) {
            setDialogState(() => dialogError = 'Validá el DNI del tutor primero');
            return;
          }
          final campos = [nombre, apellido, dni, parentesco, sexo];
          if (campos.any((c) => c.text.trim().isEmpty) || fechaNacimiento == null) {
            setDialogState(() => dialogError = 'Completá todos los datos del tutor');
            return;
          }
          setDialogState(() {
            dialogError = null;
            guardando = true;
          });
          try {
            await ref.read(alumnosEscuelaRepositoryProvider).vincularTutor(alumnoId, {
              'persona': {
                'nombre': nombre.text.trim(),
                'apellido': apellido.text.trim(),
                'dni': dni.text.trim(),
                'tipo_dni': tipoDoc.text.trim().isEmpty ? 'DNI' : tipoDoc.text.trim(),
                'sexo': sexo.text.trim(),
                'fecha_nacimiento':
                    '${fechaNacimiento!.year.toString().padLeft(4, '0')}-${fechaNacimiento!.month.toString().padLeft(2, '0')}-${fechaNacimiento!.day.toString().padLeft(2, '0')}',
              },
              'parentesco': parentesco.text.trim(),
            });
            if (dialogContext.mounted) Navigator.pop(dialogContext);
            onGuardado();
            if (context.mounted) {
              ref.read(notificacionProvider.notifier).exito('¡Tutor vinculado!');
            }
          } catch (e) {
            if (dialogContext.mounted) {
              setDialogState(() {
                guardando = false;
                dialogError = e.toString().replaceFirst('Exception: ', '');
              });
            }
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
              onChanged: (_) => setDialogState(() => renaper = null)),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: validandoDni
                  ? null
                  : () => validarRena(setDialogState),
              child: Text(validandoDni ? 'Validando…' : 'Validar en RENAPER'),
            ),
          ),
          if (renaper == null)
            Text('Validá el DNI para autocompletar. Si no está en RENAPER, igual podés cargar manual.',
                style: AppTypography.texto.copyWith(
                    fontSize: 12,
                    color: AppColors.texto.withValues(alpha: 0.6))),
          if (renaper == null) const SizedBox(height: AppSpacing.sm),
          AppTextField(label: 'Nombre *', controller: nombre,
              readOnly: renaper == null),
          const SizedBox(height: AppSpacing.sm),
          AppTextField(label: 'Apellido *', controller: apellido,
              readOnly: renaper == null),
          const SizedBox(height: AppSpacing.sm),
          AppDropdownField(
            label: 'Parentesco *',
            enabled: renaper != null,
            value: parentesco.text.isEmpty ? null : parentesco.text,
            items: const [
              (value: 'madre', label: 'Madre'),
              (value: 'padre', label: 'Padre'),
              (value: 'tutor_legal', label: 'Tutor/a legal'),
              (value: 'otro', label: 'Otro'),
            ],
            onChanged: (v) => setDialogState(() => parentesco.text = v),
          ),
          const SizedBox(height: AppSpacing.sm),
          AppDropdownField(
            label: 'Sexo *',
            enabled: renaper != null,
            value: sexo.text.isEmpty ? null : sexo.text,
            items: const [
              (value: 'masculino', label: 'Masculino'),
              (value: 'femenino', label: 'Femenino'),
              (value: 'otro', label: 'Otro'),
            ],
            onChanged: (v) => setDialogState(() => sexo.text = v),
          ),
          const SizedBox(height: AppSpacing.sm),
          IgnorePointer(
            ignoring: renaper == null,
            child: Opacity(
              opacity: renaper == null ? 0.5 : 1,
              child: AppDateField(
                label: 'Fecha de nacimiento *',
                value: fechaNacimiento,
                hint: 'dd/mm/aaaa',
                onChanged: (v) => setDialogState(() => fechaNacimiento = v),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
