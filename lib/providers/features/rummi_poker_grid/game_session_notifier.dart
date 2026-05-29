import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../logic/rummi_poker_grid/item_definition.dart';
import '../../../logic/rummi_poker_grid/item_effect_runtime.dart';
import '../../../logic/rummi_poker_grid/jester_meta.dart';
import '../../../logic/rummi_poker_grid/rummi_battle_facade.dart';
import '../../../logic/rummi_poker_grid/rummi_market_facade.dart';
import '../../../logic/rummi_poker_grid/models/board.dart';
import '../../../logic/rummi_poker_grid/models/poker_deck.dart';
import '../../../logic/rummi_poker_grid/models/tile.dart';
import '../../../logic/rummi_poker_grid/rummi_poker_grid_session.dart';
import '../../../logic/rummi_poker_grid/rummi_blind_state.dart';
import '../../../logic/rummi_poker_grid/rummi_ruleset.dart';
import '../../../logic/rummi_poker_grid/rummi_station_facade.dart';
import '../../../services/active_run_save_facade.dart';
import '../../../services/active_run_save_service.dart';
import '../../../services/blind_selection_setup.dart';
import '../../../services/new_run_setup.dart';
import '../../../services/run_unlock_state_service.dart';
import 'game_session_state.dart';

part 'game_session_notifier_models.dart';
part 'game_session_notifier_bootstrap.dart';
part 'game_session_notifier_save_commands.dart';
part 'game_session_notifier_battle_commands.dart';
part 'game_session_notifier_market_commands.dart';

/// 전투 화면의 세션/선택/UI 잠금 상태를 한곳에서 관리한다.
final gameSessionNotifierProvider =
    NotifierProvider.family<
      GameSessionNotifier,
      GameSessionState,
      GameSessionArgs
    >(GameSessionNotifier.new);

class DeckPeekBattleUseResult {
  const DeckPeekBattleUseResult._({required this.candidates, this.failMessage});

  const DeckPeekBattleUseResult.success(List<Tile> candidates)
    : this._(candidates: candidates);

  const DeckPeekBattleUseResult.failure(String message)
    : this._(candidates: const [], failMessage: message);

  final List<Tile> candidates;
  final String? failMessage;

  bool get isSuccess => failMessage == null;
}

