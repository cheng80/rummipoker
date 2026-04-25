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

    test(
      'useBattleItem queues next confirm chips modifier and consumes stack',
      () {
        final item = _item(
          id: 'chip_capsule',
          timing: 'next_confirm',
          op: 'chips_bonus',
          amount: 25,
        );
        final session = RummiPokerGridSession(
          runSeed: 1,
          blind: RummiBlindState(targetScore: 999),
        );
        _placeTwoPair(session);
        final runProgress = RummiRunProgress()
          ..itemInventory = const RunInventoryState(
            ownedItems: [
              OwnedItemEntry(
                itemId: 'chip_capsule',
                count: 1,
                placement: ItemPlacement.quickSlot,
              ),
            ],
            quickSlotItemIds: ['chip_capsule'],
          );

        final result = ItemEffectRuntime.useBattleItem(
          item: item,
          session: session,
          runProgress: runProgress,
        );

        expect(result.isSuccess, isTrue);
        expect(session.confirmModifiers.single.itemId, 'chip_capsule');
        expect(runProgress.itemInventory.ownedItems, isEmpty);
        expect(result.events.map((event) => event.kind), [
          ItemEffectEventKind.nextConfirmModifierQueued,
          ItemEffectEventKind.itemConsumed,
        ]);

        final confirmed = session.confirmAllFullLines();
        expect(confirmed.result.scoreAdded, 50);
        expect(session.confirmModifiers, isEmpty);
        expect(
          confirmed.result.lineBreakdowns.single.effects.single.jesterId,
          'chip_capsule',
        );
      },
    );

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

    test('owned confirm modifier equipment queues at station start', () {
      final catalog = ItemCatalog.fromJson({
        'schemaVersion': 1,
        'catalogId': 'test',
        'items': [
          _itemJson(
            id: 'score_abacus',
            timing: 'first_confirm_each_station',
            op: 'chips_bonus',
            placement: 'equipped',
            consume: false,
            amount: 30,
          ),
        ],
      });
      final session = RummiPokerGridSession(
        runSeed: 1,
        blind: RummiBlindState(targetScore: 999),
      );
      _placeTwoPair(session);
      final runProgress = RummiRunProgress()
        ..itemInventory = const RunInventoryState(
          ownedItems: [
            OwnedItemEntry(
              itemId: 'score_abacus',
              count: 1,
              placement: ItemPlacement.equipped,
            ),
          ],
          equippedItemIds: ['score_abacus'],
        );

      final results = ItemEffectRuntime.applyOwnedStationStartItems(
        catalog: catalog,
        session: session,
        runProgress: runProgress,
      );

      expect(results.single.isSuccess, isTrue);
      expect(session.confirmModifiers.single.itemId, 'score_abacus');
      final confirmed = session.confirmAllFullLines();
      expect(confirmed.result.scoreAdded, 55);
      expect(session.confirmModifiers, isEmpty);
    });

    test(
      'owned quick slot confirm consumables are not queued at station start',
      () {
        final catalog = ItemCatalog.fromJson({
          'schemaVersion': 1,
          'catalogId': 'test',
          'items': [
            _itemJson(
              id: 'chip_capsule',
              timing: 'next_confirm',
              op: 'chips_bonus',
              placement: 'quickSlot',
              consume: true,
              amount: 25,
            ),
          ],
        });
        final session = RummiPokerGridSession(
          runSeed: 1,
          blind: RummiBlindState(targetScore: 999),
        );
        final runProgress = RummiRunProgress()
          ..itemInventory = const RunInventoryState(
            ownedItems: [
              OwnedItemEntry(
                itemId: 'chip_capsule',
                count: 1,
                placement: ItemPlacement.quickSlot,
              ),
            ],
            quickSlotItemIds: ['chip_capsule'],
          );

        final results = ItemEffectRuntime.applyOwnedStationStartItems(
          catalog: catalog,
          session: session,
          runProgress: runProgress,
        );

        expect(results, isEmpty);
        expect(session.confirmModifiers, isEmpty);
        expect(
          runProgress.itemInventory.ownedItems.single.itemId,
          'chip_capsule',
        );
      },
    );

    test('market reroll item queues discount and consumes inventory stack', () {
      final item = _item(
        id: 'reroll_token',
        timing: 'market_reroll',
        op: 'discount_next_reroll',
        placement: ItemPlacement.inventory,
        amount: 1,
        consume: true,
      );
      final runProgress = RummiRunProgress()
        ..rerollCost = 5
        ..itemInventory = const RunInventoryState(
          ownedItems: [
            OwnedItemEntry(
              itemId: 'reroll_token',
              count: 1,
              placement: ItemPlacement.inventory,
            ),
          ],
        );

      final result = ItemEffectRuntime.applyMarketRerollItem(
        item: item,
        runProgress: runProgress,
      );

      expect(result.isSuccess, isTrue);
      expect(runProgress.effectiveRerollCost(), 4);
      expect(runProgress.itemInventory.ownedItems, isEmpty);
      expect(result.events.map((event) => event.kind), [
        ItemEffectEventKind.marketModifierQueued,
        ItemEffectEventKind.itemConsumed,
      ]);
    });

    test('market use item gains gold and consumes inventory stack', () {
      final item = _item(
        id: 'coin_cache',
        timing: 'use_market',
        op: 'gain_gold',
        placement: ItemPlacement.inventory,
        amount: 3,
        consume: true,
      );
      final runProgress = RummiRunProgress()
        ..gold = 4
        ..itemInventory = const RunInventoryState(
          ownedItems: [
            OwnedItemEntry(
              itemId: 'coin_cache',
              count: 1,
              placement: ItemPlacement.inventory,
            ),
          ],
        );

      final result = ItemEffectRuntime.applyMarketUseItem(
        item: item,
        runProgress: runProgress,
      );

      expect(result.isSuccess, isTrue);
      expect(runProgress.gold, 7);
      expect(runProgress.itemInventory.ownedItems, isEmpty);
      expect(result.events.map((event) => event.kind), [
        ItemEffectEventKind.goldGained,
        ItemEffectEventKind.itemConsumed,
      ]);
    });

    test('market use item respects low-gold threshold', () {
      final item = _item(
        id: 'thin_wallet',
        timing: 'use_market_if_gold_lte',
        op: 'gain_gold',
        placement: ItemPlacement.inventory,
        amount: 5,
        consume: true,
        rawEffect: const {'threshold': 3},
      );
      final runProgress = RummiRunProgress()
        ..gold = 4
        ..itemInventory = const RunInventoryState(
          ownedItems: [
            OwnedItemEntry(
              itemId: 'thin_wallet',
              count: 1,
              placement: ItemPlacement.inventory,
            ),
          ],
        );

      final rejected = ItemEffectRuntime.applyMarketUseItem(
        item: item,
        runProgress: runProgress,
      );
      runProgress.gold = 3;
      final applied = ItemEffectRuntime.applyMarketUseItem(
        item: item,
        runProgress: runProgress,
      );

      expect(rejected.isSuccess, isFalse);
      expect(rejected.failMessage, '현재 골드가 사용 조건보다 많습니다.');
      expect(applied.isSuccess, isTrue);
      expect(runProgress.gold, 8);
      expect(runProgress.itemInventory.ownedItems, isEmpty);
    });

    test(
      'market buy item queues category discount and consumes on purchase',
      () {
        final discountItem = _item(
          id: 'item_invoice',
          timing: 'market_buy_if_category',
          op: 'discount_next_purchase',
          placement: ItemPlacement.inventory,
          amount: 4,
          consume: true,
          rawEffect: const {'category': 'item'},
        );
        final bought = _item(
          id: 'board_scrap',
          op: 'add_board_discard',
          placement: ItemPlacement.quickSlot,
          amount: 1,
        );
        final runProgress = RummiRunProgress()
          ..gold = 10
          ..itemInventory = const RunInventoryState(
            ownedItems: [
              OwnedItemEntry(
                itemId: 'item_invoice',
                count: 1,
                placement: ItemPlacement.inventory,
              ),
            ],
          );

        final result = ItemEffectRuntime.applyMarketBuyItem(
          item: discountItem,
          runProgress: runProgress,
        );
        final boughtOk = runProgress.buyItem(bought);

        expect(result.isSuccess, isTrue);
        expect(boughtOk, isTrue);
        expect(runProgress.gold, 10);
        expect(runProgress.marketModifiers.nextItemPurchaseDiscount, 0);
        expect(
          runProgress.itemInventory.ownedItems.map((entry) => entry.itemId),
          contains('board_scrap'),
        );
      },
    );

    test('inventory capacity item reports extra quick slot modifier', () {
      final item = ItemDefinition.fromJson(
        _itemJson(
          id: 'spare_pouch',
          timing: 'inventory_capacity',
          op: 'extra_quick_slot',
          placement: 'passiveRack',
        ),
      );
      final session = RummiPokerGridSession(
        runSeed: 1,
        blind: RummiBlindState(targetScore: 999),
      );
      final runProgress = RummiRunProgress();

      final result = ItemEffectRuntime.applyInventoryCapacityItem(
        item: item,
        session: session,
        runProgress: runProgress,
      );

      expect(result.isSuccess, isTrue);
      expect(
        result.events.single.kind,
        ItemEffectEventKind.capacityModifierQueued,
      );
      expect(result.events.single.amount, 1);
      expect(result.events.single.detail, 'extra_quick_slot');
    });

    test('sell jester item reports sell price bonus modifier', () {
      final item = ItemDefinition.fromJson(
        _itemJson(
          id: 'jester_hook',
          timing: 'sell_jester',
          op: 'sell_price_bonus',
          placement: 'passiveRack',
        ),
      );

      final result = ItemEffectRuntime.applySellJesterItem(
        item: item,
        runProgress: RummiRunProgress(),
      );

      expect(result.isSuccess, isTrue);
      expect(
        result.events.single.kind,
        ItemEffectEventKind.marketModifierQueued,
      );
      expect(result.events.single.amount, 1);
      expect(result.events.single.detail, 'sell_price_bonus');
    });

    test('expiry guard item rescues the first combat lock once', () {
      final item = ItemDefinition.fromJson(
        _itemJson(
          id: 'safety_net',
          timing: 'expiry_guard',
          op: 'rescue_first_expiry_each_station',
          placement: 'passiveRack',
        ),
      );
      final session = RummiPokerGridSession(
        runSeed: 1,
        blind: RummiBlindState(targetScore: 999, boardDiscardsRemaining: 0),
      );
      final runProgress = RummiRunProgress();

      final first = ItemEffectRuntime.applyExpiryGuardItem(
        item: item,
        session: session,
        runProgress: runProgress,
        signals: const [RummiExpirySignal.boardFullAfterDcExhausted],
      );
      final second = ItemEffectRuntime.applyExpiryGuardItem(
        item: item,
        session: session,
        runProgress: runProgress,
        signals: const [RummiExpirySignal.boardFullAfterDcExhausted],
      );

      expect(first.isSuccess, isTrue);
      expect(first.events.first.kind, ItemEffectEventKind.expiryGuardTriggered);
      expect(session.blind.boardDiscardsRemaining, 1);
      expect(session.expiryGuardUsedThisStation, isTrue);
      expect(second.isSuccess, isFalse);
    });

    test('owned enter market items queue first reroll and offer modifiers', () {
      final catalog = ItemCatalog.fromJson({
        'schemaVersion': 1,
        'catalogId': 'test',
        'items': [
          _itemJson(
            id: 'merchant_stamp',
            timing: 'enter_market',
            op: 'discount_first_reroll',
            placement: 'passiveRack',
            consume: false,
          ),
          _itemJson(
            id: 'shop_lens',
            timing: 'market_build_offers',
            op: 'extra_item_offer_slot',
            placement: 'equipped',
            consume: false,
          ),
        ],
      });
      final runProgress = RummiRunProgress()
        ..rerollCost = 5
        ..itemInventory = const RunInventoryState(
          ownedItems: [
            OwnedItemEntry(
              itemId: 'merchant_stamp',
              count: 1,
              placement: ItemPlacement.passiveRack,
            ),
            OwnedItemEntry(
              itemId: 'shop_lens',
              count: 1,
              placement: ItemPlacement.equipped,
            ),
          ],
          passiveRelicIds: ['merchant_stamp'],
          equippedItemIds: ['shop_lens'],
        );

      final results = ItemEffectRuntime.applyOwnedEnterMarketItems(
        catalog: catalog,
        runProgress: runProgress,
      );

      expect(results.every((result) => result.isSuccess), isTrue);
      expect(runProgress.effectiveRerollCost(), 4);
      expect(runProgress.marketModifiers.itemOfferSlotCount, 4);
    });

    test('owned enter market gain-gold item applies immediately', () {
      final catalog = ItemCatalog.fromJson({
        'schemaVersion': 1,
        'catalogId': 'test',
        'items': [
          _itemJson(
            id: 'ledger_clip',
            timing: 'enter_market',
            op: 'gain_gold',
            placement: 'equipped',
            consume: false,
          ),
        ],
      });
      final runProgress = RummiRunProgress()
        ..gold = 10
        ..itemInventory = const RunInventoryState(
          ownedItems: [
            OwnedItemEntry(
              itemId: 'ledger_clip',
              count: 1,
              placement: ItemPlacement.equipped,
            ),
          ],
          equippedItemIds: ['ledger_clip'],
        );

      final results = ItemEffectRuntime.applyOwnedEnterMarketItems(
        catalog: catalog,
        runProgress: runProgress,
      );

      expect(results.single.isSuccess, isTrue);
      expect(runProgress.gold, 11);
      expect(results.single.events.single.kind, ItemEffectEventKind.goldGained);
    });

    test('owned boss clear gain-gold item applies on boss reward hook', () {
      final catalog = ItemCatalog.fromJson({
        'schemaVersion': 1,
        'catalogId': 'test',
        'items': [
          _itemJson(
            id: 'stage_map',
            timing: 'boss_blind_clear_reward',
            op: 'gain_gold',
            placement: 'passiveRack',
            consume: false,
          ),
        ],
      });
      final runProgress = RummiRunProgress()
        ..gold = 10
        ..itemInventory = const RunInventoryState(
          ownedItems: [
            OwnedItemEntry(
              itemId: 'stage_map',
              count: 1,
              placement: ItemPlacement.passiveRack,
            ),
          ],
          passiveRelicIds: ['stage_map'],
        );

      final results = ItemEffectRuntime.applyOwnedBossClearItems(
        catalog: catalog,
        runProgress: runProgress,
      );

      expect(results.single.isSuccess, isTrue);
      expect(runProgress.gold, 11);
      expect(results.single.events.single.kind, ItemEffectEventKind.goldGained);
    });

    test('settlement item returns settlement modifier event', () {
      final item = _item(
        id: 'coin_funnel',
        timing: 'settlement',
        op: 'board_discard_reward_bonus',
        placement: ItemPlacement.equipped,
        amount: 1,
        consume: false,
      );
      final runProgress = RummiRunProgress();

      final result = ItemEffectRuntime.applySettlementItem(
        item: item,
        runProgress: runProgress,
      );

      expect(result.isSuccess, isTrue);
      expect(
        result.events.single.kind,
        ItemEffectEventKind.settlementModifierQueued,
      );
      expect(result.events.single.detail, 'board_discard_reward_bonus');
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
          'use_battle:undo_last_board_move',
          'use_battle:peek_deck_discard_one',
          'use_battle:draw_if_hand_empty',
          'market_reroll:discount_next_reroll',
          'market_buy:discount_next_purchase',
          'market_buy_if_category:discount_next_purchase',
          'use_market:gain_gold',
          'use_market_if_gold_lte:gain_gold',
          'enter_market:gain_gold',
          'enter_market:discount_first_reroll',
          'enter_market:discount_cheapest_first_offer',
          'market_build_offers:extra_item_offer_slot',
          'market_build_offers:rarity_weight_bonus',
          'boss_blind_clear_reward:gain_gold',
          'settlement:board_discard_reward_bonus',
          'settlement:hand_discard_reward_bonus',
          'next_confirm:chips_bonus',
          'next_confirm:mult_bonus',
          'next_confirm:xmult_bonus',
          'next_confirm:temporary_overlap_cap_bonus',
          'next_confirm_if_rank:chips_bonus',
          'next_confirm_if_rank_at_least:chips_bonus',
          'next_confirm_if_rank_at_least:mult_bonus',
          'next_confirm_per_tile_color:mult_bonus',
          'next_confirm_per_repeated_rank_tile:chips_bonus',
          'first_confirm_each_station:chips_bonus',
          'first_scored_tile_each_station:chips_bonus',
          'on_confirm_if_played_hand_size_lte:mult_bonus',
          'second_confirm_each_station:add_percent_of_first_confirm_score',
          'station_start:add_board_discard',
          'station_start:add_hand_discard',
          'station_start:add_board_move',
          'station_start:increase_hand_size_with_discard_penalty',
          'inventory_capacity:increase_hand_size',
          'inventory_capacity:extra_quick_slot',
          'sell_jester:sell_price_bonus',
          'expiry_guard:rescue_first_expiry_each_station',
        },
      );
    });
  });
}

