import 'package:flutter_test/flutter_test.dart';
import 'package:rummipoker/logic/rummi_poker_grid/hand_rank.dart';
import 'package:rummipoker/logic/rummi_poker_grid/jester_meta.dart';
import 'package:rummipoker/logic/rummi_poker_grid/models/tile.dart';
import 'package:rummipoker/logic/rummi_poker_grid/rummi_settlement_facade.dart';

void main() {
  group('RummiSettlementRuntimeFacade', () {
    test('cash-out breakdown을 settlement read model로 변환한다', () {
      const breakdown = RummiCashOutBreakdown(
        stageIndex: 3,
        targetScore: 300,
        blindReward: 10,
        remainingBoardDiscards: 2,
        perBoardDiscardBonus: 3,
        boardDiscardGold: 6,
        remainingHandDiscards: 1,
        perHandDiscardBonus: 2,
        handDiscardGold: 2,
        remainingBoardMoves: 3,
        perBoardMoveBonus: 1,
        boardMoveGold: 3,
        economyGold: 4,
        economyBonuses: [
          RummiRoundEndEconomyBonus(
            jesterId: 'green_jester',
            displayName: 'Green Jester',
            gold: 4,
          ),
        ],
        itemGold: 3,
        itemBonuses: [
          RummiRoundEndItemBonus(
            itemId: 'coin_funnel',
            displayName: 'Coin Funnel',
            gold: 3,
          ),
        ],
        totalGold: 28,
      );

      final facade = RummiSettlementRuntimeFacade.fromCashOut(
        breakdown: breakdown,
        currentGold: 34,
      );

      expect(facade.stageIndex, 3);
      expect(facade.targetScore, 300);
      expect(facade.currentGold, 34);
      expect(facade.totalGold, 28);
      expect(facade.entries, hasLength(6));

      expect(facade.entries.first.kind, RummiSettlementEntryKind.stationReward);
      expect(facade.entries.first.leadingLabel, 'Station 3');
      expect(facade.entries.first.description, 'Station Goal 300 달성 보상');
      expect(facade.entries.first.gold, 10);

      final boardMove = facade.entries[3];
      expect(boardMove.kind, RummiSettlementEntryKind.boardMoveReward);
      expect(boardMove.leadingLabel, '3');
      expect(boardMove.description, '남은 보드 이동 3회 x 1');
      expect(boardMove.gold, 3);

      final economy = facade.entries[4];
      expect(economy.kind, RummiSettlementEntryKind.economyBonus);
      expect(economy.leadingLabel, 'J');
      expect(economy.jesterId, 'green_jester');
      expect(economy.displayName, 'Green Jester');
      expect(economy.gold, 4);
      expect(economy.isEconomyBonus, isTrue);

      final item = facade.entries.last;
      expect(item.kind, RummiSettlementEntryKind.itemBonus);
      expect(item.leadingLabel, 'I');
      expect(item.itemId, 'coin_funnel');
      expect(item.displayName, 'Coin Funnel');
      expect(item.gold, 3);
      expect(item.isItemBonus, isTrue);
      expect(item.isBonus, isTrue);
    });

    test('boss deck tile rewards are exposed as settlement reward entries', () {
      const rewardTile = Tile(color: TileColor.blue, number: 8, id: 1);
      const breakdown = RummiCashOutBreakdown(
        stageIndex: 2,
        targetScore: 480,
        blindReward: 8,
        remainingBoardDiscards: 0,
        perBoardDiscardBonus: 3,
        boardDiscardGold: 0,
        remainingHandDiscards: 0,
        perHandDiscardBonus: 2,
        handDiscardGold: 0,
        economyGold: 0,
        economyBonuses: [],
        totalGold: 8,
        deckTileRewards: [rewardTile],
      );

      final facade = RummiSettlementRuntimeFacade.fromCashOut(
        breakdown: breakdown,
        currentGold: 12,
      );

      final reward = facade.entries.last;
      expect(reward.kind, RummiSettlementEntryKind.deckTileReward);
      expect(reward.isDeckTileReward, isTrue);
      expect(reward.tile, rewardTile);
      expect(reward.gold, 0);
      expect(reward.description, contains('다음 전투 덱에 추가'));
    });

    test('S9 이후 settlement는 무한 도전 라벨을 사용한다', () {
      const breakdown = RummiCashOutBreakdown(
        stageIndex: 9,
        targetScore: 3602,
        blindReward: 16,
        remainingBoardDiscards: 0,
        perBoardDiscardBonus: 3,
        boardDiscardGold: 0,
        remainingHandDiscards: 0,
        perHandDiscardBonus: 2,
        handDiscardGold: 0,
        economyGold: 0,
        economyBonuses: [],
        totalGold: 16,
      );

      final facade = RummiSettlementRuntimeFacade.fromCashOut(
        breakdown: breakdown,
        currentGold: 22,
      );

      expect(facade.isEndless, isTrue);
      expect(facade.entries.first.leadingLabel, '무한 S9');
      expect(facade.entries.first.description, '무한 도전 목표 3602 달성 보상');
    });

    test('overkill growth bonuses are exposed as non-gold bonus entries', () {
      const breakdown = RummiCashOutBreakdown(
        stageIndex: 4,
        targetScore: 600,
        blindReward: 8,
        remainingBoardDiscards: 0,
        perBoardDiscardBonus: 3,
        boardDiscardGold: 0,
        remainingHandDiscards: 0,
        perHandDiscardBonus: 2,
        handDiscardGold: 0,
        economyGold: 0,
        economyBonuses: [],
        totalGold: 8,
        overkillGrowthBonuses: [
          RummiOverkillGrowthBonus(
            rank: RummiHandRank.flush,
            amount: 1,
            finalScore: 800,
            thresholdScore: 780,
          ),
        ],
      );

      final facade = RummiSettlementRuntimeFacade.fromCashOut(
        breakdown: breakdown,
        currentGold: 12,
      );

      final growth = facade.entries.last;
      expect(growth.kind, RummiSettlementEntryKind.overkillGrowthBonus);
      expect(growth.isBonus, isTrue);
      expect(growth.gold, 0);
      expect(growth.description, '초과 달성: 플러시 성장 +1');
    });

    test('overkill gold bonuses are exposed as gold bonus entries', () {
      const breakdown = RummiCashOutBreakdown(
        stageIndex: 4,
        targetScore: 600,
        blindReward: 8,
        remainingBoardDiscards: 0,
        perBoardDiscardBonus: 3,
        boardDiscardGold: 0,
        remainingHandDiscards: 0,
        perHandDiscardBonus: 2,
        handDiscardGold: 0,
        economyGold: 0,
        economyBonuses: [],
        totalGold: 10,
        overkillGoldBonus: 2,
      );

      final facade = RummiSettlementRuntimeFacade.fromCashOut(
        breakdown: breakdown,
        currentGold: 12,
      );

      final bonus = facade.entries.last;
      expect(bonus.kind, RummiSettlementEntryKind.overkillGoldBonus);
      expect(bonus.isBonus, isTrue);
      expect(bonus.gold, 2);
      expect(bonus.description, '초과 점수 보너스');
    });
  });
}
