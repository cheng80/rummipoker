part of 'game_session_notifier.dart';

mixin GameSessionNotifierSaveCommands
    on FamilyNotifier<GameSessionState, GameSessionArgs> {
  void _replaceState(GameSessionState next);

  ActiveRunRuntimeState buildSaveRuntimeState({
    ActiveRunScene? scene,
    required NewRunDifficulty difficulty,
    bool useStageStartSnapshotAsCurrent = false,
  }) {
    final currentScene = scene ?? state.activeRunScene;
    if (useStageStartSnapshotAsCurrent) {
      final stageStartSnapshot = state.stageStartSnapshot!;
      final retrySnapshot = ActiveRunStageSnapshot(
        session: stageStartSnapshot.session.copySnapshot(),
        runProgress: stageStartSnapshot.runProgress.copySnapshot(),
      );
      return ActiveRunRuntimeState(
        activeScene: ActiveRunScene.battle,
        difficulty: difficulty,
        runModifier: state.runModifier,
        session: retrySnapshot.session,
        runProgress: retrySnapshot.runProgress,
        stageStartSnapshot: retrySnapshot,
      );
    }

    return ActiveRunRuntimeState(
      activeScene: currentScene,
      difficulty: difficulty,
      runModifier: state.runModifier,
      session: state.session!,
      runProgress: state.runProgress!,
      stageStartSnapshot: state.stageStartSnapshot!,
    );
  }

  void setStageStartSnapshot(ActiveRunStageSnapshot snapshot) {
    _replaceState(
      state.copyWith(
        stageStartSnapshot: snapshot,
        revision: state.revision + 1,
      ),
    );
  }

  void replaceRuntimeState({
    required RummiPokerGridSession session,
    required RummiRunProgress runProgress,
    required ActiveRunStageSnapshot stageStartSnapshot,
    ActiveRunScene activeRunScene = ActiveRunScene.battle,
  }) {
    _replaceState(
      state.copyWith(
        session: session,
        runProgress: runProgress,
        stageStartSnapshot: stageStartSnapshot,
        runLoopPhase: _loopPhaseForScene(activeRunScene),
        activeRunScene: activeRunScene,
        debugFixtureId: state.debugFixtureId,
        selectedHandTile: null,
        selectedBoardRow: null,
        selectedBoardCol: null,
        selectedJesterOverlayIndex: null,
        stageFlowPhase: GameStageFlowPhase.none,
        stageScoreAdded: 0,
        activeSettlementLine: null,
        activeSettlementStep: ScoringPresentationStep.none,
        activeSettlementEffectIndex: null,
        activeSettlementEffectIndexes: const [],
        settlementGoalDisplayScore: null,
        settlementBoardSnapshot: const {},
        settlementSequenceTick: 0,
        revision: state.revision + 1,
      ),
    );
  }

  /// 현재 스테이지 시작 시점(stageStartSnapshot)으로 복원.
  void restartCurrentStage() {
    final snapshot = state.stageStartSnapshot;
    if (snapshot == null) return;
    final restoredSession = snapshot.session.copySnapshot();
    final restoredRunProgress = snapshot.runProgress.copySnapshot();
    final refreshedSnapshot = ActiveRunSaveService.captureStageStartSnapshot(
      session: restoredSession,
      runProgress: restoredRunProgress,
    );
    replaceRuntimeState(
      session: restoredSession,
      runProgress: restoredRunProgress,
      stageStartSnapshot: refreshedSnapshot,
      activeRunScene: ActiveRunScene.battle,
    );
  }
}
