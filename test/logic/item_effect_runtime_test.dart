import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rummipoker/logic/rummi_poker_grid/item_definition.dart';
import 'package:rummipoker/logic/rummi_poker_grid/item_effect_runtime.dart';
import 'package:rummipoker/logic/rummi_poker_grid/jester_meta.dart';
import 'package:rummipoker/logic/rummi_poker_grid/models/poker_deck.dart';
import 'package:rummipoker/logic/rummi_poker_grid/models/tile.dart';
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

    test('useBattleItem requests explicit deck discard choice', () {
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
      expect(result.failMessage, '버릴 덱 타일 선택이 필요합니다.');
      expect(runProgress.itemInventory.ownedItems.single.itemId, 'peek_chip');
      expect(
        result.events.single.kind,
        ItemEffectEventKind.interactionRequired,
      );
    });

    test('consumeBattleDeckPeekItem consumes when deck window is revealed', () {
      final item = _item(
        id: 'deck_needle',
        op: 'peek_deck_discard_one',
        rawEffect: const {'peek': 3},
      );
      final top = Tile(color: TileColor.red, number: 1);
      final second = Tile(color: TileColor.blue, number: 2);
      final third = Tile(color: TileColor.yellow, number: 3);
      final bottom = Tile(color: TileColor.black, number: 4);
      final session = RummiPokerGridSession(
        runSeed: 1,
        blind: RummiBlindState(targetScore: 999),
        deck: PokerDeck.fromSnapshot([bottom, third, second, top]),
      );
      final runProgress = RummiRunProgress()
        ..itemInventory = const RunInventoryState(
          ownedItems: [
            OwnedItemEntry(
              itemId: 'deck_needle',
              count: 1,
              placement: ItemPlacement.quickSlot,
            ),
          ],
          quickSlotItemIds: ['deck_needle'],
        );

      final result = ItemEffectRuntime.consumeBattleDeckPeekItem(
        item: item,
        session: session,
        runProgress: runProgress,
      );

      expect(result.isSuccess, isTrue);
      expect(session.peekDeckTop(3), [top, second, third]);
      expect(runProgress.itemInventory.ownedItems, isEmpty);
      expect(result.events.map((event) => event.kind), [
        ItemEffectEventKind.interactionRequired,
        ItemEffectEventKind.itemConsumed,
      ]);
    });

    test('useBattleDeckPeekDiscardItem discards chosen top-window tile', () {
      final item = _item(
        id: 'deck_needle',
        op: 'peek_deck_discard_one',
        rawEffect: const {'peek': 3},
      );
      final top = Tile(color: TileColor.red, number: 1);
      final second = Tile(color: TileColor.blue, number: 2);
      final third = Tile(color: TileColor.yellow, number: 3);
      final bottom = Tile(color: TileColor.black, number: 4);
      final session = RummiPokerGridSession(
        runSeed: 1,
        blind: RummiBlindState(targetScore: 999),
        deck: PokerDeck.fromSnapshot([bottom, third, second, top]),
      );

      final result = ItemEffectRuntime.useBattleDeckPeekDiscardItem(
        item: item,
        session: session,
        topIndex: 1,
      );

      expect(result.isSuccess, isTrue);
      expect(session.eliminated.single, second);
      expect(session.peekDeckTop(3), [top, third, bottom]);
      expect(result.events.map((event) => event.kind), [
        ItemEffectEventKind.deckTileDiscarded,
      ]);
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

    test('useBattleItem undoes last board move and consumes stack', () {
      final item = _item(id: 'undo_seal', op: 'undo_last_board_move');
      final session = RummiPokerGridSession(
        runSeed: 1,
        blind: RummiBlindState(
          targetScore: 999,
          boardMovesRemaining: 3,
          boardMovesMax: 3,
        ),
      );
      final tile = Tile(color: TileColor.red, number: 7);
      session.board.setCell(0, 0, tile);
      expect(
        session.tryMoveBoardTile(fromRow: 0, fromCol: 0, toRow: 2, toCol: 2),
        isNull,
      );
      final runProgress = RummiRunProgress()
        ..itemInventory = const RunInventoryState(
          ownedItems: [
            OwnedItemEntry(
              itemId: 'undo_seal',
              count: 1,
              placement: ItemPlacement.quickSlot,
            ),
          ],
          quickSlotItemIds: ['undo_seal'],
        );

      final result = ItemEffectRuntime.useBattleItem(
        item: item,
        session: session,
        runProgress: runProgress,
      );

      expect(result.isSuccess, isTrue);
      expect(session.board.cellAt(0, 0), tile);
      expect(session.board.cellAt(2, 2), isNull);
      expect(session.blind.boardMovesRemaining, 3);
      expect(runProgress.itemInventory.ownedItems, isEmpty);
      expect(result.events.map((event) => event.kind), [
        ItemEffectEventKind.boardMoveUndone,
        ItemEffectEventKind.itemConsumed,
      ]);
    });

    test(
      'useBattleItem does not consume undo item when no move history exists',
      () {
        final item = _item(id: 'undo_seal', op: 'undo_last_board_move');
        final session = RummiPokerGridSession(
          runSeed: 1,
          blind: RummiBlindState(targetScore: 999),
        );
        final runProgress = RummiRunProgress()
          ..itemInventory = const RunInventoryState(
            ownedItems: [
              OwnedItemEntry(
                itemId: 'undo_seal',
                count: 1,
                placement: ItemPlacement.quickSlot,
              ),
            ],
            quickSlotItemIds: ['undo_seal'],
          );

        final result = ItemEffectRuntime.useBattleItem(
          item: item,
          session: session,
          runProgress: runProgress,
        );

        expect(result.isSuccess, isFalse);
        expect(result.failMessage, '되돌릴 보드 이동이 없습니다.');
        expect(runProgress.itemInventory.ownedItems.single.itemId, 'undo_seal');
      },
    );

    test('station start item applies max hand size with discard penalty', () {
      final item = _item(
        id: 'wide_grip',
        timing: 'station_start',
        op: 'increase_hand_size_with_discard_penalty',
        placement: ItemPlacement.equipped,
        rawEffect: const {'boardDiscardPenalty': 1},
      );
      final session = RummiPokerGridSession(
        runSeed: 1,
        blind: RummiBlindState(
          targetScore: 999,
          boardDiscardsRemaining: 4,
          handDiscardsRemaining: 2,
        ),
      )..maxHandSize = 1;

      final result = ItemEffectRuntime.applyStationStartItem(
        item: item,
        session: session,
      );

      expect(result.isSuccess, isTrue);
      expect(session.maxHandSize, 2);
      expect(session.blind.boardDiscardsRemaining, 3);
      expect(session.blind.handDiscardsRemaining, 2);
      expect(result.events.map((event) => event.kind), [
        ItemEffectEventKind.maxHandSizeIncreased,
        ItemEffectEventKind.boardDiscardRemoved,
      ]);
    });

    test(
      'owned station start items apply active hand size and move effects',
      () {
        final catalog = ItemCatalog.fromJson({
          'schemaVersion': 1,
          'catalogId': 'test',
          'items': [
            _itemJson(
              id: 'travel_pouch',
              timing: 'inventory_capacity',
              op: 'increase_hand_size',
              placement: 'passiveRack',
            ),
            _itemJson(
              id: 'organizer_glove',
              timing: 'station_start',
              op: 'add_board_move',
              placement: 'equipped',
            ),
            _itemJson(
              id: 'board_lift',
              timing: 'station_start',
              op: 'add_board_move',
              placement: 'inventory',
              consume: true,
            ),
          ],
        });
        final session = RummiPokerGridSession(
          runSeed: 1,
          blind: RummiBlindState(
            targetScore: 999,
            boardMovesRemaining: 3,
            boardMovesMax: 3,
          ),
        )..maxHandSize = 1;
        final runProgress = RummiRunProgress()
          ..itemInventory = const RunInventoryState(
            ownedItems: [
              OwnedItemEntry(
                itemId: 'travel_pouch',
                count: 1,
                placement: ItemPlacement.passiveRack,
              ),
              OwnedItemEntry(
                itemId: 'organizer_glove',
                count: 1,
                placement: ItemPlacement.equipped,
              ),
              OwnedItemEntry(
                itemId: 'board_lift',
                count: 1,
                placement: ItemPlacement.inventory,
              ),
            ],
            passiveRelicIds: ['travel_pouch'],
            equippedItemIds: ['organizer_glove'],
          );

        final results = ItemEffectRuntime.applyOwnedStationStartItems(
          catalog: catalog,
          session: session,
          runProgress: runProgress,
        );

        expect(results.every((result) => result.isSuccess), isTrue);
        expect(session.maxHandSize, 2);
        expect(session.blind.boardMovesRemaining, 5);
        expect(
          runProgress.itemInventory.ownedItems.map((entry) => entry.itemId),
          isNot(contains('board_lift')),
        );
      },
    );

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
          'use_battle:undo_last_board_move',
          'use_battle:peek_deck_discard_one',
          'use_battle:draw_if_hand_empty',
          'station_start:add_board_discard',
          'station_start:add_hand_discard',
          'station_start:add_board_move',
          'station_start:increase_hand_size_with_discard_penalty',
          'inventory_capacity:increase_hand_size',
        },
      );
    });
  });
}

