import 'package:flutter/foundation.dart' show listEquals;

import 'hand_rank.dart';
import 'models/tile.dart';

/// 5장 포커 족보 판정. Flutter/Flame 의존 없음.
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

  /// 하이카드·원페어 — 양수 점수 없음 (`isDeadLineRank`).
  bool get isDeadLine => isDeadLineRank(rank);
}

class HandEvaluator {
  HandEvaluator._();

  /// 정확히 5장. 그 외는 assert 실패.
  static HandEvaluation evaluateFive(List<Tile> tiles) {
    assert(tiles.length == 5);
    final ranks = tiles.map((t) => t.number).toList()..sort();
    final byRank = <int, int>{};
    final indexesByRank = <int, List<int>>{};
    for (var i = 0; i < tiles.length; i++) {
      final n = tiles[i].number;
      byRank[n] = (byRank[n] ?? 0) + 1;
      indexesByRank.putIfAbsent(n, () => <int>[]).add(i);
    }
    final counts = byRank.values.toList()
      ..sort((a, b) => b.compareTo(a));
    final colors = tiles.map((t) => t.color).toSet();
    final flush = colors.length == 1;
    final straight = _isStraight(ranks);

    if (flush && straight) {
      return _result(
        RummiHandRank.straightFlush,
        contributingIndexes: const [0, 1, 2, 3, 4],
      );
    }
    if (listEquals(counts, <int>[4, 1])) {
      return _result(
        RummiHandRank.fourOfAKind,
        contributingIndexes: _indexesForCount(indexesByRank, 4),
      );
    }
    if (listEquals(counts, <int>[3, 2])) {
      return _result(
        RummiHandRank.fullHouse,
        contributingIndexes: const [0, 1, 2, 3, 4],
      );
    }
    if (flush) {
      return _result(
        RummiHandRank.flush,
        contributingIndexes: const [0, 1, 2, 3, 4],
      );
    }
    if (straight) {
      return _result(
        RummiHandRank.straight,
        contributingIndexes: const [0, 1, 2, 3, 4],
      );
    }
    if (listEquals(counts, <int>[3, 1, 1])) {
      return _result(
        RummiHandRank.threeOfAKind,
        contributingIndexes: _indexesForCount(indexesByRank, 3),
      );
    }
    if (listEquals(counts, <int>[2, 2, 1])) {
      return _result(
        RummiHandRank.twoPair,
        contributingIndexes: _indexesForCount(indexesByRank, 2),
      );
    }
    if (listEquals(counts, <int>[2, 1, 1, 1])) {
      return _result(
        RummiHandRank.onePair,
        contributingIndexes: _indexesForCount(indexesByRank, 2),
      );
    }
    return _result(
      RummiHandRank.highCard,
      contributingIndexes: const [],
    );
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
