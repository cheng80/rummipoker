import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:rummipoker/app_config.dart';
import 'package:rummipoker/logic/rummi_poker_grid/hand_rank.dart';
import 'package:rummipoker/logic/rummi_poker_grid/models/tile.dart';
import 'package:rummipoker/logic/rummi_poker_grid/rummi_hand_growth.dart';
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
      expect(state.isDifficultyUnlocked(NewRunDifficulty.challenge), isFalse);
      expect(state.isDifficultyCleared(NewRunDifficulty.standard), isFalse);
      expect(state.isDeckAvailable('basic_deck'), isTrue);
      expect(state.isRunModifierUnlocked(NewRunModifier.basic), isTrue);
      expect(state.isRunModifierUnlocked(NewRunModifier.highStakes), isFalse);
      expect(state.insight, 0);
    });

    test('난이도 해금 저장 후 다시 읽을 수 있다', () async {
      await RunUnlockStateService.unlockDifficulty(NewRunDifficulty.challenge);

      final state = await RunUnlockStateService.load();
      expect(state.isDifficultyUnlocked(NewRunDifficulty.challenge), isTrue);
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

    test('런 수집 기록을 저장 후 다시 읽을 수 있다', () async {
      await RunUnlockStateService.recordRunCollection(
        const RunCollectionUpdate(
          seenMarketJesterIds: {'run_call'},
          seenMarketItemIds: {'coin_cache'},
          boughtJesterIds: {'run_call'},
          boughtItemIds: {'coin_cache'},
          seenBossModifierIds: {'red_dampener_v1'},
          clearedStationKeys: {'station_1'},
          earnedMemoryCardIds: {'memory_card_expired_standard_s2'},
        ),
      );

      final state = await RunUnlockStateService.load();

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

    test('challenge 계승 snapshot을 저장 후 다시 읽을 수 있다', () async {
      await RunUnlockStateService.saveChallengeCarryover(
        const ChallengeCarryoverSnapshot(
          playedHandCounts: {RummiHandRank.flush: 3},
          handGrowthStates: {
            RummiHandRank.flush: RummiHandGrowthState(
              level: 4,
              progress: 0,
              requiredProgress: 1,
            ),
          },
          addedDeckTiles: [Tile(color: TileColor.blue, number: 9, id: 1)],
        ),
      );

      final state = await RunUnlockStateService.load();

      expect(
        state.challengeCarryover?.handGrowthStates[RummiHandRank.flush]?.level,
        4,
      );
      expect(
        state.challengeCarryover?.playedHandCounts[RummiHandRank.flush],
        3,
      );
      expect(
        state.challengeCarryover?.addedDeckTiles.single.color,
        TileColor.blue,
      );
    });
  });
}
