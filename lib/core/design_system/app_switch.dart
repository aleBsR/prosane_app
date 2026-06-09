import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

class AppSwitch extends StatelessWidget {
  const AppSwitch({super.key, required this.value, required this.onChanged, this.label});
  final bool value;
  final ValueChanged<bool> onChanged;
  final String? label;

  @override
  Widget build(BuildContext context) => GestureDetector(
        // El GestureDetector es la ÚNICA fuente del toggle (permite tocar también
        // el label). El Switch va con IgnorePointer para que no dispare onChanged
        // por su cuenta y evitar el doble-toggle al tocarlo directo.
        onTap: () => onChanged(!value),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          IgnorePointer(
            child: Switch(
              value: value,
              thumbColor: WidgetStateProperty.resolveWith(
                (states) => states.contains(WidgetState.selected) ? AppColors.primario : null,
              ),
              trackColor: WidgetStateProperty.resolveWith(
                (states) => states.contains(WidgetState.selected)
                    ? AppColors.primario.withValues(alpha: 0.5)
                    : null,
              ),
              onChanged: onChanged,
            ),
          ),
          if (label != null) Text(label!, style: AppTypography.texto),
        ]),
      );
}
