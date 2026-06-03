import 'package:flutter_test/flutter_test.dart';

import 'package:rummipoker/logic/rummi_poker_grid/boss_modifier.dart';
import 'package:rummipoker/logic/rummi_poker_grid/item_definition.dart';
import 'package:rummipoker/logic/rummi_poker_grid/jester_meta.dart';
import 'package:rummipoker/logic/rummi_poker_grid/models/tile.dart';
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
        runModifier: NewRunModifier.basic,
        ruleset: RummiRuleset.currentDefaults,
      );

      expect(options[0].tier, BlindTier.small);
      expect(options[0].availability, BlindSelectionAvailability.selectable);
      expect(options[1].tier, BlindTier.big);
      expect(options[1].availability, BlindSelectionAvailability.locked);
      expect(options[2].tier, BlindTier.boss);
      expect(options[2].availability, BlindSelectionAvailability.locked);
    });

    test('basic run modifier는 목표 점수와 보상 preview를 바꾸지 않는다', () {
      final standard = BlindSelectionSetup.resolveSpec(
        tier: BlindTier.boss,
        stationIndex: 4,
        difficulty: NewRunDifficulty.standard,
        ruleset: RummiRuleset.currentDefaults,
      );
      final basic = BlindSelectionSetup.resolveSpec(
        tier: BlindTier.boss,
        stationIndex: 4,
        difficulty: NewRunDifficulty.standard,
        runModifier: NewRunModifier.basic,
        ruleset: RummiRuleset.currentDefaults,
      );

      expect(basic.targetScore, standard.targetScore);
      expect(basic.rewardPreview, standard.rewardPreview);
      expect(NewRunModifier.parse('unknown'), NewRunModifier.basic);
      expect(NewRunModifier.basic.targetScoreMultiplier, 1);
      expect(NewRunModifier.basic.rewardMultiplier, 1);
    });

    test('high stakes run modifier는 목표 점수와 보상 preview를 함께 올린다', () {
      final standard = BlindSelectionSetup.resolveSpec(
        tier: BlindTier.boss,
        stationIndex: 4,
        difficulty: NewRunDifficulty.standard,
        ruleset: RummiRuleset.currentDefaults,
      );
      final highStakes = BlindSelectionSetup.resolveSpec(
        tier: BlindTier.boss,
        stationIndex: 4,
        difficulty: NewRunDifficulty.standard,
        runModifier: NewRunModifier.highStakes,
        ruleset: RummiRuleset.currentDefaults,
      );

      expect(highStakes.targetScore, (standard.targetScore * 1.04).round());
      expect(highStakes.rewardPreview, (standard.rewardPreview * 1.12).round());
      expect(NewRunModifier.parse('high_stakes'), NewRunModifier.highStakes);
      expect(NewRunModifier.highStakes.unlockCostInsight, 20);
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

    test('run seed가 있으면 station별 boss pool이 5~7개로 분산된다', () {
      for (var station = 1; station <= 8; station++) {
        final ids = <String>{};
        for (var seed = 1; seed <= 64; seed++) {
          final boss = BlindSelectionSetup.resolveSpec(
            tier: BlindTier.boss,
            stationIndex: station,
            difficulty: NewRunDifficulty.standard,
            runSeed: seed,
            ruleset: RummiRuleset.currentDefaults,
          );
          ids.add(boss.bossModifier!.id);
        }

        expect(ids.length, greaterThanOrEqualTo(5), reason: 'S$station');
        expect(ids.length, lessThanOrEqualTo(7), reason: 'S$station');
      }
    });

    test('보드 금지 boss modifier는 모두 5칸 이하만 막는다', () {
      final boardBlockers = RummiBossModifier.allKnownModifiers.where(
        (modifier) =>
            modifier.category == RummiBossModifierCategory.boardCellBlock,
      );

      expect(boardBlockers.length, 14);
      for (final modifier in boardBlockers) {
        expect(
          modifier.blockedCells.length,
          lessThanOrEqualTo(5),
          reason: modifier.id,
        );
      }
    });

    test('보드 금지 boss modifier는 난이도 정책에 따라 pool에 분산된다', () {
      final stationBlocks = <int, Set<String>>{};
      for (var station = 1; station <= 8; station++) {
        final ids = <String>{};
        for (var seed = 1; seed <= 128; seed++) {
          final boss = BlindSelectionSetup.resolveSpec(
            tier: BlindTier.boss,
            stationIndex: station,
            difficulty: NewRunDifficulty.standard,
            runSeed: seed,
            ruleset: RummiRuleset.currentDefaults,
          ).bossModifier!;
          if (boss.category == RummiBossModifierCategory.boardCellBlock) {
            ids.add(boss.id);
          }
        }
        stationBlocks[station] = ids;
      }

      expect(stationBlocks[1], isEmpty);
      expect(stationBlocks[2], isEmpty);
      expect(stationBlocks[3], {
        RummiBossModifier.blockRightColumn.id,
        RummiBossModifier.blockTopRow.id,
      });
      expect(stationBlocks[4], {
        RummiBossModifier.blockLeftColumn.id,
        RummiBossModifier.blockBottomRow.id,
        RummiBossModifier.blockFourCorners.id,
      });
      expect(stationBlocks[5], {
        RummiBossModifier.blockCenterRow.id,
        RummiBossModifier.blockCenterColumn.id,
      });
      for (final station in [6, 7, 8]) {
        expect(stationBlocks[station], {
          RummiBossModifier.blockMainDiagonal.id,
          RummiBossModifier.blockAntiDiagonal.id,
        });
      }

      final postponed = {
        RummiBossModifier.blockCenterCross.id,
        RummiBossModifier.blockCornersCenter.id,
        RummiBossModifier.blockInnerX.id,
        RummiBossModifier.blockCheckerA.id,
        RummiBossModifier.blockCheckerB.id,
      };
      expect(
        stationBlocks.values
            .expand((ids) => ids)
            .toSet()
            .intersection(postponed),
        isEmpty,
      );
    });

    test('도전 모드 보드 금지 boss modifier는 S1부터 고난도 패턴까지 연다', () {
      final stationBlocks = <int, Set<String>>{};
      for (var station = 1; station <= 8; station++) {
        final ids = <String>{};
        for (var seed = 1; seed <= 128; seed++) {
          final boss = BlindSelectionSetup.resolveSpec(
            tier: BlindTier.boss,
            stationIndex: station,
            difficulty: NewRunDifficulty.challenge,
            runSeed: seed,
            ruleset: RummiRuleset.currentDefaults,
          ).bossModifier!;
          if (boss.category == RummiBossModifierCategory.boardCellBlock) {
            ids.add(boss.id);
          }
        }
        stationBlocks[station] = ids;
      }

      expect(stationBlocks[1], {
        RummiBossModifier.blockRightColumn.id,
        RummiBossModifier.blockTopRow.id,
      });
      expect(stationBlocks[2], {RummiBossModifier.blockLeftColumn.id});
      expect(stationBlocks[3], {RummiBossModifier.blockBottomRow.id});
      expect(stationBlocks[4], {
        RummiBossModifier.blockFourCorners.id,
        RummiBossModifier.blockCenterColumn.id,
      });
      expect(stationBlocks[5], {RummiBossModifier.blockCenterRow.id});
      expect(stationBlocks[6], {
        RummiBossModifier.blockMainDiagonal.id,
        RummiBossModifier.blockAntiDiagonal.id,
      });
      expect(stationBlocks[7], {
        RummiBossModifier.blockCenterCross.id,
        RummiBossModifier.blockCornersCenter.id,
      });
      expect(stationBlocks[8], {
        RummiBossModifier.blockInnerX.id,
        RummiBossModifier.blockCheckerA.id,
        RummiBossModifier.blockCheckerB.id,
      });
    });

    test('boss 클리어 후 blind select runtime은 다음 station small 시작 상태로 리셋된다', () {
      final runtime = ActiveRunRuntimeState(
        activeScene: ActiveRunScene.blindSelect,
        difficulty: NewRunDifficulty.standard,
        runModifier: NewRunModifier.highStakes,
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
      expect(prepared.runModifier, NewRunModifier.highStakes);

      final options = BlindSelectionSetup.buildForStation(
        stationIndex: prepared.runProgress.stageIndex,
        clearedBlindTierIndex:
            prepared.runProgress.currentStationBlindTierIndex,
        difficulty: prepared.difficulty,
        runModifier: prepared.runModifier,
        ruleset: prepared.session.ruleset,
      );

      expect(options[0].availability, BlindSelectionAvailability.selectable);
      expect(options[1].availability, BlindSelectionAvailability.locked);
      expect(options[2].availability, BlindSelectionAvailability.locked);
    });

    test('added deck tiles are shuffled into next selected blind deck', () {
      final progress = RummiRunProgress()
        ..stageIndex = 2
        ..currentStationBlindTierIndex = -1
        ..addDeckTile(const Tile(color: TileColor.red, number: 7));
      final runtime = ActiveRunRuntimeState(
        activeScene: ActiveRunScene.blindSelect,
        difficulty: NewRunDifficulty.standard,
        runModifier: NewRunModifier.basic,
        session: RummiPokerGridSession(runSeed: 77),
        runProgress: progress,
        stageStartSnapshot: ActiveRunStageSnapshot(
          session: RummiPokerGridSession(runSeed: 77),
          runProgress: progress.copySnapshot(),
        ),
      );

      final prepared = BlindSelectionSetup.prepareContinuedRunForSelectedBlind(
        runtime: runtime,
        tier: BlindTier.small,
      );

      expect(prepared.session.totalDeckSize, 53);
      expect(prepared.session.conservationTotal, 53);
      expect(
        prepared.session.deck.snapshotPile(),
        contains(const Tile(color: TileColor.red, number: 7, id: 1)),
      );
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

      expect(small.targetScore, 480);
      expect(big.targetScore, 720);
      expect(boss.targetScore, 960);
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

      expect(small.targetScore, 650);
      expect(boss.targetScore, 1350);
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
        [480, 720, 960],
        [650, 1000, 1350],
        [900, 1400, 1900],
        [1250, 2000, 2750],
        [1750, 2850, 3950],
        [2450, 4050, 5650],
        [3450, 5750, 8050],
        [4850, 8150, 11400],
      ]);
      for (final row in targets) {
        expect(row[1], greaterThan(row[0]));
        expect(row[2], greaterThan(row[1]));
      }
    });

    test('S9 이후는 무한 도전 target 비율을 따른다', () {
      final small = BlindSelectionSetup.resolveSpec(
        tier: BlindTier.small,
        stationIndex: 9,
        difficulty: NewRunDifficulty.standard,
        ruleset: RummiRuleset.currentDefaults,
      );
      final big = BlindSelectionSetup.resolveSpec(
        tier: BlindTier.big,
        stationIndex: 9,
        difficulty: NewRunDifficulty.standard,
        ruleset: RummiRuleset.currentDefaults,
      );
      final boss = BlindSelectionSetup.resolveSpec(
        tier: BlindTier.boss,
        stationIndex: 9,
        difficulty: NewRunDifficulty.standard,
        ruleset: RummiRuleset.currentDefaults,
      );

      expect(BlindSelectionSetup.isEndlessStation(8), isFalse);
      expect(BlindSelectionSetup.isEndlessStation(9), isTrue);
      expect(small.isEndless, isTrue);
      expect(small.targetScore, (4850 * 1.25).round());
      expect(big.targetScore, (small.targetScore * 1.5).round());
      expect(boss.targetScore, small.targetScore * 2);
      expect(big.description, contains('1.5배'));
      expect(boss.description, contains('2배'));
    });

    test('도전 난이도 S9 이후도 무한 도전 비율 뒤에 난이도 보정을 적용한다', () {
      final standardSmall = BlindSelectionSetup.resolveSpec(
        tier: BlindTier.small,
        stationIndex: 10,
        difficulty: NewRunDifficulty.standard,
        ruleset: RummiRuleset.currentDefaults,
      );
      final challengeBoss = BlindSelectionSetup.resolveSpec(
        tier: BlindTier.boss,
        stationIndex: 10,
        difficulty: NewRunDifficulty.challenge,
        ruleset: RummiRuleset.currentDefaults,
      );

      expect(
        challengeBoss.targetScore,
        (standardSmall.targetScore * 2 * 1.5).round(),
      );
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
