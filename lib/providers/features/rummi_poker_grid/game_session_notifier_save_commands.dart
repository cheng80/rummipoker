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
        stakeStartSnapshot: retrySnapshot,
      );
    }

    return ActiveRunRuntimeState(
      activeScene: currentScene,
      difficulty: difficulty,
      runModifier: state.runModifier,
      session: state.session!,
      runProgress: state.runProgress!,
      stageStartSnapshot: state.stageStartSnapshot!,
      stakeStartSnapshot: state.stakeStartSnapshot ?? state.stageStartSnapshot!,
    );
  }

  void setStageStartSnapshot(ActiveRunStageSnapshot snapshot) {
    _replaceState(
      state.copyWith(
        stageStartSnapshot: snapshot,
        stakeStartSnapshot: snapshot,
        revision: state.revision + 1,
      ),
    );
  }

  void replaceRuntimeState({
    required RummiPokerGridSession session,
    required RummiRunProgress runProgress,
    required ActiveRunStageSnapshot stageStartSnapshot,
    ActiveRunStageSnapshot? stakeStartSnapshot,
    ActiveRunScene activeRunScene = ActiveRunScene.battle,
  }) {
    _replaceState(
      state.copyWith(
        session: session,
        runProgress: runProgress,
        stageStartSnapshot: stageStartSnapshot,
        stakeStartSnapshot: stakeStartSnapshot ?? stageStartSnapshot,
        runLoopPhase: _loopPhaseForScene(activeRunScene),
        activeRunScene: activeRunScene,
        debugFixtureId: state.debugFixtureId,
        presentationState: GameSessionPresentationState.initial,
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
      stakeStartSnapshot: refreshedSnapshot,
      activeRunScene: ActiveRunScene.battle,
    );
  }

  /// 현재 전투 시작 시점(stakeStartSnapshot)으로 복원.
  void restartCurrentStake() {
    final snapshot = state.stakeStartSnapshot ?? state.stageStartSnapshot;
    if (snapshot == null) return;
    final restoredSession = snapshot.session.copySnapshot();
    final restoredRunProgress = snapshot.runProgress.copySnapshot();
    final refreshedStakeSnapshot =
        ActiveRunSaveService.captureStageStartSnapshot(
          session: restoredSession,
          runProgress: restoredRunProgress,
        );
    replaceRuntimeState(
      session: restoredSession,
      runProgress: restoredRunProgress,
      stageStartSnapshot: state.stageStartSnapshot ?? refreshedStakeSnapshot,
      stakeStartSnapshot: refreshedStakeSnapshot,
      activeRunScene: ActiveRunScene.battle,
    );
  }
}
