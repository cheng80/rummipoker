import 'package:rummipoker/logic/rummi_poker_grid/jester_meta.dart';
import 'package:rummipoker/logic/rummi_poker_grid/models/board.dart';
import 'package:rummipoker/logic/rummi_poker_grid/models/tile.dart';
import 'package:rummipoker/logic/rummi_poker_grid/rummi_poker_grid_session.dart';

/// full-play integration test가 웹 타깃에서 직접 컴파일할 수 있는 전투 판단 경계.
abstract class CompetitionBattleBotPolicy {
  const CompetitionBattleBotPolicy();

  String get id;

  CompetitionBattleAction chooseAction(
    RummiPokerGridSession session, {
    required List<RummiJesterCard> jesters,
    required RummiJesterRuntimeSnapshot runtimeSnapshot,
  });
}

enum CompetitionBattleActionType {
  draw,
  place,
  confirm,
  discardHand,
  discardBoard,
  moveBoard,
  stop,
}

class CompetitionBattleAction {
  const CompetitionBattleAction._({
    required this.type,
    this.handIndex,
    this.row,
    this.col,
    this.toRow,
    this.toCol,
    this.reason,
  });

  const CompetitionBattleAction.draw()
    : this._(type: CompetitionBattleActionType.draw);

  const CompetitionBattleAction.confirm()
    : this._(type: CompetitionBattleActionType.confirm);

  const CompetitionBattleAction.place({
    required int handIndex,
    required int row,
    required int col,
  }) : this._(
         type: CompetitionBattleActionType.place,
         handIndex: handIndex,
         row: row,
         col: col,
       );

  const CompetitionBattleAction.discardBoard({
    required int row,
    required int col,
  }) : this._(
         type: CompetitionBattleActionType.discardBoard,
         row: row,
         col: col,
       );

  const CompetitionBattleAction.discardHand({required int handIndex})
    : this._(
        type: CompetitionBattleActionType.discardHand,
        handIndex: handIndex,
      );

  const CompetitionBattleAction.moveBoard({
    required int row,
    required int col,
    required int toRow,
    required int toCol,
  }) : this._(
         type: CompetitionBattleActionType.moveBoard,
         row: row,
         col: col,
         toRow: toRow,
         toCol: toCol,
       );

  const CompetitionBattleAction.stop(String reason)
    : this._(type: CompetitionBattleActionType.stop, reason: reason);

  final CompetitionBattleActionType type;
  final int? handIndex;
  final int? row;
  final int? col;
  final int? toRow;
  final int? toCol;
  final String? reason;

  @override
  String toString() {
    return switch (type) {
      CompetitionBattleActionType.draw => 'draw',
      CompetitionBattleActionType.confirm => 'confirm',
      CompetitionBattleActionType.place => 'place($handIndex,$row,$col)',
      CompetitionBattleActionType.discardHand => 'discardHand($handIndex)',
      CompetitionBattleActionType.discardBoard => 'discardBoard($row,$col)',
      CompetitionBattleActionType.moveBoard =>
        'moveBoard($row,$col->$toRow,$toCol)',
      CompetitionBattleActionType.stop => 'stop($reason)',
    };
  }
}

/// `tools/sim/planner_bot.dart`의 planner_v2 판단을 integration test용으로 옮긴다.
class CompetitionPlannerV2Policy extends CompetitionBattleBotPolicy {
  const CompetitionPlannerV2Policy();

  static const int _cleanConfirmScoreFloor = 70;
  static const int _highPressureOccupancy = kBoardSize * kBoardSize - 3;

  @override
  String get id => 'competition_planner_v2';

  @override
  CompetitionBattleAction chooseAction(
    RummiPokerGridSession session, {
    required List<RummiJesterCard> jesters,
    required RummiJesterRuntimeSnapshot runtimeSnapshot,
  }) {
    final confirmChoice = _currentConfirmChoice(
      session,
      jesters: jesters,
      runtimeSnapshot: runtimeSnapshot,
    );
    if (confirmChoice.shouldConfirmNow) {
      return const CompetitionBattleAction.confirm();
    }
    if (session.hand.isEmpty) {
      if (session.canDrawFromDeck) return const CompetitionBattleAction.draw();
      // 더 이상 드로우/배치가 불가능하면 카드 고갈 실패를 피하기 위해
      // 최소 2개 족보 조건을 마지막 수단으로만 완화한다.
      if (confirmChoice.shouldConfirmNow || confirmChoice.score > 0) {
        return const CompetitionBattleAction.confirm();
      }
      final discard = chooseBoardDiscard(session);
      if (discard != null) return discard;
      return const CompetitionBattleAction.stop('no_hand_and_cannot_draw');
    }

    final placement = _bestPlacement(
      session,
      jesters: jesters,
      runtimeSnapshot: runtimeSnapshot,
    );
    if (placement != null) return placement.action;

    if (confirmChoice.shouldConfirmNow) {
      return const CompetitionBattleAction.confirm();
    }

    final boardIsFull =
        RummiPokerGridSession.countTilesOnBoard(session.board) >=
        kBoardSize * kBoardSize;
    if (boardIsFull) {
      final scoringDiscard = _chooseScoringBoardDiscard(
        session,
        jesters: jesters,
        runtimeSnapshot: runtimeSnapshot,
      );
      if (scoringDiscard != null) return scoringDiscard;

      final handDiscard = chooseHandDiscard(session);
      if (handDiscard != null) return handDiscard;
    }

    final discard = chooseBoardDiscard(session);
    if (discard != null) return discard;

    return const CompetitionBattleAction.stop('no_legal_action');
  }