ItemDefinition _item({
  required String id,
  required String op,
  String timing = 'use_battle',
  int amount = 1,
  ItemPlacement placement = ItemPlacement.quickSlot,
  Map<String, dynamic> rawEffect = const {},
}) {
  return ItemDefinition.fromJson(
    _itemJson(
      id: id,
      timing: timing,
      op: op,
      amount: amount,
      placement: _placementName(placement),
      rawEffect: rawEffect,
    ),
  );
}

Map<String, dynamic> _itemJson({
  required String id,
  required String timing,
  required String op,
  int amount = 1,
  String placement = 'quickSlot',
  bool? consume,
  Map<String, dynamic> rawEffect = const {},
}) {
  return <String, dynamic>{
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
    'usableInBattle': timing == 'use_battle',
    'placement': placement,
    'slotHint': 'q',
    'effectText': 'Test effect.',
    'effectTextKey': 'data.items.$id.effectText',
    'effect': <String, dynamic>{
      'timing': timing,
      'op': op,
      'amount': amount,
      'consume': consume ?? timing == 'use_battle',
      ...rawEffect,
    },
    'tags': <String>['battle'],
    'sourceNotes': 'Test fixture.',
  };
}

String _placementName(ItemPlacement placement) {
  return switch (placement) {
    ItemPlacement.inventory => 'inventory',
    ItemPlacement.quickSlot => 'quickSlot',
    ItemPlacement.equipped => 'equipped',
    ItemPlacement.passiveRack => 'passiveRack',
  };
}
