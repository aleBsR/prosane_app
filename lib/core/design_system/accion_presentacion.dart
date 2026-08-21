import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Ícono genérico cuando el backend manda un `icon` que esta versión de la app
/// no conoce todavía (resiliencia entre repos — invariante #2 del spec).
const IconData kIconFallback = Icons.bolt_outlined;

/// Color genérico cuando el `color` del backend no es un hex válido.
const Color kColorFallback = AppColors.primario;

/// Nombre lógico de Material (lo manda el backend) → IconData outline.
/// Mantener en sync con authentication/actions_map.py del backend.
IconData accionIcon(String name) => switch (name) {
      'people' => Icons.people_outline,
      'clinical_notes' => Icons.medical_information_outlined,
      'assignment_add' => Icons.note_add_outlined,
      'draw' => Icons.draw_outlined,
      'dentistry' => Icons.medical_services_outlined,
      'straighten' => Icons.straighten_outlined,
      'description' => Icons.description_outlined,
      'how_to_reg' => Icons.how_to_reg_outlined,
      'school' => Icons.school_outlined,
      'menu_book' => Icons.menu_book_outlined,
      'groups' => Icons.groups_outlined,
      'person_add' => Icons.person_add_outlined,
      'manage_accounts' => Icons.manage_accounts_outlined,
      _ => kIconFallback,
    };

/// Hex del backend (`#RRGGBB` o `#AARRGGBB`) → Color. Inválido → fallback.
Color colorDesdeHex(String hex) {
  var h = hex.replaceFirst('#', '').trim();
  if (h.length == 6) h = 'FF$h';
  if (h.length != 8) return kColorFallback;
  final v = int.tryParse(h, radix: 16);
  return v == null ? kColorFallback : Color(v);
}
