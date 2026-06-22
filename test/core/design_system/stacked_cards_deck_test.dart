import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prosane_app/core/design_system/stacked_cards_deck.dart';

void main() {
  testWidgets('vacío no renderiza nada', (t) async {
    await t.pumpWidget(const MaterialApp(home: Scaffold(body: StackedCardsDeck(cards: []))));
    expect(find.byType(StackedCardsDeck), findsOneWidget);
    expect(find.byType(Text), findsNothing);
  });

  testWidgets('renderiza todas las cards (todas presentes y tappables)', (t) async {
    final taps = <int>[];
    final cards = [
      for (var i = 0; i < 4; i++)
        GestureDetector(
          key: ValueKey('c$i'),
          behavior: HitTestBehavior.opaque,
          onTap: () => taps.add(i),
          child: SizedBox(height: 104, child: Text('card $i')),
        ),
    ];
    await t.pumpWidget(MaterialApp(home: Scaffold(body: StackedCardsDeck(cards: cards))));
    // Las 4 están en el árbol.
    for (var i = 0; i < 4; i++) {
      expect(find.text('card $i'), findsOneWidget);
    }
    // La última (abajo, completa) es tappable.
    await t.tap(find.text('card 3'));
    expect(taps, contains(3));
  });
}
