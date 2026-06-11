import 'package:flutter/material.dart';
import '../design_system/floating_nav_bar.dart';

/// Envuelve el contenido de la pestaña activa y le pinta encima la FloatingNavBar.
/// Escucha el scroll del contenido para compactar la barra (estilo Instagram).
class AppShell extends StatefulWidget {
  const AppShell({
    super.key,
    required this.child,
    required this.selectedIndex,
    required this.onTap,
    this.badgePendientes = 0,
  });
  final Widget child;
  final int selectedIndex;
  final ValueChanged<int> onTap;
  final int badgePendientes;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  bool _compacta = false;

  // M1: ítems constantes para no reconstruirlos en cada frame.
  static const _itemInicio = NavItemData(outlinedIcon: Icons.home_outlined, filledIcon: Icons.home, label: 'Inicio');
  static const _itemUsuario = NavItemData(outlinedIcon: Icons.person_outline, filledIcon: Icons.person, label: 'Usuario');

  // I1: solo reaccionar al scroll vertical externo (depth == 0).
  bool _onScroll(ScrollNotification n) {
    if (n.metrics.axis != Axis.vertical || n.depth != 0) return false;
    final compacta = n.metrics.pixels > 24; // umbral simple
    if (compacta != _compacta) setState(() => _compacta = compacta);
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final items = [
      _itemInicio,
      NavItemData(outlinedIcon: Icons.sync_outlined, filledIcon: Icons.sync, label: 'Pendientes', badgeCount: widget.badgePendientes),
      _itemUsuario,
    ];
    // I2: respetar el safe-area inferior (home indicator de iPhone).
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    return Stack(children: [
      NotificationListener<ScrollNotification>(onNotification: _onScroll, child: widget.child),
      Positioned(left: 0, right: 0, bottom: 18 + bottomInset, child: Center(
        child: FloatingNavBar(
          items: items, selectedIndex: widget.selectedIndex, compacta: _compacta, onTap: widget.onTap),
      )),
    ]);
  }
}
