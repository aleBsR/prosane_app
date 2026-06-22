import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prosane_app/core/design_system/stacked_cards_deck.dart';

void main() {
  testWidgets('vacío no renderiza nada', (t) async {
    await t.pumpWidget(const MaterialApp(home: Scaffold(body: StackedCardsDeck(items: []))));
    expect(find.byType(StackedCardsDeck), findsOneWidget);
    expect(find.byType(Text), findsNothing);
  });

  testWidgets('tocar la card de adelante dispara su onTap', (t) async {
    final taps = <int>[];
    final items = <DeckCard>[
      for (var i = 0; i < 3; i++)
        (child: SizedBox(height: 120, child: Center(child: Text('card $i'))), onTap: () => taps.add(i)),
    ];
    await t.pumpWidget(MaterialApp(home: Scaffold(body: StackedCardsDeck(items: items))));
    // index 0 está al frente: tocar su texto dispara su acción.
    await t.tap(find.text('card 0'));
    await t.pump();
    expect(taps, [0]);
  });

  testWidgets('tocar una card de atrás la trae al frente (no dispara acción)', (t) async {
    final taps = <int>[];
    final items = <DeckCard>[
      for (var i = 0; i < 3; i++)
        (child: SizedBox(height: 120, child: Center(child: Text('card $i'))), onTap: () => taps.add(i)),
    ];
    await t.pumpWidget(MaterialApp(home: Scaffold(body: StackedCardsDeck(items: items, offset: 40))));
    // La card de atrás (index 1) asoma debajo de la de adelante; tocar su franja
    // baja no dispara acción sino que la trae al frente. Tocamos cerca del fondo.
    final deckRect = t.getRect(find.byType(StackedCardsDeck));
    await t.tapAt(Offset(deckRect.center.dx, deckRect.bottom - 5));
    await t.pump();
    expect(taps, isEmpty); // trajo al frente, no navegó
  });
}
