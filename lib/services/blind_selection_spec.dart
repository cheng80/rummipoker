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
  }) {
    return _buildSpec(
      tier: tier,
      stationIndex: stationIndex,
      difficulty: difficulty,
      runModifier: runModifier,
      runSeed: runSeed,
      ruleset: ruleset,
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
    final rewardPreview = switch (tier) {
      BlindTier.small => rewardBase,
      BlindTier.big => rewardBase + 4,
      BlindTier.boss => rewardBase + 8,
    };
    final modifiedRewardPreview = (rewardPreview * runModifier.rewardMultiplier)
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
      description: switch (tier) {
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
      bossModifier: tier == BlindTier.boss
          ? _bossModifierForStation(stationIndex, runSeed: runSeed)
          : null,
      lockReason: lockReason,
    );
  }

  static RummiBossModifier _bossModifierForStation(
    int stationIndex, {
    int? runSeed,
  }) {
    final normalizedStationIndex = stationIndex < 1 ? 1 : stationIndex;
    final pool =
        _bossStationPools[(normalizedStationIndex - 1) %
            _bossStationPools.length];
    if (runSeed == null) return pool.modifiers.first;
    return pool.modifiers[_bossVariantIndex(
      runSeed: runSeed,
      stationIndex: normalizedStationIndex,
      variantCount: pool.modifiers.length,
    )];
  }

  static const List<_BossStationPool> _bossStationPools = [
    _BossStationPool(
      level: _BossPoolLevel.entry,
      modifiers: [
        RummiBossModifier.redDampener,
        RummiBossModifier.yellowDampener,
        RummiBossModifier.rowDampener,
      ],
    ),
    _BossStationPool(
      level: _BossPoolLevel.early,
      modifiers: [
        RummiBossModifier.rowDampener,
        RummiBossModifier.blueDampener,
        RummiBossModifier.yellowDampener,
        RummiBossModifier.faceDampener,
      ],
    ),
    _BossStationPool(
      level: _BossPoolLevel.growthCheck,
      modifiers: [
        RummiBossModifier.faceDampener,
        RummiBossModifier.blackDampener,
        RummiBossModifier.blueDampener,
        RummiBossModifier.columnDampener,
      ],
    ),
    _BossStationPool(
      level: _BossPoolLevel.mid,
      modifiers: [
        RummiBossModifier.columnDampener,
        RummiBossModifier.singleRankPressure,
        RummiBossModifier.repeatRankPressure,
        RummiBossModifier.singleRankPressure,
      ],
    ),
    _BossStationPool(
      level: _BossPoolLevel.midLate,
      modifiers: [
        RummiBossModifier.allScoreDampener,
        RummiBossModifier.confirmLimitTax,
        RummiBossModifier.repeatRankPressure,
        RummiBossModifier.singleRankPressure,
      ],
    ),
    _BossStationPool(
      level: _BossPoolLevel.late,
      modifiers: [
        RummiBossModifier.diagonalDampener,
        RummiBossModifier.allScoreDampener,
        RummiBossModifier.firstConfirmTax,
        RummiBossModifier.confirmCountTax,
      ],
    ),
    _BossStationPool(
      level: _BossPoolLevel.late,
      modifiers: [
        RummiBossModifier.firstConfirmTax,
        RummiBossModifier.confirmCountTax,
        RummiBossModifier.confirmLimitTax,
        RummiBossModifier.allScoreDampener,
      ],
    ),
    _BossStationPool(
      level: _BossPoolLevel.finalGate,
      modifiers: [
        RummiBossModifier.confirmCountTax,
        RummiBossModifier.allScoreDampener,
        RummiBossModifier.firstConfirmTax,
        RummiBossModifier.confirmLimitTax,
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
      NewRunDifficulty.challenge => (standardTarget * 1.2).round(),
    };
    return (difficultyTarget * runModifier.targetScoreMultiplier).round();
  }

  static int _standardTargetScore({
    required int stationIndex,
    required BlindTier tier,
  }) {
    const table = <List<int>>[
      [240, 264, 265],
      [372, 431, 439],
      [463, 537, 547],
      [580, 672, 685],
      [725, 841, 857],
      [923, 1112, 1121],
      [1154, 1391, 1401],
      [1441, 1738, 1739],
    ];
    if (stationIndex <= table.length) {
      return table[stationIndex - 1][tier.index];
    }
    // S8 이후는 아직 실제 진행 구간 밖이다. 테스트/디버그용으로만
    // 마지막 구간 성장률을 이어 붙여 target 단조 증가를 보장한다.
    final extraStep = stationIndex - table.length;
    final base = table.last[tier.index];
    return (base * _pow(1.25, extraStep)).round();
  }

  static double _pow(double base, int exponent) {
    var result = 1.0;
    for (var i = 0; i < exponent; i++) {
      result *= base;
    }
    return result;
  }
}