  CompetitionBattleAction? chooseHandDiscard(RummiPokerGridSession session) {
    if (session.blind.handDiscardsRemaining <= 0 || session.hand.isEmpty) {
      return null;
    }
    var worstIndex = 0;
    var worstPotential = 1 << 30;
    for (var index = 0; index < session.hand.length; index++) {
      final bestAfterKeepingTile = _bestPlacementPotential(session, index);
      if (bestAfterKeepingTile < worstPotential) {
        worstPotential = bestAfterKeepingTile;
        worstIndex = index;
      }
    }
    return CompetitionBattleAction.discardHand(handIndex: worstIndex);
  }

  CompetitionBattleAction? chooseBoardMove(RummiPokerGridSession session) {
    if (session.blind.boardMovesRemaining <= 0) return null;
    final basePotential = _plannerBoardPotentialScore(session.board);
    _MoveChoice? best;

    for (var fromRow = 0; fromRow < kBoardSize; fromRow++) {
      for (var fromCol = 0; fromCol < kBoardSize; fromCol++) {
        if (session.board.cellAt(fromRow, fromCol) == null) continue;
        for (var toRow = 0; toRow < kBoardSize; toRow++) {
          for (var toCol = 0; toCol < kBoardSize; toCol++) {
            if (session.board.cellAt(toRow, toCol) != null) continue;
            final copy = session.board.copy();
            if (!copy.moveCell(
              fromRow: fromRow,
              fromCol: fromCol,
              toRow: toRow,
              toCol: toCol,
            )) {
              continue;
            }
            final potential = _plannerBoardPotentialScore(copy);
            final choice = _MoveChoice(
              action: CompetitionBattleAction.moveBoard(
                row: fromRow,
                col: fromCol,
                toRow: toRow,
                toCol: toCol,
              ),
              gain: potential - basePotential,
              potential: potential,
            );
            if (best == null ||
                choice.gain > best.gain ||
                choice.gain == best.gain && choice.potential > best.potential) {
              best = choice;
            }
          }
        }
      }
    }
    if (best == null) return null;
    return best.action;
  }

  int _bestPlacementPotential(RummiPokerGridSession session, int handIndex) {
    if (handIndex < 0 || handIndex >= session.hand.length) return 0;
    final tile = session.hand[handIndex];
    var best = -1 << 30;
    for (var row = 0; row < kBoardSize; row++) {
      for (var col = 0; col < kBoardSize; col++) {
        if (session.board.cellAt(row, col) != null) continue;
        final copy = session.copySnapshot();
        if (!copy.tryPlaceFromHand(tile, row, col)) continue;
        final potential = _plannerBoardPotentialScore(copy.board);
        if (potential > best) best = potential;
      }
    }
    return best == -1 << 30 ? 0 : best;
  }

  _ConfirmChoice _currentConfirmChoice(
    RummiPokerGridSession session, {
    required List<RummiJesterCard> jesters,
    required RummiJesterRuntimeSnapshot runtimeSnapshot,
  }) {
    if (!session.canConfirmAllFullLines) {
      return const _ConfirmChoice(score: 0, shouldConfirmNow: false);
    }
    final preview = session.copySnapshot().confirmAllFullLines(
      jesters: jesters,
      runtimeSnapshot: runtimeSnapshot,
      applyScoreToBlind: false,
    );
    final score = preview.result.scoreAdded;
    final lineCount = preview.result.lineBreakdowns.length;
    final remainingScore =
        session.blind.targetScore - session.blind.scoreTowardBlind;
    final occupancy = RummiPokerGridSession.countTilesOnBoard(session.board);
    final emptyCells = kBoardSize * kBoardSize - occupancy;

    if (lineCount < 2) {
      return _ConfirmChoice(
        lineCount: lineCount,
        score: score,
        shouldConfirmNow: false,
      );
    }
    if (remainingScore > 0 && score >= remainingScore) {
      return _ConfirmChoice(
        lineCount: lineCount,
        score: score,
        shouldConfirmNow: true,
      );
    }
    if (score >= _cleanConfirmScoreFloor) {
      return _ConfirmChoice(
        lineCount: lineCount,
        score: score,
        shouldConfirmNow: true,
      );
    }
    if (emptyCells <= 2 && score > 0) {
      return _ConfirmChoice(
        lineCount: lineCount,
        score: score,
        shouldConfirmNow: true,
      );
    }
    return _ConfirmChoice(
      lineCount: lineCount,
      score: score,
      shouldConfirmNow: false,
    );
  }

