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
        ),
      );

      final state = await RunUnlockStateService.load();
      expect(state.isDifficultyUnlocked(NewRunDifficulty.relaxed), isFalse);
      expect(state.isDifficultyCleared(NewRunDifficulty.standard), isFalse);
    });

    test('표준 클리어는 표준 클리어 기록과 다음 난이도 해금을 남긴다', () async {
      await RunProgressionService.handleRunEnded(
        const RunEndSummary(
          result: RunEndResult.completed,
          difficulty: NewRunDifficulty.standard,
          reachedStageIndex: 9,
        ),
      );

      final state = await RunUnlockStateService.load();
      expect(state.isDifficultyCleared(NewRunDifficulty.standard), isTrue);
      expect(state.isDifficultyUnlocked(NewRunDifficulty.relaxed), isTrue);
    });

    test('완화 클리어는 압박 난이도를 해금한다', () async {
      await RunUnlockStateService.unlockDifficulty(
        NewRunDifficulty.relaxed,
      );

      await RunProgressionService.handleRunEnded(
        const RunEndSummary(
          result: RunEndResult.completed,
          difficulty: NewRunDifficulty.relaxed,
          reachedStageIndex: 11,
        ),
      );

      final state = await RunUnlockStateService.load();
      expect(state.isDifficultyCleared(NewRunDifficulty.relaxed), isTrue);
      expect(state.isDifficultyUnlocked(NewRunDifficulty.pressure), isTrue);
    });
  });
}
