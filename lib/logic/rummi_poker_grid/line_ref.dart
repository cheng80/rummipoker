import 'models/board.dart';

/// 12줄 중 하나.
enum LineKind {
  row,
  col,
  diagMain,
  diagAnti,
}

/// 행/열은 `index` 0~4, 대각은 인덱스 미사용(항상 0).
class LineRef {
  const LineRef._(this.kind, this.index);

  factory LineRef.row(int r) {
    assert(r >= 0 && r < kBoardSize);
    return LineRef._(LineKind.row, r);
  }

  factory LineRef.col(int c) {
    assert(c >= 0 && c < kBoardSize);
    return LineRef._(LineKind.col, c);
  }

  static const LineRef diagMain = LineRef._(LineKind.diagMain, 0);
  static const LineRef diagAnti = LineRef._(LineKind.diagAnti, 0);

  final LineKind kind;
  final int index;

  /// 이 줄이 차지하는 `(row,col)` 목록(항상 5칸).
  List<(int, int)> cells() {
    return switch (kind) {
      LineKind.row => List.generate(kBoardSize, (c) => (index, c)),
      LineKind.col => List.generate(kBoardSize, (r) => (r, index)),
      LineKind.diagMain => List.generate(kBoardSize, (i) => (i, i)),
      LineKind.diagAnti =>
        List.generate(kBoardSize, (i) => (i, kBoardSize - 1 - i)),
    };
  }

  @override
  bool operator ==(Object other) =>
      other is LineRef && other.kind == kind && other.index == index;

  @override
  int get hashCode => Object.hash(kind, index);
}
