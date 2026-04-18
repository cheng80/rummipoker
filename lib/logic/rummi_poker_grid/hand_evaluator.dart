import 'package:flutter/foundation.dart' show listEquals;

import 'hand_rank.dart';
import 'models/tile.dart';

/// 2~5장 부분 족보 판정. Flutter/Flame 의존 없음.
///
/// 스트레이트: 일반 연속 `n..n+4`(1≤n≤9) + 휠 **10–11–12–13–1** (`game_logic` §4.1).
class HandEvaluation {
  const HandEvaluation({
    required this.rank,
    required this.baseScore,
    required this.canClearLine,
    required this.contributingIndexes,
  });

  final RummiHandRank rank;
  final int baseScore;
  final bool canClearLine;
  final List<int> contributingIndexes;

  /// 현재 룰에서 점수 없는 줄은 하이카드만이다.
  bool get isDeadLine => isDeadLineRank(rank);
}

class HandEvaluator {
  HandEvaluator._();

  /// 한 줄의 5칸을 평가한다. 빈 칸은 허용하되, 기여 인덱스는 원래 줄 좌표 기준으로 반환한다.
  static HandEvaluation evaluateLine(List<Tile?> line) {
    assert(line.length == 5);
    final present = <({int index, Tile tile})>[
      for (var i = 0; i < line.length; i++)
        if (line[i] != null) (index: i, tile: line[i]!),
    ];
    if (present.length <= 1) {
      return _result(RummiHandRank.highCard, contributingIndexes: const []);
    }

    final tiles = [for (final entry in present) entry.tile];
    final originalIndexes = [for (final entry in present) entry.index];
    final ranks = tiles.map((t) => t.number).toList()..sort();
    final byRank = <int, int>{};
    final indexesByRank = <int, List<int>>{};
    for (var i = 0; i < tiles.length; i++) {
      final n = tiles[i].number;
      byRank[n] = (byRank[n] ?? 0) + 1;
      indexesByRank.putIfAbsent(n, () => <int>[]).add(i);
    }
    final counts = byRank.values.toList()..sort((a, b) => b.compareTo(a));
    final colors = tiles.map((t) => t.color).toSet();
    final flush = colors.length == 1;
    final straight = _isStraight(ranks);

    switch (tiles.length) {
      case 5:
        if (flush && straight) {
          return _result(
            RummiHandRank.straightFlush,
            contributingIndexes: List<int>.unmodifiable(originalIndexes),
          );
        }
        if (listEquals(counts, <int>[4, 1])) {
          return _result(
            RummiHandRank.fourOfAKind,
            contributingIndexes: _mapIndexes(
              originalIndexes,
              _indexesForCount(indexesByRank, 4),
            ),
          );
        }
        if (listEquals(counts, <int>[3, 2])) {
          return _result(
            RummiHandRank.fullHouse,
            contributingIndexes: List<int>.unmodifiable(originalIndexes),
          );
        }
        if (flush) {
          return _result(
            RummiHandRank.flush,
            contributingIndexes: List<int>.unmodifiable(originalIndexes),
          );
        }
        if (straight) {
          return _result(
            RummiHandRank.straight,
            contributingIndexes: List<int>.unmodifiable(originalIndexes),
          );
        }
        if (listEquals(counts, <int>[3, 1, 1])) {
          return _result(
            RummiHandRank.threeOfAKind,
            contributingIndexes: _mapIndexes(
              originalIndexes,
              _indexesForCount(indexesByRank, 3),
            ),
          );
        }
        if (listEquals(counts, <int>[2, 2, 1])) {
          return _result(
            RummiHandRank.twoPair,
            contributingIndexes: _mapIndexes(
              originalIndexes,
              _indexesForCount(indexesByRank, 2),
            ),
          );
        }
        if (listEquals(counts, <int>[2, 1, 1, 1])) {
          return _result(
            RummiHandRank.onePair,
            contributingIndexes: _mapIndexes(
              originalIndexes,
              _indexesForCount(indexesByRank, 2),
            ),
          );
        }
      case 4:
        if (listEquals(counts, <int>[4])) {
          return _result(
            RummiHandRank.fourOfAKind,
            contributingIndexes: List<int>.unmodifiable(originalIndexes),
          );
        }
        if (listEquals(counts, <int>[2, 2])) {
          return _result(
            RummiHandRank.twoPair,
            contributingIndexes: _mapIndexes(
              originalIndexes,
              _indexesForCount(indexesByRank, 2),
            ),
          );
        }
        if (listEquals(counts, <int>[3, 1])) {
          return _result(
            RummiHandRank.threeOfAKind,
            contributingIndexes: _mapIndexes(
              originalIndexes,
              _indexesForCount(indexesByRank, 3),
            ),
          );
        }
        if (listEquals(counts, <int>[2, 1, 1])) {
          return _result(
            RummiHandRank.onePair,
            contributingIndexes: _mapIndexes(
              originalIndexes,
              _indexesForCount(indexesByRank, 2),
            ),
          );
        }
      case 3:
        if (listEquals(counts, <int>[3])) {
          return _result(
            RummiHandRank.threeOfAKind,
            contributingIndexes: List<int>.unmodifiable(originalIndexes),
          );
        }
        if (listEquals(counts, <int>[2, 1])) {
          return _result(
            RummiHandRank.onePair,
            contributingIndexes: _mapIndexes(
              originalIndexes,
              _indexesForCount(indexesByRank, 2),
            ),
          );
        }
      case 2:
        if (listEquals(counts, <int>[2])) {
          return _result(
            RummiHandRank.onePair,
            contributingIndexes: List<int>.unmodifiable(originalIndexes),
          );
        }
    }

    return _result(RummiHandRank.highCard, contributingIndexes: const []);
  }

