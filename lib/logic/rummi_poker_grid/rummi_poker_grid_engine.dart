import 'hand_evaluator.dart';
import 'line_ref.dart';
import 'models/board.dart';
import 'models/tile.dart';

/// 보드의 한 줄(행/열) 평가 결과.
class LineHandReport {
  const LineHandReport({required this.evaluation, required this.occupiedCount});

  final HandEvaluation evaluation;
  final int occupiedCount;
}

/// 줄 단위 핸드 판정. 턴 UI·Riverpod는 `RummiPokerGridSession`·후속.
class RummiPokerGridEngine {
  LineHandReport? _evaluateLine(List<Tile?> line) {
    final occupiedCount = line.whereType<Tile>().length;
    if (occupiedCount == 0) return null;
    return LineHandReport(
      evaluation: HandEvaluator.evaluateLine(line),
      occupiedCount: occupiedCount,
    );
  }

  /// 현재 놓인 카드가 있는 행 `rowIndex`를 평가한다. 완성 여부는 요구하지 않는다.
  LineHandReport? evaluateRow(RummiBoard board, int rowIndex) {
    return _evaluateLine(board.row(rowIndex));
  }

  /// 현재 놓인 카드가 있는 열 `colIndex`를 평가한다.
  LineHandReport? evaluateCol(RummiBoard board, int colIndex) {
    return _evaluateLine(board.col(colIndex));
  }

  /// 주 대각선 (↘)의 현재 카드 상태를 평가한다.
  LineHandReport? evaluateDiagMain(RummiBoard board) {
    return _evaluateLine(board.diagMain());
  }

  /// 반대 대각선 (↙)의 현재 카드 상태를 평가한다.
  LineHandReport? evaluateDiagAnti(RummiBoard board) {
    return _evaluateLine(board.diagAnti());
  }

  /// 현재 카드가 하나라도 있는 **모든** 평가줄(최대 12개).
  List<({LineRef ref, LineHandReport report})> listEvaluatedLines(
    RummiBoard board,
  ) {
    final out = <({LineRef ref, LineHandReport report})>[];
    for (var r = 0; r < kBoardSize; r++) {
      final e = evaluateRow(board, r);
      if (e != null) out.add((ref: LineRef.row(r), report: e));
    }
    for (var c = 0; c < kBoardSize; c++) {
      final e = evaluateCol(board, c);
      if (e != null) out.add((ref: LineRef.col(c), report: e));
    }
    final dm = evaluateDiagMain(board);
    if (dm != null) out.add((ref: LineRef.diagMain, report: dm));
    final da = evaluateDiagAnti(board);
    if (da != null) out.add((ref: LineRef.diagAnti, report: da));
    return out;
  }
}
