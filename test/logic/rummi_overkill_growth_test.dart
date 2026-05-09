import 'package:flutter_test/flutter_test.dart';
import 'package:rummipoker/logic/rummi_poker_grid/hand_rank.dart';
import 'package:rummipoker/logic/rummi_poker_grid/jester_meta.dart';
import 'package:rummipoker/logic/rummi_poker_grid/line_ref.dart';
import 'package:rummipoker/logic/rummi_poker_grid/rummi_poker_grid_session.dart';

void main() {
  group('overkill hand growth', () {
    test('일반 Station 130% 이상이면 대표 족보 성장 +1을 지급한다', () {
      final progress = RummiRunProgress.restore(
        stageIndex: 3,
        currentStationBlindTierIndex: 0,
        gold: 0,
        rerollCost: RummiRunProgress.shopBaseRerollCost,
        ownedJesters: const [],
        shopOffers: const [],
        statefulValuesBySlot: const {},
        playedHandCounts: const {},
      );
      progress.onConfirmedLines([
        _line(rank: RummiHandRank.straight, finalScore: 150),
        _line(rank: RummiHandRank.flush, finalScore: 220),
      ]);

      final bonuses = progress.claimOverkillGrowthBonus(
        targetScore: 250,
        finalScore: 330,
      );

      expect(bonuses, hasLength(1));
      expect(bonuses.single.rank, RummiHandRank.flush);
      expect(progress.snapshotPlayedHandCounts()[RummiHandRank.flush], 1);
      expect(
        progress.snapshotHandGrowthStates()[RummiHandRank.flush]!.level,
        3,
      );
      expect(
        progress.claimOverkillGrowthBonus(targetScore: 250, finalScore: 330),
        isEmpty,
      );
    });

    test('Boss는 120% 이상이면 대표 족보 성장 +1을 지급한다', () {
      final progress = RummiRunProgress.restore(
        stageIndex: 8,
        currentStationBlindTierIndex: 2,
        gold: 0,
        rerollCost: RummiRunProgress.shopBaseRerollCost,
        ownedJesters: const [],
        shopOffers: const [],
        statefulValuesBySlot: const {},
        playedHandCounts: const {},
      );
      progress.onConfirmedLines([
        _line(rank: RummiHandRank.straightFlush, finalScore: 1200),
      ]);

      final bonuses = progress.claimOverkillGrowthBonus(
        targetScore: 1000,
        finalScore: 1200,
      );

      expect(bonuses.single.rank, RummiHandRank.straightFlush);
      expect(
        progress.snapshotPlayedHandCounts()[RummiHandRank.straightFlush],
        1,
      );
      expect(
        progress.snapshotHandGrowthStates()[RummiHandRank.straightFlush]!.level,
        3,
      );
    });
  });
}

ConfirmedLineBreakdown _line({
  required RummiHandRank rank,
  required int finalScore,
}) {
  return ConfirmedLineBreakdown(
    ref: LineRef.row(0),
    rank: rank,
    baseScore: finalScore,
    finalScore: finalScore,
    jesterBonus: 0,
    hasScoringFaceCard: false,
    effects: const [],
  );
}
