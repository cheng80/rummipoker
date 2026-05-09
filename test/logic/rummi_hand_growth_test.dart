import 'package:flutter_test/flutter_test.dart';
import 'package:rummipoker/logic/rummi_poker_grid/hand_rank.dart';
import 'package:rummipoker/logic/rummi_poker_grid/rummi_hand_growth.dart';

void main() {
  test('족보 성장 레벨은 완성 횟수 + 1이다', () {
    expect(
      RummiHandGrowth.levelForCompletedCount(RummiHandRank.straight, 0),
      1,
    );
    expect(
      RummiHandGrowth.levelForCompletedCount(RummiHandRank.straight, 2),
      3,
    );
  });

  test('dead line은 성장 점수와 레벨을 갖지 않는다', () {
    expect(
      RummiHandGrowth.levelForCompletedCount(RummiHandRank.highCard, 3),
      0,
    );
    expect(
      RummiHandGrowth.growthBonusFor(
        rank: RummiHandRank.onePair,
        completedCount: 3,
      ),
      0,
    );
  });

  test('성장 보너스는 족보별 단계값에 완성 횟수를 곱한다', () {
    expect(
      RummiHandGrowth.grownBaseScoreFor(
        rank: RummiHandRank.flush,
        baseScore: 50,
        completedCount: 2,
      ),
      70,
    );
    expect(
      RummiHandGrowth.grownBaseScoreFor(
        rank: RummiHandRank.straightFlush,
        baseScore: 150,
        completedCount: 1,
      ),
      180,
    );
  });
}
