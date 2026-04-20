import '../app_config.dart';
import '../logic/rummi_poker_grid/jester_meta.dart';
import '../logic/rummi_poker_grid/rummi_ruleset.dart';
import 'active_run_save_service.dart';
import 'new_run_setup.dart';

enum BlindTier { small, big, boss }

enum BlindSelectionAvailability { selectable, cleared, locked }

class BlindSelectionSpec {
  const BlindSelectionSpec({
    required this.tier,
    required this.title,
    required this.badgeLabel,
    required this.description,
    required this.targetScore,
    required this.boardDiscards,
    required this.handDiscards,
    required this.maxHandSize,
    required this.rewardPreview,
    required this.availability,
    this.lockReason,
  });

  final BlindTier tier;
  final String title;
  final String badgeLabel;
  final String description;
  final int targetScore;
  final int boardDiscards;
  final int handDiscards;
  final int maxHandSize;
  final int rewardPreview;
  final BlindSelectionAvailability availability;
  final String? lockReason;

  bool get isSelectable =>
      availability == BlindSelectionAvailability.selectable;
  bool get isCleared => availability == BlindSelectionAvailability.cleared;
  bool get isLocked => availability == BlindSelectionAvailability.locked;
}

class BlindSelectionSetup {
  const BlindSelectionSetup._();

  static BlindTier parseTier(String? raw) {
    return switch (raw) {
      'big' => BlindTier.big,
      'boss' => BlindTier.boss,
      _ => BlindTier.small,
    };
  }

  static List<BlindSelectionSpec> buildForStation({
    required int stationIndex,
    required int clearedBlindTierIndex,
    required NewRunDifficulty difficulty,
    required RummiRuleset ruleset,
  }) {
    final normalizedStationIndex = stationIndex < 1 ? 1 : stationIndex;
    final normalizedClearedBlindTierIndex = clearedBlindTierIndex.clamp(-1, 2);
    return <BlindSelectionSpec>[
      _buildSpec(
        tier: BlindTier.small,
        stationIndex: normalizedStationIndex,
        difficulty: difficulty,
        ruleset: ruleset,
        availability: normalizedClearedBlindTierIndex >= BlindTier.small.index
            ? BlindSelectionAvailability.cleared
            : BlindSelectionAvailability.selectable,
      ),
      _buildSpec(
        tier: BlindTier.big,
        stationIndex: normalizedStationIndex,
        difficulty: difficulty,
        ruleset: ruleset,
        availability: normalizedClearedBlindTierIndex >= BlindTier.big.index
            ? BlindSelectionAvailability.cleared
            : normalizedClearedBlindTierIndex >= BlindTier.small.index
            ? BlindSelectionAvailability.selectable
            : BlindSelectionAvailability.locked,
        lockReason: normalizedClearedBlindTierIndex >= BlindTier.small.index
            ? null
            : '스몰 블라인드 클리어 후 빅 블라인드가 열립니다.',
      ),
      _buildSpec(
        tier: BlindTier.boss,
        stationIndex: normalizedStationIndex,
        difficulty: difficulty,
        ruleset: ruleset,
        availability: normalizedClearedBlindTierIndex >= BlindTier.boss.index
            ? BlindSelectionAvailability.cleared
            : normalizedClearedBlindTierIndex >= BlindTier.big.index
            ? BlindSelectionAvailability.selectable
            : BlindSelectionAvailability.locked,
        lockReason: normalizedClearedBlindTierIndex >= BlindTier.big.index
            ? null
            : '빅 블라인드 클리어 후 보스 블라인드가 열립니다.',
      ),
    ];
  }

  static BlindSelectionSpec resolveSpec({
    required BlindTier tier,
    required int stationIndex,
    required NewRunDifficulty difficulty,
    required RummiRuleset ruleset,
  }) {
    return _buildSpec(
      tier: tier,
      stationIndex: stationIndex,
      difficulty: difficulty,
      ruleset: ruleset,
      availability: BlindSelectionAvailability.selectable,
    );
  }

