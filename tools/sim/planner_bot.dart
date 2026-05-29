import 'dart:math';

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

/// 평균 플레이어 proxy.
///
/// 좋은 족보를 기다리기보다, 보드가 거의 찼을 때는 먼저 비워서 락을 피한다.
class PlannerV3BotPolicy extends PlannerV2BotPolicy {
  const PlannerV3BotPolicy();

  @override
  String get id => 'planner_v3';

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

    final occupancy = RummiPokerGridSession.countTilesOnBoard(session.board);
    final emptyCells = kBoardSize * kBoardSize - occupancy;
    if (emptyCells <= 3 && confirmChoice.score > 0) {
      return const BalanceSimAction.confirm();
    }
    if (emptyCells <= 4 && confirmChoice.score == 0) {
      final discard = _lastResortDiscard(session);
      if (discard != null) return discard;
    }

    return super.chooseAction(
      session,
      jesters: jesters,
      runtimeSnapshot: runtimeSnapshot,
    );
  }
}

/// 제출 QA 봇에서 검증된 일반 플레이 판단만 CLI 레벨링에 옮긴 proxy.
///
/// retry recovery, 실패 route 회피, seed 기반 보정은 넣지 않는다.
class FullRunPolicyV1BotPolicy extends BalanceSimBotPolicy {
  const FullRunPolicyV1BotPolicy();

  static const int _cleanConfirmScoreFloor = 70;
  static const int _highTargetConfirmTargetFloor = 600;
  static const int _highTargetTwoLineConfirmScoreFloor = 300;
  static const int _highTargetConfirmScoreFloor = 180;
  static const int _bossConfirmScoreFloor = 360;
  static const int _bossConfirmMinOccupancy = kBoardSize * 4;
  static const int _midBoardMoveMinOccupancy = kBoardSize * 2 + 2;
  static const int _midBoardMoveMaxOccupancy = kBoardSize * 4 - 1;
  static const int _midBoardMoveMinGain = 20;
  static const int _boardDiscardReplacementMinOccupancy = kBoardSize * 4;
  static const int _strategicDrawMaxOccupancy = kBoardSize * 4;
  static const int _midUtilityTargetScoreFloor = 500;
  static const int _lateDeckRemainingMax = 8;

  @override
  String get id => 'full_run_policy_v1';

  @override
  BalanceSimAction chooseAction(
    RummiPokerGridSession session, {
    required List<RummiJesterCard> jesters,
    required RummiJesterRuntimeSnapshot runtimeSnapshot,
  }) {
    final occupancy = RummiPokerGridSession.countTilesOnBoard(session.board);
    final boardIsFull = occupancy >= kBoardSize * kBoardSize;
    final confirmChoice = _contestConfirmChoice(
      session,
      jesters: jesters,
      runtimeSnapshot: runtimeSnapshot,
    );
    if (confirmChoice.shouldConfirmNow) {
      return const BalanceSimAction.confirm();
    }

    final shouldUseStrategicUtility =
        session.blind.bossModifier != null ||
        session.blind.targetScore >= _midUtilityTargetScoreFloor;

    if (session.hand.isEmpty) {
      if (session.canDrawFromDeck) return const BalanceSimAction.draw();
      if ((shouldUseStrategicUtility || boardIsFull) &&
          occupancy >= _boardDiscardReplacementMinOccupancy) {
        final discard = _scoringBoardDiscard(
          session,
          jesters: jesters,
          runtimeSnapshot: runtimeSnapshot,
        );
        if (discard != null) return discard;
      }
      if (confirmChoice.score > 0) return const BalanceSimAction.confirm();
      return const BalanceSimAction.stop('no_hand_and_cannot_draw');
    }

    if (shouldUseStrategicUtility &&
        occupancy >= _midBoardMoveMinOccupancy &&
        occupancy <= _midBoardMoveMaxOccupancy) {
      final move = _boardMove(
        session,
        jesters: jesters,
        runtimeSnapshot: runtimeSnapshot,
      );
      if (move != null && (move.gain ?? 0) >= _midBoardMoveMinGain) {
        return move;
      }
    }

    if (_shouldDrawForMoreOptions(
      session,
      occupancy: occupancy,
      confirmChoice: confirmChoice,
    )) {
      return const BalanceSimAction.draw();
    }

    final placement = _contestBestPlacement(
      session,
      jesters: jesters,
      runtimeSnapshot: runtimeSnapshot,
    );
    if (placement != null) return placement.action;

    if (confirmChoice.score > 0) return const BalanceSimAction.confirm();

    if ((shouldUseStrategicUtility || boardIsFull) &&
        occupancy >= _boardDiscardReplacementMinOccupancy) {
      final discard = _scoringBoardDiscard(
        session,
        jesters: jesters,
        runtimeSnapshot: runtimeSnapshot,
      );
      if (discard != null) return discard;
    }

    if (boardIsFull) {
      final handDiscard = _handDiscard(session);
      if (handDiscard != null) return handDiscard;
      if (confirmChoice.score > 0) return const BalanceSimAction.confirm();
    }

    return const BalanceSimAction.stop('no_legal_action');
  }

