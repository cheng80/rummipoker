import 'package:rummipoker/logic/rummi_poker_grid/hand_rank.dart';
import 'package:rummipoker/logic/rummi_poker_grid/models/board.dart';
import 'package:rummipoker/logic/rummi_poker_grid/models/tile.dart';
import 'package:rummipoker/logic/rummi_poker_grid/rummi_poker_grid_engine.dart';
import 'package:flutter_test/flutter_test.dart';

Tile t(TileColor c, int n) => Tile(color: c, number: n);

void main() {
  test('빈 칸이 있으면 행 평가 null', () {
    final board = RummiBoard();
    board.setCell(0, 0, t(TileColor.red, 1));
    final engine = RummiPokerGridEngine();
    expect(engine.evaluateRow(board, 0), isNull);
  });

  test('가득 찬 행은 스트레이트로 평가 (색 혼합)', () {
    final board = RummiBoard();
    for (var i = 0; i < kBoardSize; i++) {
      board.setCell(
        2,
        i,
        t(i.isEven ? TileColor.red : TileColor.blue, i + 1),
      );
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
