import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:rummipoker/services/new_run_setup.dart';
import 'package:rummipoker/services/run_progression_service.dart';
import 'package:rummipoker/services/run_unlock_state_service.dart';
import 'package:rummipoker/utils/storage_helper.dart';

void main() {
  group('RunProgressionService', () {
    setUp(() async {
      StorageHelper.resetForTest();
      SharedPreferences.setMockInitialValues(<String, Object>{});
      await StorageHelper.init();
    });

    test('패배 종료는 해금 상태를 바꾸지 않는다', () async {
      await RunProgressionService.handleRunEnded(
        const RunEndSummary(
          result: RunEndResult.expired,
          difficulty: NewRunDifficulty.standard,
          reachedStageIndex: 2,
          defeatedBossCount: 0,
        ),
      );

      final state = await RunUnlockStateService.load();
      expect(state.isDifficultyUnlocked(NewRunDifficulty.relaxed), isFalse);
      expect(state.isDifficultyCleared(NewRunDifficulty.standard), isFalse);
      expect(state.insight, 2);
    });

    test('표준 클리어는 표준 클리어 기록과 다음 난이도 해금을 남긴다', () async {
      await RunProgressionService.handleRunEnded(
        const RunEndSummary(
          result: RunEndResult.completed,
          difficulty: NewRunDifficulty.standard,
          reachedStageIndex: 9,
          defeatedBossCount: 3,
        ),
      );

      final state = await RunUnlockStateService.load();
      expect(state.isDifficultyCleared(NewRunDifficulty.standard), isTrue);
      expect(state.isDifficultyUnlocked(NewRunDifficulty.relaxed), isTrue);
      expect(state.insight, 27);
    });

    test('완화 클리어는 압박 난이도를 해금한다', () async {
      await RunUnlockStateService.unlockDifficulty(NewRunDifficulty.relaxed);

      await RunProgressionService.handleRunEnded(
        const RunEndSummary(
          result: RunEndResult.completed,
          difficulty: NewRunDifficulty.relaxed,
          reachedStageIndex: 11,
          defeatedBossCount: 4,
        ),
      );

      final state = await RunUnlockStateService.load();
      expect(state.isDifficultyCleared(NewRunDifficulty.relaxed), isTrue);
      expect(state.isDifficultyUnlocked(NewRunDifficulty.pressure), isTrue);
      expect(state.insight, 31);
    });

    test('retire 보상은 누적되지만 난이도를 해금하지 않는다', () async {
      await RunProgressionService.handleRunEnded(
        const RunEndSummary(
          result: RunEndResult.expired,
          difficulty: NewRunDifficulty.standard,
          reachedStageIndex: 2,
          defeatedBossCount: 1,
        ),
      );
      await RunProgressionService.handleRunEnded(
        const RunEndSummary(
          result: RunEndResult.retired,
          difficulty: NewRunDifficulty.standard,
          reachedStageIndex: 4,
          defeatedBossCount: 1,
        ),
      );

      final state = await RunUnlockStateService.load();
      expect(state.insight, 10);
      expect(state.isDifficultyUnlocked(NewRunDifficulty.relaxed), isFalse);
    });
  });
}
