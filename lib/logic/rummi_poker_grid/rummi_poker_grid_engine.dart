import 'hand_evaluator.dart';
import 'line_ref.dart';
import 'models/board.dart';

/// 보드의 한 줄(행/열) 평가 결과.
class LineHandReport {
  const LineHandReport({
    required this.evaluation,
  });

  final HandEvaluation evaluation;
}

/// 줄 단위 핸드 판정 + `listFullLines`. 턴 UI·Riverpod는 `RummiPokerGridSession`·후속.
class RummiPokerGridEngine {
  /// 5칸이 모두 채워진 행 `rowIndex`만 평가. 아니면 `null`.
  LineHandReport? evaluateRow(RummiBoard board, int rowIndex) {
    final line = board.fullLineOrNull(board.row(rowIndex));
    if (line == null) return null;
    return LineHandReport(evaluation: HandEvaluator.evaluateFive(line));
  }

  /// 5칸이 모두 채워진 열 `colIndex`만 평가.
  LineHandReport? evaluateCol(RummiBoard board, int colIndex) {
    final line = board.fullLineOrNull(board.col(colIndex));
    if (line == null) return null;
    return LineHandReport(evaluation: HandEvaluator.evaluateFive(line));
  }

  /// 주 대각선 (↘) 5칸이 모두 채워졌을 때만 평가.
  LineHandReport? evaluateDiagMain(RummiBoard board) {
    final line = board.fullLineOrNull(board.diagMain());
    if (line == null) return null;
    return LineHandReport(evaluation: HandEvaluator.evaluateFive(line));
  }

  /// 반대 대각선 (↙) 5칸이 모두 채워졌을 때만 평가.
  LineHandReport? evaluateDiagAnti(RummiBoard board) {
    final line = board.fullLineOrNull(board.diagAnti());
    if (line == null) return null;
    return LineHandReport(evaluation: HandEvaluator.evaluateFive(line));
  }

  /// 5칸이 모두 찬 **모든** 평가줄(최대 12개).
  List<({LineRef ref, LineHandReport report})> listFullLines(RummiBoard board) {
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
