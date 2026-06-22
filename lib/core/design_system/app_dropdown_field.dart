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
    required this.onChanged,
    this.value,
    this.hint = 'Seleccioná',
  });

  final String label;
  final List<({String value, String label})> items;
  final ValueChanged<String> onChanged;
  final String? value;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(label, style: AppTypography.subtitulo),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          initialValue: (value == null || value!.isEmpty) ? null : value,
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
              borderSide: const BorderSide(color: AppColors.primario, width: 1.5),
            ),
          ),
          items: [
            for (final it in items)
              DropdownMenuItem(value: it.value, child: Text(it.label)),
          ],
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ],
    );
  }
}
