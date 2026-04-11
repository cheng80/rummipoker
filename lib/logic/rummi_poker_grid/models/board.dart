import 'tile.dart';

const int kBoardSize = 5;

/// 5×5 보드. 빈 칸은 `null`.
class RummiBoard {
  RummiBoard() : _cells = List.generate(kBoardSize * kBoardSize, (_) => null);

  RummiBoard._(this._cells);

  final List<Tile?> _cells;

  /// 깊은 복사 (타일은 불변이라 참조 복사).
  RummiBoard copy() => RummiBoard._(List<Tile?>.from(_cells));

  int get indexLength => _cells.length;

  Tile? cellAt(int row, int col) {
    assert(row >= 0 && row < kBoardSize && col >= 0 && col < kBoardSize);
    return _cells[row * kBoardSize + col];
  }

  void setCell(int row, int col, Tile? tile) {
    assert(row >= 0 && row < kBoardSize && col >= 0 && col < kBoardSize);
    _cells[row * kBoardSize + col] = tile;
  }

  /// 행 0~4, 왼쪽→오른쪽 5장.
  List<Tile?> row(int r) =>
      List.generate(kBoardSize, (c) => cellAt(r, c));

  /// 열 0~4, 위→아래 5장.
  List<Tile?> col(int c) =>
      List.generate(kBoardSize, (r) => cellAt(r, c));

  /// 주 대각선 (0,0) → (4,4).
  List<Tile?> diagMain() =>
      List.generate(kBoardSize, (i) => cellAt(i, i));

  /// 반대 대각선 (0,4) → (4,0).
  List<Tile?> diagAnti() =>
      List.generate(kBoardSize, (i) => cellAt(i, kBoardSize - 1 - i));

  /// 5칸이 모두 타일이면 해당 리스트, 아니면 `null`.
  List<Tile>? fullLineOrNull(List<Tile?> line) {
    if (line.length != kBoardSize) return null;
    for (final t in line) {
      if (t == null) return null;
    }
    return line.cast<Tile>();
  }
}
