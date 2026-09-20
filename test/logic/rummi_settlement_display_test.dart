import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:rummipoker/logic/rummi_poker_grid/hand_rank.dart';
import 'package:rummipoker/logic/rummi_poker_grid/jester_meta.dart';
import 'package:rummipoker/logic/rummi_poker_grid/models/tile.dart';
import 'package:rummipoker/logic/rummi_poker_grid/rummi_settlement_facade.dart';

const settlementReceipt = RummiCashOutBreakdown(
  stageIndex: 9,
  targetScore: 9999,
  blindReward: 4,
  remainingBoardDiscards: 2,
  remainingHandDiscards: 1,
  remainingBoardMoves: 3,
  perBoardDiscardBonus: 2,
  perHandDiscardBonus: 1,
  perBoardMoveBonus: 1,
  boardDiscardGold: 4,
  handDiscardGold: 1,
  boardMoveGold: 3,
  economyBonuses: [
    RummiRoundEndEconomyBonus(
      jesterId: 'unknown_jester',
      displayName: '저장된 사용자 이름',
      gold: 2,
    ),
  ],
  economyGold: 2,
  firstBlindClearBonusGold: 2,
  itemBonuses: [
    RummiRoundEndItemBonus(
      itemId: 'unknown_item',
      displayName: 'Custom item',
      gold: 1,
    ),
  ],
  itemGold: 1,
  deckTileRewards: [Tile(color: TileColor.red, number: 13)],
  overkillGrowthBonuses: [
    RummiOverkillGrowthBonus(
      rank: RummiHandRank.flushHouse,
      amount: 2,
      finalScore: 20000,
      thresholdScore: 9999,
    ),
    RummiOverkillGrowthBonus(
      rank: RummiHandRank.flushFive,
      amount: 3,
      finalScore: 30000,
      thresholdScore: 9999,
    ),
  ],
  overkillGoldBonus: 2,
  totalGold: 19,
);

void main() {
  test(
    'receipt JSON and stored names survive transient localization metadata',
    () {
      final before = jsonEncode(settlementReceipt.toJson());
      final restored = RummiCashOutBreakdown.fromJson(
        jsonDecode(before) as Map<String, dynamic>,
      );
      final facade = RummiSettlementRuntimeFacade.fromCashOut(
        breakdown: restored,
        currentGold: 30,
      );
      expect(jsonEncode(restored.toJson()), before);
      expect(facade.totalGold, 19);
      expect(
        facade.entries.first.descriptionKey,
        'coreSettlementEndlessReward',
      );
      expect(facade.entries.first.descriptionArgs, {'score': '9999'});
      expect(facade.entries[3].descriptionArgs, {'count': '3', 'gold': '1'});
      expect(
        facade.entries
            .where((e) => e.isOverkillGrowthBonus)
            .map((e) => e.growthRank),
        [RummiHandRank.flushHouse, RummiHandRank.flushFive],
      );
      expect(
        facade.entries.firstWhere((e) => e.isEconomyBonus).displayName,
        '저장된 사용자 이름',
      );
      expect(
        facade.entries.firstWhere((e) => e.isItemBonus).displayName,
        'Custom item',
      );
      expect(before, isNot(contains('coreSettlement')));
    },
  );

  test('manual legacy entries need no display metadata', () {
    const entry = RummiSettlementEntryView(
      kind: RummiSettlementEntryKind.stationReward,
      leadingLabel: 'Custom title',
      description: 'Custom message',
      gold: 3,
    );
    expect(entry.descriptionKey, isNull);
    expect(entry.leadingKey, isNull);
    expect(entry.description, 'Custom message');
  });
}
