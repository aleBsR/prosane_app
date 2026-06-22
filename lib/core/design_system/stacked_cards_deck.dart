import 'package:flutter/material.dart';

/// Muestra una lista de cards apiladas tipo mazo: la de adelante (índice 0) full
/// e interactiva; detrás, hasta [maxVisible]-1 asomando con offset/escala. Si hay
/// más de [maxVisible], las extra se acumulan al fondo y se indica "+N".
class StackedCardsDeck extends StatelessWidget {
  const StackedCardsDeck({
    super.key,
    required this.cards,
    this.maxVisible = 3,
    this.cardHeight = 104,
    this.offset = 14,
  });

  final List<Widget> cards; // front = index 0
  final int maxVisible;
  final double cardHeight;
  final double offset;

  @override
  Widget build(BuildContext context) {
    if (cards.isEmpty) return const SizedBox.shrink();
    final visibles = cards.length < maxVisible ? cards.length : maxVisible;
    final extra = cards.length - visibles;

    final capas = <Widget>[];
    // Dibujar de atrás hacia adelante para que la de índice 0 quede arriba.
    for (var depth = visibles - 1; depth >= 0; depth--) {
      capas.add(Positioned(
        left: 0,
        right: 0,
        top: depth * offset,
        child: Transform.scale(
          scale: 1.0 - depth * 0.04,
          alignment: Alignment.topCenter,
          child: IgnorePointer(
            ignoring: depth != 0, // solo la de adelante recibe toques
            child: Opacity(opacity: depth == 0 ? 1.0 : 0.9, child: cards[depth]),
          ),
        ),
      ));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: cardHeight + (visibles - 1) * offset,
          child: Stack(clipBehavior: Clip.none, children: capas),
        ),
        if (extra > 0)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Text('+$extra más',
                textAlign: TextAlign.center,
                style: const TextStyle(fontFamily: 'Rubik', color: Colors.white, fontWeight: FontWeight.w600)),
          ),
      ],
    );
  }
}