  _ConfirmChoice _contestConfirmChoice(
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
    final isBossBattle = session.blind.bossModifier != null;
    final isHighTarget =
        session.blind.targetScore >= _highTargetConfirmTargetFloor;

    if (remainingScore > 0 && score >= remainingScore) {
      return _ConfirmChoice(score: score, shouldConfirmNow: true);
    }
    if (lineCount < 2) {
      if (session.deck.remaining <= _lateDeckRemainingMax && score > 0) {
        return _ConfirmChoice(score: score, shouldConfirmNow: true);
      }
      return _ConfirmChoice(score: score, shouldConfirmNow: false);
    }
    if (isBossBattle) {
      final hasLargeBundle =
          score >= _bossConfirmScoreFloor &&
          (occupancy >= _bossConfirmMinOccupancy || lineCount >= 3);
      return _ConfirmChoice(
        score: score,
        shouldConfirmNow: hasLargeBundle || emptyCells <= 2 && score > 0,
      );
    }
    if (isHighTarget) {
      return _ConfirmChoice(
        score: score,
        shouldConfirmNow:
            score >= _highTargetTwoLineConfirmScoreFloor ||
            lineCount >= 3 && score >= _highTargetConfirmScoreFloor ||
            emptyCells == 0 && score > 0,
      );
    }
    if (score >= _cleanConfirmScoreFloor || emptyCells <= 2 && score > 0) {
      return _ConfirmChoice(score: score, shouldConfirmNow: true);
    }
    return _ConfirmChoice(score: score, shouldConfirmNow: false);
  }

  bool _shouldDrawForMoreOptions(
    RummiPokerGridSession session, {
    required int occupancy,
    required _ConfirmChoice confirmChoice,
  }) {
    if (session.maxHandSize <= 1 || !session.canDrawFromDeck) return false;
    if (session.hand.length >= session.maxHandSize) return false;
    if (confirmChoice.shouldConfirmNow) return false;
    if (session.deck.remaining <= _lateDeckRemainingMax &&
        confirmChoice.score > 0) {
      return false;
    }
    return occupancy <= _strategicDrawMaxOccupancy;
  }

