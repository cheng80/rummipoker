import 'hand_rank.dart';

class RummiHandGrowthState {
  const RummiHandGrowthState({
    required this.level,
    required this.progress,
    required this.requiredProgress,
  });

  factory RummiHandGrowthState.initial(RummiHandRank rank) {
    if (!RummiHandGrowth.grows(rank)) {
      return const RummiHandGrowthState(
        level: 0,
        progress: 0,
        requiredProgress: 0,
      );
    }
    return RummiHandGrowthState(
      level: 1,
      progress: 0,
      requiredProgress: RummiHandGrowth.requiredProgressForLevel(
        rank: rank,
        level: 1,
      ),
    );
  }

  factory RummiHandGrowthState.fromCompletedCount(
    RummiHandRank rank,
    int completedCount,
  ) {
    if (!RummiHandGrowth.grows(rank)) {
      return RummiHandGrowthState.initial(rank);
    }
    return RummiHandGrowthState(
      level: RummiHandGrowth.levelForCompletedCount(rank, completedCount),
      progress: 0,
      requiredProgress: RummiHandGrowth.requiredProgressForLevel(
        rank: rank,
        level: RummiHandGrowth.levelForCompletedCount(rank, completedCount),
      ),
    );
  }

  factory RummiHandGrowthState.fromJson(
    RummiHandRank rank,
    Map<String, dynamic> json,
  ) {
    if (!RummiHandGrowth.grows(rank)) {
      return RummiHandGrowthState.initial(rank);
    }
    final rawLevel = (json['level'] as num?)?.toInt() ?? 1;
    final level = rawLevel < 1 ? 1 : rawLevel;
    final requiredProgress =
        (json['requiredProgress'] as num?)?.toInt() ??
        RummiHandGrowth.requiredProgressForLevel(rank: rank, level: level);
    final safeRequired = requiredProgress <= 0 ? 1 : requiredProgress;
    final rawProgress = (json['progress'] as num?)?.toInt() ?? 0;
    return RummiHandGrowthState(
      level: level,
      progress: rawProgress.clamp(0, safeRequired - 1),
      requiredProgress: safeRequired,
    );
  }

  final int level;
  final int progress;
  final int requiredProgress;

  Map<String, dynamic> toJson() => {
    'level': level,
    'progress': progress,
    'requiredProgress': requiredProgress,
  };

  RummiHandGrowthState addProgress(RummiHandRank rank, int amount) {
    if (amount <= 0 || !RummiHandGrowth.grows(rank)) return this;
    var nextLevel = level < 1 ? 1 : level;
    var nextRequired = requiredProgress <= 0
        ? RummiHandGrowth.requiredProgressForLevel(rank: rank, level: nextLevel)
        : requiredProgress;
    var nextProgress = progress + amount;
    while (nextProgress >= nextRequired) {
      nextProgress -= nextRequired;
      nextLevel += 1;
      nextRequired = RummiHandGrowth.requiredProgressForLevel(
        rank: rank,
        level: nextLevel,
      );
    }
    return RummiHandGrowthState(
      level: nextLevel,
      progress: nextProgress,
      requiredProgress: nextRequired,
    );
  }
}

/// 현재 run 안에서 족보 완성 횟수를 레벨과 점수 보정으로 바꾼다.
class RummiHandGrowth {
  const RummiHandGrowth._();

  static const List<RummiHandRank> scoringRanks = [
    RummiHandRank.twoPair,
    RummiHandRank.threeOfAKind,
    RummiHandRank.straight,
    RummiHandRank.flush,
    RummiHandRank.fullHouse,
    RummiHandRank.fourOfAKind,
    RummiHandRank.straightFlush,
  ];

  static const List<RummiHandRank> hiddenRanks = [
    RummiHandRank.prismStraight,
    RummiHandRank.crownFourOfAKind,
    RummiHandRank.lowStraightFlush,
    RummiHandRank.royalStraightFlush,
    RummiHandRank.fiveOfAKind,
    RummiHandRank.flushHouse,
    RummiHandRank.flushFive,
  ];

  static bool grows(RummiHandRank rank) => !isDeadLineRank(rank);

  static int requiredProgressForLevel({
    required RummiHandRank rank,
    required int level,
  }) {
    if (!grows(rank)) return 0;
    return 1;
  }

  static int levelForCompletedCount(RummiHandRank rank, int completedCount) {
    if (!grows(rank)) return 0;
    return 1 + completedCount.clamp(0, 999999);
  }

  static int growthStepFor(RummiHandRank rank) => switch (rank) {
    RummiHandRank.twoPair => 5,
    RummiHandRank.threeOfAKind => 8,
    RummiHandRank.straight => 14,
    RummiHandRank.flush => 10,
    RummiHandRank.fullHouse => 16,
    RummiHandRank.fourOfAKind => 20,
    RummiHandRank.straightFlush => 30,
    RummiHandRank.prismStraight => 18,
    RummiHandRank.crownFourOfAKind => 26,
    RummiHandRank.lowStraightFlush => 36,
    RummiHandRank.royalStraightFlush => 40,
    RummiHandRank.fiveOfAKind => 44,
    RummiHandRank.flushHouse => 48,
    RummiHandRank.flushFive => 52,
    RummiHandRank.highCard || RummiHandRank.onePair => 0,
  };

  static int growthBonusFor({
    required RummiHandRank rank,
    required int completedCount,
  }) {
    return growthBonusForState(
      rank: rank,
      state: RummiHandGrowthState.fromCompletedCount(rank, completedCount),
    );
  }

  static int growthBonusForState({
    required RummiHandRank rank,
    required RummiHandGrowthState state,
  }) {
    if (!grows(rank)) return 0;
    final levelBonus = (state.level - 1).clamp(0, 999999);
    return levelBonus * growthStepFor(rank);
  }

  static int grownBaseScoreFor({
    required RummiHandRank rank,
    required int baseScore,
    required int completedCount,
  }) {
    return grownBaseScoreForState(
      rank: rank,
      baseScore: baseScore,
      state: RummiHandGrowthState.fromCompletedCount(rank, completedCount),
    );
  }

  static int grownBaseScoreForState({
    required RummiHandRank rank,
    required int baseScore,
    required RummiHandGrowthState state,
  }) {
    return baseScore + growthBonusForState(rank: rank, state: state);
  }

  static int completedCountFor(
    Map<RummiHandRank, int> counts,
    RummiHandRank rank,
  ) {
    final count = counts[rank] ?? 0;
    return count < 0 ? 0 : count;
  }
}
