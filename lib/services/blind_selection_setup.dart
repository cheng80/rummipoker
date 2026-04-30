import '../logic/rummi_poker_grid/item_definition.dart';
import '../logic/rummi_poker_grid/item_effect_runtime.dart';
import '../logic/rummi_poker_grid/rummi_ruleset.dart';
import 'active_run_save_service.dart';
import 'blind_selection_spec.dart';
import 'new_run_setup.dart';

export 'blind_selection_spec.dart';

class BlindSelectionSetup {
  const BlindSelectionSetup._();

  static BlindTier parseTier(String? raw) =>
      BlindSelectionSpecBuilder.parseTier(raw);

  static List<BlindSelectionSpec> buildForStation({
    required int stationIndex,
    required int clearedBlindTierIndex,
    required NewRunDifficulty difficulty,
    required RummiRuleset ruleset,
  }) => BlindSelectionSpecBuilder.buildForStation(
    stationIndex: stationIndex,
    clearedBlindTierIndex: clearedBlindTierIndex,
    difficulty: difficulty,
    ruleset: ruleset,
  );

  static BlindSelectionSpec resolveSpec({
    required BlindTier tier,
    required int stationIndex,
    required NewRunDifficulty difficulty,
    required RummiRuleset ruleset,
  }) => BlindSelectionSpecBuilder.resolveSpec(
    tier: tier,
    stationIndex: stationIndex,
    difficulty: difficulty,
    ruleset: ruleset,
  );

  /// 시장 이후 다음 Station 진입 직전에 선택한 블라인드 조건을 런타임에 반영한다.
  static ActiveRunRuntimeState prepareContinuedRunForSelectedBlind({
    required ActiveRunRuntimeState runtime,
    required BlindTier tier,
    ItemCatalog? itemCatalog,
  }) {
    final session = runtime.session.copySnapshot();
    final runProgress = runtime.runProgress.copySnapshot();
    final stationIndex = runProgress.stageIndex;
    final selected = resolveSpec(
      tier: tier,
      stationIndex: stationIndex,
      difficulty: runtime.difficulty,
      ruleset: session.ruleset,
    );

    runProgress.startBlind(
      session,
      stationIndex: stationIndex,
      blindTierIndex: tier.index,
      shuffleSeed: _deriveBlindShuffleSeed(
        runSeed: session.runSeed,
        stationIndex: stationIndex,
        blindTierIndex: tier.index,
      ),
      targetScore: selected.targetScore,
      boardDiscards: selected.boardDiscards,
      handDiscards: selected.handDiscards,
      maxHandSize: selected.maxHandSize,
    );
    session.blind.bossModifier = selected.bossModifier;
    if (itemCatalog != null) {
      ItemEffectRuntime.applyOwnedStationStartItems(
        catalog: itemCatalog,
        session: session,
        runProgress: runProgress,
      );
    }
    final stageStartSnapshot = ActiveRunSaveService.captureStageStartSnapshot(
      session: session,
      runProgress: runProgress,
    );

    return ActiveRunRuntimeState(
      activeScene: ActiveRunScene.battle,
      difficulty: runtime.difficulty,
      session: session,
      runProgress: runProgress,
      stageStartSnapshot: stageStartSnapshot,
    );
  }

  /// blind select 진입 직전 runtime을 station/blind 진행도 기준으로 정규화한다.
  static ActiveRunRuntimeState prepareRuntimeForBlindSelect({
    required ActiveRunRuntimeState runtime,
  }) {
    final session = runtime.session.copySnapshot();
    final runProgress = runtime.runProgress.copySnapshot();
    if (runProgress.currentStationBlindTierIndex >= BlindTier.boss.index) {
      runProgress.stageIndex += 1;
      runProgress.currentStationBlindTierIndex = -1;
    }
    return ActiveRunRuntimeState(
      activeScene: ActiveRunScene.blindSelect,
      difficulty: runtime.difficulty,
      session: session,
      runProgress: runProgress,
      stageStartSnapshot: runtime.stageStartSnapshot,
    );
  }

  static int _deriveBlindShuffleSeed({
    required int runSeed,
    required int stationIndex,
    required int blindTierIndex,
  }) {
    final stageSeed = runSeed * 1103515245 + 12345 + stationIndex * 1013904223;
    final mixed = (stageSeed + (blindTierIndex + 1) * 2654435761) & 0x7fffffff;
    return mixed == 0 ? stationIndex + blindTierIndex + 1 : mixed;
  }
}
