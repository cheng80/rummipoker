import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:rummipoker/logic/rummi_poker_grid/jester_meta.dart';
import 'package:rummipoker/logic/rummi_poker_grid/rummi_blind_state.dart';
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
      expect(initial.stationView!.objective.targetScore, 300);
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
      expect(state.session?.blind.targetScore, 240);
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
      expect(state.session?.blind.targetScore, 450);
      expect(
        state.session?.blind.boardDiscardsRemaining,
        RummiRuleset.currentDefaults.defaultBoardDiscards - 1,
      );
      expect(
        state.session?.blind.handDiscardsRemaining,
        RummiRuleset.currentDefaults.defaultHandDiscards,
      );
      expect(state.session?.maxHandSize, RummiRuleset.currentDefaults.defaultMaxHandSize);
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

      final runtime = notifier.buildSaveRuntimeState();

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
  });
}
