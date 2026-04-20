import 'new_run_setup.dart';
import 'run_unlock_state_service.dart';

enum RunEndResult { expired, retired, completed }

class RunEndSummary {
  const RunEndSummary({
    required this.result,
    required this.difficulty,
    required this.reachedStageIndex,
  });

  final RunEndResult result;
  final NewRunDifficulty difficulty;
  final int reachedStageIndex;
}

class RunProgressionService {
  RunProgressionService._();

  static Future<void> handleRunEnded(RunEndSummary summary) async {
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

  static NewRunDifficulty? _nextDifficulty(NewRunDifficulty difficulty) {
    return switch (difficulty) {
      NewRunDifficulty.standard => NewRunDifficulty.relaxed,
      NewRunDifficulty.relaxed => NewRunDifficulty.pressure,
      NewRunDifficulty.pressure => null,
    };
  }
}
