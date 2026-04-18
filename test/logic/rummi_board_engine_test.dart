import 'package:rummipoker/logic/rummi_poker_grid/hand_rank.dart';
import 'package:rummipoker/logic/rummi_poker_grid/models/board.dart';
import 'package:rummipoker/logic/rummi_poker_grid/models/tile.dart';
import 'package:rummipoker/logic/rummi_poker_grid/rummi_poker_grid_engine.dart';
import 'package:flutter_test/flutter_test.dart';

Tile t(TileColor c, int n) => Tile(color: c, number: n);

void main() {
  test('1장만 있으면 행은 하이카드로 평가된다', () {
    final board = RummiBoard();
    board.setCell(0, 0, t(TileColor.red, 1));
    final engine = RummiPokerGridEngine();
    final report = engine.evaluateRow(board, 0);
    expect(report, isNotNull);
    expect(report!.occupiedCount, 1);
    expect(report.evaluation.rank, RummiHandRank.highCard);
  });

  test('부분 줄도 현재 카드만으로 평가한다', () {
    final board = RummiBoard();
    board.setCell(1, 0, t(TileColor.red, 7));
    board.setCell(1, 3, t(TileColor.blue, 7));
    final engine = RummiPokerGridEngine();
    final report = engine.evaluateRow(board, 1);
    expect(report, isNotNull);
    expect(report!.occupiedCount, 2);
    expect(report.evaluation.rank, RummiHandRank.onePair);
    expect(report.evaluation.contributingIndexes, [0, 3]);
  });

  test('가득 찬 행은 스트레이트로 평가 (색 혼합)', () {
    final board = RummiBoard();
    for (var i = 0; i < kBoardSize; i++) {
      board.setCell(2, i, t(i.isEven ? TileColor.red : TileColor.blue, i + 1));
    }
    final engine = RummiPokerGridEngine();
    final r = engine.evaluateRow(board, 2);
    expect(r, isNotNull);
    expect(r!.evaluation.rank, RummiHandRank.straight);
  });

  test('주 대각선 5칸 채우면 평가', () {
    final board = RummiBoard();
    for (var i = 0; i < kBoardSize; i++) {
      board.setCell(
        i,
        i,
        t(i.isEven ? TileColor.yellow : TileColor.black, i + 1),
      );
    }
    final engine = RummiPokerGridEngine();
    final r = engine.evaluateDiagMain(board);
    expect(r, isNotNull);
    expect(r!.evaluation.rank, RummiHandRank.straight);
  });
}
