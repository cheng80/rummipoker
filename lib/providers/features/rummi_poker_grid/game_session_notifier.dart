import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../logic/rummi_poker_grid/jester_meta.dart';
import '../../../logic/rummi_poker_grid/models/tile.dart';
import '../../../logic/rummi_poker_grid/rummi_poker_grid_session.dart';
import '../../../services/active_run_save_service.dart';
import 'game_session_state.dart';

class GameSessionArgs {
  const GameSessionArgs({
    required this.runSeed,
    this.restoredRun,
  });

  final int runSeed;
  final ActiveRunRuntimeState? restoredRun;

  @override
  bool operator ==(Object other) =>
      other is GameSessionArgs &&
      other.runSeed == runSeed &&
      identical(other.restoredRun, restoredRun);

  @override
  int get hashCode => Object.hash(runSeed, restoredRun);
}

/// 전투 화면의 세션/선택/UI 잠금 상태를 한곳에서 관리한다.
final gameSessionNotifierProvider =
    NotifierProvider.family<GameSessionNotifier, GameSessionState, GameSessionArgs>(
  GameSessionNotifier.new,
);

class GameSessionNotifier extends FamilyNotifier<GameSessionState, GameSessionArgs> {
  @override
  GameSessionState build(GameSessionArgs args) {
    final restoredRun = args.restoredRun;
    if (restoredRun != null) {
      return GameSessionState(
        session: restoredRun.session,
        runProgress: restoredRun.runProgress,
        stageStartSnapshot: restoredRun.stageStartSnapshot,
        activeRunScene: restoredRun.activeScene,
        pendingResumeShop: restoredRun.activeScene == ActiveRunScene.shop,
      );
    }

    final session = RummiPokerGridSession(runSeed: args.runSeed);
    final runProgress = RummiRunProgress();
    return GameSessionState(
      session: session,
      runProgress: runProgress,
      stageStartSnapshot: ActiveRunSaveService.captureStageStartSnapshot(
        session: session,
        runProgress: runProgress,
      ),
      activeRunScene: ActiveRunScene.battle,
    );
  }

  void markDirty() {
    state = state.copyWith(revision: state.revision + 1);
  }

  void setJesterCatalog(RummiJesterCatalog? catalog) {
    state = state.copyWith(
      jesterCatalog: catalog,
      revision: state.revision + 1,
    );
  }

  void setActiveRunScene(ActiveRunScene scene) {
    state = state.copyWith(
      activeRunScene: scene,
      revision: state.revision + 1,
    );
  }

  void setPendingResumeShop(bool value) {
    state = state.copyWith(
      pendingResumeShop: value,
      revision: state.revision + 1,
    );
  }

  void setStageStartSnapshot(ActiveRunStageSnapshot snapshot) {
    state = state.copyWith(
      stageStartSnapshot: snapshot,
      revision: state.revision + 1,
    );
  }

  void replaceRuntimeState({
    required RummiPokerGridSession session,
    required RummiRunProgress runProgress,
    required ActiveRunStageSnapshot stageStartSnapshot,
    ActiveRunScene activeRunScene = ActiveRunScene.battle,
  }) {
    state = state.copyWith(
      session: session,
      runProgress: runProgress,
      stageStartSnapshot: stageStartSnapshot,
      activeRunScene: activeRunScene,
      pendingResumeShop: false,
      selectedHandTile: null,
      selectedBoardRow: null,
      selectedBoardCol: null,
      selectedJesterOverlayIndex: null,
      stageFlowPhase: GameStageFlowPhase.none,
      stageScoreAdded: 0,
      activeSettlementLine: null,
      settlementBoardSnapshot: const {},
      settlementSequenceTick: 0,
      revision: state.revision + 1,
    );
  }

  void setDebugMaxHandSize(int value) {
    final session = state.session;
    if (session == null) return;
    session.setDebugMaxHandSize(value);
    final selectedHandTile = state.selectedHandTile;
    state = state.copyWith(
      selectedHandTile:
          selectedHandTile != null && !session.hand.contains(selectedHandTile)
          ? null
          : selectedHandTile,
      revision: state.revision + 1,
    );
  }

  void clearSelections() {
    state = state.copyWith(
      selectedHandTile: null,
      selectedBoardRow: null,
      selectedBoardCol: null,
      revision: state.revision + 1,
    );
  }

  void setSelectedHandTile(Tile? tile) {
    state = state.copyWith(
      selectedHandTile: tile,
      selectedBoardRow: tile == null ? state.selectedBoardRow : null,
      selectedBoardCol: tile == null ? state.selectedBoardCol : null,
      revision: state.revision + 1,
    );
  }

  void setSelectedBoardCell(int? row, int? col) {
    state = state.copyWith(
      selectedBoardRow: row,
      selectedBoardCol: col,
      selectedHandTile: row == null && col == null ? state.selectedHandTile : null,
      revision: state.revision + 1,
    );
  }

  void setSelectedJesterOverlayIndex(int? index) {
    state = state.copyWith(
      selectedJesterOverlayIndex: index,
      revision: state.revision + 1,
    );
  }

  void setSettlementBoardSnapshot(Map<String, Tile> snapshot) {
    state = state.copyWith(
      settlementBoardSnapshot: snapshot,
      revision: state.revision + 1,
    );
  }

  void setStageFlow({
    required GameStageFlowPhase phase,
    int? stageScoreAdded,
    ConfirmedLineBreakdown? activeSettlementLine,
    Map<String, Tile>? settlementBoardSnapshot,
    bool bumpSettlementSequence = false,
  }) {
    state = state.copyWith(
      stageFlowPhase: phase,
      stageScoreAdded: stageScoreAdded,
      activeSettlementLine: activeSettlementLine,
      settlementBoardSnapshot: settlementBoardSnapshot,
      settlementSequenceTick: bumpSettlementSequence
          ? state.settlementSequenceTick + 1
          : state.settlementSequenceTick,
      revision: state.revision + 1,
    );
  }
}
