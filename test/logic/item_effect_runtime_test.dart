import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rummipoker/logic/rummi_poker_grid/hand_rank.dart';
import 'package:rummipoker/logic/rummi_poker_grid/item_definition.dart';
import 'package:rummipoker/logic/rummi_poker_grid/item_effect_runtime.dart';
import 'package:rummipoker/logic/rummi_poker_grid/jester_meta.dart';
import 'package:rummipoker/logic/rummi_poker_grid/line_ref.dart';
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

    test(
      'useBattleItem does not open deck discard choice when deck is empty',
      () {
        final item = _item(
          id: 'deck_needle',
          op: 'peek_deck_discard_one',
          rawEffect: const {'peek': 3},
        );
        final session = RummiPokerGridSession(
          runSeed: 1,
          blind: RummiBlindState(targetScore: 999),
          deck: PokerDeck.fromSnapshot(const []),
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

        final result = ItemEffectRuntime.useBattleItem(
          item: item,
          session: session,
          runProgress: runProgress,
        );

        expect(result.isSuccess, isFalse);
        expect(result.isPending, isFalse);
        expect(result.failMessage, '덱에 확인할 타일이 없습니다.');
        expect(
          runProgress.itemInventory.ownedItems.single.itemId,
          'deck_needle',
        );
      },
    );

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

    test('useBattleItem supports temporary hand capacity increase', () {
      final item = _item(id: 'battle_pouch', op: 'increase_hand_size');
      final session = RummiPokerGridSession(
        runSeed: 1,
        blind: RummiBlindState(targetScore: 999),
      )..maxHandSize = 1;
      final runProgress = RummiRunProgress()
        ..itemInventory = const RunInventoryState(
          ownedItems: [
            OwnedItemEntry(
              itemId: 'battle_pouch',
              count: 1,
              placement: ItemPlacement.quickSlot,
            ),
          ],
          quickSlotItemIds: ['battle_pouch'],
        );

      final result = ItemEffectRuntime.useBattleItem(
        item: item,
        session: session,
        runProgress: runProgress,
      );

      expect(result.isSuccess, isTrue);
      expect(session.maxHandSize, 2);
      expect(runProgress.itemInventory.ownedItems, isEmpty);
      expect(result.events.map((event) => event.kind), [
        ItemEffectEventKind.maxHandSizeIncreased,
        ItemEffectEventKind.itemConsumed,
      ]);
    });

    test('useBattleItem requests scoring line selection for line memory', () {
      final item = _item(
        id: 'line_memory',
        op: 'add_hand_rank_progress_from_selected_line',
      );
      final session = RummiPokerGridSession(
        runSeed: 1,
        blind: RummiBlindState(targetScore: 999),
      );
      _placeFlush(session);
      final runProgress = RummiRunProgress()
        ..itemInventory = const RunInventoryState(
          ownedItems: [
            OwnedItemEntry(
              itemId: 'line_memory',
              count: 1,
              placement: ItemPlacement.quickSlot,
            ),
          ],
          quickSlotItemIds: ['line_memory'],
        );

      final result = ItemEffectRuntime.useBattleItem(
        item: item,
        session: session,
        runProgress: runProgress,
      );

      expect(result.isPending, isTrue);
      expect(result.failMessage, '성장시킬 완성 줄 선택이 필요합니다.');
      expect(result.events.single.detail, 'select_scoring_line');
      expect(runProgress.itemInventory.ownedItems.single.itemId, 'line_memory');
    });

    test('useBattleItemOnLine grows the selected scoring line rank', () {
      final item = _item(
        id: 'line_memory',
        op: 'add_hand_rank_progress_from_selected_line',
      );
      final session = RummiPokerGridSession(
        runSeed: 1,
        blind: RummiBlindState(targetScore: 999),
      );
      _placeFlush(session);
      final runProgress = RummiRunProgress()
        ..itemInventory = const RunInventoryState(
          ownedItems: [
            OwnedItemEntry(
              itemId: 'line_memory',
              count: 1,
              placement: ItemPlacement.quickSlot,
            ),
          ],
          quickSlotItemIds: ['line_memory'],
        );

      final result = ItemEffectRuntime.useBattleItemOnLine(
        item: item,
        session: session,
        runProgress: runProgress,
        lineRef: LineRef.row(0),
      );

      expect(result.isSuccess, isTrue);
      expect(
        runProgress.snapshotHandGrowthStates()[RummiHandRank.flush]?.level,
        2,
      );
      expect(runProgress.itemInventory.ownedItems, isEmpty);
      expect(result.events.map((event) => event.kind), [
        ItemEffectEventKind.handRankProgressAdded,
        ItemEffectEventKind.itemConsumed,
      ]);
      expect(result.events.first.detail, 'flush:row:0');
    });

    test('useBattleItem rejects line memory when no scoring line exists', () {
      final item = _item(
        id: 'line_memory',
        op: 'add_hand_rank_progress_from_selected_line',
      );
      final session = RummiPokerGridSession(
        runSeed: 1,
        blind: RummiBlindState(targetScore: 999),
      );
      final runProgress = RummiRunProgress()
        ..itemInventory = const RunInventoryState(
          ownedItems: [
            OwnedItemEntry(
              itemId: 'line_memory',
              count: 1,
              placement: ItemPlacement.quickSlot,
            ),
          ],
          quickSlotItemIds: ['line_memory'],
        );

      final result = ItemEffectRuntime.useBattleItemOnLine(
        item: item,
        session: session,
        runProgress: runProgress,
        lineRef: LineRef.row(0),
      );

      expect(result.isSuccess, isFalse);
      expect(result.failMessage, '선택한 완성 줄이 없습니다.');
      expect(runProgress.itemInventory.ownedItems.single.itemId, 'line_memory');
    });

    test('useBattleItem caps hand capacity at five and reports no effect', () {
      final item = _item(id: 'battle_pouch', op: 'increase_hand_size');
      final session = RummiPokerGridSession(
        runSeed: 1,
        blind: RummiBlindState(targetScore: 999),
      )..maxHandSize = ItemEffectRuntime.maxSupportedHandSize;
      final runProgress = RummiRunProgress()
        ..itemInventory = const RunInventoryState(
          ownedItems: [
            OwnedItemEntry(
              itemId: 'battle_pouch',
              count: 1,
              placement: ItemPlacement.quickSlot,
            ),
          ],
          quickSlotItemIds: ['battle_pouch'],
        );

      final result = ItemEffectRuntime.useBattleItem(
        item: item,
        session: session,
        runProgress: runProgress,
      );

      expect(result.isSuccess, isFalse);
      expect(result.failMessage, '손패 최대치입니다.');
      expect(session.maxHandSize, ItemEffectRuntime.maxSupportedHandSize);
      expect(
        runProgress.itemInventory.ownedItems.single.itemId,
        'battle_pouch',
      );
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
      'useBattleItem caps board discard at supported maximum without consume',
      () {
        final item = _item(id: 'board_scrap', op: 'add_board_discard');
        final session = RummiPokerGridSession(
          runSeed: 1,
          blind: RummiBlindState(
            targetScore: 999,
            boardDiscardsRemaining: ItemEffectRuntime.maxSupportedBoardDiscards,
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

        expect(result.isSuccess, isFalse);
        expect(result.failMessage, '보드 버림 최대치입니다.');
        expect(
          session.blind.boardDiscardsRemaining,
          ItemEffectRuntime.maxSupportedBoardDiscards,
        );
        expect(
          runProgress.itemInventory.ownedItems.single.itemId,
          'board_scrap',
        );
      },
    );

    test(
      'useBattleItem caps hand discard at supported maximum without consume',
      () {
        final item = _item(id: 'hand_scrap', op: 'add_hand_discard');
        final session = RummiPokerGridSession(
          runSeed: 1,
          blind: RummiBlindState(
            targetScore: 999,
            handDiscardsRemaining: ItemEffectRuntime.maxSupportedHandDiscards,
          ),
        );
        final runProgress = RummiRunProgress()
          ..itemInventory = const RunInventoryState(
            ownedItems: [
              OwnedItemEntry(
                itemId: 'hand_scrap',
                count: 1,
                placement: ItemPlacement.quickSlot,
              ),
            ],
            quickSlotItemIds: ['hand_scrap'],
          );

        final result = ItemEffectRuntime.useBattleItem(
          item: item,
          session: session,
          runProgress: runProgress,
        );

        expect(result.isSuccess, isFalse);
        expect(result.failMessage, '손패 버림 최대치입니다.');
        expect(
          session.blind.handDiscardsRemaining,
          ItemEffectRuntime.maxSupportedHandDiscards,
        );
        expect(
          runProgress.itemInventory.ownedItems.single.itemId,
          'hand_scrap',
        );
      },
    );

    test(
      'useBattleItem caps board move at supported maximum without consume',
      () {
        final item = _item(id: 'move_token', op: 'add_board_move');
        final session = RummiPokerGridSession(
          runSeed: 1,
          blind: RummiBlindState(
            targetScore: 999,
            boardMovesRemaining: ItemEffectRuntime.maxSupportedBoardMoves,
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

        expect(result.isSuccess, isFalse);
        expect(result.failMessage, '보드 이동 최대치입니다.');
        expect(
          session.blind.boardMovesRemaining,
          ItemEffectRuntime.maxSupportedBoardMoves,
        );
        expect(
          runProgress.itemInventory.ownedItems.single.itemId,
          'move_token',
        );
      },
    );

    test(
      'station start board move applies only available amount before cap',
      () {
        final item = _item(
          id: 'board_lift',
          timing: 'station_start',
          op: 'add_board_move',
          amount: 3,
          placement: ItemPlacement.inventory,
        );
        final session = RummiPokerGridSession(
          runSeed: 1,
          blind: RummiBlindState(
            targetScore: 999,
            boardMovesRemaining: ItemEffectRuntime.maxSupportedBoardMoves - 1,
          ),
        );

        final result = ItemEffectRuntime.applyStationStartItem(
          item: item,
          session: session,
        );

        expect(result.isSuccess, isTrue);
        expect(
          session.blind.boardMovesRemaining,
          ItemEffectRuntime.maxSupportedBoardMoves,
        );
        expect(result.events.single.amount, 1);
      },
    );

    test(
      'useBattleItem queues next board move slide bonus and consumes stack',
      () {
        final item = _item(id: 'slide_wax', op: 'mark_next_board_move_bonus');
        final session = RummiPokerGridSession(
          runSeed: 1,
          blind: RummiBlindState(targetScore: 999),
        );
        final runProgress = RummiRunProgress()
          ..itemInventory = const RunInventoryState(
            ownedItems: [
              OwnedItemEntry(
                itemId: 'slide_wax',
                count: 1,
                placement: ItemPlacement.quickSlot,
              ),
            ],
            quickSlotItemIds: ['slide_wax'],
          );

        final result = ItemEffectRuntime.useBattleItem(
          item: item,
          session: session,
          runProgress: runProgress,
        );

        expect(result.isSuccess, isTrue);
        expect(session.nextBoardMoveSlideBonusQueued, isTrue);
        expect(session.slideBonusTriggerCountThisStation, 0);
        expect(runProgress.itemInventory.ownedItems, isEmpty);
        expect(result.events.map((event) => event.kind), [
          ItemEffectEventKind.boardMoveSlideBonusQueued,
          ItemEffectEventKind.itemConsumed,
        ]);
        expect(result.events.first.detail, 'next_board_move_slide_bonus');
      },
    );

    test(
      'useBattleItem does not consume slide wax when no board move remains',
      () {
        final item = _item(id: 'slide_wax', op: 'mark_next_board_move_bonus');
        final session = RummiPokerGridSession(
          runSeed: 1,
          blind: RummiBlindState(
            targetScore: 999,
            boardMovesRemaining: 0,
            boardMovesMax: 3,
          ),
        );
        final runProgress = RummiRunProgress()
          ..itemInventory = const RunInventoryState(
            ownedItems: [
              OwnedItemEntry(
                itemId: 'slide_wax',
                count: 1,
                placement: ItemPlacement.quickSlot,
              ),
            ],
            quickSlotItemIds: ['slide_wax'],
          );

        final result = ItemEffectRuntime.useBattleItem(
          item: item,
          session: session,
          runProgress: runProgress,
        );

        expect(result.isSuccess, isFalse);
        expect(result.failMessage, '사용 가능한 보드 이동이 없습니다.');
        expect(session.nextBoardMoveSlideBonusQueued, isFalse);
        expect(runProgress.itemInventory.ownedItems.single.itemId, 'slide_wax');
      },
    );

    test('successful board move consumes queued slide bonus marker', () {
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
      expect(session.queueNextBoardMoveSlideBonus(), isTrue);

      expect(
        session.tryMoveBoardTile(fromRow: 0, fromCol: 0, toRow: 2, toCol: 2),
        isNull,
      );

      expect(session.nextBoardMoveSlideBonusQueued, isFalse);
      expect(session.slideBonusTriggerCountThisStation, 1);
      expect(session.boardMoveHistory.single.slideBonusTriggered, isTrue);

      expect(session.undoLastBoardMove(), isNull);
      expect(session.nextBoardMoveSlideBonusQueued, isTrue);
      expect(session.slideBonusTriggerCountThisStation, 0);
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

    test(
      'useBattleItem does not consume next-confirm item when one is queued',
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
        session.addConfirmModifier(
          const RummiConfirmModifier(
            itemId: 'mult_capsule',
            timing: 'next_confirm',
            op: 'mult_bonus',
            percent: 0.3,
            consumeOnApply: true,
          ),
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

        final result = ItemEffectRuntime.useBattleItem(
          item: item,
          session: session,
          runProgress: runProgress,
        );

        expect(result.isSuccess, isFalse);
        expect(result.failMessage, '이미 다음 확정 보너스가 준비되어 있습니다.');
        expect(session.confirmModifiers.single.itemId, 'mult_capsule');
        expect(
          runProgress.itemInventory.ownedItems.single.itemId,
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

    test('station start hand capacity item does not apply penalty at cap', () {
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
      )..maxHandSize = ItemEffectRuntime.maxSupportedHandSize;

      final result = ItemEffectRuntime.applyStationStartItem(
        item: item,
        session: session,
      );

      expect(result.isSuccess, isFalse);
      expect(result.failMessage, '손패 최대치입니다.');
      expect(session.maxHandSize, ItemEffectRuntime.maxSupportedHandSize);
      expect(session.blind.boardDiscardsRemaining, 4);
      expect(session.blind.handDiscardsRemaining, 2);
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

    test(
      'market reroll item queues free reroll and consumes inventory stack',
      () {
        final item = _item(
          id: 'reroll_token',
          timing: 'market_reroll',
          op: 'free_next_reroll',
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
        expect(runProgress.effectiveRerollCost(), 0);
        expect(runProgress.itemInventory.ownedItems, isEmpty);
        expect(result.events.map((event) => event.kind), [
          ItemEffectEventKind.marketModifierQueued,
          ItemEffectEventKind.itemConsumed,
        ]);
      },
    );

    test(
      'market reroll discount item uses its amount instead of making reroll free',
      () {
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
      },
    );

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

    test('market use trade ticket advances item offer reroll offset', () {
      final item = _item(
        id: 'trade_ticket',
        timing: 'use_market',
        op: 'reroll_item_offers_only',
        placement: ItemPlacement.inventory,
        consume: true,
      );
      final runProgress = RummiRunProgress()
        ..itemInventory = const RunInventoryState(
          ownedItems: [
            OwnedItemEntry(
              itemId: 'trade_ticket',
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
      expect(
        runProgress.marketModifiers.itemOfferRerollOffset,
        runProgress.marketModifiers.itemOfferSlotCount,
      );
      expect(
        runProgress.marketModifiers.quickSlotOfferRerollOffset,
        runProgress.marketModifiers.itemOfferSlotCount,
      );
      expect(
        runProgress.marketModifiers.passiveOfferRerollOffset,
        runProgress.marketModifiers.itemOfferSlotCount,
      );
      expect(
        runProgress.marketModifiers.toolOfferRerollOffset,
        runProgress.marketModifiers.itemOfferSlotCount,
      );
      expect(
        runProgress.marketModifiers.gearOfferRerollOffset,
        runProgress.marketModifiers.itemOfferSlotCount,
      );
      expect(runProgress.itemInventory.ownedItems, isEmpty);
      expect(result.events.map((event) => event.kind), [
        ItemEffectEventKind.marketModifierQueued,
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

    test('applyMarketUseItem directly adds hand rank growth progress', () {
      final item = _item(
        id: 'straight_study',
        timing: 'use_market',
        op: 'add_hand_rank_progress',
        placement: ItemPlacement.inventory,
        consume: true,
        rawEffect: const {'rank': 'straight'},
      );
      final runProgress = RummiRunProgress()
        ..itemInventory = const RunInventoryState(
          ownedItems: [
            OwnedItemEntry(
              itemId: 'straight_study',
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
      expect(
        runProgress.snapshotPlayedHandCounts()[RummiHandRank.straight],
        isNull,
      );
      expect(
        runProgress.snapshotHandGrowthStates()[RummiHandRank.straight]!.level,
        2,
      );
      expect(runProgress.itemInventory.ownedItems, isEmpty);
      expect(result.events.map((event) => event.kind), [
        ItemEffectEventKind.handRankProgressAdded,
        ItemEffectEventKind.itemConsumed,
      ]);
      expect(result.events.first.detail, 'straight');
    });

    test(
      'market buy item queues category discount and consumes on purchase',
      () {
        final discountItem = _item(
          id: 'item_invoice',
          timing: 'market_buy_if_category',
          op: 'discount_next_purchase',
          placement: ItemPlacement.inventory,
          amount: 9,
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

    test('owned enter market items queue first reroll modifier', () {
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
          ],
          passiveRelicIds: ['merchant_stamp'],
          equippedItemIds: [],
        );

      final results = ItemEffectRuntime.applyOwnedEnterMarketItems(
        catalog: catalog,
        runProgress: runProgress,
      );

      expect(results.every((result) => result.isSuccess), isTrue);
      expect(runProgress.effectiveRerollCost(), 4);
      expect(runProgress.marketModifiers.itemOfferSlotCount, 3);
    });

    test('legacy market build item offer slot fails at supported cap', () {
      final item = _item(
        id: 'legacy_item_offer_slot_test',
        timing: 'market_build_offers',
        op: 'extra_item_offer_slot',
        placement: ItemPlacement.equipped,
      );
      final runProgress = RummiRunProgress()
        ..queueMarketModifier(op: 'extra_item_offer_slot', amount: 1);

      final result = ItemEffectRuntime.applyEnterMarketItem(
        item: item,
        runProgress: runProgress,
      );

      expect(result.isSuccess, isFalse);
      expect(result.failMessage, 'Item 후보 슬롯 최대치입니다.');
      expect(
        runProgress.marketModifiers.itemOfferSlotCount,
        ItemEffectRuntime.maxSupportedMarketOfferSlots,
      );
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

    test('owned boss trophy queues next market jester offer slot', () {
      final catalog = ItemCatalog.fromJson({
        'schemaVersion': 1,
        'catalogId': 'test',
        'items': [
          _itemJson(
            id: 'boss_trophy',
            timing: 'boss_blind_clear_market',
            op: 'extra_jester_offer_next_market',
            placement: 'passiveRack',
          ),
        ],
      });
      final runProgress = RummiRunProgress()
        ..itemInventory = const RunInventoryState(
          ownedItems: [
            OwnedItemEntry(
              itemId: 'boss_trophy',
              count: 1,
              placement: ItemPlacement.passiveRack,
            ),
          ],
          passiveRelicIds: ['boss_trophy'],
        );

      final results = ItemEffectRuntime.applyOwnedBossClearItems(
        catalog: catalog,
        runProgress: runProgress,
      );

      expect(results.single.isSuccess, isTrue);
      expect(
        results.single.events.single.kind,
        ItemEffectEventKind.bossModifierQueued,
      );
      expect(results.single.events.single.amount, 1);
      expect(runProgress.marketModifiers.nextMarketExtraJesterOfferSlots, 1);
    });

    test('boss trophy queues only available jester offer slots before cap', () {
      final item = _item(
        id: 'boss_trophy',
        timing: 'boss_blind_clear_market',
        op: 'extra_jester_offer_next_market',
        placement: ItemPlacement.passiveRack,
        amount: 2,
      );
      final runProgress = RummiRunProgress();

      final result = ItemEffectRuntime.applyBossClearItem(
        item: item,
        runProgress: runProgress,
      );

      expect(result.isSuccess, isTrue);
      expect(result.events.single.amount, 1);
      expect(runProgress.marketModifiers.nextMarketExtraJesterOfferSlots, 1);
    });

    test(
      'boss trophy fails when next jester offer slots are already capped',
      () {
        final item = _item(
          id: 'boss_trophy',
          timing: 'boss_blind_clear_market',
          op: 'extra_jester_offer_next_market',
          placement: ItemPlacement.passiveRack,
        );
        final runProgress = RummiRunProgress()
          ..queueMarketModifier(
            op: 'extra_jester_offer_next_market',
            amount: 1,
          );

        final result = ItemEffectRuntime.applyBossClearItem(
          item: item,
          runProgress: runProgress,
        );

        expect(result.isSuccess, isFalse);
        expect(result.failMessage, 'Jester 후보 슬롯 최대치입니다.');
        expect(runProgress.marketModifiers.nextMarketExtraJesterOfferSlots, 1);
      },
    );

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
          'use_battle:mark_next_board_move_bonus',
          'use_battle:undo_last_board_move',
          'use_battle:peek_deck_discard_one',
          'use_battle:draw_if_hand_empty',
          'use_battle:increase_hand_size',
          'use_battle:add_hand_rank_progress_from_selected_line',
          'market_reroll:discount_next_reroll',
          'market_buy:discount_next_purchase',
          'market_buy_if_category:discount_next_purchase',
          'use_market:gain_gold',
          'use_market:add_hand_rank_progress',
          'use_market:reroll_item_offers_only',
          'use_market_if_gold_lte:gain_gold',
          'enter_market:gain_gold',
          'enter_market:discount_first_reroll',
          'enter_market:discount_cheapest_first_offer',
          'boss_blind_clear_reward:gain_gold',
          'boss_blind_clear_market:extra_jester_offer_next_market',
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

void _placeFlush(RummiPokerGridSession session) {
  const numbers = [1, 3, 6, 8, 10];
  for (var col = 0; col < 5; col += 1) {
    session.board.setCell(
      0,
      col,
      Tile(color: TileColor.red, number: numbers[col]),
    );
  }
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
