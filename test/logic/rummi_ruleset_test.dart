import 'package:flutter_test/flutter_test.dart';

import 'package:rummipoker/logic/rummi_poker_grid/hand_rank.dart';
import 'package:rummipoker/logic/rummi_poker_grid/models/board.dart';
import 'package:rummipoker/logic/rummi_poker_grid/models/poker_deck.dart';
import 'package:rummipoker/logic/rummi_poker_grid/rummi_poker_grid_session.dart';
import 'package:rummipoker/logic/rummi_poker_grid/rummi_ruleset.dart';

void main() {
  group('RummiRuleset.currentDefaults', () {
    test('mirrors current board, deck, hand-size, and overlap constants', () {
      const ruleset = RummiRuleset.currentDefaults;

      expect(ruleset.boardSize, kBoardSize);
      expect(ruleset.evaluationLineCount, kCurrentEvaluationLineCount);
      expect(ruleset.copiesPerTile, kDefaultCopiesPerTile);
      expect(
        ruleset.defaultMaxHandSize,
        RummiPokerGridSession.kDefaultMaxHandSize,
      );
      expect(
        ruleset.minDebugMaxHandSize,
        RummiPokerGridSession.kMinDebugMaxHandSize,
      );
      expect(
        ruleset.maxDebugMaxHandSize,
        RummiPokerGridSession.kMaxDebugMaxHandSize,
      );
      expect(ruleset.overlapAlpha, RummiPokerGridSession.kOverlapAlpha);
      expect(
        ruleset.overlapMultiplierCap,
        RummiPokerGridSession.kOverlapMultiplierCap,
      );
    });

    test('locks current dead-line and confirm/removal policies', () {
      const ruleset = RummiRuleset.currentDefaults;

      expect(ruleset.instantConfirmAllScoringLines, isTrue);
      expect(ruleset.removeContributorUnionOnly, isTrue);
      expect(ruleset.wheelStraightAllowed, isTrue);
      expect(ruleset.highCardIsDeadLine, isTrue);
      expect(ruleset.onePairIsDeadLine, isTrue);
    });

    test('mirrors current base score table including one pair at zero', () {
      const ruleset = RummiRuleset.currentDefaults;

      expect(ruleset.baseScoreFor(RummiHandRank.highCard), 0);
      expect(ruleset.baseScoreFor(RummiHandRank.onePair), 0);
      expect(ruleset.baseScoreFor(RummiHandRank.twoPair), 25);
      expect(ruleset.baseScoreFor(RummiHandRank.threeOfAKind), 40);
      expect(ruleset.baseScoreFor(RummiHandRank.straight), 70);
      expect(ruleset.baseScoreFor(RummiHandRank.flush), 50);
      expect(ruleset.baseScoreFor(RummiHandRank.fullHouse), 80);
      expect(ruleset.baseScoreFor(RummiHandRank.fourOfAKind), 100);
      expect(ruleset.baseScoreFor(RummiHandRank.straightFlush), 150);
    });
  });
}
