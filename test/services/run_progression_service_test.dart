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
      expect(state.isDifficultyUnlocked(NewRunDifficulty.challenge), isFalse);
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
      expect(state.isDifficultyUnlocked(NewRunDifficulty.challenge), isTrue);
      expect(state.insight, 27);
    });

    test('도전 클리어는 추가 난이도를 해금하지 않는다', () async {
      await RunUnlockStateService.unlockDifficulty(NewRunDifficulty.challenge);

      await RunProgressionService.handleRunEnded(
        const RunEndSummary(
          result: RunEndResult.completed,
          difficulty: NewRunDifficulty.challenge,
          reachedStageIndex: 11,
          defeatedBossCount: 4,
        ),
      );

      final state = await RunUnlockStateService.load();
      expect(state.isDifficultyCleared(NewRunDifficulty.challenge), isTrue);
      expect(state.isDifficultyUnlocked(NewRunDifficulty.challenge), isTrue);
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
      expect(state.isDifficultyUnlocked(NewRunDifficulty.challenge), isFalse);
    });

    test('런 종료 시 수집 기록과 기억 카드 획득 이력을 남긴다', () async {
      await RunProgressionService.handleRunEnded(
        const RunEndSummary(
          result: RunEndResult.expired,
          difficulty: NewRunDifficulty.standard,
          reachedStageIndex: 2,
          defeatedBossCount: 1,
          seenMarketJesterIds: {'run_call'},
          seenMarketItemIds: {'coin_cache'},
          boughtJesterIds: {'run_call'},
          boughtItemIds: {'coin_cache'},
          seenBossModifierIds: {'red_dampener_v1'},
          clearedStationKeys: {'station_1'},
        ),
      );

      final state = await RunUnlockStateService.load();

      expect(state.insight, 4);
      expect(state.seenMarketJesterIds, contains('run_call'));
      expect(state.seenMarketItemIds, contains('coin_cache'));
      expect(state.boughtJesterIds, contains('run_call'));
      expect(state.boughtItemIds, contains('coin_cache'));
      expect(state.seenBossModifierIds, contains('red_dampener_v1'));
      expect(state.clearedStationKeys, contains('station_1'));
      expect(
        state.earnedMemoryCardIds,
        contains('memory_card_expired_standard_s2'),
      );
    });
  });
}
