import 'package:rummipoker/logic/rummi_poker_grid/jester_meta.dart';
import 'package:rummipoker/logic/rummi_poker_grid/models/board.dart';
import 'package:rummipoker/logic/rummi_poker_grid/models/tile.dart';
import 'package:rummipoker/logic/rummi_poker_grid/rummi_poker_grid_session.dart';

import 'bot_policy.dart';

/// 즉시 점수보다 향후 좋은 족보 가능성과 자원 보존을 조금 더 보는 bot.
class PlannerBotPolicy extends BalanceSimBotPolicy {
  const PlannerBotPolicy();

  @override
  String get id => 'planner_v1';

  @override
  BalanceSimAction chooseAction(
    RummiPokerGridSession session, {
    required List<RummiJesterCard> jesters,
    required RummiJesterRuntimeSnapshot runtimeSnapshot,
  }) {
    if (session.canConfirmAllFullLines) {
      return const BalanceSimAction.confirm();
    }
    if (session.hand.isEmpty) {
      return session.canDrawFromDeck
          ? const BalanceSimAction.draw()
          : const BalanceSimAction.stop('no_hand_and_cannot_draw');
    }

    final placement = _bestPlacement(
      session,
      jesters: jesters,
      runtimeSnapshot: runtimeSnapshot,
    );
    if (placement != null) return placement.action;

    final discard = _conservativeDiscard(session);
    if (discard != null) return discard;

    return const BalanceSimAction.stop('no_legal_action');
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
          final clearsTarget =
              remainingScore > 0 && immediateScore >= remainingScore;
          if (clearsTarget) {
            // 클리어 가능한 배치는 더 좋은 모양을 기다리지 않고 즉시 선택한다.
            return _PlacementChoice(
              action: BalanceSimAction.place(
                handIndex: handIndex,
                row: row,
                col: col,
              ),
              clearsTarget: true,
              immediateScore: immediateScore,
              potentialScore: 0,
              boardPressure: RummiPokerGridSession.countTilesOnBoard(
                copy.board,
              ),
            );
          }
          final potentialScore = _plannerBoardPotentialScore(copy.board);
          final choice = _PlacementChoice(
            action: BalanceSimAction.place(
              handIndex: handIndex,
              row: row,
              col: col,
            ),
            clearsTarget: clearsTarget,
            immediateScore: immediateScore,
            potentialScore: potentialScore,
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
    // 클리어가 눈앞이면 잠재 모양보다 확정 가능한 점수를 먼저 본다.
    if (candidate.clearsTarget != best.clearsTarget) {
      return candidate.clearsTarget;
    }
    if (candidate.clearsTarget) {
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

  BalanceSimAction? _conservativeDiscard(RummiPokerGridSession session) {
    if (session.blind.boardDiscardsRemaining <= 0) return null;
    final occupancy = RummiPokerGridSession.countTilesOnBoard(session.board);
    if (occupancy < kBoardSize * kBoardSize - 1) return null;

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
    return BalanceSimAction.discardBoard(row: worstCell.$1, col: worstCell.$2);
  }
}

/// `planner_v1` 결과를 보존하면서 확정 타이밍과 자원 보존만 더 조심하는 bot.
class PlannerV2BotPolicy extends BalanceSimBotPolicy {
  const PlannerV2BotPolicy();

  static const int _cleanConfirmScoreFloor = 70;
  static const int _highPressureOccupancy = kBoardSize * kBoardSize - 3;

  @override
  String get id => 'planner_v2';

  @override
  BalanceSimAction chooseAction(
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
      return const BalanceSimAction.confirm();
    }
    if (session.hand.isEmpty) {
      if (session.canDrawFromDeck) return const BalanceSimAction.draw();
      if (confirmChoice.score > 0) return const BalanceSimAction.confirm();
      return const BalanceSimAction.stop('no_hand_and_cannot_draw');
    }

    final placement = _bestPlacement(
      session,
      jesters: jesters,
      runtimeSnapshot: runtimeSnapshot,
    );
    if (placement != null) return placement.action;

    if (confirmChoice.score > 0) return const BalanceSimAction.confirm();

    final discard = _lastResortDiscard(session);
    if (discard != null) return discard;

    return const BalanceSimAction.stop('no_legal_action');
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
    final remainingScore =
        session.blind.targetScore - session.blind.scoreTowardBlind;
    final occupancy = RummiPokerGridSession.countTilesOnBoard(session.board);
    final emptyCells = kBoardSize * kBoardSize - occupancy;

    // 클리어가 가능하면 더 좋은 족보를 기다리지 않는다.
    if (remainingScore > 0 && score >= remainingScore) {
      return _ConfirmChoice(score: score, shouldConfirmNow: true);
    }
    if (score >= _cleanConfirmScoreFloor) {
      return _ConfirmChoice(score: score, shouldConfirmNow: true);
    }
    // 보드 여유가 거의 없으면 낮은 점수라도 먼저 비워 락을 피한다.
    if (emptyCells <= 2 && score > 0) {
      return _ConfirmChoice(score: score, shouldConfirmNow: true);
    }
    return _ConfirmChoice(score: score, shouldConfirmNow: false);
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
          final clearsTarget =
              remainingScore > 0 && immediateScore >= remainingScore;
          if (clearsTarget) {
            return _PlacementChoice(
              action: BalanceSimAction.place(
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
            action: BalanceSimAction.place(
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

  BalanceSimAction? _lastResortDiscard(RummiPokerGridSession session) {
    if (session.blind.boardDiscardsRemaining <= 0) return null;
    final occupancy = RummiPokerGridSession.countTilesOnBoard(session.board);
    if (occupancy < _highPressureOccupancy) return null;

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
    return BalanceSimAction.discardBoard(row: worstCell.$1, col: worstCell.$2);
  }
}

class _ConfirmChoice {
  const _ConfirmChoice({required this.score, required this.shouldConfirmNow});

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

  final BalanceSimAction action;
  final bool clearsTarget;
  final int immediateScore;
  final int potentialScore;
  final int boardPressure;
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
  // 좋은 족보로 이어지는 축은 비워 둔 칸이 있어도 높게 평가한다.
  if (maxSameRank + missing >= 4) score += 90;
  if (pairCount >= 2 || pairCount == 1 && missing >= 2) score += 45;
  if (maxSameRank >= 3 && missing >= 1) score += 35;
  if (maxSameColor + missing >= 5) score += 65;
  if (straightRun + missing >= 5) score += 70;
  score += tiles.length * 2;

  // 같은 줄 안에서 색·숫자가 모두 흩어지면 확정 가능한 족보까지 오래 걸린다.
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
