import 'package:flutter_test/flutter_test.dart';
import 'package:rummipoker/logic/rummi_poker_grid/jester_meta.dart';
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
        economyGold: 4,
        economyBonuses: [
          RummiRoundEndEconomyBonus(
            jesterId: 'green_jester',
            displayName: 'Green Jester',
            gold: 4,
          ),
        ],
        totalGold: 22,
      );

      final facade = RummiSettlementRuntimeFacade.fromCashOut(
        breakdown: breakdown,
        currentGold: 34,
      );

      expect(facade.stageIndex, 3);
      expect(facade.targetScore, 300);
      expect(facade.currentGold, 34);
      expect(facade.totalGold, 22);
      expect(facade.entries, hasLength(4));

      expect(
        facade.entries.first.kind,
        RummiSettlementEntryKind.stationReward,
      );
      expect(facade.entries.first.leadingLabel, 'Station 3');
      expect(facade.entries.first.description, 'Station Goal 300 달성 보상');
      expect(facade.entries.first.gold, 10);

      final economy = facade.entries.last;
      expect(economy.kind, RummiSettlementEntryKind.economyBonus);
      expect(economy.leadingLabel, 'J');
      expect(economy.jesterId, 'green_jester');
      expect(economy.displayName, 'Green Jester');
      expect(economy.gold, 4);
      expect(economy.isEconomyBonus, isTrue);
    });
  });
}
