import 'package:flutter/material.dart';

/// Cards apiladas en abanico vertical (estilo mazo): cada card de atrás asoma su
/// encabezado por arriba de la siguiente y la última queda completa. TODAS son
/// tappables (cada una conserva su propio onTap), para ver de qué trata cada
/// pendiente y elegir cualquiera.
///
/// Orden visual: `cards[0]` arriba (asomando su encabezado), la última abajo y
/// completa. Las cards posteriores se dibujan por encima, así el encabezado de
/// cada card previa queda expuesto y recibe el toque en esa franja.
class StackedCardsDeck extends StatelessWidget {
  const StackedCardsDeck({
    super.key,
    required this.cards,
    this.peek = 66,
    this.cardHeight = 104,
  });

  final List<Widget> cards; // front/top = index 0
  final double peek;        // alto del encabezado que asoma de cada card detrás
  final double cardHeight;

  @override
  Widget build(BuildContext context) {
    if (cards.isEmpty) return const SizedBox.shrink();
    if (cards.length == 1) {
      return SizedBox(height: cardHeight, child: cards.first);
    }
    final n = cards.length;
    final altura = cardHeight + peek * (n - 1);
    return SizedBox(
      height: altura,
      child: Stack(
        children: [
          for (var i = 0; i < n; i++)
            Positioned(
              left: 0,
              right: 0,
              top: i * peek,
              height: cardHeight,
              child: cards[i],
            ),
        ],
      ),
    );
  }
}