  static HandEvaluation evaluateFive(List<Tile> tiles) {
    assert(tiles.length == 5);
    return evaluateLine(tiles);
  }

  static HandEvaluation _result(
    RummiHandRank rank, {
    required List<int> contributingIndexes,
  }) {
    return HandEvaluation(
      rank: rank,
      baseScore: gddBaseScore(rank),
      canClearLine: gddCanClearLine(rank),
      contributingIndexes: List.unmodifiable(contributingIndexes),
    );
  }

  static List<int> _indexesForCount(
    Map<int, List<int>> indexesByRank,
    int count,
  ) {
    final out = <int>[];
    for (final entry in indexesByRank.entries) {
      if (entry.value.length == count) {
        out.addAll(entry.value);
      }
    }
    out.sort();
    return out;
  }

  static List<int> _mapIndexes(
    List<int> originalIndexes,
    List<int> localIndexes,
  ) {
    final out = <int>[];
    for (final index in localIndexes) {
      if (index < 0 || index >= originalIndexes.length) continue;
      out.add(originalIndexes[index]);
    }
    out.sort();
    return out;
  }

  /// 5장 숫자가 모두 다를 때: 일반 연속 `n..n+4` 또는 휠 `1,10,11,12,13`.
  static bool _isStraight(List<int> sortedRanks) {
    if (sortedRanks.length != 5) return false;
    if (sortedRanks.toSet().length != 5) return false;
    // 정렬 후 [1,10,11,12,13] 이면 휠 스트레이트 (10–J–Q–K–A, A=1).
    if (sortedRanks[0] == 1 &&
        sortedRanks[1] == 10 &&
        sortedRanks[2] == 11 &&
        sortedRanks[3] == 12 &&
        sortedRanks[4] == 13) {
      return true;
    }
    final lo = sortedRanks.first;
    final hi = sortedRanks.last;
    if (hi - lo != 4) return false;
    for (var i = 0; i < 5; i++) {
      if (sortedRanks[i] != lo + i) return false;
    }
    return lo >= 1 && hi <= 13;
  }
}
