import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_radii.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Campo de selección estándar: label + DropdownButtonFormField con la
/// decoración del design system (campo lavanda, focus violeta). Reemplaza la
/// decoración duplicada del wizard de registro.
class AppDropdownField extends StatelessWidget {
  const AppDropdownField({
    super.key,
    required this.label,
    required this.items,
    this.onChanged,
    this.value,
    this.hint = 'Seleccioná',
    this.enabled = true,
  });

  final String label;
  final List<({String value, String label})> items;
  final ValueChanged<String>? onChanged;
  final String? value;
  final String hint;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    // Si el valor guardado no está en la lista (dato viejo o inválido),
    // se muestra el hint en vez de reventar el desplegable.
    final valido = value != null &&
        value!.isNotEmpty &&
        items.any((it) => it.value == value);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(label, style: AppTypography.subtitulo),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          isExpanded: true, // evita overflow horizontal en anchos fijos (ej: grilla del odontograma)
          initialValue: valido ? value : null,
          hint: Text(hint),
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
              borderSide:  BorderSide(color: AppColors.primario, width: 1.5),
            ),
          ),
          items: [
            for (final it in items)
              DropdownMenuItem(value: it.value, child: Text(it.label)),
          ],
          onChanged: enabled && onChanged != null
              ? (v) {
                  if (v != null) onChanged!(v);
                }
              : null,
        ),
      ],
    );
  }
}
