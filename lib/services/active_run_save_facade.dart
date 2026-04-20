import 'active_run_save_service.dart';

/// V4 target-term read model over the current active run save/runtime.
///
/// Important:
/// - This is a compatibility facade only.
/// - It does not change save keys, schema version, or restore behavior.
/// - It lets future Station/checkpoint terminology read the current active run
///   payload without forcing an early save migration.
enum RummiSaveSceneAlias { battle, market, blindSelect }

String rummiSaveSceneLabel(RummiSaveSceneAlias sceneAlias) {
  return switch (sceneAlias) {
    RummiSaveSceneAlias.market => 'Market',
    RummiSaveSceneAlias.battle => 'Battle',
    RummiSaveSceneAlias.blindSelect => 'Blind Select',
  };
}

class RummiStationCheckpointSaveView {
  const RummiStationCheckpointSaveView({
    required this.stageIndex,
    required this.stationIndex,
    required this.runSeed,
    required this.gold,
  });

  factory RummiStationCheckpointSaveView.fromSaveData(ActiveRunSaveData save) {
    return RummiStationCheckpointSaveView(
      stageIndex: save.stageStartRunProgress.stageIndex,
      stationIndex: save.stageStartRunProgress.stageIndex,
      runSeed: save.stageStartSession.runSeed,
      gold: save.stageStartRunProgress.gold,
    );
  }

  factory RummiStationCheckpointSaveView.fromRuntimeState(
    ActiveRunRuntimeState runtime,
  ) {
    return RummiStationCheckpointSaveView(
      stageIndex: runtime.stageStartSnapshot.runProgress.stageIndex,
      stationIndex: runtime.stageStartSnapshot.runProgress.stageIndex,
      runSeed: runtime.stageStartSnapshot.session.runSeed,
      gold: runtime.stageStartSnapshot.runProgress.gold,
    );
  }

  final int stageIndex;
  final int stationIndex;
  final int runSeed;
  final int gold;
}

class RummiActiveRunSaveFacade {
  const RummiActiveRunSaveFacade({
    required this.schemaVersion,
    required this.activeScene,
    required this.sceneAlias,
    required this.currentStageIndex,
    required this.currentStationIndex,
    required this.currentRunSeed,
    required this.currentGold,
    required this.checkpoint,
  });

  factory RummiActiveRunSaveFacade.fromSaveData(ActiveRunSaveData save) {
    return RummiActiveRunSaveFacade(
      schemaVersion: save.schemaVersion,
      activeScene: save.activeScene,
      sceneAlias: _sceneAliasFromName(save.activeScene),
      currentStageIndex: save.runProgress.stageIndex,
      currentStationIndex: save.runProgress.stageIndex,
      currentRunSeed: save.session.runSeed,
      currentGold: save.runProgress.gold,
      checkpoint: RummiStationCheckpointSaveView.fromSaveData(save),
    );
  }

  factory RummiActiveRunSaveFacade.fromRuntimeState(
    ActiveRunRuntimeState runtime,
  ) {
    return RummiActiveRunSaveFacade(
      schemaVersion: ActiveRunSaveService.schemaVersion,
      activeScene: runtime.activeScene.name,
      sceneAlias: _sceneAliasFromScene(runtime.activeScene),
      currentStageIndex: runtime.runProgress.stageIndex,
      currentStationIndex: runtime.runProgress.stageIndex,
      currentRunSeed: runtime.session.runSeed,
      currentGold: runtime.runProgress.gold,
      checkpoint: RummiStationCheckpointSaveView.fromRuntimeState(runtime),
    );
  }

  final int schemaVersion;
  final String activeScene;
  final RummiSaveSceneAlias sceneAlias;
  final int currentStageIndex;
  final int currentStationIndex;
  final int currentRunSeed;
  final int currentGold;
  final RummiStationCheckpointSaveView checkpoint;

  String get currentLocationSummary =>
      '현재 Station $currentStationIndex · ${rummiSaveSceneLabel(sceneAlias)} · Gold $currentGold';

  String get checkpointSummary => '체크포인트 Station ${checkpoint.stationIndex}';

  String snapshotSummaryLabel({bool includeCheckpoint = true}) {
    if (!includeCheckpoint) {
      return currentLocationSummary;
    }
    return '$currentLocationSummary\n$checkpointSummary';
  }

  String continueDialogMessage() {
    return '저장된 현재 런을 복원합니다.\n'
        '${snapshotSummaryLabel()}\n'
        '삭제하거나 그대로 이어할지 선택하세요.';
  }

  static RummiSaveSceneAlias _sceneAliasFromName(String scene) {
    return switch (scene) {
      'shop' => RummiSaveSceneAlias.market,
      'blindSelect' => RummiSaveSceneAlias.blindSelect,
      _ => RummiSaveSceneAlias.battle,
    };
  }

  static RummiSaveSceneAlias _sceneAliasFromScene(ActiveRunScene scene) {
    return switch (scene) {
      ActiveRunScene.shop => RummiSaveSceneAlias.market,
      ActiveRunScene.battle => RummiSaveSceneAlias.battle,
      ActiveRunScene.blindSelect => RummiSaveSceneAlias.blindSelect,
    };
  }
}