void _placeTwoPair(RummiPokerGridSession session) {
  session.board.setCell(0, 0, Tile(color: TileColor.red, number: 2));
  session.board.setCell(0, 1, Tile(color: TileColor.blue, number: 2));
  session.board.setCell(0, 2, Tile(color: TileColor.red, number: 3));
  session.board.setCell(0, 3, Tile(color: TileColor.blue, number: 3));
}

ItemDefinition _item({
  required String id,
  required String op,
  String timing = 'use_battle',
  int amount = 1,
  ItemPlacement placement = ItemPlacement.quickSlot,
  bool? consume,
  Map<String, dynamic> rawEffect = const {},
}) {
  return ItemDefinition.fromJson(
    _itemJson(
      id: id,
      timing: timing,
      op: op,
      amount: amount,
      placement: _placementName(placement),
      consume: consume,
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
    'usableInBattle':
        timing == 'use_battle' || timing.startsWith('next_confirm'),
    'placement': placement,
    'slotHint': 'q',
    'effectText': 'Test effect.',
    'effectTextKey': 'data.items.$id.effectText',
    'effect': <String, dynamic>{
      'timing': timing,
      'op': op,
      'amount': amount,
      'consume':
          consume ??
          timing == 'use_battle' || timing.startsWith('next_confirm'),
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
