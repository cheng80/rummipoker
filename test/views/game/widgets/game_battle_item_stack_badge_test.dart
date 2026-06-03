import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rummipoker/logic/rummi_poker_grid/item_definition.dart';
import 'package:rummipoker/logic/rummi_poker_grid/jester_meta.dart';
import 'package:rummipoker/logic/rummi_poker_grid/models/board.dart';
import 'package:rummipoker/logic/rummi_poker_grid/rummi_battle_facade.dart';
import 'package:rummipoker/views/game/widgets/game_shared_widgets.dart';

void main() {
  testWidgets('battle item stack badge does not cover card name', (
    tester,
  ) async {
    const itemName = 'Deck Needle';
    final item = ItemDefinition.fromJson(const <String, dynamic>{
      'id': 'deck_needle',
      'displayName': itemName,
      'displayNameKey': 'data.items.deck_needle.displayName',
      'type': 'utility',
      'rarity': 'common',
      'basePrice': 3,
      'sellPrice': 1,
      'stackable': true,
      'maxStack': 3,
      'sellable': true,
      'usableInBattle': true,
      'placement': 'quickSlot',
      'slotHint': 'quick',
      'effectText': 'Peek and discard.',
      'effectTextKey': 'data.items.deck_needle.effectText',
      'effect': <String, dynamic>{
        'timing': 'use_battle',
        'op': 'peek_deck_discard_one',
        'amount': 1,
        'consume': true,
      },
      'tags': <String>['battle', 'deck'],
      'sourceNotes': 'Test fixture.',
    });
    final slot = RummiBattleItemSlotView(
      slotIndex: 0,
      slotLabel: 'Q1',
      contentId: item.id,
      displayName: itemName,
      displayNameKey: item.displayNameKey,
      effectText: item.effectText,
      effectTextKey: item.effectTextKey,
      count: 2,
      placement: item.placement,
      usableInBattle: item.usableInBattle,
      item: item,
    );
    final battle = RummiBattleRuntimeFacade(
      stageIndex: 1,
      currentGold: 0,
      totalDeckSize: 52,
      board: RummiBoard(),
      hand: const [],
      scoringCellKeys: const {},
      itemSlots: [slot],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 360,
              child: GameItemZoneSkeleton(
                battle: battle,
                activeEffects: const <RummiJesterEffectBreakdown>[],
                settlementSequenceTick: 0,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final nameRect = tester.getRect(find.text(itemName));
    final badgeRect = tester.getRect(
      find.byKey(const ValueKey('battle-item-stack-count-badge')),
    );

    expect(nameRect.overlaps(badgeRect), isFalse);
    expect(find.text('x2'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