  _PlacementChoice? _bestPlacement(
    RummiPokerGridSession session, {
    required List<RummiJesterCard> jesters,
    required RummiJesterRuntimeSnapshot runtimeSnapshot,
  }) {
    _PlacementChoice? best;
    final remainingScore =
        session.blind.targetScore - session.blind.scoreTowardBlind;

    for (var handIndex = 0; handIndex < session.hand.length; handIndex++) {
      final tile = session.hand[handIndex];
      for (var row = 0; row < kBoardSize; row++) {
        for (var col = 0; col < kBoardSize; col++) {
          if (session.board.cellAt(row, col) != null) continue;
          final copy = session.copySnapshot();
          if (!copy.tryPlaceFromHand(tile, row, col)) continue;

          final preview = copy.confirmAllFullLines(
            jesters: jesters,
            runtimeSnapshot: runtimeSnapshot,
            applyScoreToBlind: false,
          );
          final immediateScore = preview.result.scoreAdded;
          if (remainingScore > 0 && immediateScore >= remainingScore) {
            return _PlacementChoice(
              action: CompetitionBattleAction.place(
                handIndex: handIndex,
                row: row,
                col: col,
              ),
              clearsTarget: true,
              immediateScore: immediateScore,
              potentialScore: _plannerBoardPotentialScore(copy.board),
              boardPressure: RummiPokerGridSession.countTilesOnBoard(
                copy.board,
              ),
            );
          }

          final choice = _PlacementChoice(
            action: CompetitionBattleAction.place(
              handIndex: handIndex,
              row: row,
              col: col,
            ),
            clearsTarget: false,
            immediateScore: immediateScore,
            potentialScore: _plannerBoardPotentialScore(copy.board),
            boardPressure: RummiPokerGridSession.countTilesOnBoard(copy.board),
          );

          if (best == null || _isBetterPlacement(choice, best)) {
            best = choice;
          }
        }
      }
    }

    return best;
  }

  bool _isBetterPlacement(_PlacementChoice candidate, _PlacementChoice best) {
    if (candidate.clearsTarget != best.clearsTarget) {
      return candidate.clearsTarget;
    }
    if (candidate.immediateScore != best.immediateScore &&
        candidate.immediateScore >= _cleanConfirmScoreFloor) {
      return candidate.immediateScore > best.immediateScore;
    }
    if (candidate.potentialScore != best.potentialScore) {
      return candidate.potentialScore > best.potentialScore;
    }
    if (candidate.immediateScore != best.immediateScore) {
      return candidate.immediateScore > best.immediateScore;
    }
    return candidate.boardPressure < best.boardPressure;
  }

  CompetitionBattleAction? chooseBoardDiscard(
    RummiPokerGridSession session, {
    int minOccupancy = _highPressureOccupancy,
  }) {
    if (session.blind.boardDiscardsRemaining <= 0) return null;
    final occupancy = RummiPokerGridSession.countTilesOnBoard(session.board);
    if (occupancy < minOccupancy) return null;

    (int, int)? worstCell;
    var worstLoss = 1 << 30;
    final basePotential = _plannerBoardPotentialScore(session.board);
    for (var row = 0; row < kBoardSize; row++) {
      for (var col = 0; col < kBoardSize; col++) {
        if (session.board.cellAt(row, col) == null) continue;
        final copy = session.board.copy();
        copy.setCell(row, col, null);
        final loss = basePotential - _plannerBoardPotentialScore(copy);
        if (loss < worstLoss) {
          worstLoss = loss;
          worstCell = (row, col);
        }
      }
    }
    if (worstCell == null) return null;
    return CompetitionBattleAction.discardBoard(
      row: worstCell.$1,
      col: worstCell.$2,
    );
  }

