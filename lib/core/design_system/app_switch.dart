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
        // opaque: toda la fila es tappable (incluido el espacio vacío del label
        // flexible), no solo donde hay glifos/widgets.
        behavior: HitTestBehavior.opaque,
        onTap: () => onChanged(!value),
        child: Row(children: [
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
          // Flexible: el label envuelve a varias líneas en vez de desbordar el Row
          // cuando el texto es largo (ej. "Acepto la política de privacidad y términos").
          if (label != null) Flexible(child: Text(label!, style: AppTypography.texto)),
        ]),
      );
}
