import 'dart:math';

import 'board.dart';
import 'tile.dart';

const int kTileRanks = 13;
const int kTileColors = 4;
const int kBasePokerTileCount = kTileRanks * kTileColors;
const int kDefaultCopiesPerTile = 1;

int totalDeckSizeForCopies(int copiesPerTile) =>
    kBasePokerTileCount * copiesPerTile;

/// 럼미 스타일 포커 덱. `(색, 랭크)` 조합당 [copiesPerTile]장.
List<Tile> buildStandardPokerDeck({int copiesPerTile = kDefaultCopiesPerTile}) {
  assert(copiesPerTile > 0);
  final out = <Tile>[];
  for (final c in TileColor.values) {
    for (var n = 1; n <= 13; n++) {
      for (var copyIndex = 0; copyIndex < copiesPerTile; copyIndex++) {
        out.add(Tile(color: c, number: n, id: copyIndex));
      }
    }
  }
  assert(out.length == totalDeckSizeForCopies(copiesPerTile));
  return out;
}

/// 표준 덱에서 보드·손패에 이미 있는 타일을 제외한 드로우 더미.
List<Tile> tilesRemainingForBoardAndHand({
  required RummiBoard board,
  List<Tile> hand = const [],
  int copiesPerTile = kDefaultCopiesPerTile,
}) {
  final all = List<Tile>.from(
    buildStandardPokerDeck(copiesPerTile: copiesPerTile),
  );
  void takeAway(Tile? tile) {
    if (tile == null) return;
    final i = all.indexWhere((t) => t == tile);
    if (i >= 0) all.removeAt(i);
  }

  for (var r = 0; r < kBoardSize; r++) {
    for (var c = 0; c < kBoardSize; c++) {
      takeAway(board.cellAt(r, c));
    }
  }
  for (final t in hand) {
    takeAway(t);
  }
  return all;
}

/// 드로우 전용 더미. 뽑힌 카드는 세션(손·보드 등)이 보관한다.
class PokerDeck {
  PokerDeck._(List<Tile> pile) : _pile = pile;

  factory PokerDeck.fromSnapshot(List<Tile> pile) {
    return PokerDeck._(List<Tile>.from(pile));
  }

  /// [source]를 섞아 새 덱을 만든다. 기본은 표준 덱.
  factory PokerDeck.shuffled([
    Random? random,
    List<Tile>? source,
    int copiesPerTile = kDefaultCopiesPerTile,
  ]) {
    final tiles = List<Tile>.from(
      source ?? buildStandardPokerDeck(copiesPerTile: copiesPerTile),
    );
    tiles.shuffle(random ?? Random());
    return PokerDeck._(tiles);
  }

  /// 이미 보드·손 등에 나간 타일을 제외한 **나머지**를 드로우 더미로 쓴다.
  factory PokerDeck.remainingAfterPlaced({
    required RummiBoard board,
    List<Tile> hand = const [],
    Random? random,
    int copiesPerTile = kDefaultCopiesPerTile,
  }) {
    final remaining = tilesRemainingForBoardAndHand(
      board: board,
      hand: hand,
      copiesPerTile: copiesPerTile,
    );
    remaining.shuffle(random ?? Random());
    return PokerDeck._(remaining);
  }

  final List<Tile> _pile;

  List<Tile> snapshotPile() => List<Tile>.unmodifiable(_pile);

  int get remaining => _pile.length;

  bool get isEmpty => _pile.isEmpty;

  List<Tile> peekTop(int count) {
    if (count <= 0 || _pile.isEmpty) return const [];
    final takeCount = count > _pile.length ? _pile.length : count;
    return List<Tile>.unmodifiable(
      List.generate(takeCount, (index) => _pile[_pile.length - 1 - index]),
    );
  }

  void resetShuffled({
    Random? random,
    List<Tile>? source,
    int copiesPerTile = kDefaultCopiesPerTile,
  }) {
    _pile
      ..clear()
      ..addAll(source ?? buildStandardPokerDeck(copiesPerTile: copiesPerTile));
    _pile.shuffle(random ?? Random());
  }

  /// 맨 위(끝) 한 장. 없으면 `null`.
  Tile? draw() {
    if (_pile.isEmpty) return null;
    return _pile.removeLast();
  }

  Tile? discardFromTopWindow({required int topIndex, required int windowSize}) {
    if (topIndex < 0 || windowSize <= 0) return null;
    final visible = peekTop(windowSize);
    if (topIndex >= visible.length) return null;
    return _pile.removeAt(_pile.length - 1 - topIndex);
  }
}
