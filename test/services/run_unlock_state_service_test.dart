import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:rummipoker/app_config.dart';
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
      expect(state.isRunModifierUnlocked(NewRunModifier.basic), isTrue);
      expect(state.isRunModifierUnlocked(NewRunModifier.highStakes), isFalse);
      expect(state.insight, 0);
    });

    test('난이도 해금 저장 후 다시 읽을 수 있다', () async {
      await RunUnlockStateService.unlockDifficulty(NewRunDifficulty.relaxed);

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

    test('기존 해금 저장에 insight가 없어도 0으로 복원한다', () async {
      await StorageHelper.write(
        StorageKeys.runUnlockStateV1,
        '{"unlockedDifficultyNames":["standard"],'
        '"clearedDifficultyNames":[],'
        '"availableDeckIds":["basic_deck"]}',
      );

      final state = await RunUnlockStateService.load();
      expect(state.insight, 0);
      expect(state.isRunModifierUnlocked(NewRunModifier.basic), isTrue);
      expect(state.isRunModifierUnlocked(NewRunModifier.highStakes), isFalse);
    });

    test('insight를 사용해 high stakes modifier를 해금한다', () async {
      await RunUnlockStateService.addInsight(25);

      final unlocked = await RunUnlockStateService.unlockRunModifier(
        NewRunModifier.highStakes,
      );

      final state = await RunUnlockStateService.load();
      expect(unlocked, isTrue);
      expect(state.insight, 5);
      expect(state.isRunModifierUnlocked(NewRunModifier.highStakes), isTrue);
    });

    test('insight가 부족하면 high stakes modifier를 해금하지 않는다', () async {
      await RunUnlockStateService.addInsight(19);

      final unlocked = await RunUnlockStateService.unlockRunModifier(
        NewRunModifier.highStakes,
      );

      final state = await RunUnlockStateService.load();
      expect(unlocked, isFalse);
      expect(state.insight, 19);
      expect(state.isRunModifierUnlocked(NewRunModifier.highStakes), isFalse);
    });
  });
}
