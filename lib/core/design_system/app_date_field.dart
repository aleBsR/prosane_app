import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_radii.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Campo de fecha estándar: label + recuadro tappable que abre showDatePicker
/// y muestra dd/mm/aaaa (o un hint si no hay valor).
class AppDateField extends StatelessWidget {
  const AppDateField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.hint = 'Seleccionar fecha',
    this.firstDate,
    this.lastDate,
  });

  final String label;
  final DateTime? value;
  final ValueChanged<DateTime> onChanged;
  final String hint;
  final DateTime? firstDate;
  final DateTime? lastDate;

  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/'
      '${d.month.toString().padLeft(2, '0')}/${d.year}';

  Future<void> _abrir(BuildContext context) async {
    final ahora = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: value ?? DateTime(ahora.year - 8, ahora.month, ahora.day),
      firstDate: firstDate ?? DateTime(1900),
      lastDate: lastDate ?? ahora,
      helpText: label,
    );
    if (picked != null) onChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(label, style: AppTypography.subtitulo),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: () => _abrir(context),
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.campo,
              borderRadius: BorderRadius.circular(AppRadii.campo),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(value != null ? _fmt(value!) : hint,
                    style: AppTypography.campo),
                 Icon(Icons.calendar_today_outlined,
                    size: 18, color: AppColors.link),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
