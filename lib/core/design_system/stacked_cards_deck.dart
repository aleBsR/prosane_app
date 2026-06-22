import 'package:flutter/material.dart';

/// Una card del mazo: su contenido visual + la acción al tocarla estando al frente.
typedef DeckCard = ({Widget child, VoidCallback onTap});

/// Mazo de cards apiladas (front full + las de atrás con offset y escala).
/// Interacción: tocar una card de atrás la trae al frente; tocar la de adelante
/// dispara su [onTap]. Muestra hasta [maxVisible]; si hay más, indica "+N".
class StackedCardsDeck extends StatefulWidget {
  const StackedCardsDeck({
    super.key,
    required this.items,
    this.cardHeight = 120,
    this.offset = 18,
    this.maxVisible = 4,
  });

  final List<DeckCard> items; // orden lógico inicial: index 0 al frente
  final double cardHeight;
  final double offset;
  final int maxVisible;

  @override
  State<StackedCardsDeck> createState() => _StackedCardsDeckState();
}

class _StackedCardsDeckState extends State<StackedCardsDeck> {
  late List<int> _order; // índices de items, _order[0] = frente

  @override
  void initState() {
    super.initState();
    _order = List<int>.generate(widget.items.length, (i) => i);
  }

  @override
  void didUpdateWidget(StackedCardsDeck old) {
    super.didUpdateWidget(old);
    // Si cambió la cantidad de items, reconstruir el orden (mantener simple).
    if (old.items.length != widget.items.length) {
      _order = List<int>.generate(widget.items.length, (i) => i);
    }
  }

  void _traerAlFrente(int itemIndex) {
    setState(() {
      _order
        ..remove(itemIndex)
        ..insert(0, itemIndex);
    });
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.items;
    if (items.isEmpty) return const SizedBox.shrink();

    final n = items.length;
    final visibles = n < widget.maxVisible ? n : widget.maxVisible;
    final extra = n - visibles;
    final altura = widget.cardHeight + (visibles - 1) * widget.offset;

    // Dibujar de atrás hacia adelante: depth visibles-1 .. 0 (0 = frente, arriba).
    final capas = <Widget>[];
    for (var depth = visibles - 1; depth >= 0; depth--) {
      final itemIndex = _order[depth];
      final item = items[itemIndex];
      final esFrente = depth == 0;
      capas.add(Positioned(
        left: 0,
        right: 0,
        top: depth * widget.offset,
        height: widget.cardHeight,
        child: Transform.scale(
          scale: 1.0 - depth * 0.04,
          alignment: Alignment.topCenter,
          child: Opacity(
            opacity: esFrente ? 1.0 : 0.94,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: esFrente ? item.onTap : () => _traerAlFrente(itemIndex),
              child: item.child,
            ),
          ),
        ),
      ));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(height: altura, child: Stack(clipBehavior: Clip.none, children: capas)),
        if (extra > 0)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Text('+$extra más',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontFamily: 'Rubik', color: Colors.white, fontWeight: FontWeight.w600)),
          ),
      ],
    );
  }
}
