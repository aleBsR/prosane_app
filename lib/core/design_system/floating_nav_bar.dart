import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'nav_bar_badge.dart';

class NavItemData {
  const NavItemData({required this.outlinedIcon, required this.filledIcon, required this.label, this.badgeCount = 0});
  final IconData outlinedIcon, filledIcon;
  final String label;
  final int badgeCount;
}

/// Píldora frosted flotante. TONTA: no conoce go_router; recibe selectedIndex,
/// onTap y compacta. El activo va relleno + fondo sutil; inactivos en contorno.
class FloatingNavBar extends StatelessWidget {
  const FloatingNavBar({
    super.key, required this.items, required this.selectedIndex,
    required this.onTap, required this.compacta,
  });
  final List<NavItemData> items;
  final int selectedIndex;
  final ValueChanged<int> onTap;
  final bool compacta;

  static const _inactivo = Color(0xFF9286C4); // primario violeta desaturado (sin token aún)
  static Color get _activo => AppColors.link;

  @override
  Widget build(BuildContext context) {
    assert(items.isNotEmpty && selectedIndex >= 0 && selectedIndex < items.length,
        'selectedIndex $selectedIndex fuera de rango [0, ${items.length})');
    return AnimatedContainer(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
      padding: EdgeInsets.symmetric(horizontal: compacta ? 9 : 12, vertical: compacta ? 7 : 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.86),
        borderRadius: BorderRadius.circular(compacta ? 28 : 32),
        border: Border.all(color: Colors.white.withValues(alpha: 0.75)),
        boxShadow: [BoxShadow(color: const Color(0xFF3C288C).withValues(alpha: 0.32), blurRadius: 34, offset: const Offset(0, 14))],
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        for (var i = 0; i < items.length; i++) _item(i),
      ]),
    );
  }

  Widget _item(int i) {
    final it = items[i];
    final activo = i == selectedIndex;
    final color = activo ? _activo : _inactivo;
    return Semantics(
      button: true,
      selected: activo,
      label: it.label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onTap(i),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: compacta ? 9 : 12, vertical: 8),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Stack(clipBehavior: Clip.none, children: [
              Container(
                width: 48, height: 32,
                decoration: BoxDecoration(
                  color: activo ? _activo.withValues(alpha: 0.17) : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                ),
                alignment: Alignment.center,
                child: Icon(activo ? it.filledIcon : it.outlinedIcon, color: color, size: 24),
              ),
              if (it.badgeCount > 0)
                Positioned(top: -2, right: 6, child: NavBarBadge(count: it.badgeCount)),
            ]),
            if (!compacta) ...[
              const SizedBox(height: 4),
              Text(it.label, style: TextStyle(fontFamily: 'Rubik', fontSize: 11,
                  fontWeight: activo ? FontWeight.w700 : FontWeight.w600, color: color)),
            ],
          ]),
        ),
      ),
    );
  }
}
