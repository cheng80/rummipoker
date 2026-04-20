import 'package:flutter_test/flutter_test.dart';

import 'package:rummipoker/logic/rummi_poker_grid/jester_meta.dart';
import 'package:rummipoker/logic/rummi_poker_grid/rummi_ruleset.dart';
import 'package:rummipoker/logic/rummi_poker_grid/rummi_poker_grid_session.dart';
import 'package:rummipoker/services/blind_selection_setup.dart';
import 'package:rummipoker/services/active_run_save_service.dart';
import 'package:rummipoker/services/new_run_setup.dart';

void main() {
  group('BlindSelectionSetup', () {
    test('station 1에서는 small만 열리고 big/boss는 잠긴다', () {
      final options = BlindSelectionSetup.buildForStation(
        stationIndex: 1,
        clearedBlindTierIndex: -1,
        difficulty: NewRunDifficulty.standard,
        ruleset: RummiRuleset.currentDefaults,
      );

      expect(options[0].tier, BlindTier.small);
      expect(options[0].availability, BlindSelectionAvailability.selectable);
      expect(options[1].tier, BlindTier.big);
      expect(options[1].availability, BlindSelectionAvailability.locked);
      expect(options[2].tier, BlindTier.boss);
      expect(options[2].availability, BlindSelectionAvailability.locked);
    });

    test('station 2에서는 small은 clear 비활성이고 big만 선택 가능하다', () {
      final options = BlindSelectionSetup.buildForStation(
        stationIndex: 1,
        clearedBlindTierIndex: 0,
        difficulty: NewRunDifficulty.standard,
        ruleset: RummiRuleset.currentDefaults,
      );

      expect(options[0].availability, BlindSelectionAvailability.cleared);
      expect(options[1].availability, BlindSelectionAvailability.selectable);
      expect(options[2].availability, BlindSelectionAvailability.locked);
    });

    test('big까지 클리어한 같은 station에서는 boss가 열린다', () {
      final options = BlindSelectionSetup.buildForStation(
        stationIndex: 1,
        clearedBlindTierIndex: 1,
        difficulty: NewRunDifficulty.standard,
        ruleset: RummiRuleset.currentDefaults,
      );

      expect(options[0].availability, BlindSelectionAvailability.cleared);
      expect(options[1].availability, BlindSelectionAvailability.cleared);
      expect(options[2].availability, BlindSelectionAvailability.selectable);
    });

    test('boss 클리어 후 blind select runtime은 다음 station small 시작 상태로 리셋된다', () {
      final runtime = ActiveRunRuntimeState(
        activeScene: ActiveRunScene.blindSelect,
        difficulty: NewRunDifficulty.standard,
        session: RummiPokerGridSession(runSeed: 77),
        runProgress: RummiRunProgress()
          ..stageIndex = 1
          ..currentStationBlindTierIndex = 2,
        stageStartSnapshot: ActiveRunStageSnapshot(
          session: RummiPokerGridSession(runSeed: 77),
          runProgress: RummiRunProgress(),
        ),
      );

      final prepared = BlindSelectionSetup.prepareRuntimeForBlindSelect(
        runtime: runtime,
      );

      expect(prepared.runProgress.stageIndex, 2);
      expect(prepared.runProgress.currentStationBlindTierIndex, -1);

      final options = BlindSelectionSetup.buildForStation(
        stationIndex: prepared.runProgress.stageIndex,
        clearedBlindTierIndex:
            prepared.runProgress.currentStationBlindTierIndex,
        difficulty: prepared.difficulty,
        ruleset: prepared.session.ruleset,
      );

      expect(options[0].availability, BlindSelectionAvailability.selectable);
      expect(options[1].availability, BlindSelectionAvailability.locked);
      expect(options[2].availability, BlindSelectionAvailability.locked);
    });

    test('station이 올라가면 같은 tier의 목표 점수도 함께 오른다', () {
      final stationOne = BlindSelectionSetup.resolveSpec(
        tier: BlindTier.small,
        stationIndex: 1,
        difficulty: NewRunDifficulty.standard,
        ruleset: RummiRuleset.currentDefaults,
      );
      final stationTwo = BlindSelectionSetup.resolveSpec(
        tier: BlindTier.small,
        stationIndex: 2,
        difficulty: NewRunDifficulty.standard,
        ruleset: RummiRuleset.currentDefaults,
      );

      expect(stationTwo.targetScore, greaterThan(stationOne.targetScore));
    });
  });
}
