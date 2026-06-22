import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prosane_app/core/design_system/stacked_cards_deck.dart';

void main() {
  testWidgets('vacío no renderiza nada', (t) async {
    await t.pumpWidget(const MaterialApp(home: Scaffold(body: StackedCardsDeck(cards: []))));
    expect(find.byType(StackedCardsDeck), findsOneWidget);
    expect(find.byType(Text), findsNothing); // no renderiza contenido de cards
  });

  testWidgets('con >3 cards muestra "+N más"', (t) async {
    final cards = [for (var i = 0; i < 5; i++) SizedBox(key: ValueKey('c$i'), height: 80, child: Text('card $i'))];
    await t.pumpWidget(MaterialApp(home: Scaffold(body: StackedCardsDeck(cards: cards))));
    expect(find.text('+2 más'), findsOneWidget);
    // La de adelante (índice 0) está presente.
    expect(find.text('card 0'), findsOneWidget);
  });
}
