import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:rummipoker/logic/rummi_poker_grid/item_definition.dart';
import 'package:rummipoker/logic/rummi_poker_grid/jester_meta.dart';
import 'package:rummipoker/logic/rummi_poker_grid/rummi_market_facade.dart';
import 'package:rummipoker/logic/rummi_poker_grid/rummi_blind_state.dart';
import 'package:rummipoker/logic/rummi_poker_grid/models/poker_deck.dart';
import 'package:rummipoker/logic/rummi_poker_grid/models/tile.dart';
import 'package:rummipoker/logic/rummi_poker_grid/rummi_poker_grid_session.dart';
import 'package:rummipoker/logic/rummi_poker_grid/rummi_ruleset.dart';
import 'package:rummipoker/providers/features/rummi_poker_grid/game_session_notifier.dart';
import 'package:rummipoker/providers/features/rummi_poker_grid/game_session_state.dart';
import 'package:rummipoker/services/active_run_save_facade.dart';
import 'package:rummipoker/services/active_run_save_service.dart';
import 'package:rummipoker/services/blind_selection_setup.dart';
import 'package:rummipoker/services/new_run_setup.dart';

void main() {
  group('GameSessionNotifier', () {
    test('새 런 초기화 시 세션과 진행도가 준비된다', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      const args = GameSessionArgs(runSeed: 12345);

      container.read(gameSessionNotifierProvider(args).notifier);

      final state = container.read(gameSessionNotifierProvider(args));
      expect(state.isReady, isTrue);
      expect(state.session?.runSeed, 12345);
      expect(state.runProgress, isNotNull);
      expect(state.stationView, isNotNull);
      expect(state.marketView, isNotNull);
      expect(state.battleView, isNotNull);
      expect(state.activeRunSaveView, isNotNull);
      expect(state.runLoopPhase, GameRunLoopPhase.battle);
    });

    test('파생 facade state가 orchestration 변경과 함께 갱신된다', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      const args = GameSessionArgs(runSeed: 77);

      final notifier = container.read(
        gameSessionNotifierProvider(args).notifier,
      );
      final initial = container.read(gameSessionNotifierProvider(args));

      expect(initial.stationView, isNotNull);
      expect(initial.marketView, isNotNull);
      expect(initial.battleView, isNotNull);
      expect(initial.activeRunSaveView, isNotNull);
      expect(initial.stationView!.objective.targetScore, 270);
      expect(initial.marketView!.gold, RummiEconomyConfig.startingGold);
      expect(initial.battleView!.stageIndex, 1);
      expect(initial.battleView!.currentGold, RummiEconomyConfig.startingGold);
      expect(initial.activeRunSaveView!.sceneAlias, RummiSaveSceneAlias.battle);
      expect(initial.runLoopPhase, GameRunLoopPhase.battle);

      initial.runProgress!.gold += 9;
      notifier.setActiveRunScene(ActiveRunScene.shop);

      final updated = container.read(gameSessionNotifierProvider(args));
      expect(updated.marketView!.gold, RummiEconomyConfig.startingGold + 9);
      expect(
        updated.battleView!.currentGold,
        RummiEconomyConfig.startingGold + 9,
      );
      expect(updated.runLoopPhase, GameRunLoopPhase.market);
      expect(updated.activeRunSaveView!.currentGold, 19);
      expect(updated.activeRunSaveView!.sceneAlias, RummiSaveSceneAlias.market);
    });

    test('battle facade state가 draw와 배치 후에도 함께 갱신된다', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      const args = GameSessionArgs(runSeed: 57);

      final notifier = container.read(
        gameSessionNotifierProvider(args).notifier,
      );
      final before = container.read(gameSessionNotifierProvider(args));

      expect(before.battleView!.hand, isEmpty);
      expect(before.battleView!.board.cellAt(0, 0), isNull);

      expect(notifier.drawTile(), isNull);
      final drawn = container
          .read(gameSessionNotifierProvider(args))
          .battleView!;
      final tile = drawn.hand.single;

      expect(notifier.tryPlaceTile(tile, 0, 0), isTrue);
      final updated = container.read(gameSessionNotifierProvider(args));

      expect(updated.battleView!.hand, isEmpty);
      expect(updated.battleView!.board.cellAt(0, 0), isNotNull);
      expect(updated.battleView!.scoringCellKeys, isEmpty);
    });

    test('tapBoardCell은 내부 선택 상태만으로 배치와 선택 토글을 처리한다', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      const args = GameSessionArgs(runSeed: 59);

      final notifier = container.read(
        gameSessionNotifierProvider(args).notifier,
      );

      expect(notifier.drawTile(), isNull);
      final drawn = container
          .read(gameSessionNotifierProvider(args))
          .battleView!
          .hand
          .single;

      notifier.toggleSelectedHandTile(drawn);
      final placed = notifier.tapBoardCell(0, 0);
      final afterPlace = container.read(gameSessionNotifierProvider(args));

      expect(placed.failMessage, isNull);
      expect(placed.didPlaceTile, isTrue);
      expect(afterPlace.battleView!.board.cellAt(0, 0), isNotNull);
      expect(afterPlace.selectedHandTile, isNull);

      final selected = notifier.tapBoardCell(0, 0);
      expect(selected.didChangeSelection, isTrue);
      expect(
        container.read(gameSessionNotifierProvider(args)).selectedBoardRow,
        0,
      );

      final unselected = notifier.tapBoardCell(0, 0);
      expect(unselected.didChangeSelection, isTrue);
      final finalState = container.read(gameSessionNotifierProvider(args));
      expect(finalState.selectedBoardRow, isNull);
      expect(finalState.selectedBoardCol, isNull);
    });

    test('discard selected commands는 내부 선택 상태만으로 버림을 처리한다', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      const args = GameSessionArgs(runSeed: 61);

      final notifier = container.read(
        gameSessionNotifierProvider(args).notifier,
      );

      expect(notifier.drawTile(), isNull);
      final initial = container.read(gameSessionNotifierProvider(args));
      final tile = initial.battleView!.hand.single;

      notifier.toggleSelectedHandTile(tile);
      expect(notifier.discardSelectedHandTileFromState(), isNull);
      final afterHandDiscard = container.read(
        gameSessionNotifierProvider(args),
      );
      expect(afterHandDiscard.battleView!.hand, hasLength(1));
      expect(afterHandDiscard.selectedHandTile, isNull);

      final replacement = afterHandDiscard.battleView!.hand.single;
      notifier.toggleSelectedHandTile(replacement);
      expect(notifier.tapBoardCell(0, 0).didPlaceTile, isTrue);
      expect(notifier.tapBoardCell(0, 0).didChangeSelection, isTrue);
      expect(notifier.discardSelectedBoardTileFromState(), isNull);

      final afterBoardDiscard = container.read(
        gameSessionNotifierProvider(args),
      );
      expect(afterBoardDiscard.battleView!.board.cellAt(0, 0), isNull);
      expect(afterBoardDiscard.selectedBoardRow, isNull);
      expect(afterBoardDiscard.selectedBoardCol, isNull);
    });

    test('move selected board tile command는 이동 후 선택과 facade를 갱신한다', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      const args = GameSessionArgs(runSeed: 62);

      final notifier = container.read(
        gameSessionNotifierProvider(args).notifier,
      );

      expect(notifier.drawTile(), isNull);
      final tile = container
          .read(gameSessionNotifierProvider(args))
          .battleView!
          .hand
          .single;
      notifier.toggleSelectedHandTile(tile);
      expect(notifier.tapBoardCell(0, 0).didPlaceTile, isTrue);
      expect(notifier.tapBoardCell(0, 0).didChangeSelection, isTrue);

      expect(
        notifier.moveSelectedBoardTileToFromState(toRow: 2, toCol: 2),
        isNull,
      );

      final moved = container.read(gameSessionNotifierProvider(args));
      expect(moved.battleView!.board.cellAt(0, 0), isNull);
      expect(moved.battleView!.board.cellAt(2, 2), tile);
      expect(moved.stationView!.resources.boardMovesRemaining, 2);
      expect(moved.stationView!.resources.boardMovesMax, 3);
      expect(moved.session!.blind.boardDiscardsRemaining, 4);
      expect(moved.session!.blind.handDiscardsRemaining, 2);
      expect(moved.selectedBoardRow, isNull);
      expect(moved.selectedBoardCol, isNull);
    });

    test('move selected board tile command는 실패 시 보드와 선택을 유지한다', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      const args = GameSessionArgs(runSeed: 63);

      final notifier = container.read(
        gameSessionNotifierProvider(args).notifier,
      );

      expect(notifier.drawTile(), isNull);
      final first = container
          .read(gameSessionNotifierProvider(args))
          .battleView!
          .hand
          .single;
      notifier.toggleSelectedHandTile(first);
      expect(notifier.tapBoardCell(0, 0).didPlaceTile, isTrue);

      expect(notifier.drawTile(), isNull);
      final second = container
          .read(gameSessionNotifierProvider(args))
          .battleView!
          .hand
          .single;
      notifier.toggleSelectedHandTile(second);
      expect(notifier.tapBoardCell(1, 1).didPlaceTile, isTrue);

      expect(notifier.tapBoardCell(0, 0).didChangeSelection, isTrue);
      expect(
        notifier.moveSelectedBoardTileToFromState(toRow: 1, toCol: 1),
        '이동할 칸이 비어 있지 않습니다.',
      );

      final afterOccupiedFail = container.read(
        gameSessionNotifierProvider(args),
      );
      expect(afterOccupiedFail.battleView!.board.cellAt(0, 0), first);
      expect(afterOccupiedFail.battleView!.board.cellAt(1, 1), second);
      expect(afterOccupiedFail.session!.blind.boardMovesRemaining, 3);
      expect(afterOccupiedFail.selectedBoardRow, 0);
      expect(afterOccupiedFail.selectedBoardCol, 0);

      afterOccupiedFail.session!.blind.boardMovesRemaining = 0;
      expect(
        notifier.moveSelectedBoardTileToFromState(toRow: 2, toCol: 2),
        '보드 이동 횟수가 없습니다.',
      );
      final afterNoMovesFail = container.read(
        gameSessionNotifierProvider(args),
      );
      expect(afterNoMovesFail.battleView!.board.cellAt(0, 0), first);
      expect(afterNoMovesFail.battleView!.board.cellAt(2, 2), isNull);
      expect(afterNoMovesFail.selectedBoardRow, 0);
      expect(afterNoMovesFail.selectedBoardCol, 0);
    });

    test('손패 선택과 선택 해제를 상태에서 관리한다', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      const args = GameSessionArgs(runSeed: 7);

      final notifier = container.read(
        gameSessionNotifierProvider(args).notifier,
      );

      const tile = Tile(id: 1, color: TileColor.red, number: 1);
      notifier.setSelectedHandTile(tile);
      expect(
        container.read(gameSessionNotifierProvider(args)).selectedHandTile,
        tile,
      );

      notifier.clearSelections();
      final state = container.read(gameSessionNotifierProvider(args));
      expect(state.selectedHandTile, isNull);
      expect(state.selectedBoardRow, isNull);
      expect(state.selectedBoardCol, isNull);
    });

    test('디버그 손패 수를 바꾸면 세션 값이 갱신된다', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      const args = GameSessionArgs(runSeed: 9);

      final notifier = container.read(
        gameSessionNotifierProvider(args).notifier,
      );
      notifier.setDebugMaxHandSize(3);

      final state = container.read(gameSessionNotifierProvider(args));
      expect(state.session?.maxHandSize, 3);
    });

    test('ruleset currentDefaults가 provider 초기 세션 값과 parity를 유지한다', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      const args = GameSessionArgs(runSeed: 19);

      final state = container.read(gameSessionNotifierProvider(args));
      final ruleset = state.ruleset;

      expect(ruleset, RummiRuleset.currentDefaults);
      expect(state.session?.deckCopiesPerTile, ruleset.copiesPerTile);
      expect(state.session?.maxHandSize, ruleset.defaultMaxHandSize);
      expect(
        state.session?.blind.boardDiscardsRemaining,
        ruleset.defaultBoardDiscards,
      );
      expect(
        state.session?.blind.handDiscardsRemaining,
        ruleset.defaultHandDiscards,
      );
    });

    test('완화 난이도는 시작 보정과 blind 조건을 함께 반영한다', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      const args = GameSessionArgs(
        runSeed: 23,
        difficulty: NewRunDifficulty.relaxed,
      );

      final state = container.read(gameSessionNotifierProvider(args));

      expect(state.runProgress?.gold, RummiEconomyConfig.startingGold + 3);
      expect(
        state.runProgress?.rerollCost,
        RummiRunProgress.shopBaseRerollCost - 1,
      );
      expect(state.session?.blind.targetScore, 216);
      expect(
        state.session?.blind.boardDiscardsRemaining,
        RummiRuleset.currentDefaults.defaultBoardDiscards + 1,
      );
      expect(
        state.session?.blind.handDiscardsRemaining,
        RummiRuleset.currentDefaults.defaultHandDiscards + 1,
      );
    });

    test('빅 블라인드 시작은 목표 점수와 자원 조건을 더 강하게 반영한다', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      const args = GameSessionArgs(
        runSeed: 24,
        difficulty: NewRunDifficulty.standard,
        blindTier: BlindTier.big,
      );

      final state = container.read(gameSessionNotifierProvider(args));
      expect(state.session?.blind.targetScore, 405);
      expect(
        state.session?.blind.boardDiscardsRemaining,
        RummiRuleset.currentDefaults.defaultBoardDiscards - 1,
      );
      expect(
        state.session?.blind.handDiscardsRemaining,
        RummiRuleset.currentDefaults.defaultHandDiscards,
      );
      expect(
        state.session?.maxHandSize,
        RummiRuleset.currentDefaults.defaultMaxHandSize,
      );
    });

    test('ruleset debug hand-size bounds clamp provider mutations', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      const args = GameSessionArgs(runSeed: 21);

      final notifier = container.read(
        gameSessionNotifierProvider(args).notifier,
      );

      notifier.setDebugMaxHandSize(99);
      expect(
        container.read(gameSessionNotifierProvider(args)).session?.maxHandSize,
        RummiRuleset.currentDefaults.maxDebugMaxHandSize,
      );

      notifier.setDebugMaxHandSize(0);
      expect(
        container.read(gameSessionNotifierProvider(args)).session?.maxHandSize,
        RummiRuleset.currentDefaults.minDebugMaxHandSize,
      );
    });

    test('게임 화면 Jester 판매 후 상세 오버레이 선택은 닫힌다', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      const args = GameSessionArgs(runSeed: 31);

      final notifier = container.read(
        gameSessionNotifierProvider(args).notifier,
      );
      final state = container.read(gameSessionNotifierProvider(args));
      final runProgress = state.runProgress!;

      runProgress.ownedJesters.add(
        RummiJesterCard(
          id: 'green_jester',
          displayName: 'Green Jester',
          rarity: RummiJesterRarity.common,
          baseCost: 3,
          effectText: '',
          effectType: 'mult_bonus',
          trigger: 'passive',
          conditionType: 'none',
          conditionValue: null,
          value: 4,
          xValue: null,
          mappedTileColors: const [],
          mappedTileNumbers: const [],
        ),
      );
      notifier.markDirty();
      notifier.setSelectedJesterOverlayIndex(0);

      final sold = notifier.sellOwnedJester(0);
      final updated = container.read(gameSessionNotifierProvider(args));

      expect(sold, isTrue);
      expect(updated.selectedJesterOverlayIndex, isNull);
      expect(updated.runProgress!.ownedJesters, isEmpty);
    });

    test('sellSelectedJesterOverlayFromState는 선택된 오버레이 슬롯을 판매한다', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      const args = GameSessionArgs(runSeed: 33);

      final notifier = container.read(
        gameSessionNotifierProvider(args).notifier,
      );
      final state = container.read(gameSessionNotifierProvider(args));
      state.runProgress!.ownedJesters.add(
        const RummiJesterCard(
          id: 'egg',
          displayName: 'Egg',
          rarity: RummiJesterRarity.common,
          baseCost: 5,
          effectText: '',
          effectType: 'chips_bonus',
          trigger: 'onScore',
          conditionType: 'none',
          conditionValue: null,
          value: 5,
          xValue: null,
          mappedTileColors: [],
          mappedTileNumbers: [],
        ),
      );
      notifier.markDirty();
      notifier.setSelectedJesterOverlayIndex(0);

      expect(notifier.sellSelectedJesterOverlayFromState(), isTrue);
      final updated = container.read(gameSessionNotifierProvider(args));
      expect(updated.runProgress!.ownedJesters, isEmpty);
      expect(updated.selectedJesterOverlayIndex, isNull);
    });

    test('buyShopOffer는 골드와 market facade를 함께 갱신한다', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      const args = GameSessionArgs(runSeed: 37);

      final notifier = container.read(
        gameSessionNotifierProvider(args).notifier,
      );
      final state = container.read(gameSessionNotifierProvider(args));
      state.runProgress!.shopOffers.add(
        RummiShopOffer(
          slotIndex: 0,
          card: const RummiJesterCard(
            id: 'green_jester',
            displayName: 'Green Jester',
            rarity: RummiJesterRarity.common,
            baseCost: 3,
            effectText: '',
            effectType: 'mult_bonus',
            trigger: 'passive',
            conditionType: 'none',
            conditionValue: null,
            value: 4,
            xValue: null,
            mappedTileColors: [],
            mappedTileNumbers: [],
          ),
          price: 3,
        ),
      );
      notifier.markDirty();

      final failMessage = notifier.buyShopOffer(0);
      final updated = container.read(gameSessionNotifierProvider(args));

      expect(failMessage, isNull);
      expect(updated.runProgress!.gold, RummiEconomyConfig.startingGold - 3);
      expect(updated.marketView!.gold, RummiEconomyConfig.startingGold - 3);
      expect(updated.runProgress!.ownedJesters.length, 1);
      expect(updated.marketView!.ownedEntries.length, 1);
      expect(updated.runProgress!.shopOffers, isEmpty);
    });

    test('buyItemOffer는 골드와 owned item inventory를 갱신한다', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      const args = GameSessionArgs(runSeed: 38);

      final notifier = container.read(
        gameSessionNotifierProvider(args).notifier,
      );
      final item = ItemDefinition.fromJson(const <String, dynamic>{
        'id': 'board_scrap',
        'displayName': 'Board Scrap',
        'displayNameKey': 'data.items.board_scrap.displayName',
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
        'effectText': 'Gain +1 board discard for this Station.',
        'effectTextKey': 'data.items.board_scrap.effectText',
        'effect': <String, dynamic>{
          'timing': 'use_battle',
          'op': 'add_board_discard',
          'amount': 1,
          'consume': true,
        },
        'tags': <String>['battle', 'discard', 'safety'],
        'sourceNotes': 'Test fixture.',
      });
      final offer = RummiMarketItemOfferView.fromItemDefinition(
        item,
        slotIndex: 0,
        currentGold: RummiEconomyConfig.startingGold,
      );

      final failMessage = notifier.buyItemOffer(offer);
      final updated = container.read(gameSessionNotifierProvider(args));

      expect(failMessage, isNull);
      expect(updated.runProgress!.gold, RummiEconomyConfig.startingGold - 4);
      expect(updated.marketView!.gold, RummiEconomyConfig.startingGold - 4);
      expect(updated.runProgress!.itemInventory.ownedItems.length, 1);
      expect(
        updated.runProgress!.itemInventory.ownedItems.first.itemId,
        item.id,
      );
      expect(updated.runProgress!.itemInventory.quickSlotItemIds, [item.id]);
    });

    test('buyItemOffer는 market item discount를 적용하고 소비한다', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      const args = GameSessionArgs(runSeed: 3801);

      final notifier = container.read(
        gameSessionNotifierProvider(args).notifier,
      );
      final state = container.read(gameSessionNotifierProvider(args));
      final item = ItemDefinition.fromJson(const <String, dynamic>{
        'id': 'board_scrap',
        'displayName': 'Board Scrap',
        'displayNameKey': 'data.items.board_scrap.displayName',
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
        'effectText': 'Gain +1 board discard for this Station.',
        'effectTextKey': 'data.items.board_scrap.effectText',
        'effect': <String, dynamic>{
          'timing': 'use_battle',
          'op': 'add_board_discard',
          'amount': 1,
          'consume': true,
        },
        'tags': <String>['battle'],
        'sourceNotes': 'Test fixture.',
      });
      state.runProgress!.queueMarketModifier(
        op: 'discount_next_purchase',
        amount: 2,
        category: 'item',
      );
      notifier.markDirty();
      final offer = RummiMarketItemOfferView.fromItemDefinition(
        item,
        slotIndex: 0,
        currentGold: RummiEconomyConfig.startingGold,
        price: state.runProgress!.effectiveItemPrice(item),
      );

      final failMessage = notifier.buyItemOffer(offer);
      final updated = container.read(gameSessionNotifierProvider(args));

      expect(failMessage, isNull);
      expect(updated.runProgress!.gold, RummiEconomyConfig.startingGold - 2);
      expect(updated.runProgress!.marketModifiers.nextItemPurchaseDiscount, 0);
      expect(updated.marketView!.gold, RummiEconomyConfig.startingGold - 2);
    });

    test('useBattleItem은 discard 자원을 올리고 consumable stack을 소모한다', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      const args = GameSessionArgs(runSeed: 40);

      final notifier = container.read(
        gameSessionNotifierProvider(args).notifier,
      );
      final state = container.read(gameSessionNotifierProvider(args));
      final item = ItemDefinition.fromJson(const <String, dynamic>{
        'id': 'board_scrap',
        'displayName': 'Board Scrap',
        'displayNameKey': 'data.items.board_scrap.displayName',
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
        'effectText': 'Gain +1 board discard for this Station.',
        'effectTextKey': 'data.items.board_scrap.effectText',
        'effect': <String, dynamic>{
          'timing': 'use_battle',
          'op': 'add_board_discard',
          'amount': 1,
          'consume': true,
        },
        'tags': <String>['battle', 'discard', 'safety'],
        'sourceNotes': 'Test fixture.',
      });
      state.runProgress!.itemInventory = const RunInventoryState(
        ownedItems: [
          OwnedItemEntry(
            itemId: 'board_scrap',
            count: 1,
            placement: ItemPlacement.quickSlot,
          ),
        ],
        quickSlotItemIds: ['board_scrap'],
      );
      final beforeDiscards = state.session!.blind.boardDiscardsRemaining;

      final failMessage = notifier.useBattleItem(item);
      final updated = container.read(gameSessionNotifierProvider(args));

      expect(failMessage, isNull);
      expect(
        updated.stationView!.resources.boardDiscardsRemaining,
        beforeDiscards + 1,
      );
      expect(updated.runProgress!.itemInventory.ownedItems, isEmpty);
      expect(updated.runProgress!.itemInventory.quickSlotItemIds, isEmpty);
    });

    test('useBattleItem은 board move 자원을 올리고 facade를 갱신한다', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      const args = GameSessionArgs(runSeed: 42);

      final notifier = container.read(
        gameSessionNotifierProvider(args).notifier,
      );
      final state = container.read(gameSessionNotifierProvider(args));
      final item = ItemDefinition.fromJson(const <String, dynamic>{
        'id': 'move_token',
        'displayName': 'Move Token',
        'displayNameKey': 'data.items.move_token.displayName',
        'type': 'consumable',
        'rarity': 'common',
        'basePrice': 5,
        'sellPrice': 2,
        'stackable': true,
        'maxStack': 2,
        'sellable': true,
        'usableInBattle': true,
        'placement': 'quickSlot',
        'slotHint': 'q',
        'effectText': 'Gain +1 board move for this Station.',
        'effectTextKey': 'data.items.move_token.effectText',
        'effect': <String, dynamic>{
          'timing': 'use_battle',
          'op': 'add_board_move',
          'amount': 1,
          'consume': true,
        },
        'tags': <String>['battle', 'move', 'safety'],
        'sourceNotes': 'Test fixture.',
      });
      state.session!.blind.boardMovesRemaining = 1;
      state.runProgress!.itemInventory = const RunInventoryState(
        ownedItems: [
          OwnedItemEntry(
            itemId: 'move_token',
            count: 1,
            placement: ItemPlacement.quickSlot,
          ),
        ],
        quickSlotItemIds: ['move_token'],
      );

      final failMessage = notifier.useBattleItem(item);
      final updated = container.read(gameSessionNotifierProvider(args));

      expect(failMessage, isNull);
      expect(updated.stationView!.resources.boardMovesRemaining, 2);
      expect(updated.stationView!.resources.boardMovesMax, 3);
      expect(updated.runProgress!.itemInventory.ownedItems, isEmpty);
      expect(updated.runProgress!.itemInventory.quickSlotItemIds, isEmpty);
    });

    test('rerollShop는 골드 부족 시 에러 문구를 반환한다', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      const args = GameSessionArgs(runSeed: 39);

      final notifier = container.read(
        gameSessionNotifierProvider(args).notifier,
      );
      final state = container.read(gameSessionNotifierProvider(args));
      state.runProgress!
        ..gold = 0
        ..rerollCost = 1;

      final message = notifier.rerollShop(
        catalog: const <RummiJesterCard>[],
        rng: state.session!.runRandom,
      );

      expect(message, '리롤 골드가 부족합니다.');
    });

    test('rerollShopFromState는 notifier 내부 session/catalog를 사용해 상점을 갱신한다', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      const args = GameSessionArgs(runSeed: 41);

      final notifier = container.read(
        gameSessionNotifierProvider(args).notifier,
      );
      final state = container.read(gameSessionNotifierProvider(args));

      notifier.setJesterCatalog(
        RummiJesterCatalog.fromJsonString('''
[
  {
    "id": "green_jester",
    "displayName": "Green Jester",
    "rarity": "common",
    "baseCost": 3,
    "effectText": "",
    "effectType": "stateful_growth",
    "trigger": "passive",
    "conditionType": "none",
    "conditionValue": null,
    "value": 1,
    "xValue": null,
    "mappedTileColors": [],
    "mappedTileNumbers": []
  }
]
'''),
      );
      state.runProgress!
        ..gold = 10
        ..rerollCost = 5;
      state.runProgress!.shopOffers.add(
        RummiShopOffer(
          slotIndex: 0,
          card: const RummiJesterCard(
            id: 'popcorn',
            displayName: 'Popcorn',
            rarity: RummiJesterRarity.common,
            baseCost: 3,
            effectText: '',
            effectType: 'stateful_growth',
            trigger: 'passive',
            conditionType: 'none',
            conditionValue: null,
            value: 1,
            xValue: null,
            mappedTileColors: [],
            mappedTileNumbers: [],
          ),
          price: 3,
        ),
      );
      notifier.markDirty();

      final message = notifier.rerollShopFromState();
      final updated = container.read(gameSessionNotifierProvider(args));

      expect(message, isNull);
      expect(updated.runProgress!.gold, 5);
      expect(updated.marketView!.gold, 5);
      expect(updated.runProgress!.shopOffers, hasLength(1));
      expect(updated.runProgress!.shopOffers.first.card.id, 'green_jester');
    });

    test(
      'settlement/market/next station command가 gold, scene, checkpoint를 함께 갱신한다',
      () {
        final container = ProviderContainer();
        addTearDown(container.dispose);
        const args = GameSessionArgs(runSeed: 43);

        final notifier = container.read(
          gameSessionNotifierProvider(args).notifier,
        );
        notifier.setJesterCatalog(
          RummiJesterCatalog.fromJsonString('''
[
  {
    "id": "green_jester",
    "displayName": "Green Jester",
    "rarity": "common",
    "baseCost": 3,
    "effectText": "",
    "effectType": "mult_bonus",
    "trigger": "passive",
    "conditionType": "none",
    "conditionValue": null,
    "value": 4,
    "xValue": null,
    "mappedTileColors": [],
    "mappedTileNumbers": []
  }
]
'''),
        );

        final before = container.read(gameSessionNotifierProvider(args));
        final initialStage = before.runProgress!.stageIndex;
        final initialGold = before.runProgress!.gold;

        before.session!.blind.boardDiscardsRemaining = 2;
        before.session!.blind.handDiscardsRemaining = 1;

        final breakdown = notifier.prepareSettlementAndCashOut();
        final afterCashOut = container.read(gameSessionNotifierProvider(args));

        expect(breakdown.totalGold, greaterThan(0));
        expect(
          afterCashOut.runProgress!.gold,
          initialGold + breakdown.totalGold,
        );
        expect(
          afterCashOut.activeRunSaveView!.sceneAlias,
          RummiSaveSceneAlias.battle,
        );
        expect(afterCashOut.runLoopPhase, GameRunLoopPhase.settlement);

        notifier.enterMarketAfterCashOut();
        final inMarket = container.read(gameSessionNotifierProvider(args));

        expect(inMarket.activeRunScene, ActiveRunScene.shop);
        expect(inMarket.runLoopPhase, GameRunLoopPhase.market);
        expect(
          inMarket.activeRunSaveView!.sceneAlias,
          RummiSaveSceneAlias.market,
        );
        expect(inMarket.marketView!.offers, isNotEmpty);

        notifier.beginNextStationTransition();
        final transitioning = container.read(gameSessionNotifierProvider(args));
        expect(
          transitioning.runLoopPhase,
          GameRunLoopPhase.nextStationTransition,
        );

        notifier.advanceToNextStation(args.runSeed);
        final advanced = container.read(gameSessionNotifierProvider(args));

        expect(advanced.activeRunScene, ActiveRunScene.battle);
        expect(advanced.runLoopPhase, GameRunLoopPhase.battle);
        expect(
          advanced.activeRunSaveView!.sceneAlias,
          RummiSaveSceneAlias.battle,
        );
        expect(advanced.runProgress!.stageIndex, initialStage + 1);
        expect(
          advanced.stageStartSnapshot!.runProgress.stageIndex,
          advanced.runProgress!.stageIndex,
        );
        expect(
          advanced.stageStartSnapshot!.runProgress.gold,
          advanced.runProgress!.gold,
        );
        expect(
          advanced.stageStartSnapshot!.session.blind.targetScore,
          advanced.session!.blind.targetScore,
        );
      },
    );

    test('buildSaveRuntimeState는 현재 runtime과 active scene을 그대로 반영한다', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      const args = GameSessionArgs(runSeed: 45);

      final notifier = container.read(
        gameSessionNotifierProvider(args).notifier,
      );
      final state = container.read(gameSessionNotifierProvider(args));

      state.runProgress!.gold += 7;
      notifier.setActiveRunScene(ActiveRunScene.shop);

      final runtime = notifier.buildSaveRuntimeState(
        difficulty: NewRunDifficulty.standard,
      );

      expect(runtime.activeScene, ActiveRunScene.shop);
      expect(runtime.session, same(state.session));
      expect(runtime.runProgress, same(state.runProgress));
      expect(runtime.stageStartSnapshot, same(state.stageStartSnapshot));
    });

    test(
      'buildSaveRuntimeState retry mode는 stageStartSnapshot 복사본을 current로 만든다',
      () {
        final container = ProviderContainer();
        addTearDown(container.dispose);
        const args = GameSessionArgs(runSeed: 47);

        final notifier = container.read(
          gameSessionNotifierProvider(args).notifier,
        );
        final state = container.read(gameSessionNotifierProvider(args));

        expect(notifier.drawTile(), isNull);
        final tile = container
            .read(gameSessionNotifierProvider(args))
            .battleView!
            .hand
            .single;
        expect(notifier.tryPlaceTile(tile, 0, 0), isTrue);
        state.runProgress!.gold += 13;
        notifier.markDirty();

        final runtime = notifier.buildSaveRuntimeState(
          difficulty: NewRunDifficulty.standard,
          useStageStartSnapshotAsCurrent: true,
        );

        expect(runtime.activeScene, ActiveRunScene.battle);
        expect(runtime.session.board.cellAt(0, 0), isNull);
        expect(runtime.runProgress.gold, RummiEconomyConfig.startingGold);
        expect(runtime.stageStartSnapshot.session.board.cellAt(0, 0), isNull);
        expect(
          runtime.stageStartSnapshot.runProgress.gold,
          RummiEconomyConfig.startingGold,
        );
        expect(runtime.session, isNot(same(state.session)));
        expect(runtime.runProgress, isNot(same(state.runProgress)));
      },
    );

    test('debugForceBlindClear는 현재 블라인드를 즉시 목표 점수까지 올린다', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      const args = GameSessionArgs(runSeed: 141);

      final notifier = container.read(
        gameSessionNotifierProvider(args).notifier,
      );
      final before = container.read(gameSessionNotifierProvider(args));
      final session = before.session!;
      final runProgress = before.runProgress!;
      session.blind.scoreTowardBlind = session.blind.targetScore - 37;

      final added = notifier.debugForceBlindClear();
      final after = container.read(gameSessionNotifierProvider(args));

      expect(added, 37);
      expect(
        after.session!.blind.scoreTowardBlind,
        after.session!.blind.targetScore,
      );
      expect(
        after.runProgress!.currentStationBlindTierIndex,
        runProgress.currentStationBlindTierIndex,
      );
    });

    test('debugForceBlindClear는 override tier를 함께 반영한다', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      const args = GameSessionArgs(runSeed: 142);

      final notifier = container.read(
        gameSessionNotifierProvider(args).notifier,
      );

      final added = notifier.debugForceBlindClear(overrideTier: BlindTier.boss);
      final after = container.read(gameSessionNotifierProvider(args));

      expect(added, greaterThanOrEqualTo(0));
      expect(
        after.runProgress!.currentStationBlindTierIndex,
        BlindTier.boss.index,
      );
      expect(
        after.session!.blind.scoreTowardBlind,
        after.session!.blind.targetScore,
      );
    });

    test('restartCurrentStage는 변경된 전투 상태와 골드를 stage-start 기준으로 되돌린다', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      const args = GameSessionArgs(runSeed: 99);

      final notifier = container.read(
        gameSessionNotifierProvider(args).notifier,
      );
      final initialState = container.read(gameSessionNotifierProvider(args));
      final session = initialState.session!;
      final runProgress = initialState.runProgress!;

      expect(runProgress.gold, RummiEconomyConfig.startingGold);
      expect(session.board.cellAt(0, 0), isNull);

      final drawn = session.drawToHand();
      expect(drawn, isNotNull);
      expect(notifier.tryPlaceTile(drawn!, 0, 0), isTrue);
      runProgress.gold += 17;
      notifier.markDirty();

      var mutated = container.read(gameSessionNotifierProvider(args));
      expect(mutated.session!.board.cellAt(0, 0), isNotNull);
      expect(mutated.runProgress!.gold, RummiEconomyConfig.startingGold + 17);

      notifier.restartCurrentStage();

      final restarted = container.read(gameSessionNotifierProvider(args));
      expect(restarted.session!.board.cellAt(0, 0), isNull);
      expect(restarted.session!.hand, isEmpty);
      expect(restarted.runProgress!.gold, RummiEconomyConfig.startingGold);
      expect(restarted.stageStartSnapshot, isNotNull);
      expect(restarted.stageStartSnapshot!.session.board.cellAt(0, 0), isNull);
      expect(
        restarted.stageStartSnapshot!.runProgress.gold,
        RummiEconomyConfig.startingGold,
      );
    });

    test(
      'restored run에서도 restartCurrentStage는 saved stageStartSnapshot 기준으로 되돌린다',
      () {
        final stageStartSession = RummiPokerGridSession(
          runSeed: 500,
          blind: RummiBlindState(targetScore: 300),
        );
        final stageStartProgress = RummiRunProgress();
        final currentSession = stageStartSession.copySnapshot();
        final currentProgress = stageStartProgress.copySnapshot();

        final drawn = currentSession.drawToHand();
        expect(drawn, isNotNull);
        expect(currentSession.tryPlaceFromHand(drawn!, 0, 0), isTrue);
        currentProgress.gold += 23;

        final restoredRun = ActiveRunRuntimeState(
          activeScene: ActiveRunScene.battle,
          difficulty: NewRunDifficulty.standard,
          session: currentSession,
          runProgress: currentProgress,
          stageStartSnapshot: ActiveRunStageSnapshot(
            session: stageStartSession.copySnapshot(),
            runProgress: stageStartProgress.copySnapshot(),
          ),
        );

        final container = ProviderContainer();
        addTearDown(container.dispose);
        final args = GameSessionArgs(runSeed: 500, restoredRun: restoredRun);

        final before = container.read(gameSessionNotifierProvider(args));
        expect(before.session!.board.cellAt(0, 0), isNotNull);
        expect(before.runProgress!.gold, RummiEconomyConfig.startingGold + 23);

        container
            .read(gameSessionNotifierProvider(args).notifier)
            .restartCurrentStage();

        final restarted = container.read(gameSessionNotifierProvider(args));
        expect(restarted.session!.board.cellAt(0, 0), isNull);
        expect(restarted.session!.hand, isEmpty);
        expect(restarted.runProgress!.gold, RummiEconomyConfig.startingGold);
        expect(restarted.activeRunScene, ActiveRunScene.battle);
        expect(restarted.runLoopPhase, GameRunLoopPhase.battle);
      },
    );

    test('clear confirm 직후에도 expiry 신호가 동시에 나올 수 있는 상태를 재현한다', () {
      final session = RummiPokerGridSession(
        runSeed: 700,
        blind: RummiBlindState(
          targetScore: 40,
          boardDiscardsRemaining: 4,
          handDiscardsRemaining: 2,
        ),
        deck: PokerDeck.fromSnapshot(const []),
      );
      final runProgress = RummiRunProgress();

      final drawnA = session.drawToHand();
      final drawnB = session.drawToHand();
      expect(drawnA, isNull);
      expect(drawnB, isNull);

      session.board.setCell(
        0,
        0,
        const Tile(id: 1, color: TileColor.red, number: 1),
      );
      session.board.setCell(
        0,
        1,
        const Tile(id: 2, color: TileColor.blue, number: 2),
      );
      session.board.setCell(
        0,
        2,
        const Tile(id: 3, color: TileColor.yellow, number: 3),
      );
      session.board.setCell(
        0,
        3,
        const Tile(id: 4, color: TileColor.black, number: 4),
      );
      session.board.setCell(
        0,
        4,
        const Tile(id: 5, color: TileColor.red, number: 5),
      );

      final restoredRun = ActiveRunRuntimeState(
        activeScene: ActiveRunScene.battle,
        difficulty: NewRunDifficulty.standard,
        session: session,
        runProgress: runProgress,
        stageStartSnapshot: ActiveRunStageSnapshot(
          session: session.copySnapshot(),
          runProgress: runProgress.copySnapshot(),
        ),
      );

      final container = ProviderContainer();
      addTearDown(container.dispose);
      final args = GameSessionArgs(runSeed: 700, restoredRun: restoredRun);
      final notifier = container.read(
        gameSessionNotifierProvider(args).notifier,
      );

      final result = notifier.confirmLines();

      expect(result, isNotNull);
      expect(result!.stageCleared, isTrue);
      expect(
        notifier.evaluateExpiry(),
        contains(RummiExpirySignal.drawPileExhausted),
      );
    });
  });
}
