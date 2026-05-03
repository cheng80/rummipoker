import 'package:flutter_test/flutter_test.dart';

import 'package:rummipoker/logic/rummi_poker_grid/item_definition.dart';
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
      expect(options[2].bossModifier?.title, '빨간 타일 약화');
    });

    test('station별 boss modifier는 deterministic하게 순환한다', () {
      final station1 = BlindSelectionSetup.buildForStation(
        stationIndex: 1,
        clearedBlindTierIndex: 1,
        difficulty: NewRunDifficulty.standard,
        ruleset: RummiRuleset.currentDefaults,
      );
      final station2 = BlindSelectionSetup.buildForStation(
        stationIndex: 2,
        clearedBlindTierIndex: 1,
        difficulty: NewRunDifficulty.standard,
        ruleset: RummiRuleset.currentDefaults,
      );

      expect(station1[2].bossModifier?.id, 'red_dampener_v1');
      expect(station2[2].bossModifier?.id, 'row_line_dampener_v1');
      expect(station2[2].bossModifier?.title, '가로줄 약화');
    });

    test('station별 boss modifier는 실제 표현 가능한 후보 풀을 순환한다', () {
      final bossModifierIds = List.generate(8, (index) {
        final boss = BlindSelectionSetup.resolveSpec(
          tier: BlindTier.boss,
          stationIndex: index + 1,
          difficulty: NewRunDifficulty.standard,
          ruleset: RummiRuleset.currentDefaults,
        );
        return boss.bossModifier?.id;
      });

      expect(bossModifierIds, [
        'red_dampener_v1',
        'row_line_dampener_v1',
        'face_tile_dampener_v1',
        'column_line_dampener_v1',
        'all_score_dampener_v1',
        'diagonal_line_dampener_v1',
        'first_confirm_tax_v1',
        'confirm_count_tax_v2',
      ]);
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

    test('station 1 boss는 유입 구간용 target table을 따른다', () {
      final small = BlindSelectionSetup.resolveSpec(
        tier: BlindTier.small,
        stationIndex: 1,
        difficulty: NewRunDifficulty.standard,
        ruleset: RummiRuleset.currentDefaults,
      );
      final big = BlindSelectionSetup.resolveSpec(
        tier: BlindTier.big,
        stationIndex: 1,
        difficulty: NewRunDifficulty.standard,
        ruleset: RummiRuleset.currentDefaults,
      );
      final boss = BlindSelectionSetup.resolveSpec(
        tier: BlindTier.boss,
        stationIndex: 1,
        difficulty: NewRunDifficulty.standard,
        ruleset: RummiRuleset.currentDefaults,
      );

      expect(small.targetScore, 257);
      expect(big.targetScore, 284);
      expect(boss.targetScore, 285);
      expect(boss.boardDiscards, big.boardDiscards);
      expect(boss.handDiscards, 1);
      expect(boss.maxHandSize, 1);
      expect(boss.bossModifier?.id, 'red_dampener_v1');
    });

    test('station 2 이후 boss 목표는 구간별 target table을 따른다', () {
      final small = BlindSelectionSetup.resolveSpec(
        tier: BlindTier.small,
        stationIndex: 2,
        difficulty: NewRunDifficulty.standard,
        ruleset: RummiRuleset.currentDefaults,
      );
      final boss = BlindSelectionSetup.resolveSpec(
        tier: BlindTier.boss,
        stationIndex: 2,
        difficulty: NewRunDifficulty.standard,
        ruleset: RummiRuleset.currentDefaults,
      );

      expect(small.targetScore, 372);
      expect(boss.targetScore, 439);
      expect(boss.bossModifier?.id, 'row_line_dampener_v1');
    });

    test('S1부터 S8까지 small big boss target table을 고정한다', () {
      final targets = <List<int>>[];
      for (var station = 1; station <= 8; station++) {
        targets.add([
          BlindSelectionSetup.resolveSpec(
            tier: BlindTier.small,
            stationIndex: station,
            difficulty: NewRunDifficulty.standard,
            ruleset: RummiRuleset.currentDefaults,
          ).targetScore,
          BlindSelectionSetup.resolveSpec(
            tier: BlindTier.big,
            stationIndex: station,
            difficulty: NewRunDifficulty.standard,
            ruleset: RummiRuleset.currentDefaults,
          ).targetScore,
          BlindSelectionSetup.resolveSpec(
            tier: BlindTier.boss,
            stationIndex: station,
            difficulty: NewRunDifficulty.standard,
            ruleset: RummiRuleset.currentDefaults,
          ).targetScore,
        ]);
      }

      expect(targets, [
        [257, 284, 285],
        [372, 431, 439],
        [463, 537, 547],
        [580, 672, 685],
        [725, 841, 857],
        [923, 1112, 1121],
        [1154, 1391, 1401],
        [1441, 1738, 1739],
      ]);
      for (final row in targets) {
        expect(row[1], greaterThan(row[0]));
        expect(row[2], greaterThan(row[1]));
      }
    });

    test('selected blind start applies active item station start effects', () {
      final session = RummiPokerGridSession(runSeed: 77);
      final runProgress = RummiRunProgress()
        ..stageIndex = 2
        ..currentStationBlindTierIndex = 0
        ..itemInventory = const RunInventoryState(
          ownedItems: [
            OwnedItemEntry(
              itemId: 'travel_pouch',
              count: 1,
              placement: ItemPlacement.passiveRack,
            ),
            OwnedItemEntry(
              itemId: 'wide_grip',
              count: 1,
              placement: ItemPlacement.equipped,
            ),
          ],
          passiveRelicIds: ['travel_pouch'],
          equippedItemIds: ['wide_grip'],
        );
      final runtime = ActiveRunRuntimeState(
        activeScene: ActiveRunScene.blindSelect,
        difficulty: NewRunDifficulty.standard,
        session: session,
        runProgress: runProgress,
        stageStartSnapshot: ActiveRunStageSnapshot(
          session: session.copySnapshot(),
          runProgress: runProgress.copySnapshot(),
        ),
      );
      final catalog = ItemCatalog.fromJson({
        'schemaVersion': 1,
        'catalogId': 'test',
        'items': [
          _itemJson(
            id: 'travel_pouch',
            timing: 'inventory_capacity',
            op: 'increase_hand_size',
            placement: 'passiveRack',
          ),
          _itemJson(
            id: 'wide_grip',
            timing: 'station_start',
            op: 'increase_hand_size_with_discard_penalty',
            placement: 'equipped',
            rawEffect: const {'boardDiscardPenalty': 1},
          ),
        ],
      });

      final prepared = BlindSelectionSetup.prepareContinuedRunForSelectedBlind(
        runtime: runtime,
        tier: BlindTier.big,
        itemCatalog: catalog,
      );
      final base = BlindSelectionSetup.resolveSpec(
        tier: BlindTier.big,
        stationIndex: 2,
        difficulty: NewRunDifficulty.standard,
        ruleset: RummiRuleset.currentDefaults,
      );

      expect(prepared.session.maxHandSize, base.maxHandSize + 2);
      expect(
        prepared.session.blind.boardDiscardsRemaining,
        base.boardDiscards - 1,
      );
      expect(
        prepared.stageStartSnapshot.session.maxHandSize,
        prepared.session.maxHandSize,
      );
      expect(
        prepared.stageStartSnapshot.session.blind.boardDiscardsRemaining,
        prepared.session.blind.boardDiscardsRemaining,
      );
    });
  });
}

Map<String, dynamic> _itemJson({
  required String id,
  required String timing,
  required String op,
  required String placement,
  Map<String, dynamic> rawEffect = const {},
}) {
  return <String, dynamic>{
    'id': id,
    'displayName': id,
    'type': 'equipment',
    'rarity': 'common',
    'basePrice': 4,
    'sellPrice': 2,
    'stackable': false,
    'maxStack': 1,
    'sellable': true,
    'usableInBattle': false,
    'placement': placement,
    'slotHint': 'test',
    'effectText': 'Test effect.',
    'effect': <String, dynamic>{
      'timing': timing,
      'op': op,
      'amount': 1,
      ...rawEffect,
    },
    'tags': <String>['test'],
    'sourceNotes': 'Test fixture.',
  };
}