class GameSessionNotifier
    extends FamilyNotifier<GameSessionState, GameSessionArgs>
    with
        GameSessionNotifierSaveCommands,
        GameSessionNotifierBattleCommands,
        GameSessionNotifierMarketCommands {
  @override
  GameSessionState build(GameSessionArgs args) {
    return _withDerivedViews(_buildInitialGameSessionState(args));
  }

  void markDirty() {
    _replaceState(state.copyWith(revision: state.revision + 1));
  }

  void setJesterCatalog(RummiJesterCatalog? catalog) {
    _replaceState(
      state.copyWith(jesterCatalog: catalog, revision: state.revision + 1),
    );
  }

  void setActiveRunScene(ActiveRunScene scene) {
    _replaceState(
      state.copyWith(
        runLoopPhase: _loopPhaseForScene(scene),
        activeRunScene: scene,
        revision: state.revision + 1,
      ),
    );
  }

  void setDebugMaxHandSize(int value) {
    final session = state.session;
    if (session == null) return;
    final ruleset = state.ruleset;
    final clamped = value.clamp(
      ruleset.minDebugMaxHandSize,
      ruleset.maxDebugMaxHandSize,
    );
    session.setDebugMaxHandSize(clamped);
    final selectedHandTile = state.selectedHandTile;
    _replaceState(
      state.copyWith(
        selectedHandTile:
            selectedHandTile != null && !session.hand.contains(selectedHandTile)
            ? null
            : selectedHandTile,
        revision: state.revision + 1,
      ),
    );
  }

  @override
  void clearSelections() {
    _replaceState(
      state.copyWith(
        selectedHandTile: null,
        selectedBoardRow: null,
        selectedBoardCol: null,
        revision: state.revision + 1,
      ),
    );
  }

  void setSelectedHandTile(Tile? tile) {
    _replaceState(
      state.copyWith(
        selectedHandTile: tile,
        selectedBoardRow: tile == null ? state.selectedBoardRow : null,
        selectedBoardCol: tile == null ? state.selectedBoardCol : null,
        revision: state.revision + 1,
      ),
    );
  }

  void toggleSelectedHandTile(Tile tile) {
    setSelectedHandTile(state.selectedHandTile == tile ? null : tile);
  }

  @override
  void setSelectedBoardCell(int? row, int? col) {
    _replaceState(
      state.copyWith(
        selectedBoardRow: row,
        selectedBoardCol: col,
        selectedHandTile: row == null && col == null
            ? state.selectedHandTile
            : null,
        revision: state.revision + 1,
      ),
    );
  }

  void setSelectedJesterOverlayIndex(int? index) {
    _replaceState(
      state.copyWith(
        selectedJesterOverlayIndex: index,
        revision: state.revision + 1,
      ),
    );
  }

  @override
  void setSettlementBoardSnapshot(Map<String, Tile> snapshot) {
    _replaceState(
      state.copyWith(
        settlementBoardSnapshot: snapshot,
        revision: state.revision + 1,
      ),
    );
  }

  void setStageFlow({
    required GameStageFlowPhase phase,
    int? stageScoreAdded,
    ConfirmedLineBreakdown? activeSettlementLine,
    ScoringPresentationStep activeSettlementStep = ScoringPresentationStep.none,
    int? activeSettlementEffectIndex,
    List<int> activeSettlementEffectIndexes = const [],
    Object? settlementGoalDisplayScore = GameSessionState.unsetValue,
    Map<String, Tile>? settlementBoardSnapshot,
    bool bumpSettlementSequence = false,
  }) {
    _replaceState(
      state.copyWith(
        stageFlowPhase: phase,
        stageScoreAdded: stageScoreAdded,
        activeSettlementLine: activeSettlementLine,
        activeSettlementStep: activeSettlementStep,
        activeSettlementEffectIndex: activeSettlementEffectIndex,
        activeSettlementEffectIndexes: activeSettlementEffectIndexes,
        settlementGoalDisplayScore: settlementGoalDisplayScore,
        settlementBoardSnapshot: settlementBoardSnapshot,
        settlementSequenceTick: bumpSettlementSequence
            ? state.settlementSequenceTick + 1
            : state.settlementSequenceTick,
        revision: state.revision + 1,
      ),
    );
  }

  @override
  GameSessionState _withValidSelections(GameSessionState current) {
    final session = current.session;
    if (session == null) return current;

    final selectedHandTile = current.selectedHandTile;
    final keepHandSelection =
        selectedHandTile != null && session.hand.contains(selectedHandTile);
    final selectedBoardRow = current.selectedBoardRow;
    final selectedBoardCol = current.selectedBoardCol;
    final keepBoardSelection =
        selectedBoardRow != null &&
        selectedBoardCol != null &&
        selectedBoardRow >= 0 &&
        selectedBoardRow < kBoardSize &&
        selectedBoardCol >= 0 &&
        selectedBoardCol < kBoardSize &&
        session.board.cellAt(selectedBoardRow, selectedBoardCol) != null;

    return current.copyWith(
      selectedHandTile: keepHandSelection ? selectedHandTile : null,
      selectedBoardRow: keepBoardSelection ? selectedBoardRow : null,
      selectedBoardCol: keepBoardSelection ? selectedBoardCol : null,
    );
  }

  // -- Business logic --

  /// 스테이지 잔여물 처리 + 캐시아웃 계산/적용. 결과 breakdown 반환.
  RummiCashOutBreakdown prepareCashOut({ItemCatalog? itemCatalog}) {
    final session = state.session!;
    final runProgress = state.runProgress!;
    session.discardStageRemainder();
    var breakdown = runProgress.buildCashOutBreakdown(
      session,
      itemCatalog: itemCatalog,
      rewardMultiplier: state.runModifier.rewardMultiplier,
    );
    runProgress.applyCashOut(breakdown);
    if (runProgress.currentStationBlindTierIndex == BlindTier.boss.index) {
      final rewardTile = runProgress.addBossClearDeckTileReward(
        session.runRandom,
      );
      breakdown = breakdown.copyWith(deckTileRewards: [rewardTile]);
      if (itemCatalog != null) {
        ItemEffectRuntime.applyOwnedBossClearItems(
          catalog: itemCatalog,
          runProgress: runProgress,
        );
      }
      runProgress.claimBossSlotUnlockRewards(itemCatalog: itemCatalog);
      runProgress.recordSeenBossModifier(session.blind.bossModifier?.id);
      runProgress.recordClearedStation(runProgress.stageIndex);
    }
    _replaceState(state.copyWith(revision: state.revision + 1));
    return breakdown;
  }

  /// 전투 정산 직후 캐시아웃 준비를 notifier 경계로 모은다.
  RummiCashOutBreakdown prepareSettlementAndCashOut({
    ItemCatalog? itemCatalog,
  }) {
    final breakdown = prepareCashOut(itemCatalog: itemCatalog);
    _replaceState(
      state.copyWith(
        runLoopPhase: GameRunLoopPhase.settlement,
        activeRunScene: ActiveRunScene.battle,
        revision: state.revision + 1,
      ),
    );
    return breakdown;
  }

  /// market 종료 후 다음 station 로딩 직전의 짧은 전환 단계를 기록한다.
  void beginNextStationTransition() {
    _replaceState(
      state.copyWith(
        runLoopPhase: GameRunLoopPhase.nextStationTransition,
        activeRunScene: ActiveRunScene.blindSelect,
        revision: state.revision + 1,
      ),
    );
  }

  /// Market 종료 뒤 blind select route로 넘길 runtime을 station-loop 경계에서 만든다.
  ActiveRunRuntimeState prepareNextStationBlindSelectRuntime({
    required NewRunDifficulty difficulty,
  }) {
    beginNextStationTransition();
    return BlindSelectionSetup.prepareRuntimeForBlindSelect(
      runtime: buildSaveRuntimeState(
        scene: ActiveRunScene.blindSelect,
        difficulty: difficulty,
      ),
    );
  }

  /// 다음 스테이지로 진입 처리.
  void advanceToNextStage(int runSeed, {ItemCatalog? itemCatalog}) {
    final session = state.session!;
    final runProgress = state.runProgress!;
    runProgress.advanceStage(session, runSeed: runSeed);
    if (itemCatalog != null) {
      ItemEffectRuntime.applyOwnedStationStartItems(
        catalog: itemCatalog,
        session: session,
        runProgress: runProgress,
      );
    }
    clearSelections();
    _replaceState(
      state.copyWith(
        stageStartSnapshot: ActiveRunSaveService.captureStageStartSnapshot(
          session: session,
          runProgress: runProgress,
        ),
        runLoopPhase: GameRunLoopPhase.battle,
        revision: state.revision + 1,
      ),
    );
  }

  /// market 종료 후 다음 station 진입까지를 notifier command로 감싼다.
  void advanceToNextStation(int runSeed, {ItemCatalog? itemCatalog}) {
    advanceToNextStage(runSeed, itemCatalog: itemCatalog);
    _replaceState(
      state.copyWith(
        activeRunScene: ActiveRunScene.battle,
        revision: state.revision + 1,
      ),
    );
  }

  // -- 전투 액션 (View에서 직접 session을 조작하던 것을 이관) --

  @override
  void _replaceState(GameSessionState next) {
    state = _withDerivedViews(next);
  }

  GameSessionState _withDerivedViews(GameSessionState next) {
    final session = next.session;
    final runProgress = next.runProgress;
    if (session == null || runProgress == null) {
      return next.copyWith(
        stationView: null,
        marketView: null,
        battleView: null,
        activeRunSaveView: null,
      );
    }

    return next.copyWith(
      stationView: RummiStationRuntimeFacade.fromSession(session),
      marketView: RummiMarketRuntimeFacade.fromRunProgress(
        runProgress,
        pressureProfile: _marketPressureProfileFor(next.runModifier),
      ),
      battleView: RummiBattleRuntimeFacade.fromRuntime(
        session: session,
        runProgress: runProgress,
      ),
      activeRunSaveView: RummiActiveRunSaveFacade.fromRuntimeState(
        ActiveRunRuntimeState(
          activeScene: next.activeRunScene,
          difficulty: arg.difficulty,
          session: session,
          runProgress: runProgress,
          stageStartSnapshot:
              next.stageStartSnapshot ??
              ActiveRunSaveService.captureStageStartSnapshot(
                session: session,
                runProgress: runProgress,
              ),
        ),
      ),
    );
  }

  @override
  RummiMarketPressureProfile _marketPressureProfileFor(
    NewRunModifier modifier,
  ) {
    return modifier == NewRunModifier.highStakes
        ? RummiMarketPressureProfile.highStakes
        : RummiMarketPressureProfile.standard;
  }
}
