import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:rummipoker/logic/rummi_poker_grid/jester_meta.dart';
import 'package:rummipoker/logic/rummi_poker_grid/rummi_blind_state.dart';
import 'package:rummipoker/logic/rummi_poker_grid/models/tile.dart';
import 'package:rummipoker/logic/rummi_poker_grid/rummi_poker_grid_session.dart';
import 'package:rummipoker/logic/rummi_poker_grid/rummi_ruleset.dart';
import 'package:rummipoker/providers/features/rummi_poker_grid/game_session_notifier.dart';
import 'package:rummipoker/services/active_run_save_facade.dart';
import 'package:rummipoker/services/active_run_save_service.dart';

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
      expect(state.activeRunSaveView, isNotNull);
      expect(state.pendingResumeShop, isFalse);
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
      expect(initial.activeRunSaveView, isNotNull);
      expect(initial.stationView!.objective.targetScore, 300);
      expect(initial.marketView!.gold, RummiEconomyConfig.startingGold);
      expect(initial.activeRunSaveView!.sceneAlias, RummiSaveSceneAlias.battle);

      initial.runProgress!.gold += 9;
      notifier.setActiveRunScene(ActiveRunScene.shop);

      final updated = container.read(gameSessionNotifierProvider(args));
      expect(updated.marketView!.gold, RummiEconomyConfig.startingGold + 9);
      expect(updated.activeRunSaveView!.currentGold, 19);
      expect(updated.activeRunSaveView!.sceneAlias, RummiSaveSceneAlias.market);
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
      },
    );
  });
}
