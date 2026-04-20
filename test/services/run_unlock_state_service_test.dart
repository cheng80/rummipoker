import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:rummipoker/services/new_run_setup.dart';
import 'package:rummipoker/services/run_unlock_state_service.dart';
import 'package:rummipoker/utils/storage_helper.dart';

void main() {
  group('RunUnlockStateService', () {
    setUp(() async {
      StorageHelper.resetForTest();
      SharedPreferences.setMockInitialValues(<String, Object>{});
      await StorageHelper.init();
    });

    test('초기 로드 시 기본 해금 상태를 만든다', () async {
      final state = await RunUnlockStateService.load();

      expect(state.isDifficultyUnlocked(NewRunDifficulty.standard), isTrue);
      expect(state.isDifficultyUnlocked(NewRunDifficulty.relaxed), isFalse);
      expect(state.isDifficultyCleared(NewRunDifficulty.standard), isFalse);
      expect(state.isDeckAvailable('basic_deck'), isTrue);
    });

    test('난이도 해금 저장 후 다시 읽을 수 있다', () async {
      await RunUnlockStateService.unlockDifficulty(
        NewRunDifficulty.relaxed,
      );

      final state = await RunUnlockStateService.load();
      expect(state.isDifficultyUnlocked(NewRunDifficulty.relaxed), isTrue);
      expect(state.isDifficultyUnlocked(NewRunDifficulty.pressure), isFalse);
    });

    test('클리어한 난이도 이력을 따로 저장한다', () async {
      await RunUnlockStateService.markDifficultyCleared(
        NewRunDifficulty.standard,
      );

      final state = await RunUnlockStateService.load();
      expect(state.isDifficultyCleared(NewRunDifficulty.standard), isTrue);
      expect(state.isDifficultyUnlocked(NewRunDifficulty.standard), isTrue);
    });
  });
}
