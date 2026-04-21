import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rummipoker/logic/rummi_poker_grid/item_definition.dart';
import 'package:rummipoker/logic/rummi_poker_grid/item_effect_runtime.dart';
import 'package:rummipoker/logic/rummi_poker_grid/jester_meta.dart';
import 'package:rummipoker/logic/rummi_poker_grid/rummi_blind_state.dart';
import 'package:rummipoker/logic/rummi_poker_grid/rummi_poker_grid_session.dart';

void main() {
  group('ItemEffectRuntime', () {
    test('useBattleItem applies board discard effect and emits events', () {
      final item = _item(id: 'board_scrap', op: 'add_board_discard', amount: 1);
      final session = RummiPokerGridSession(
        runSeed: 1,
        blind: RummiBlindState(
          targetScore: 999,
          boardDiscardsRemaining: 2,
          handDiscardsRemaining: 1,
        ),
      );
      final runProgress = RummiRunProgress()
        ..itemInventory = const RunInventoryState(
          ownedItems: [
            OwnedItemEntry(
              itemId: 'board_scrap',
              count: 1,
              placement: ItemPlacement.quickSlot,
            ),
          ],
          quickSlotItemIds: ['board_scrap'],
        );

      final result = ItemEffectRuntime.useBattleItem(
        item: item,
        session: session,
        runProgress: runProgress,
      );

      expect(result.isSuccess, isTrue);
      expect(session.blind.boardDiscardsRemaining, 3);
      expect(session.blind.handDiscardsRemaining, 1);
      expect(runProgress.itemInventory.ownedItems, isEmpty);
      expect(result.events.map((event) => event.kind), [
        ItemEffectEventKind.boardDiscardAdded,
        ItemEffectEventKind.itemConsumed,
      ]);
      expect(result.events.first.amount, 1);
    });

    test('useBattleItem rejects unsupported op without consuming item', () {
      final item = _item(id: 'peek_chip', op: 'peek_deck_discard_one');
      final session = RummiPokerGridSession(
        runSeed: 1,
        blind: RummiBlindState(targetScore: 999),
      );
      final runProgress = RummiRunProgress()
        ..itemInventory = const RunInventoryState(
          ownedItems: [
            OwnedItemEntry(
              itemId: 'peek_chip',
              count: 1,
              placement: ItemPlacement.quickSlot,
            ),
          ],
          quickSlotItemIds: ['peek_chip'],
        );

      final result = ItemEffectRuntime.useBattleItem(
        item: item,
        session: session,
        runProgress: runProgress,
      );

      expect(result.isSuccess, isFalse);
      expect(result.isPending, isTrue);
      expect(result.failMessage, '덱 확인/버림 선택 UI 연결이 필요합니다.');
      expect(runProgress.itemInventory.ownedItems.single.itemId, 'peek_chip');
      expect(
        result.events.single.kind,
        ItemEffectEventKind.interactionRequired,
      );
    });

    test('useBattleItem supports emergency draw when hand is empty', () {
      final item = _item(id: 'emergency_draw', op: 'draw_if_hand_empty');
      final session = RummiPokerGridSession(
        runSeed: 1,
        blind: RummiBlindState(targetScore: 999),
      );
      final runProgress = RummiRunProgress()
        ..itemInventory = const RunInventoryState(
          ownedItems: [
            OwnedItemEntry(
              itemId: 'emergency_draw',
              count: 1,
              placement: ItemPlacement.quickSlot,
            ),
          ],
          quickSlotItemIds: ['emergency_draw'],
        );

      final result = ItemEffectRuntime.useBattleItem(
        item: item,
        session: session,
        runProgress: runProgress,
      );

      expect(result.isSuccess, isTrue);
      expect(session.hand.length, 1);
      expect(runProgress.itemInventory.ownedItems, isEmpty);
      expect(result.events.map((event) => event.kind), [
        ItemEffectEventKind.tileDrawn,
        ItemEffectEventKind.itemConsumed,
      ]);
    });

    test('useBattleItem applies board move effect and consumes stack', () {
      final item = _item(id: 'move_token', op: 'add_board_move', amount: 1);
      final session = RummiPokerGridSession(
        runSeed: 1,
        blind: RummiBlindState(
          targetScore: 999,
          boardMovesRemaining: 1,
          boardMovesMax: 3,
        ),
      );
      final runProgress = RummiRunProgress()
        ..itemInventory = const RunInventoryState(
          ownedItems: [
            OwnedItemEntry(
              itemId: 'move_token',
              count: 1,
              placement: ItemPlacement.quickSlot,
            ),
          ],
          quickSlotItemIds: ['move_token'],
        );

      final result = ItemEffectRuntime.useBattleItem(
        item: item,
        session: session,
        runProgress: runProgress,
      );

      expect(result.isSuccess, isTrue);
      expect(session.blind.boardMovesRemaining, 2);
      expect(session.blind.boardMovesMax, 3);
      expect(runProgress.itemInventory.ownedItems, isEmpty);
      expect(result.events.map((event) => event.kind), [
        ItemEffectEventKind.boardMoveAdded,
        ItemEffectEventKind.itemConsumed,
      ]);
      expect(result.events.first.amount, 1);
    });

    test('catalogEffectRows assigns every v1 item to a runtime handler', () {
      final catalog = ItemCatalog.fromJsonString(
        File('data/common/items_common_v1.json').readAsStringSync(),
      );

      final rows = ItemEffectRuntime.catalogEffectRows(catalog);
      final unassigned = rows
          .where((row) => row.handlerName == 'unassignedItemEffectHandler')
          .toList(growable: false);

      expect(rows.length, catalog.all.length);
      expect(unassigned, isEmpty);
      expect(
        rows
            .where((row) => row.status == ItemEffectApplicationStatus.applied)
            .map((row) => row.key)
            .toSet(),
        {
          'use_battle:add_board_discard',
          'use_battle:add_hand_discard',
          'use_battle:add_board_move',
          'use_battle:draw_if_hand_empty',
        },
      );
    });
  });
}

ItemDefinition _item({required String id, required String op, int amount = 1}) {
  return ItemDefinition.fromJson(<String, dynamic>{
    'id': id,
    'displayName': id,
    'displayNameKey': 'data.items.$id.displayName',
    'type': 'consumable',
    'rarity': 'common',
    'basePrice': 4,
    'sellPrice': 2,
    'stackable': true,
    'maxStack': 2,
    'sellable': true,
    'usableInBattle': true,
    'placement': 'quickSlot',
    'slotHint': 'q',
    'effectText': 'Test effect.',
    'effectTextKey': 'data.items.$id.effectText',
    'effect': <String, dynamic>{
      'timing': 'use_battle',
      'op': op,
      'amount': amount,
      'consume': true,
    },
    'tags': <String>['battle'],
    'sourceNotes': 'Test fixture.',
  });
}
