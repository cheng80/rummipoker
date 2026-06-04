import '../logic/rummi_poker_grid/hand_rank.dart';
import '../logic/rummi_poker_grid/models/tile.dart';
import '../logic/rummi_poker_grid/rummi_hand_growth.dart';
import 'active_run_save_service.dart';
import 'new_run_setup.dart';

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
    RummiSaveSceneAlias.blindSelect => 'Station Select',
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

class ActiveRunBookmarkSlotView {
  const ActiveRunBookmarkSlotView({
    required this.slotIndex,
    required this.summary,
  });

  final int slotIndex;
  final RummiActiveRunSaveFacade? summary;

  bool get isEmpty => summary == null;
  String get title => '슬롯 ${slotIndex + 1}';
  String get label => summary?.bookmarkLabel ?? '비어 있음';
}

class RummiActiveRunSaveFacade {
  const RummiActiveRunSaveFacade({
    required this.schemaVersion,
    required this.activeScene,
    required this.sceneAlias,
    this.difficultyLabel = '표준',
    this.runModifierLabel,
    required this.currentStageIndex,
    required this.currentStationIndex,
    this.currentBlindTierIndex = 0,
    required this.currentRunSeed,
    required this.currentGold,
    required this.checkpoint,
    this.currentPlayedHandCounts = const {},
    this.currentHandGrowthStates = const {},
    this.currentAddedDeckTiles = const [],
  });

  factory RummiActiveRunSaveFacade.fromSaveData(ActiveRunSaveData save) {
    return RummiActiveRunSaveFacade(
      schemaVersion: save.schemaVersion,
      activeScene: save.activeScene,
      sceneAlias: _sceneAliasFromName(save.activeScene),
      difficultyLabel: NewRunSetup(
        difficulty: NewRunSetup.parseDifficulty(save.difficulty),
      ).difficultyLabel,
      runModifierLabel: _runModifierLabel(
        NewRunModifier.parse(save.runModifier),
      ),
      currentStageIndex: save.runProgress.stageIndex,
      currentStationIndex: save.runProgress.stageIndex,
      currentBlindTierIndex: save.runProgress.currentStationBlindTierIndex,
      currentRunSeed: save.session.runSeed,
      currentGold: save.runProgress.gold,
      currentPlayedHandCounts: _parsePlayedHandCounts(
        save.runProgress.playedHandCounts,
      ),
      currentHandGrowthStates: _parseHandGrowthStates(
        save.runProgress.handGrowthStates,
        save.runProgress.playedHandCounts,
      ),
      currentAddedDeckTiles: _parseTileList(save.runProgress.addedDeckTiles),
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
      difficultyLabel: NewRunSetup(
        difficulty: runtime.difficulty,
      ).difficultyLabel,
      runModifierLabel: _runModifierLabel(runtime.runModifier),
      currentStageIndex: runtime.runProgress.stageIndex,
      currentStationIndex: runtime.runProgress.stageIndex,
      currentBlindTierIndex: runtime.runProgress.currentStationBlindTierIndex,
      currentRunSeed: runtime.session.runSeed,
      currentGold: runtime.runProgress.gold,
      currentPlayedHandCounts: runtime.runProgress.snapshotPlayedHandCounts(),
      currentHandGrowthStates: runtime.runProgress.snapshotHandGrowthStates(),
      currentAddedDeckTiles: runtime.runProgress.addedDeckTiles,
      checkpoint: RummiStationCheckpointSaveView.fromRuntimeState(runtime),
    );
  }

  final int schemaVersion;
  final String activeScene;
  final RummiSaveSceneAlias sceneAlias;
  final String difficultyLabel;
  final String? runModifierLabel;
  final int currentStageIndex;
  final int currentStationIndex;
  final int currentBlindTierIndex;
  final int currentRunSeed;
  final int currentGold;
  final Map<RummiHandRank, int> currentPlayedHandCounts;
  final Map<RummiHandRank, RummiHandGrowthState> currentHandGrowthStates;
  final List<Tile> currentAddedDeckTiles;
  final RummiStationCheckpointSaveView checkpoint;

  String get currentLocationSummary =>
      '현재 Station $currentStationIndex · ${rummiSaveSceneLabel(sceneAlias)} · Gold $currentGold';

  String get checkpointSummary => '체크포인트 Station ${checkpoint.stationIndex}';

  String get bookmarkLabel {
    final stationLabel = currentStageIndex >= 9
        ? '∞S$currentStageIndex'
        : 'S$currentStageIndex';
    final modifier = runModifierLabel;
    final modeLabel = modifier == null || modifier.isEmpty
        ? difficultyLabel
        : '$difficultyLabel · $modifier';
    return '$stationLabel · $modeLabel · ${_blindTierLabel(currentBlindTierIndex)}';
  }

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

  static Map<RummiHandRank, int> _parsePlayedHandCounts(
    Map<String, int> counts,
  ) {
    final out = <RummiHandRank, int>{};
    for (final entry in counts.entries) {
      for (final rank in RummiHandRank.values) {
        if (rank.name == entry.key) {
          out[rank] = entry.value;
          break;
        }
      }
    }
    return Map<RummiHandRank, int>.unmodifiable(out);
  }

  static List<Tile> _parseTileList(List<Map<String, dynamic>> tiles) {
    final out = <Tile>[];
    for (final tile in tiles) {
      try {
        out.add(Tile.fromJson(tile));
      } on Object {
        continue;
      }
    }
    return List<Tile>.unmodifiable(out);
  }

  static Map<RummiHandRank, RummiHandGrowthState> _parseHandGrowthStates(
    Map<String, Map<String, dynamic>> states,
    Map<String, int> playedHandCounts,
  ) {
    final out = <RummiHandRank, RummiHandGrowthState>{};
    for (final entry in states.entries) {
      for (final rank in RummiHandRank.values) {
        if (rank.name != entry.key) continue;
        out[rank] = RummiHandGrowthState.fromJson(rank, entry.value);
        break;
      }
    }
    if (out.isNotEmpty) {
      return Map<RummiHandRank, RummiHandGrowthState>.unmodifiable(out);
    }
    for (final entry in playedHandCounts.entries) {
      for (final rank in RummiHandRank.values) {
        if (rank.name != entry.key) continue;
        out[rank] = RummiHandGrowthState.fromCompletedCount(rank, entry.value);
        break;
      }
    }
    return Map<RummiHandRank, RummiHandGrowthState>.unmodifiable(out);
  }
}

String? _runModifierLabel(NewRunModifier modifier) {
  return switch (modifier) {
    NewRunModifier.basic => null,
    NewRunModifier.highStakes => '하이',
  };
}

String _blindTierLabel(int tierIndex) {
  return switch (tierIndex) {
    0 => 'SCOUT',
    1 => 'CLASH',
    2 => 'BOSS',
    _ => '선택 전',
  };
}