  _PlacementChoice? _contestBestPlacement(
    RummiPokerGridSession session, {
    required List<RummiJesterCard> jesters,
    required RummiJesterRuntimeSnapshot runtimeSnapshot,
  }) {
    _PlacementChoice? best;
    final remainingScore =
        session.blind.targetScore - session.blind.scoreTowardBlind;
    final basePotential = _plannerBoardPotentialScoreForJesters(
      session.board,
      jesters,
    );

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
          final potentialScore = _plannerBoardPotentialScoreForJesters(
            copy.board,
            jesters,
          );
          final action = BalanceSimAction.place(
            handIndex: handIndex,
            row: row,
            col: col,
          );
          final choice = _PlacementChoice(
            action: action,
            clearsTarget:
                remainingScore > 0 && immediateScore >= remainingScore,
            immediateScore: immediateScore,
            potentialScore: potentialScore,
            lookaheadScore: _placementLookaheadScore(
              copy,
              row: row,
              col: col,
              basePotential: basePotential,
              jesters: jesters,
            ),
            boardPressure: RummiPokerGridSession.countTilesOnBoard(copy.board),
          );
          if (best == null || _isBetterContestPlacement(choice, best)) {
            best = choice;
          }
        }
      }
    }
    return best;
  }

  bool _isBetterContestPlacement(
    _PlacementChoice candidate,
    _PlacementChoice best,
  ) {
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
    if (candidate.lookaheadScore != best.lookaheadScore) {
      return candidate.lookaheadScore > best.lookaheadScore;
    }
    if (candidate.immediateScore != best.immediateScore) {
      return candidate.immediateScore > best.immediateScore;
    }
    return candidate.boardPressure < best.boardPressure;
  }

  int _placementLookaheadScore(
    RummiPokerGridSession afterPlacement, {
    required int row,
    required int col,
    required int basePotential,
    required List<RummiJesterCard> jesters,
  }) {
    final lines = <List<Tile?>>[
      afterPlacement.board.row(row),
      afterPlacement.board.col(col),
    ];
    if (row == col) lines.add(afterPlacement.board.diagMain());
    if (row + col == kBoardSize - 1) lines.add(afterPlacement.board.diagAnti());

    var nearlyCompleteLines = 0;
    var promisingLines = 0;
    for (final line in lines) {
      final filled = line.whereType<Tile>().length;
      final potential = _plannerLinePotentialScore(line);
      if (filled >= kBoardSize - 1 && potential > 0) nearlyCompleteLines++;
      if (filled >= 3 && potential > 0) promisingLines++;
    }

    var bestNextGain = 0;
    final currentPotential = _plannerBoardPotentialScoreForJesters(
      afterPlacement.board,
      jesters,
    );
    for (var index = 0; index < afterPlacement.hand.length; index++) {
      final nextPotential = _bestPlacementPotential(afterPlacement, index);
      final gain = nextPotential - currentPotential;
      if (gain > bestNextGain) bestNextGain = gain;
    }

    return currentPotential -
        basePotential +
        nearlyCompleteLines * 120 +
        promisingLines * 45 +
        bestNextGain;
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
        best = max(best, _plannerBoardPotentialScore(copy.board));
      }
    }
    return best == -1 << 30 ? 0 : best;
  }

  BalanceSimAction? _boardMove(
    RummiPokerGridSession session, {
    required List<RummiJesterCard> jesters,
    required RummiJesterRuntimeSnapshot runtimeSnapshot,
  }) {
    if (session.blind.boardMovesRemaining <= 0) return null;
    if (session.blind.boardMovesRemaining < session.blind.boardMovesMax) {
      return null;
    }
    _MoveChoice? best;
    for (var fromRow = 0; fromRow < kBoardSize; fromRow++) {
      for (var fromCol = 0; fromCol < kBoardSize; fromCol++) {
        if (session.board.cellAt(fromRow, fromCol) == null) continue;
        for (var toRow = 0; toRow < kBoardSize; toRow++) {
          for (var toCol = 0; toCol < kBoardSize; toCol++) {
            if (session.board.cellAt(toRow, toCol) != null) continue;
            final movedBoard = session.board.copy();
            if (!movedBoard.moveCell(
              fromRow: fromRow,
              fromCol: fromCol,
              toRow: toRow,
              toCol: toCol,
            )) {
              continue;
            }
            final followUp = _bestImmediateConfirmAfterBoardChange(
              session,
              movedBoard: movedBoard,
              jesters: jesters,
              runtimeSnapshot: runtimeSnapshot,
            );
            if (followUp.lineCount < 2 || followUp.score <= 0) continue;
            final potential = _plannerBoardPotentialScoreForJesters(
              movedBoard,
              jesters,
            );
            final choice = _MoveChoice(
              action: BalanceSimAction.moveBoard(
                row: fromRow,
                col: fromCol,
                toRow: toRow,
                toCol: toCol,
                gain: followUp.score,
              ),
              gain: followUp.score,
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
    return best?.action;
  }

  _ImmediateConfirmChoice _bestImmediateConfirmAfterBoardChange(
    RummiPokerGridSession session, {
    required RummiBoard movedBoard,
    required List<RummiJesterCard> jesters,
    required RummiJesterRuntimeSnapshot runtimeSnapshot,
  }) {
    var best = const _ImmediateConfirmChoice(score: 0, lineCount: 0);
    for (var handIndex = 0; handIndex < session.hand.length; handIndex++) {
      final tile = session.hand[handIndex];
      for (var row = 0; row < kBoardSize; row++) {
        for (var col = 0; col < kBoardSize; col++) {
          if (movedBoard.cellAt(row, col) != null) continue;
          final copy = session.copySnapshot();
          for (var r = 0; r < kBoardSize; r++) {
            for (var c = 0; c < kBoardSize; c++) {
              copy.board.setCell(r, c, movedBoard.cellAt(r, c));
            }
          }
          if (!copy.tryPlaceFromHand(tile, row, col)) continue;
          final preview = copy.confirmAllFullLines(
            jesters: jesters,
            runtimeSnapshot: runtimeSnapshot,
            applyScoreToBlind: false,
          );
          final choice = _ImmediateConfirmChoice(
            score: preview.result.scoreAdded,
            lineCount: preview.result.lineBreakdowns.length,
          );
          if (choice.lineCount > best.lineCount ||
              choice.lineCount == best.lineCount && choice.score > best.score) {
            best = choice;
          }
        }
      }
    }
    return best;
  }

  BalanceSimAction? _scoringBoardDiscard(
    RummiPokerGridSession session, {
    required List<RummiJesterCard> jesters,
    required RummiJesterRuntimeSnapshot runtimeSnapshot,
  }) {
    if (session.blind.boardDiscardsRemaining <= 0 || session.hand.isEmpty) {
      return null;
    }
    final currentPreview = session.copySnapshot().confirmAllFullLines(
      jesters: jesters,
      runtimeSnapshot: runtimeSnapshot,
      applyScoreToBlind: false,
    );
    final currentScore = currentPreview.result.scoreAdded;
    final currentLineCount = currentPreview.result.lineBreakdowns.length;
    _BoardDiscardChoice? best;
    for (var row = 0; row < kBoardSize; row++) {
      for (var col = 0; col < kBoardSize; col++) {
        if (session.board.cellAt(row, col) == null) continue;
        final afterDiscard = session.copySnapshot();
        afterDiscard.board.setCell(row, col, null);
        final afterDiscardPotential = _plannerBoardPotentialScoreForJesters(
          afterDiscard.board,
          jesters,
        );
        for (final tile in session.hand) {
          final copy = afterDiscard.copySnapshot();
          if (!copy.tryPlaceFromHand(tile, row, col)) continue;
          final preview = copy.confirmAllFullLines(
            jesters: jesters,
            runtimeSnapshot: runtimeSnapshot,
            applyScoreToBlind: false,
          );
          final lineCount = preview.result.lineBreakdowns.length;
          final score = preview.result.scoreAdded;
          final potentialScore = _plannerBoardPotentialScoreForJesters(
            copy.board,
            jesters,
          );
          final improvesConfirm =
              lineCount > currentLineCount ||
              lineCount == currentLineCount && score > currentScore;
          final revivesDeadLine =
              lineCount > 0 &&
              score > 0 &&
              potentialScore >= afterDiscardPotential;
          if (!improvesConfirm && !revivesDeadLine) continue;
          final choice = _BoardDiscardChoice(
            action: BalanceSimAction.discardBoard(row: row, col: col),
            immediateScore: score,
            potentialScore: potentialScore,
          );
          if (best == null ||
              choice.immediateScore > best.immediateScore ||
              choice.immediateScore == best.immediateScore &&
                  choice.potentialScore > best.potentialScore) {
            best = choice;
          }
        }
      }
    }
    return best?.action;
  }

  BalanceSimAction? _handDiscard(RummiPokerGridSession session) {
    if (session.blind.handDiscardsRemaining <= 0 || session.hand.isEmpty) {
      return null;
    }
    var worstIndex = 0;
    var worstPotential = 1 << 30;
    for (var index = 0; index < session.hand.length; index++) {
      final potential = _bestPlacementPotential(session, index);
      if (potential < worstPotential) {
        worstPotential = potential;
        worstIndex = index;
      }
    }
    return BalanceSimAction.discardHand(handIndex: worstIndex);
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
    this.lookaheadScore = 0,
    required this.boardPressure,
  });

  final BalanceSimAction action;
  final bool clearsTarget;
  final int immediateScore;
  final int potentialScore;
  final int lookaheadScore;
  final int boardPressure;
}

class _MoveChoice {
  const _MoveChoice({
    required this.action,
    required this.gain,
    required this.potential,
  });

  final BalanceSimAction action;
  final int gain;
  final int potential;
}

class _ImmediateConfirmChoice {
  const _ImmediateConfirmChoice({required this.score, required this.lineCount});

  final int score;
  final int lineCount;
}

class _BoardDiscardChoice {
  const _BoardDiscardChoice({
    required this.action,
    required this.immediateScore,
    required this.potentialScore,
  });

  final BalanceSimAction action;
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

int _plannerBoardPotentialScoreForJesters(
  RummiBoard board,
  List<RummiJesterCard> jesters,
) {
  var score = _plannerBoardPotentialScore(board);
  final wantsFlush = jesters.any(
    (jester) =>
        jester.conditionType == 'flush' ||
        jester.conditionType == 'tile_color_scored',
  );
  final wantsFourKind = jesters.any((jester) => jester.id == 'the_family');
  final wantsPairs = jesters.any(
    (jester) =>
        jester.id == 'clever_jester' ||
        jester.conditionType == 'two_pair' ||
        jester.conditionType == 'three_of_a_kind' ||
        jester.conditionType == 'four_of_a_kind' ||
        jester.conditionType == 'full_house',
  );
  if (!wantsFlush && !wantsPairs) return score;

  for (var row = 0; row < kBoardSize; row++) {
    score += _plannerJesterLineBonus(
      board.row(row),
      wantsFlush: wantsFlush,
      wantsFourKind: wantsFourKind,
      wantsPairs: wantsPairs,
    );
  }
  for (var col = 0; col < kBoardSize; col++) {
    score += _plannerJesterLineBonus(
      board.col(col),
      wantsFlush: wantsFlush,
      wantsFourKind: wantsFourKind,
      wantsPairs: wantsPairs,
    );
  }
  score += _plannerJesterLineBonus(
    board.diagMain(),
    wantsFlush: wantsFlush,
    wantsFourKind: wantsFourKind,
    wantsPairs: wantsPairs,
  );
  score += _plannerJesterLineBonus(
    board.diagAnti(),
    wantsFlush: wantsFlush,
    wantsFourKind: wantsFourKind,
    wantsPairs: wantsPairs,
  );
  return score;
}

int _plannerJesterLineBonus(
  List<Tile?> line, {
  required bool wantsFlush,
  required bool wantsFourKind,
  required bool wantsPairs,
}) {
  final tiles = line.whereType<Tile>().toList(growable: false);
  if (tiles.isEmpty) return 0;
  final missing = kBoardSize - tiles.length;
  final colorCounts = <TileColor, int>{};
  final rankCounts = <int, int>{};
  for (final tile in tiles) {
    colorCounts[tile.color] = (colorCounts[tile.color] ?? 0) + 1;
    rankCounts[tile.number] = (rankCounts[tile.number] ?? 0) + 1;
  }

  var bonus = 0;
  if (wantsFlush) {
    final maxSameColor = colorCounts.values.fold<int>(
      0,
      (maxValue, count) => count > maxValue ? count : maxValue,
    );
    if (maxSameColor + missing >= kBoardSize) {
      bonus += maxSameColor * 70 + (missing == 0 ? 280 : 0);
    }
  }
  if (wantsPairs) {
    final pairCount = rankCounts.values.where((count) => count >= 2).length;
    final maxSameRank = rankCounts.values.fold<int>(
      0,
      (maxValue, count) => count > maxValue ? count : maxValue,
    );
    if (wantsFourKind && maxSameRank + missing >= 4) {
      bonus += maxSameRank * 180 + (missing == 0 ? 520 : 0);
    }
    if (pairCount >= 2 || maxSameRank >= 3) {
      bonus += pairCount * 90 + maxSameRank * 55 + (missing == 0 ? 160 : 0);
    }
  }
  return bonus;
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