  CompetitionBattleAction? _chooseScoringBoardDiscard(
    RummiPokerGridSession session, {
    required List<RummiJesterCard> jesters,
    required RummiJesterRuntimeSnapshot runtimeSnapshot,
  }) {
    if (session.blind.boardDiscardsRemaining <= 0 || session.hand.isEmpty) {
      return null;
    }

    _BoardDiscardChoice? best;
    for (var row = 0; row < kBoardSize; row++) {
      for (var col = 0; col < kBoardSize; col++) {
        if (session.board.cellAt(row, col) == null) continue;
        final copy = session.copySnapshot();
        copy.board.setCell(row, col, null);
        if (!copy.tryPlaceFromHand(session.hand.first, row, col)) continue;
        final preview = copy.confirmAllFullLines(
          jesters: jesters,
          runtimeSnapshot: runtimeSnapshot,
          applyScoreToBlind: false,
        );
        final immediateScore = preview.result.scoreAdded;
        if (immediateScore <= 0) continue;

        final choice = _BoardDiscardChoice(
          action: CompetitionBattleAction.discardBoard(row: row, col: col),
          immediateScore: immediateScore,
          potentialScore: _plannerBoardPotentialScore(copy.board),
        );
        if (best == null ||
            choice.immediateScore > best.immediateScore ||
            choice.immediateScore == best.immediateScore &&
                choice.potentialScore > best.potentialScore) {
          best = choice;
        }
      }
    }
    return best?.action;
  }
}

class _ConfirmChoice {
  const _ConfirmChoice({
    this.lineCount = 0,
    required this.score,
    required this.shouldConfirmNow,
  });

  final int lineCount;
  final int score;
  final bool shouldConfirmNow;
}

class _PlacementChoice {
  const _PlacementChoice({
    required this.action,
    required this.clearsTarget,
    required this.immediateScore,
    required this.potentialScore,
    required this.boardPressure,
  });

  final CompetitionBattleAction action;
  final bool clearsTarget;
  final int immediateScore;
  final int potentialScore;
  final int boardPressure;
}

class _MoveChoice {
  const _MoveChoice({
    required this.action,
    required this.gain,
    required this.potential,
  });

  final CompetitionBattleAction action;
  final int gain;
  final int potential;
}

class _BoardDiscardChoice {
  const _BoardDiscardChoice({
    required this.action,
    required this.immediateScore,
    required this.potentialScore,
  });

  final CompetitionBattleAction action;
  final int immediateScore;
  final int potentialScore;
}

int _plannerBoardPotentialScore(RummiBoard board) {
  var score = 0;
  for (var row = 0; row < kBoardSize; row++) {
    score += _plannerLinePotentialScore(board.row(row));
  }
  for (var col = 0; col < kBoardSize; col++) {
    score += _plannerLinePotentialScore(board.col(col));
  }
  score += _plannerLinePotentialScore(board.diagMain());
  score += _plannerLinePotentialScore(board.diagAnti());
  return score;
}

int _plannerLinePotentialScore(List<Tile?> line) {
  final tiles = line.whereType<Tile>().toList(growable: false);
  if (tiles.isEmpty) return 0;
  final missing = kBoardSize - tiles.length;
  final rankCounts = <int, int>{};
  final colorCounts = <TileColor, int>{};
  for (final tile in tiles) {
    rankCounts[tile.number] = (rankCounts[tile.number] ?? 0) + 1;
    colorCounts[tile.color] = (colorCounts[tile.color] ?? 0) + 1;
  }

  final maxSameRank = rankCounts.values.fold<int>(
    0,
    (maxValue, count) => count > maxValue ? count : maxValue,
  );
  final pairCount = rankCounts.values.where((count) => count >= 2).length;
  final maxSameColor = colorCounts.values.fold<int>(
    0,
    (maxValue, count) => count > maxValue ? count : maxValue,
  );
  final straightRun = _plannerLongestStraightRun(rankCounts.keys.toList());

  var score = 0;
  if (maxSameRank + missing >= 4) score += 90;
  if (pairCount >= 2 || pairCount == 1 && missing >= 2) score += 45;
  if (maxSameRank >= 3 && missing >= 1) score += 35;
  if (maxSameColor + missing >= 5) score += 65;
  if (straightRun + missing >= 5) score += 70;
  score += tiles.length * 2;

  if (missing <= 1 && maxSameRank < 2 && maxSameColor < 4 && straightRun < 4) {
    score -= 50;
  }
  return score;
}

int _plannerLongestStraightRun(List<int> ranks) {
  if (ranks.isEmpty) return 0;
  final normalized = ranks.toSet().toList()..sort();
  var best = 1;
  var current = 1;
  for (var index = 1; index < normalized.length; index++) {
    if (normalized[index] == normalized[index - 1] + 1) {
      current++;
    } else {
      current = 1;
    }
    if (current > best) best = current;
  }
  if (normalized.contains(1)) {
    final highAce = [...normalized.where((rank) => rank != 1), 14]..sort();
    current = 1;
    for (var index = 1; index < highAce.length; index++) {
      if (highAce[index] == highAce[index - 1] + 1) {
        current++;
      } else {
        current = 1;
      }
      if (current > best) best = current;
    }
  }
  return best;
}
