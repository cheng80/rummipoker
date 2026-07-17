import '../logic/rummi_poker_grid/boss_modifier.dart';
import '../logic/rummi_poker_grid/jester_meta.dart';
import '../logic/rummi_poker_grid/rummi_ruleset.dart';
import 'new_run_setup.dart';

enum BlindTier { small, big, boss }

enum BlindSelectionAvailability { selectable, cleared, locked }

enum _BossPoolLevel { entry, early, growthCheck, mid, midLate, late, finalGate }

class _BossStationPool {
  const _BossStationPool({required this.level, required this.modifiers});

  final _BossPoolLevel level;
  final List<RummiBossModifier> modifiers;
}

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
    required this.isEndless,
    this.bossModifier,
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
  final bool isEndless;
  final RummiBossModifier? bossModifier;
  final String? lockReason;

  bool get isSelectable =>
      availability == BlindSelectionAvailability.selectable;
  bool get isCleared => availability == BlindSelectionAvailability.cleared;
  bool get isLocked => availability == BlindSelectionAvailability.locked;
}

/// 앱 UI와 CLI simulator가 공유하는 순수 Blind 선택 spec 계산기.
class BlindSelectionSpecBuilder {
  const BlindSelectionSpecBuilder._();

  static const int finalCoreStationIndex = 8;

