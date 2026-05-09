import 'hand_rank.dart';

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

  static bool grows(RummiHandRank rank) => !isDeadLineRank(rank);

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
    RummiHandRank.highCard || RummiHandRank.onePair => 0,
  };

  static int growthBonusFor({
    required RummiHandRank rank,
    required int completedCount,
  }) {
    if (!grows(rank)) return 0;
    final safeCount = completedCount.clamp(0, 999999);
    return safeCount * growthStepFor(rank);
  }

  static int grownBaseScoreFor({
    required RummiHandRank rank,
    required int baseScore,
    required int completedCount,
  }) {
    return baseScore +
        growthBonusFor(rank: rank, completedCount: completedCount);
  }

  static int completedCountFor(
    Map<RummiHandRank, int> counts,
    RummiHandRank rank,
  ) {
    final count = counts[rank] ?? 0;
    return count < 0 ? 0 : count;
  }
}
