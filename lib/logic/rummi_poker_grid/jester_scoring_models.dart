part of 'jester_meta.dart';

class RummiJesterScoreContext {
  const RummiJesterScoreContext({
    required this.discardsRemaining,
    required this.cardsRemainingInDeck,
    required this.ownedJesterCount,
    this.maxJesterSlots = RummiRunProgress.maxJesterSlots,
    this.stateValue = 0,
    this.currentHandPlayedCount = 0,
  });

  final int discardsRemaining;
  final int cardsRemainingInDeck;
  final int ownedJesterCount;
  final int maxJesterSlots;
  final int stateValue;
  final int currentHandPlayedCount;
}

class RummiJesterRuntimeSnapshot {
  const RummiJesterRuntimeSnapshot({
    this.slotStateValues = const {},
    this.playedHandCounts = const {},
    this.handGrowthStates = const {},
  });

  final Map<int, int> slotStateValues;
  final Map<RummiHandRank, int> playedHandCounts;
  final Map<RummiHandRank, RummiHandGrowthState> handGrowthStates;

  int stateValueForSlot(int slotIndex) => slotStateValues[slotIndex] ?? 0;

  int playedCountForRank(RummiHandRank rank) => playedHandCounts[rank] ?? 0;

  RummiHandGrowthState growthStateForRank(RummiHandRank rank) {
    return handGrowthStates[rank] ?? RummiHandGrowthState.initial(rank);
  }
}

class RummiLineScore {
  const RummiLineScore({
    required this.baseScore,
    required this.chipsBonus,
    required this.multBonus,
    required this.xmultBonus,
    required this.finalScore,
    this.effect,
  });

  final int baseScore;
  final int chipsBonus;
  final int multBonus;
  final double xmultBonus;
  final int finalScore;
  final RummiJesterEffectBreakdown? effect;
}

class RummiJesterEffectBreakdown {
  const RummiJesterEffectBreakdown({
    required this.jesterId,
    required this.displayName,
    required this.chipsBonus,
    required this.multBonus,
    required this.xmultBonus,
    required this.scoreDelta,
  });

  final String jesterId;
  final String displayName;
  final int chipsBonus;
  final int multBonus;
  final double xmultBonus;
  final int scoreDelta;

  bool get hasIntegerMultiplierToken =>
      xmultBonus > 1.0 && (xmultBonus - xmultBonus.round()).abs() < 0.05;

  int get multPercentBonus => multBonus * 5;

  String get displayToken {
    if (hasIntegerMultiplierToken) {
      return '점수 x${xmultBonus.round()}';
    }
    if (xmultBonus > 1.0) {
      return '점수 x${xmultBonus.toStringAsFixed(1)}';
    }
    if (chipsBonus > 0) {
      return '+$chipsBonus';
    }
    if (multBonus > 0) {
      return '+$multPercentBonus%';
    }
    return '+$scoreDelta';
  }

  String get displaySuffix {
    if (xmultBonus > 1.0) {
      return '';
    }
    if (chipsBonus > 0) {
      return '칩';
    }
    if (multBonus > 0) {
      return '점수';
    }
    return '점수';
  }
}
