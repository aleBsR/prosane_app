import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Card-acordeón de una categoría. Header (título + chevron) + lista colapsable.
/// Arranca expandido (initiallyExpanded = true).
class ActionGroup extends StatefulWidget {
  const ActionGroup({
    super.key,
    required this.titulo,
    required this.children,
    this.initiallyExpanded = true,
  });
  final String titulo;
  final List<Widget> children;
  final bool initiallyExpanded;

  @override
  State<ActionGroup> createState() => _ActionGroupState();
}

class _ActionGroupState extends State<ActionGroup> {
  late bool _abierto = widget.initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppColors.blanco,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: const Color(0xFF2B2440).withValues(alpha: 0.16), blurRadius: 22, offset: const Offset(0, 8))],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: [
        Semantics(
          button: true,
          label: '${widget.titulo}, ${_abierto ? 'expandido' : 'colapsado'}',
          child: ExcludeSemantics(
            child: InkWell(
              onTap: () => setState(() => _abierto = !_abierto),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
                child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text(widget.titulo, style:  TextStyle(fontFamily: 'Rubik', fontWeight: FontWeight.w700,
                      fontSize: 13, letterSpacing: 1, color: AppColors.primario)),
                  Icon(_abierto ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_right, color: const Color(0xFFB9AEE8)),
                ]),
              ),
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          child: _abierto
              ? Column(children: widget.children)
              // width infinito: evita que AnimatedSize colapse el ancho al cerrar
              : const SizedBox(width: double.infinity, height: 0),
        ),
      ]),
    );
  }
}
