import '../logic/rummi_poker_grid/hand_rank.dart';
import '../logic/rummi_poker_grid/models/tile.dart';
import '../logic/rummi_poker_grid/rummi_hand_growth.dart';
import 'new_run_setup.dart';
import 'run_unlock_state_service.dart';

enum RunEndResult { expired, retired, completed }

class RunEndSummary {
  const RunEndSummary({
    required this.result,
    required this.difficulty,
    required this.reachedStageIndex,
    this.defeatedBossCount = 0,
    this.seenMarketJesterIds = const <String>{},
    this.seenMarketItemIds = const <String>{},
    this.boughtJesterIds = const <String>{},
    this.boughtItemIds = const <String>{},
    this.seenBossModifierIds = const <String>{},
    this.clearedStationKeys = const <String>{},
    this.playedHandCounts = const <RummiHandRank, int>{},
    this.handGrowthStates = const <RummiHandRank, RummiHandGrowthState>{},
    this.addedDeckTiles = const <Tile>[],
  });

  final RunEndResult result;
  final NewRunDifficulty difficulty;
  final int reachedStageIndex;
  final int defeatedBossCount;
  final Set<String> seenMarketJesterIds;
  final Set<String> seenMarketItemIds;
  final Set<String> boughtJesterIds;
  final Set<String> boughtItemIds;
  final Set<String> seenBossModifierIds;
  final Set<String> clearedStationKeys;
  final Map<RummiHandRank, int> playedHandCounts;
  final Map<RummiHandRank, RummiHandGrowthState> handGrowthStates;
  final List<Tile> addedDeckTiles;
}

class RunProgressionService {
  RunProgressionService._();

  static Future<void> handleRunEnded(
    RunEndSummary summary, {
    String? runClaimId,
  }) async {
    if (summary.result == RunEndResult.completed && runClaimId == null) {
      throw StateError('Completed run requires a stable claim ID.');
    }
    final memoryCardReward = calculateInsightReward(summary);
    if (summary.result == RunEndResult.completed) {
      await RunUnlockStateService.claimInsight(runClaimId!, memoryCardReward);
    } else {
      await RunUnlockStateService.addInsight(memoryCardReward);
    }
    await RunUnlockStateService.recordRunCollection(
      RunCollectionUpdate(
        seenMarketJesterIds: summary.seenMarketJesterIds,
        seenMarketItemIds: summary.seenMarketItemIds,
        boughtJesterIds: summary.boughtJesterIds,
        boughtItemIds: summary.boughtItemIds,
        seenBossModifierIds: summary.seenBossModifierIds,
        clearedStationKeys: summary.clearedStationKeys,
        earnedMemoryCardIds: memoryCardReward <= 0
            ? const <String>{}
            : <String>{_memoryCardId(summary)},
      ),
    );

    if (summary.result != RunEndResult.completed) {
      return;
    }

    await RunUnlockStateService.markDifficultyCleared(summary.difficulty);

    final nextDifficulty = _nextDifficulty(summary.difficulty);
    if (nextDifficulty == null) {
      return;
    }
    await RunUnlockStateService.unlockDifficulty(nextDifficulty);
    if (summary.difficulty == NewRunDifficulty.standard) {
      await RunUnlockStateService.saveChallengeCarryover(
        ChallengeCarryoverSnapshot(
          playedHandCounts: summary.playedHandCounts,
          handGrowthStates: summary.handGrowthStates,
          addedDeckTiles: summary.addedDeckTiles,
        ),
      );
    }
  }

  static int calculateInsightReward(RunEndSummary summary) {
    final stageReward = summary.reachedStageIndex < 0
        ? 0
        : summary.reachedStageIndex;
    final bossReward = summary.defeatedBossCount < 0
        ? 0
        : summary.defeatedBossCount * 2;
    final clearReward = summary.result == RunEndResult.completed ? 12 : 0;
    return stageReward + bossReward + clearReward;
  }

  static NewRunDifficulty? _nextDifficulty(NewRunDifficulty difficulty) {
    return switch (difficulty) {
      NewRunDifficulty.standard => NewRunDifficulty.challenge,
      NewRunDifficulty.relaxed => null,
      NewRunDifficulty.challenge => null,
    };
  }

  static String _memoryCardId(RunEndSummary summary) {
    final result = summary.result.name;
    final station = summary.reachedStageIndex < 0
        ? 0
        : summary.reachedStageIndex;
    return 'memory_card_${result}_${summary.difficulty.name}_s$station';
  }
}
