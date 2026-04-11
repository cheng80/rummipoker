import 'package:rummipoker/logic/rummi_poker_grid/hand_evaluator.dart';
import 'package:rummipoker/logic/rummi_poker_grid/hand_rank.dart';
import 'package:rummipoker/logic/rummi_poker_grid/models/tile.dart';
import 'package:flutter_test/flutter_test.dart';

Tile t(TileColor c, int n) => Tile(color: c, number: n);

void main() {
  group('HandEvaluator', () {
    test('straight flush 9–13 same color', () {
      final e = HandEvaluator.evaluateFive([
        t(TileColor.red, 9),
        t(TileColor.red, 10),
        t(TileColor.red, 11),
        t(TileColor.red, 12),
        t(TileColor.red, 13),
      ]);
      expect(e.rank, RummiHandRank.straightFlush);
      expect(e.baseScore, 150);
      expect(e.canClearLine, true);
    });

    test('straight 1–5 mixed colors', () {
      final e = HandEvaluator.evaluateFive([
        t(TileColor.red, 1),
        t(TileColor.blue, 2),
        t(TileColor.yellow, 3),
        t(TileColor.black, 4),
        t(TileColor.red, 5),
      ]);
      expect(e.rank, RummiHandRank.straight);
      expect(e.baseScore, 70);
    });

    test('straight wheel 10–11–12–13–1 mixed colors', () {
      final e = HandEvaluator.evaluateFive([
        t(TileColor.red, 10),
        t(TileColor.blue, 11),
        t(TileColor.yellow, 12),
        t(TileColor.black, 13),
        t(TileColor.red, 1),
      ]);
      expect(e.rank, RummiHandRank.straight);
      expect(e.baseScore, 70);
    });

    test('straight flush wheel same color', () {
      final e = HandEvaluator.evaluateFive([
        t(TileColor.blue, 10),
        t(TileColor.blue, 11),
        t(TileColor.blue, 12),
        t(TileColor.blue, 13),
        t(TileColor.blue, 1),
      ]);
      expect(e.rank, RummiHandRank.straightFlush);
    });

    test('flush not straight', () {
      final e = HandEvaluator.evaluateFive([
        t(TileColor.blue, 1),
        t(TileColor.blue, 3),
        t(TileColor.blue, 5),
        t(TileColor.blue, 7),
        t(TileColor.blue, 9),
      ]);
      expect(e.rank, RummiHandRank.flush);
      expect(e.baseScore, 50);
    });

    test('four of a kind', () {
      final e = HandEvaluator.evaluateFive([
        t(TileColor.red, 7),
        t(TileColor.blue, 7),
        t(TileColor.yellow, 7),
        t(TileColor.black, 7),
        t(TileColor.red, 3),
      ]);
      expect(e.rank, RummiHandRank.fourOfAKind);
      expect(e.baseScore, 100);
    });

    test('full house', () {
      final e = HandEvaluator.evaluateFive([
        t(TileColor.red, 8),
        t(TileColor.blue, 8),
        t(TileColor.yellow, 8),
        t(TileColor.black, 4),
        t(TileColor.red, 4),
      ]);
      expect(e.rank, RummiHandRank.fullHouse);
      expect(e.baseScore, 80);
    });

    test('three of a kind', () {
      final e = HandEvaluator.evaluateFive([
        t(TileColor.red, 6),
        t(TileColor.blue, 6),
        t(TileColor.yellow, 6),
        t(TileColor.black, 2),
        t(TileColor.red, 9),
      ]);
      expect(e.rank, RummiHandRank.threeOfAKind);
      expect(e.baseScore, 40);
    });

    test('two pair', () {
      final e = HandEvaluator.evaluateFive([
        t(TileColor.red, 5),
        t(TileColor.blue, 5),
        t(TileColor.yellow, 2),
        t(TileColor.black, 2),
        t(TileColor.red, 11),
      ]);
      expect(e.rank, RummiHandRank.twoPair);
      expect(e.baseScore, 25);
    });

    test('one pair', () {
      final e = HandEvaluator.evaluateFive([
        t(TileColor.red, 4),
        t(TileColor.blue, 4),
        t(TileColor.yellow, 1),
        t(TileColor.black, 8),
        t(TileColor.red, 12),
      ]);
      expect(e.rank, RummiHandRank.onePair);
      expect(e.baseScore, 0);
      expect(e.isDeadLine, true);
      expect(e.canClearLine, true);
    });

    test('high card', () {
      final e = HandEvaluator.evaluateFive([
        t(TileColor.red, 2),
        t(TileColor.blue, 5),
        t(TileColor.yellow, 8),
        t(TileColor.black, 11),
        t(TileColor.red, 13),
      ]);
      expect(e.rank, RummiHandRank.highCard);
      expect(e.isDeadLine, true);
      expect(e.canClearLine, true);
    });

    test('not a straight: 1,2,3,4,6', () {
      final e = HandEvaluator.evaluateFive([
        t(TileColor.red, 1),
        t(TileColor.blue, 2),
        t(TileColor.yellow, 3),
        t(TileColor.black, 4),
        t(TileColor.red, 6),
      ]);
      expect(e.rank, isNot(RummiHandRank.straight));
    });
  });
}
