import 'new_run_setup.dart';
import 'run_unlock_state_service.dart';

enum RunEndResult { expired, retired, completed }

class RunEndSummary {
  const RunEndSummary({
    required this.result,
    required this.difficulty,
    required this.reachedStageIndex,
    this.defeatedBossCount = 0,
  });

  final RunEndResult result;
  final NewRunDifficulty difficulty;
  final int reachedStageIndex;
  final int defeatedBossCount;
}

class RunProgressionService {
  RunProgressionService._();

  static Future<void> handleRunEnded(RunEndSummary summary) async {
    await RunUnlockStateService.addInsight(calculateInsightReward(summary));

    if (summary.result != RunEndResult.completed) {
      return;
    }

    await RunUnlockStateService.markDifficultyCleared(summary.difficulty);

    final nextDifficulty = _nextDifficulty(summary.difficulty);
    if (nextDifficulty == null) {
      return;
    }
    await RunUnlockStateService.unlockDifficulty(nextDifficulty);
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
      NewRunDifficulty.standard => NewRunDifficulty.relaxed,
      NewRunDifficulty.relaxed => NewRunDifficulty.pressure,
      NewRunDifficulty.pressure => null,
    };
  }
}
