import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:rummipoker/services/new_run_setup.dart';
import 'package:rummipoker/services/run_progression_service.dart';
import 'package:rummipoker/services/run_unlock_state_service.dart';
import 'package:rummipoker/utils/storage_helper.dart';

void main() {
  group('Run completion flow', () {
    setUp(() async {
      StorageHelper.resetForTest();
      SharedPreferences.setMockInitialValues(<String, Object>{});
      await StorageHelper.init();
    });

    test('completed 결과를 전달하면 다음 난이도가 해금된다', () async {
      await RunProgressionService.handleRunEnded(
        const RunEndSummary(
          result: RunEndResult.completed,
          difficulty: NewRunDifficulty.standard,
          reachedStageIndex: 4,
        ),
      );

      final state = await RunUnlockStateService.load();
      expect(state.isDifficultyCleared(NewRunDifficulty.standard), isTrue);
      expect(state.isDifficultyUnlocked(NewRunDifficulty.relaxed), isTrue);
    });
  });
}