  static bool isEndlessStation(int stationIndex) =>
      stationIndex > finalCoreStationIndex;

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
    NewRunModifier runModifier = NewRunModifier.basic,
    int? runSeed,
    required RummiRuleset ruleset,
    RummiBossModifier? bossModifierOverride,
  }) {
    final normalizedStationIndex = stationIndex < 1 ? 1 : stationIndex;
    final normalizedClearedBlindTierIndex = clearedBlindTierIndex.clamp(-1, 2);
    return <BlindSelectionSpec>[
      _buildSpec(
        tier: BlindTier.small,
        stationIndex: normalizedStationIndex,
        difficulty: difficulty,
        runModifier: runModifier,
        runSeed: runSeed,
        ruleset: ruleset,
        availability: normalizedClearedBlindTierIndex >= BlindTier.small.index
            ? BlindSelectionAvailability.cleared
            : BlindSelectionAvailability.selectable,
      ),
      _buildSpec(
        tier: BlindTier.big,
        stationIndex: normalizedStationIndex,
        difficulty: difficulty,
        runModifier: runModifier,
        runSeed: runSeed,
        ruleset: ruleset,
        availability: normalizedClearedBlindTierIndex >= BlindTier.big.index
            ? BlindSelectionAvailability.cleared
            : normalizedClearedBlindTierIndex >= BlindTier.small.index
            ? BlindSelectionAvailability.selectable
            : BlindSelectionAvailability.locked,
        lockReason: normalizedClearedBlindTierIndex >= BlindTier.small.index
            ? null
            : 'Scout 클리어 후 Clash 열림',
      ),
      _buildSpec(
        tier: BlindTier.boss,
        stationIndex: normalizedStationIndex,
        difficulty: difficulty,
        runModifier: runModifier,
        runSeed: runSeed,
        ruleset: ruleset,
        bossModifierOverride: bossModifierOverride,
        availability: normalizedClearedBlindTierIndex >= BlindTier.boss.index
            ? BlindSelectionAvailability.cleared
            : normalizedClearedBlindTierIndex >= BlindTier.big.index
            ? BlindSelectionAvailability.selectable
            : BlindSelectionAvailability.locked,
        lockReason: normalizedClearedBlindTierIndex >= BlindTier.big.index
            ? null
            : 'Clash 클리어 후 Boss 열림',
      ),
    ];
  }

  static BlindSelectionSpec resolveSpec({
    required BlindTier tier,
    required int stationIndex,
    required NewRunDifficulty difficulty,
    NewRunModifier runModifier = NewRunModifier.basic,
    int? runSeed,
    required RummiRuleset ruleset,
    RummiBossModifier? bossModifierOverride,
  }) {
    return _buildSpec(
      tier: tier,
      stationIndex: stationIndex,
      difficulty: difficulty,
      runModifier: runModifier,
      runSeed: runSeed,
      ruleset: ruleset,
      bossModifierOverride: bossModifierOverride,
      availability: BlindSelectionAvailability.selectable,
    );
  }

  static BlindSelectionSpec _buildSpec({
    required BlindTier tier,
    required int stationIndex,
    required NewRunDifficulty difficulty,
    required NewRunModifier runModifier,
    int? runSeed,
    required RummiRuleset ruleset,
    RummiBossModifier? bossModifierOverride,
    required BlindSelectionAvailability availability,
    String? lockReason,
  }) {
    final baseBoardDiscards = switch (difficulty) {
      NewRunDifficulty.standard => ruleset.defaultBoardDiscards,
      NewRunDifficulty.relaxed => ruleset.defaultBoardDiscards + 1,
      NewRunDifficulty.challenge => ruleset.defaultBoardDiscards - 1,
    };
    final baseHandDiscards = switch (difficulty) {
      NewRunDifficulty.standard => ruleset.defaultHandDiscards,
      NewRunDifficulty.relaxed => ruleset.defaultHandDiscards + 1,
      NewRunDifficulty.challenge => ruleset.defaultHandDiscards - 1,
    };
    final baseHandSize = ruleset.defaultMaxHandSize;
    final rewardBase = RummiRunProgress.stageClearGoldBase;
    final isEndless = isEndlessStation(stationIndex);

    final targetScore = _targetScoreForSpec(
      stationIndex: stationIndex,
      tier: tier,
      difficulty: difficulty,
      runModifier: runModifier,
    );
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
    final modifiedRewardPreview = (rewardBase * runModifier.rewardMultiplier)
        .round();

    return BlindSelectionSpec(
      tier: tier,
      title: switch (tier) {
        BlindTier.small => 'Scout',
        BlindTier.big => 'Clash',
        BlindTier.boss => 'Boss',
      },
      badgeLabel: switch (tier) {
        BlindTier.small => 'SCOUT',
        BlindTier.big => 'CLASH',
        BlindTier.boss => 'BOSS',
      },
      description: isEndless
          ? switch (tier) {
              BlindTier.small => '무한 도전의 기본 전투입니다.',
              BlindTier.big => '무한 도전 목표 점수가 1.5배로 오릅니다.',
              BlindTier.boss => '무한 도전 목표 점수가 2배로 오르는 Boss 전투입니다.',
            }
          : switch (tier) {
              BlindTier.small => '기본 조건으로 이번 전투를 시작합니다.',
              BlindTier.big => '목표 점수를 올리고 보드 버림 여유를 줄입니다.',
              BlindTier.boss => '손패 크기와 버림 여유를 줄인 강한 Boss 전투입니다.',
            },
      targetScore: targetScore,
      boardDiscards: boardDiscards,
      handDiscards: handDiscards,
      maxHandSize: maxHandSize,
      rewardPreview: modifiedRewardPreview,
      availability: availability,
      isEndless: isEndless,
      bossModifier: tier == BlindTier.boss
          ? bossModifierOverride ??
                _bossModifierForStation(
                  stationIndex,
                  difficulty: difficulty,
                  runSeed: runSeed,
                )
          : null,
      lockReason: lockReason,
    );
  }

  static RummiBossModifier _bossModifierForStation(
    int stationIndex, {
    required NewRunDifficulty difficulty,
    int? runSeed,
  }) {
    final normalizedStationIndex = stationIndex < 1 ? 1 : stationIndex;
    final pools = _bossStationPoolsForDifficulty(difficulty);
    final pool = pools[(normalizedStationIndex - 1) % pools.length];
    if (runSeed == null) return pool.modifiers.first;
    return pool.modifiers[_bossVariantIndex(
      runSeed: runSeed,
      stationIndex: normalizedStationIndex,
      variantCount: pool.modifiers.length,
    )];
  }

  static List<_BossStationPool> _bossStationPoolsForDifficulty(
    NewRunDifficulty difficulty,
  ) {
    return switch (difficulty) {
      NewRunDifficulty.challenge => _challengeBossStationPools,
      NewRunDifficulty.standard ||
      NewRunDifficulty.relaxed => _standardBossStationPools,
    };
  }

  static const List<_BossStationPool> _standardBossStationPools = [
    _BossStationPool(
      level: _BossPoolLevel.entry,
      modifiers: [
        RummiBossModifier.redDampener,
        RummiBossModifier.yellowDampener,
        RummiBossModifier.rowDampener,
        RummiBossModifier.blueDampener,
        RummiBossModifier.blackDampener,
      ],
    ),
    _BossStationPool(
      level: _BossPoolLevel.early,
      modifiers: [
        RummiBossModifier.rowDampener,
        RummiBossModifier.blueDampener,
        RummiBossModifier.yellowDampener,
        RummiBossModifier.faceDampener,
        RummiBossModifier.redDampener,
      ],
    ),
    _BossStationPool(
      level: _BossPoolLevel.growthCheck,
      modifiers: [
        RummiBossModifier.faceDampener,
        RummiBossModifier.blackDampener,
        RummiBossModifier.blueDampener,
        RummiBossModifier.columnDampener,
        RummiBossModifier.blockRightColumn,
        RummiBossModifier.blockTopRow,
      ],
    ),
    _BossStationPool(
      level: _BossPoolLevel.mid,
      modifiers: [
        RummiBossModifier.columnDampener,
        RummiBossModifier.singleRankPressure,
        RummiBossModifier.repeatRankPressure,
        RummiBossModifier.faceDampener,
        RummiBossModifier.blockLeftColumn,
        RummiBossModifier.blockBottomRow,
        RummiBossModifier.blockFourCorners,
      ],
    ),
    _BossStationPool(
      level: _BossPoolLevel.midLate,
      modifiers: [
        RummiBossModifier.allScoreDampener,
        RummiBossModifier.confirmLimitTax,
        RummiBossModifier.repeatRankPressure,
        RummiBossModifier.singleRankPressure,
        RummiBossModifier.blockCenterRow,
        RummiBossModifier.blockCenterColumn,
      ],
    ),
    _BossStationPool(
      level: _BossPoolLevel.late,
      modifiers: [
        RummiBossModifier.diagonalDampener,
        RummiBossModifier.allScoreDampener,
        RummiBossModifier.firstConfirmTax,
        RummiBossModifier.confirmCountTax,
        RummiBossModifier.blockMainDiagonal,
        RummiBossModifier.blockAntiDiagonal,
      ],
    ),
    _BossStationPool(
      level: _BossPoolLevel.late,
      modifiers: [
        RummiBossModifier.firstConfirmTax,
        RummiBossModifier.confirmCountTax,
        RummiBossModifier.confirmLimitTax,
        RummiBossModifier.allScoreDampener,
        RummiBossModifier.blockMainDiagonal,
        RummiBossModifier.blockAntiDiagonal,
      ],
    ),
    _BossStationPool(
      level: _BossPoolLevel.finalGate,
      modifiers: [
        RummiBossModifier.confirmCountTax,
        RummiBossModifier.allScoreDampener,
        RummiBossModifier.firstConfirmTax,
        RummiBossModifier.confirmLimitTax,
        RummiBossModifier.blockMainDiagonal,
        RummiBossModifier.blockAntiDiagonal,
      ],
    ),
  ];

  static const List<_BossStationPool> _challengeBossStationPools = [
    _BossStationPool(
      level: _BossPoolLevel.entry,
      modifiers: [
        RummiBossModifier.redDampener,
        RummiBossModifier.yellowDampener,
        RummiBossModifier.rowDampener,
        RummiBossModifier.blockRightColumn,
        RummiBossModifier.blockTopRow,
      ],
    ),
    _BossStationPool(
      level: _BossPoolLevel.early,
      modifiers: [
        RummiBossModifier.rowDampener,
        RummiBossModifier.blueDampener,
        RummiBossModifier.yellowDampener,
        RummiBossModifier.faceDampener,
        RummiBossModifier.blockLeftColumn,
      ],
    ),
    _BossStationPool(
      level: _BossPoolLevel.growthCheck,
      modifiers: [
        RummiBossModifier.faceDampener,
        RummiBossModifier.blackDampener,
        RummiBossModifier.blueDampener,
        RummiBossModifier.columnDampener,
        RummiBossModifier.blockBottomRow,
      ],
    ),
    _BossStationPool(
      level: _BossPoolLevel.mid,
      modifiers: [
        RummiBossModifier.columnDampener,
        RummiBossModifier.singleRankPressure,
        RummiBossModifier.repeatRankPressure,
        RummiBossModifier.singleRankPressure,
        RummiBossModifier.blockFourCorners,
        RummiBossModifier.blockCenterColumn,
      ],
    ),
    _BossStationPool(
      level: _BossPoolLevel.midLate,
      modifiers: [
        RummiBossModifier.allScoreDampener,
        RummiBossModifier.confirmLimitTax,
        RummiBossModifier.repeatRankPressure,
        RummiBossModifier.singleRankPressure,
        RummiBossModifier.blockCenterRow,
      ],
    ),
    _BossStationPool(
      level: _BossPoolLevel.late,
      modifiers: [
        RummiBossModifier.diagonalDampener,
        RummiBossModifier.allScoreDampener,
        RummiBossModifier.firstConfirmTax,
        RummiBossModifier.confirmCountTax,
        RummiBossModifier.blockMainDiagonal,
        RummiBossModifier.blockAntiDiagonal,
      ],
    ),
    _BossStationPool(
      level: _BossPoolLevel.late,
      modifiers: [
        RummiBossModifier.firstConfirmTax,
        RummiBossModifier.confirmCountTax,
        RummiBossModifier.confirmLimitTax,
        RummiBossModifier.allScoreDampener,
        RummiBossModifier.blockCenterCross,
        RummiBossModifier.blockCornersCenter,
      ],
    ),
    _BossStationPool(
      level: _BossPoolLevel.finalGate,
      modifiers: [
        RummiBossModifier.confirmCountTax,
        RummiBossModifier.allScoreDampener,
        RummiBossModifier.firstConfirmTax,
        RummiBossModifier.confirmLimitTax,
        RummiBossModifier.blockInnerX,
        RummiBossModifier.blockCheckerA,
        RummiBossModifier.blockCheckerB,
      ],
    ),
  ];

  static int _bossVariantIndex({
    required int runSeed,
    required int stationIndex,
    required int variantCount,
  }) {
    final mixed =
        (runSeed * 1103515245 + stationIndex * 1013904223 + 0x9E3779B9) &
        0x7fffffff;
    return mixed % variantCount;
  }

  static int _targetScoreForSpec({
    required int stationIndex,
    required BlindTier tier,
    required NewRunDifficulty difficulty,
    required NewRunModifier runModifier,
  }) {
    final normalizedStationIndex = stationIndex < 1 ? 1 : stationIndex;
    final standardTarget = _standardTargetScore(
      stationIndex: normalizedStationIndex,
      tier: tier,
    );
    final difficultyTarget = switch (difficulty) {
      NewRunDifficulty.standard => standardTarget,
      NewRunDifficulty.relaxed => (standardTarget * 0.8).round(),
      NewRunDifficulty.challenge => (standardTarget * 1.5).round(),
    };
    return (difficultyTarget * runModifier.targetScoreMultiplier).round();
  }

  static int _standardTargetScore({
    required int stationIndex,
    required BlindTier tier,
  }) {
    const table = <List<int>>[
      [480, 720, 960],
      [650, 1000, 1350],
      [900, 1400, 1900],
      [1250, 2000, 2750],
      [1750, 2850, 3950],
      [2450, 4050, 5650],
      [3450, 5750, 8050],
      [4850, 8150, 11400],
    ];
    if (stationIndex <= table.length) {
      return table[stationIndex - 1][tier.index];
    }
    // S8 이후는 정식 무한 도전 구간이다. Station 기준 점수는 매 구간
    // 상승하고, tier별 목표는 Scout 1배, Clash 1.5배, Boss 2배를 따른다.
    final extraStep = stationIndex - table.length;
    final stationBase =
        (table.last[BlindTier.small.index] * _pow(1.25, extraStep)).round();
    final tierMultiplier = switch (tier) {
      BlindTier.small => 1.0,
      BlindTier.big => 1.5,
      BlindTier.boss => 2.0,
    };
    return (stationBase * tierMultiplier).round();
  }

  static double _pow(double base, int exponent) {
    var result = 1.0;
    for (var i = 0; i < exponent; i++) {
      result *= base;
    }
    return result;
  }
}
