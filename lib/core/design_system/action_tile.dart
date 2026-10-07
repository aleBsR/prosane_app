import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Fila de una acción: chip con el color del backend + ícono blanco + label.
class ActionTile extends StatelessWidget {
  const ActionTile({
    super.key,
    required this.color,
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final Color color;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: ExcludeSemantics(
        child: InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
            decoration: BoxDecoration(border: Border(top: BorderSide(color: AppColors.campo))),
            child: Row(children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(13)),
                child: Icon(icon, color: Colors.white, size: 21),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Text(
                  label,
                  style:  TextStyle(fontFamily: 'Rubik', fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.texto),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