  static BlindSelectionSpec _buildSpec({
    required BlindTier tier,
    required int stationIndex,
    required NewRunDifficulty difficulty,
    required RummiRuleset ruleset,
    required BlindSelectionAvailability availability,
    String? lockReason,
  }) {
    final baseTarget = _baseTargetForStation(
      stationIndex: stationIndex,
      difficulty: difficulty,
    );
    final baseBoardDiscards = switch (difficulty) {
      NewRunDifficulty.standard => ruleset.defaultBoardDiscards,
      NewRunDifficulty.relaxed => ruleset.defaultBoardDiscards + 1,
      NewRunDifficulty.pressure => ruleset.defaultBoardDiscards - 1,
    };
    final baseHandDiscards = switch (difficulty) {
      NewRunDifficulty.standard => ruleset.defaultHandDiscards,
      NewRunDifficulty.relaxed => ruleset.defaultHandDiscards + 1,
      NewRunDifficulty.pressure => ruleset.defaultHandDiscards - 1,
    };
    final baseHandSize = ruleset.defaultMaxHandSize;
    final rewardBase = RummiRunProgress.stageClearGoldBase;

    final targetScore = switch (tier) {
      BlindTier.small => baseTarget,
      BlindTier.big => (baseTarget * 1.5).round(),
      BlindTier.boss => (baseTarget * 2.0).round(),
    };
    final boardDiscards = switch (tier) {
      BlindTier.small => baseBoardDiscards,
      BlindTier.big => baseBoardDiscards > 1 ? baseBoardDiscards - 1 : 1,
      BlindTier.boss => baseBoardDiscards > 1 ? baseBoardDiscards - 1 : 1,
    };
    final handDiscards = switch (tier) {
      BlindTier.small => baseHandDiscards,
      BlindTier.big => baseHandDiscards,
      BlindTier.boss => baseHandDiscards > 1 ? baseHandDiscards - 1 : 1,
    };
    final maxHandSize = switch (tier) {
      BlindTier.small => baseHandSize,
      BlindTier.big => baseHandSize,
      BlindTier.boss => baseHandSize > 1 ? baseHandSize - 1 : 1,
    };
    final rewardPreview = switch (tier) {
      BlindTier.small => rewardBase,
      BlindTier.big => rewardBase + 4,
      BlindTier.boss => rewardBase + 8,
    };

    return BlindSelectionSpec(
      tier: tier,
      title: switch (tier) {
        BlindTier.small => '스몰 블라인드',
        BlindTier.big => '빅 블라인드',
        BlindTier.boss => '보스 블라인드',
      },
      badgeLabel: switch (tier) {
        BlindTier.small => 'SMALL',
        BlindTier.big => 'BIG',
        BlindTier.boss => 'BOSS',
      },
      description: switch (tier) {
        BlindTier.small => '기본 조건으로 런을 시작합니다.',
        BlindTier.big => '목표 점수를 크게 올리고 보드 버림 여유를 줄입니다.',
        BlindTier.boss => '손패 크기와 버림 여유를 줄인 강한 압박 블라인드입니다.',
      },
      targetScore: targetScore,
      boardDiscards: boardDiscards,
      handDiscards: handDiscards,
      maxHandSize: maxHandSize,
      rewardPreview: rewardPreview,
      availability: availability,
      lockReason: lockReason,
    );
  }

  /// 시장 이후 다음 Station 진입 직전에 선택한 블라인드 조건을 런타임에 반영한다.
  static ActiveRunRuntimeState prepareContinuedRunForSelectedBlind({
    required ActiveRunRuntimeState runtime,
    required BlindTier tier,
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

  static int _baseTargetForStation({
    required int stationIndex,
    required NewRunDifficulty difficulty,
  }) {
    final normalizedStationIndex = stationIndex < 1 ? 1 : stationIndex;
    final stageScaled = normalizedStationIndex <= 1
        ? 300
        : (300 * _pow(1.6, normalizedStationIndex - 1)).floor();
    final scaledTarget = (stageScaled * AppConfig.stationTargetScoreScale)
        .round();
    return switch (difficulty) {
      NewRunDifficulty.standard => scaledTarget,
      NewRunDifficulty.relaxed => (scaledTarget * 0.8).round(),
      NewRunDifficulty.pressure => (scaledTarget * 1.2).round(),
    };
  }

  static double _pow(double base, int exponent) {
    var result = 1.0;
    for (var i = 0; i < exponent; i++) {
      result *= base;
    }
    return result;
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
