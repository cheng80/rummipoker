import 'dart:math';

import 'package:rummipoker/logic/rummi_poker_grid/boss_modifier.dart';
import 'package:rummipoker/logic/rummi_poker_grid/jester_meta.dart';
import 'package:rummipoker/logic/rummi_poker_grid/models/board.dart';
import 'package:rummipoker/logic/rummi_poker_grid/models/tile.dart';
import 'package:rummipoker/logic/rummi_poker_grid/rummi_poker_grid_session.dart';

/// full-play integration test가 웹 타깃에서 직접 컴파일할 수 있는 전투 판단 경계.
abstract class FullRunBattleBotPolicy {
  const FullRunBattleBotPolicy();

  String get id;

  FullRunBattleAction chooseAction(
    RummiPokerGridSession session, {
    required List<RummiJesterCard> jesters,
    required RummiJesterRuntimeSnapshot runtimeSnapshot,
  });
}

enum FullRunBattleActionType {
  draw,
  place,
  confirm,
  discardHand,
  discardBoard,
  moveBoard,
  stop,
}

bool fullRunBattleItemOpSupportsPlannedAction(
  String op,
  FullRunBattleActionType plannedActionType,
) {
  return switch (op) {
    'add_board_move' => plannedActionType == FullRunBattleActionType.moveBoard,
    'mark_next_board_move_bonus' =>
      plannedActionType == FullRunBattleActionType.moveBoard,
    'add_board_discard' =>
      plannedActionType == FullRunBattleActionType.discardBoard,
    'add_hand_discard' =>
      plannedActionType == FullRunBattleActionType.discardHand,
    'chips_bonus' ||
    'mult_bonus' ||
    'xmult_bonus' ||
    'temporary_overlap_cap_bonus' ||
    'add_percent_of_first_confirm_score' =>
      plannedActionType == FullRunBattleActionType.confirm,
    'draw_if_hand_empty' || 'increase_hand_size' || 'peek_deck_discard_one' =>
      plannedActionType == FullRunBattleActionType.draw,
    _ => false,
  };
}

class FullRunBattleAction {
  const FullRunBattleAction._({
    required this.type,
    this.handIndex,
    this.row,
    this.col,
    this.toRow,
    this.toCol,
    this.gain,
    this.reason,
  });

  const FullRunBattleAction.draw() : this._(type: FullRunBattleActionType.draw);

  const FullRunBattleAction.confirm()
    : this._(type: FullRunBattleActionType.confirm);

  const FullRunBattleAction.place({
    required int handIndex,
    required int row,
    required int col,
  }) : this._(
         type: FullRunBattleActionType.place,
         handIndex: handIndex,
         row: row,
         col: col,
       );

  const FullRunBattleAction.discardBoard({required int row, required int col})
    : this._(type: FullRunBattleActionType.discardBoard, row: row, col: col);

  const FullRunBattleAction.discardHand({required int handIndex})
    : this._(type: FullRunBattleActionType.discardHand, handIndex: handIndex);

  const FullRunBattleAction.moveBoard({
    required int row,
    required int col,
    required int toRow,
    required int toCol,
    int? gain,
  }) : this._(
         type: FullRunBattleActionType.moveBoard,
         row: row,
         col: col,
         toRow: toRow,
         toCol: toCol,
         gain: gain,
       );

  const FullRunBattleAction.stop(String reason)
    : this._(type: FullRunBattleActionType.stop, reason: reason);

  final FullRunBattleActionType type;
  final int? handIndex;
  final int? row;
  final int? col;
  final int? toRow;
  final int? toCol;
  final int? gain;
  final String? reason;

  @override
  String toString() {
    return switch (type) {
      FullRunBattleActionType.draw => 'draw',
      FullRunBattleActionType.confirm => 'confirm',
      FullRunBattleActionType.place => 'place($handIndex,$row,$col)',
      FullRunBattleActionType.discardHand => 'discardHand($handIndex)',
      FullRunBattleActionType.discardBoard => 'discardBoard($row,$col)',
      FullRunBattleActionType.moveBoard =>
        'moveBoard($row,$col->$toRow,$toCol)',
      FullRunBattleActionType.stop => 'stop($reason)',
    };
  }
}

String fullRunBattleActionRouteKey(FullRunBattleAction action) {
  return switch (action.type) {
    FullRunBattleActionType.place =>
      'place:${action.handIndex}:${action.row}:${action.col}',
    FullRunBattleActionType.discardHand => 'discardHand:${action.handIndex}',
    FullRunBattleActionType.discardBoard =>
      'discardBoard:${action.row}:${action.col}',
    FullRunBattleActionType.moveBoard =>
      'moveBoard:${action.row}:${action.col}:${action.toRow}:${action.toCol}',
    FullRunBattleActionType.confirm => 'confirm',
    FullRunBattleActionType.draw => 'draw',
    FullRunBattleActionType.stop => 'stop:${action.reason ?? ''}',
  };
}

/// `tools/sim/planner_bot.dart`의 planner_v2 판단을 integration test용으로 옮긴다.
class FullRunPlannerV2Policy extends FullRunBattleBotPolicy {
  const FullRunPlannerV2Policy({
    this.enableRetryRecoveryConfirmDelay = false,
    this.retryRecoveryAttempt = 0,
    this.avoidedActionRouteKeys = const <String>{},
  });

  final bool enableRetryRecoveryConfirmDelay;
  final int retryRecoveryAttempt;
  final Set<String> avoidedActionRouteKeys;

  static const int _cleanConfirmScoreFloor = 70;
  static const int _highTargetConfirmScoreFloor = 180;
  static const int _highTargetTwoLineConfirmScoreFloor = 300;
  static const int _highTargetConfirmTargetFloor = 600;
  static const int _bossConfirmScoreFloor = 360;
  static const int _bossRetryConfirmScoreFloor = 360;
  static const int _retryRecoveryConfirmHoldScoreFloor = 520;
  static const int _bossConfirmMinOccupancy = kBoardSize * 4;
  static const int _midBoardMoveMinOccupancy = kBoardSize * 2 + 2;
  static const int _midBoardMoveMaxOccupancy = kBoardSize * 4 - 1;
  static const int _midBoardMoveMinGain = 20;
  static const int _lateDeckBoardMoveMinOccupancy = kBoardSize * 2;
  static const int _lateDeckUtilityRemainingMax = 12;
  static const int _mysticBoardDiscardMinOccupancy = kBoardSize * 4 - 2;
  static const int _boardDiscardReplacementMinOccupancy = kBoardSize * 4;
  static const int _strategicDrawMaxOccupancy = kBoardSize * 4;
  static const int _strategicUtilityTargetScoreFloor = 1000;
  static const double _battleLateProgressFloor = 0.65;
  static const int _failedRouteActionPenalty = 900;
  static const int _retryDeckLookaheadTileCount = 5;
  static const int _lateRetryConfirmShortageWindow = 320;
  static const int _retryPressureSingleLineConfirmFloor =
      _highTargetConfirmScoreFloor;
  @override
  String get id => 'full_run_planner_v2_tempo_clear';

  @override
  FullRunBattleAction chooseAction(
    RummiPokerGridSession session, {
    required List<RummiJesterCard> jesters,
    required RummiJesterRuntimeSnapshot runtimeSnapshot,
  }) {
    final occupancy = RummiPokerGridSession.countTilesOnBoard(session.board);
    final boardIsFull = _hasNoOpenPlayableCells(session);
    final confirmChoice = _currentConfirmChoice(
      session,
      jesters: jesters,
      runtimeSnapshot: runtimeSnapshot,
    );
    if (confirmChoice.shouldConfirmNow &&
        !_shouldTryBoardFullRecoveryBeforeConfirm(session, confirmChoice) &&
        !_shouldDelayLateRetryConfirmForRemaining(
          session,
          confirmChoice,
          boardIsFull: boardIsFull,
        ) &&
        !_shouldDelayRetryConfirmForPlacement(
          session,
          confirmChoice,
          boardIsFull: boardIsFull,
        )) {
      return const FullRunBattleAction.confirm();
    }
    final shouldUseStrategicUtility = _shouldUseStrategicUtility(session);
    if (session.hand.isEmpty) {
      if (_shouldUseBoardBlockTempoClear(session) &&
          confirmChoice.lineCount >= 1 &&
          confirmChoice.score > 0) {
        return const FullRunBattleAction.confirm();
      }
      if (session.canDrawFromDeck) return const FullRunBattleAction.draw();
      if ((shouldUseStrategicUtility || boardIsFull) &&
          _canUseBoardDiscardUtility(session) &&
          occupancy >= _boardDiscardReplacementMinOccupancy) {
        final scoringDiscard = chooseScoringBoardDiscard(
          session,
          jesters: jesters,
          runtimeSnapshot: runtimeSnapshot,
        );
        if (scoringDiscard != null) return scoringDiscard;
      }
      if (boardIsFull) {
        final recoveryDiscard = chooseRecoveryBoardDiscard(
          session,
          jesters: jesters,
          runtimeSnapshot: runtimeSnapshot,
        );
        if (recoveryDiscard != null) return recoveryDiscard;
      }
      // 더 이상 드로우/배치가 불가능하면 카드 고갈 실패를 피하기 위해
      // 최소 2개 족보 조건을 마지막 수단으로만 완화한다.
      if (confirmChoice.shouldConfirmNow || confirmChoice.score > 0) {
        return const FullRunBattleAction.confirm();
      }
      return const FullRunBattleAction.stop('no_hand_and_cannot_draw');
    }

    if (boardIsFull &&
        !_canUseBoardDiscardUtility(session) &&
        confirmChoice.score > 0) {
      return const FullRunBattleAction.confirm();
    }

    if (_shouldUseBoardMoveNow(
      session,
      occupancy: occupancy,
      shouldUseStrategicUtility: shouldUseStrategicUtility,
    )) {
      final move = chooseBoardMove(
        session,
        jesters: jesters,
        runtimeSnapshot: runtimeSnapshot,
      );
      final minGain = _shouldSpendBoardMoveBeforeBoardLock(
        session,
        occupancy: occupancy,
      )
          ? 1
          : _midBoardMoveMinGain;
      if (move != null && (move.gain ?? 0) >= minGain) {
        return move;
      }
    }

    if (_shouldContinueBoardDiscardMoveCombo(session)) {
      final move = chooseBoardMove(
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
      return const FullRunBattleAction.draw();
    }

    if (_shouldSpendBoardDiscardForMystic(session, jesters)) {
      final mysticDiscard = chooseMysticBoardDiscard(
        session,
        jesters: jesters,
        runtimeSnapshot: runtimeSnapshot,
      );
      if (mysticDiscard != null) return mysticDiscard;
    }

    final placement = _bestPlacement(
      session,
      jesters: jesters,
      runtimeSnapshot: runtimeSnapshot,
    );
    if (placement != null) return placement.action;

    if (confirmChoice.shouldConfirmNow) {
      return const FullRunBattleAction.confirm();
    }

    if ((shouldUseStrategicUtility || boardIsFull) &&
        _canUseBoardDiscardUtility(session) &&
        occupancy >= _boardDiscardReplacementMinOccupancy) {
      final scoringDiscard = chooseScoringBoardDiscard(
        session,
        jesters: jesters,
        runtimeSnapshot: runtimeSnapshot,
      );
      if (scoringDiscard != null) return scoringDiscard;
    }

    if (boardIsFull) {
      final recoveryDiscard = chooseRecoveryBoardDiscard(
        session,
        jesters: jesters,
        runtimeSnapshot: runtimeSnapshot,
      );
      if (recoveryDiscard != null) return recoveryDiscard;

      final pressureDiscard = chooseBoardDiscard(session, minOccupancy: 0);
      if (pressureDiscard != null) return pressureDiscard;

      if (_shouldConfirmInsteadOfLateHandDiscard(session, confirmChoice)) {
        return const FullRunBattleAction.confirm();
      }

      final handDiscard = chooseHandDiscard(session);
      if (handDiscard != null) return handDiscard;

      // 보드가 꽉 찬 뒤 버림 수단도 없으면 2족보 원칙보다 진행 지속을 우선한다.
      if (confirmChoice.score > 0) {
        return const FullRunBattleAction.confirm();
      }
    }

    return const FullRunBattleAction.stop('no_legal_action');
  }

  FullRunBattleAction? chooseHandDiscard(RummiPokerGridSession session) {
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
    return FullRunBattleAction.discardHand(handIndex: worstIndex);
  }

  FullRunBattleAction? chooseBoardMove(
    RummiPokerGridSession session, {
    required List<RummiJesterCard> jesters,
    required RummiJesterRuntimeSnapshot runtimeSnapshot,
  }) {
    if (session.blind.boardMovesRemaining <= 0) return null;
    final allowsRepeatedStrategicMove = _allowsRepeatedStrategicBoardMove(
      session,
    );
    if (!allowsRepeatedStrategicMove &&
        session.blind.boardMovesRemaining < session.blind.boardMovesMax) {
      return null;
    }
    if (!allowsRepeatedStrategicMove && session.boardMoveHistory.isNotEmpty) {
      return null;
    }
    _MoveChoice? best;
    final blockedCellKeys = _blockedCellKeysForSession(session);
    final acceptsBoardLockTempoMove = _shouldSpendBoardMoveBeforeBoardLock(
      session,
      occupancy: RummiPokerGridSession.countTilesOnBoard(session.board),
    );
    final basePotential = acceptsBoardLockTempoMove
        ? _plannerBoardPotentialScoreForJesters(
            session.board,
            jesters,
            blockedCellKeys: blockedCellKeys,
          )
        : 0;

    for (var fromRow = 0; fromRow < kBoardSize; fromRow++) {
      for (var fromCol = 0; fromCol < kBoardSize; fromCol++) {
        if (session.board.cellAt(fromRow, fromCol) == null) continue;
        for (var toRow = 0; toRow < kBoardSize; toRow++) {
          for (var toCol = 0; toCol < kBoardSize; toCol++) {
            if (session.board.cellAt(toRow, toCol) != null) continue;
            if (blockedCellKeys.contains(_boardCellKey(toRow, toCol))) {
              continue;
            }
            final copy = session.board.copy();
            if (!copy.moveCell(
              fromRow: fromRow,
              fromCol: fromCol,
              toRow: toRow,
              toCol: toCol,
            )) {
              continue;
            }
            final followUp = _bestImmediateConfirmAfterBoardChange(
              session,
              movedBoard: copy,
              jesters: jesters,
              runtimeSnapshot: runtimeSnapshot,
              blockedCellKeys: blockedCellKeys,
            );
            final acceptsBoardLockSingleLine =
                _shouldAcceptBoardLockMove(session, followUp);
            final potential = _plannerBoardPotentialScoreForJesters(
              copy,
              jesters,
              blockedCellKeys: blockedCellKeys,
            );
            final potentialGain = potential - basePotential;
            final acceptsBoardLockPotentialMove =
                acceptsBoardLockTempoMove && potentialGain > 0;
            if (!acceptsBoardLockSingleLine &&
                !acceptsBoardLockPotentialMove &&
                (followUp.lineCount < 2 || followUp.score <= 0)) {
              continue;
            }
            if (allowsRepeatedStrategicMove &&
                !acceptsBoardLockSingleLine &&
                !acceptsBoardLockPotentialMove &&
                !_isHighTargetRecoveryBundle(followUp) &&
                !_isLateDeckBoardMoveBundle(
                  session,
                  followUp,
                  occupancy: RummiPokerGridSession.countTilesOnBoard(
                    session.board,
                  ),
                )) {
              continue;
            }
            final choice = _MoveChoice(
              action: FullRunBattleAction.moveBoard(
                row: fromRow,
                col: fromCol,
                toRow: toRow,
                toCol: toCol,
                gain: max(followUp.score, potentialGain),
              ),
              gain: max(followUp.score, potentialGain),
              potential: potential,
            );
            if (best == null || _isBetterMoveChoice(choice, best)) {
              best = choice;
            }
          }
        }
      }
    }
    if (best == null) return null;
    return best.action;
  }

  bool _isBetterMoveChoice(_MoveChoice candidate, _MoveChoice best) {
    if (_shouldAvoidRepeatedFailedRoutes()) {
      final candidateScore = _adjustedRouteScore(
        candidate.action,
        candidate.gain * 4 + candidate.potential,
      );
      final bestScore = _adjustedRouteScore(
        best.action,
        best.gain * 4 + best.potential,
      );
      if (candidateScore != bestScore) return candidateScore > bestScore;
    }
    return candidate.gain > best.gain ||
        candidate.gain == best.gain && candidate.potential > best.potential;
  }

  bool _allowsRepeatedStrategicBoardMove(RummiPokerGridSession session) {
    if (!enableRetryRecoveryConfirmDelay) return false;
    if (session.blind.boardMovesRemaining >= session.blind.boardMovesMax) {
      return true;
    }
    final occupancy = RummiPokerGridSession.countTilesOnBoard(session.board);
    final lateOrNearlyFull =
        session.deck.remaining <= _lateDeckUtilityRemainingMax ||
        occupancy >= _bossConfirmMinOccupancy;
    if (!lateOrNearlyFull) return false;
    if (session.blind.bossModifier != null) return true;
    return session.blind.targetScore >= _strategicUtilityTargetScoreFloor;
  }

  bool _shouldDrawForMoreOptions(
    RummiPokerGridSession session, {
    required int occupancy,
    required _ConfirmChoice confirmChoice,
  }) {
    if (session.maxHandSize <= 1 || !session.canDrawFromDeck) return false;
    if (session.hand.length >= session.maxHandSize) return false;
    if (confirmChoice.shouldConfirmNow) return false;
    if (occupancy > _strategicDrawMaxOccupancy) return false;
    return true;
  }

  int bestPlacementPotentialForTile(RummiPokerGridSession session, Tile tile) {
    final copy = session.copySnapshot();
    copy.hand.add(tile);
    return _bestPlacementPotential(copy, copy.hand.length - 1);
  }

  bool isBattleTargetLateForTest(RummiPokerGridSession session) {
    return _isBattleTargetLate(session);
  }

  bool usesRetryDeckLookaheadForTest(RummiPokerGridSession session) {
    return _shouldUseRetryDeckLookahead(session);
  }

  FullRunBattleAction? bestPlacementForTest(
    RummiPokerGridSession session, {
    required List<RummiJesterCard> jesters,
    required RummiJesterRuntimeSnapshot runtimeSnapshot,
  }) {
    return _bestPlacement(
      session,
      jesters: jesters,
      runtimeSnapshot: runtimeSnapshot,
    )?.action;
  }

  int _bestPlacementPotential(RummiPokerGridSession session, int handIndex) {
    if (handIndex < 0 || handIndex >= session.hand.length) return 0;
    final tile = session.hand[handIndex];
    final blockedCellKeys = _blockedCellKeysForSession(session);
    var best = -1 << 30;
    for (var row = 0; row < kBoardSize; row++) {
      for (var col = 0; col < kBoardSize; col++) {
        if (session.board.cellAt(row, col) != null) continue;
        final copy = session.copySnapshot();
        if (!copy.tryPlaceFromHand(tile, row, col)) continue;
        final potential = _plannerBoardPotentialScore(
          copy.board,
          blockedCellKeys: blockedCellKeys,
        );
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
    final isBossBattle = session.blind.bossModifier != null;
    final isHighTarget =
        session.blind.targetScore >= _highTargetConfirmTargetFloor;
    final isRetryRecoveryHighTarget =
        enableRetryRecoveryConfirmDelay &&
        retryRecoveryAttempt >= 2 &&
        isHighTarget;

    if (remainingScore > 0 && score >= remainingScore) {
      return _ConfirmChoice(
        lineCount: lineCount,
        score: score,
        shouldConfirmNow: true,
      );
    }
    if (isRetryRecoveryHighTarget &&
        lineCount == 1 &&
        score >= _retryPressureSingleLineConfirmFloor &&
        session.blind.boardDiscardsRemaining <= 0) {
      return _ConfirmChoice(
        lineCount: lineCount,
        score: score,
        shouldConfirmNow: true,
      );
    }
    if (lineCount < 2) {
      return _ConfirmChoice(
        lineCount: lineCount,
        score: score,
        shouldConfirmNow: false,
      );
    }
    if (score > 0 && !isHighTarget && _shouldTempoConfirm(session, jesters)) {
      return _ConfirmChoice(
        lineCount: lineCount,
        score: score,
        shouldConfirmNow: true,
      );
    }
    if (isBossBattle) {
      // 보스전은 덱 고갈 리스크가 커서 작은 2줄 확정을 참는다.
      // 보드를 충분히 채워 3줄 이상 또는 고득점 묶음을 노리는 것이 목적이다.
      if (isRetryRecoveryHighTarget) {
        final isTempoClear =
            _shouldUseBoardBlockTempoClear(session) &&
            lineCount >= 1 &&
            score > 0;
        final hasRecoveryBundle = _isBossRetryRecoveryBundle(
          _ImmediateConfirmChoice(score: score, lineCount: lineCount),
        );
        final isForcedBoardLock =
            _hasNoOpenPlayableCells(session) &&
            score > 0 &&
            session.blind.boardDiscardsRemaining <= 0;
        return _ConfirmChoice(
          lineCount: lineCount,
          score: score,
          shouldConfirmNow:
              hasRecoveryBundle || isForcedBoardLock || isTempoClear,
        );
      }
      final hasLargeBundle =
          score >= _bossConfirmScoreFloor &&
          (occupancy >= _bossConfirmMinOccupancy || lineCount >= 3);
      final isNearBoardLock = emptyCells <= 2 && score > 0;
      return _ConfirmChoice(
        lineCount: lineCount,
        score: score,
        shouldConfirmNow: hasLargeBundle || isNearBoardLock,
      );
    }
    if (isHighTarget) {
      // 고점수 구간에서는 작은 확정을 바로 먹기보다, 보드 버림/이동으로
      // 더 큰 중복 족보 묶음을 만들 여지를 먼저 본다.
      final isForcedBoardLock =
          _hasNoOpenPlayableCells(session) &&
          score > 0 &&
          session.blind.boardDiscardsRemaining <= 0;
      return _ConfirmChoice(
        lineCount: lineCount,
        score: score,
        shouldConfirmNow:
            _isHighTargetRecoveryBundle(
              _ImmediateConfirmChoice(score: score, lineCount: lineCount),
            ) ||
            isForcedBoardLock,
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

  bool _shouldTempoConfirm(
    RummiPokerGridSession session,
    List<RummiJesterCard> jesters,
  ) {
    final hasRideTheBus = jesters.any((jester) => jester.id == 'ride_the_bus');
    final bossId = session.blind.bossModifier?.id;
    return hasRideTheBus || bossId == 'confirm_limit_tax_v1';
  }

  bool _isHighTargetRecoveryBundle(_ImmediateConfirmChoice choice) {
    if (enableRetryRecoveryConfirmDelay && retryRecoveryAttempt >= 2) {
      return choice.score >= 420 ||
          choice.lineCount >= 4 && choice.score >= _highTargetConfirmScoreFloor;
    }
    return choice.score >= _highTargetTwoLineConfirmScoreFloor ||
        (choice.lineCount >= 3 && choice.score >= _highTargetConfirmScoreFloor);
  }

  bool _isBossRetryRecoveryBundle(_ImmediateConfirmChoice choice) {
    return choice.score >= _bossRetryConfirmScoreFloor ||
        choice.lineCount >= 5 && choice.score >= _bossConfirmScoreFloor;
  }

  bool isHighTargetRecoveryBundleForTest({
    required int score,
    required int lineCount,
  }) {
    return _isHighTargetRecoveryBundle(
      _ImmediateConfirmChoice(score: score, lineCount: lineCount),
    );
  }

  bool isBossRetryRecoveryBundleForTest({
    required int score,
    required int lineCount,
  }) {
    return _isBossRetryRecoveryBundle(
      _ImmediateConfirmChoice(score: score, lineCount: lineCount),
    );
  }

  bool delaysLateRetryConfirmForTest(
    RummiPokerGridSession session, {
    required int score,
    required int lineCount,
    bool boardIsFull = false,
  }) {
    return _shouldDelayLateRetryConfirmForRemaining(
      session,
      _ConfirmChoice(
        score: score,
        lineCount: lineCount,
        shouldConfirmNow: true,
      ),
      boardIsFull: boardIsFull,
    );
  }

  bool _shouldUseStrategicUtility(RummiPokerGridSession session) {
    if (session.blind.bossModifier != null) return true;
    if (session.blind.targetScore >= _strategicUtilityTargetScoreFloor) {
      return true;
    }
    return false;
  }

  bool _shouldUseBoardMoveNow(
    RummiPokerGridSession session, {
    required int occupancy,
    required bool shouldUseStrategicUtility,
  }) {
    if (!shouldUseStrategicUtility) return false;
    if (!_isBattleTargetLate(session)) return false;
    if (occupancy >= _midBoardMoveMinOccupancy &&
        occupancy <= _midBoardMoveMaxOccupancy) {
      return true;
    }
    if (!enableRetryRecoveryConfirmDelay || retryRecoveryAttempt < 2) {
      return false;
    }
    if (session.blind.targetScore < _strategicUtilityTargetScoreFloor) {
      return false;
    }
    if (session.blind.boardMovesRemaining <= 0) return false;
    final remainingScore =
        session.blind.targetScore - session.blind.scoreTowardBlind;
    if (remainingScore <= 0) return false;
    if (_shouldSpendBoardMoveBeforeBoardLock(session, occupancy: occupancy)) {
      return true;
    }
    if (session.deck.remaining > _lateDeckUtilityRemainingMax) return false;
    return occupancy >= _lateDeckBoardMoveMinOccupancy &&
        occupancy <= _midBoardMoveMaxOccupancy;
  }

  bool _shouldUseBoardBlockTempoClear(RummiPokerGridSession session) {
    if (!enableRetryRecoveryConfirmDelay || retryRecoveryAttempt < 2) {
      return false;
    }
    if (session.blind.bossModifier?.category !=
        RummiBossModifierCategory.boardCellBlock) {
      return false;
    }
    if (session.blind.boardDiscardsRemaining > 0) return false;
    final remainingScore =
        session.blind.targetScore - session.blind.scoreTowardBlind;
    if (remainingScore <= 0) return false;
    return _openPlayableCellCount(session) <= 4;
  }

  bool _shouldSpendBoardMoveBeforeBoardLock(
    RummiPokerGridSession session, {
    required int occupancy,
  }) {
    if (session.blind.boardMovesRemaining <= 0) return false;
    if (session.hand.isNotEmpty && session.boardMoveHistory.isNotEmpty) {
      return false;
    }
    return _shouldUseBoardBlockTempoClear(session) &&
        occupancy >= _lateDeckBoardMoveMinOccupancy;
  }

  bool _shouldAcceptBoardLockMove(
    RummiPokerGridSession session,
    _ImmediateConfirmChoice choice,
  ) {
    if (!_shouldSpendBoardMoveBeforeBoardLock(
      session,
      occupancy: RummiPokerGridSession.countTilesOnBoard(session.board),
    )) {
      return false;
    }
    return choice.lineCount >= 1 && choice.score > 0;
  }

  bool _isBattleTargetLate(RummiPokerGridSession session) {
    final target = session.blind.targetScore;
    if (target <= 0) return false;
    final progress = session.blind.scoreTowardBlind / target;
    if (progress >= _battleLateProgressFloor) return true;
    final remainingScore = target - session.blind.scoreTowardBlind;
    if (remainingScore <= _highTargetTwoLineConfirmScoreFloor) return true;
    final occupancy = RummiPokerGridSession.countTilesOnBoard(session.board);
    return occupancy >= _bossConfirmMinOccupancy &&
        remainingScore <= _retryRecoveryConfirmHoldScoreFloor;
  }

  bool _isLateDeckBoardMoveBundle(
    RummiPokerGridSession session,
    _ImmediateConfirmChoice choice, {
    required int occupancy,
  }) {
    if (!enableRetryRecoveryConfirmDelay || retryRecoveryAttempt < 2) {
      return false;
    }
    if (session.deck.remaining > _lateDeckUtilityRemainingMax) return false;
    if (session.blind.targetScore < _strategicUtilityTargetScoreFloor) {
      return false;
    }
    if (occupancy < _lateDeckBoardMoveMinOccupancy) return false;
    return choice.score >= _highTargetTwoLineConfirmScoreFloor ||
        choice.lineCount >= 3 && choice.score >= _highTargetConfirmScoreFloor;
  }

  bool _shouldContinueBoardDiscardMoveCombo(RummiPokerGridSession session) {
    final occupancy = RummiPokerGridSession.countTilesOnBoard(session.board);
    if (!_canUseBoardDiscardUtility(session)) return false;
    return occupancy == kBoardSize * kBoardSize - 1 &&
        session.blind.boardDiscardsRemaining < session.blind.boardDiscardsMax &&
        session.blind.boardMovesRemaining == session.blind.boardMovesMax;
  }

  bool _canUseBoardDiscardUtility(RummiPokerGridSession session) {
    if (_isBattleTargetLate(session)) return true;
    if (!enableRetryRecoveryConfirmDelay || retryRecoveryAttempt < 2) {
      return false;
    }
    if (session.deck.remaining > _lateDeckUtilityRemainingMax) return false;
    return _isBattleTargetLate(session);
  }

  bool _shouldSpendBoardDiscardForMystic(
    RummiPokerGridSession session,
    List<RummiJesterCard> jesters,
  ) {
    if (!enableRetryRecoveryConfirmDelay || retryRecoveryAttempt < 2) {
      return false;
    }
    if (session.blind.boardDiscardsRemaining <= 0 || session.hand.isEmpty) {
      return false;
    }
    if (!jesters.any((jester) => jester.id == 'mystic_summit')) return false;
    if (session.blind.bossModifier == null &&
        session.blind.targetScore < _strategicUtilityTargetScoreFloor) {
      return false;
    }
    final occupancy = RummiPokerGridSession.countTilesOnBoard(session.board);
    if (occupancy < _mysticBoardDiscardMinOccupancy) return false;
    return true;
  }

  bool _shouldDelayRetryConfirmForPlacement(
    RummiPokerGridSession session,
    _ConfirmChoice choice, {
    required bool boardIsFull,
  }) {
    if (!enableRetryRecoveryConfirmDelay || retryRecoveryAttempt < 2) {
      return false;
    }
    if (session.blind.targetScore < _highTargetConfirmTargetFloor) {
      return false;
    }
    if (boardIsFull) return false;
    final holdFloor = session.blind.bossModifier == null
        ? _retryRecoveryConfirmHoldScoreFloor
        : _bossConfirmScoreFloor;
    if (choice.score >= holdFloor) return false;
    if (session.hand.isEmpty) {
      return session.canDrawFromDeck;
    }
    final remainingScore =
        session.blind.targetScore - session.blind.scoreTowardBlind;
    return remainingScore > choice.score;
  }

  bool _shouldTryBoardFullRecoveryBeforeConfirm(
    RummiPokerGridSession session,
    _ConfirmChoice choice,
  ) {
    if (!enableRetryRecoveryConfirmDelay || retryRecoveryAttempt < 2) {
      return false;
    }
    if (session.blind.boardDiscardsRemaining <= 0 || session.hand.isEmpty) {
      return false;
    }
    if (!_hasNoOpenPlayableCells(session)) return false;
    final remainingScore =
        session.blind.targetScore - session.blind.scoreTowardBlind;
    if (remainingScore <= choice.score) return false;
    if (choice.lineCount >= 3 &&
        choice.score >= _retryRecoveryConfirmHoldScoreFloor) {
      return false;
    }
    return true;
  }

  bool _shouldDelayLateRetryConfirmForRemaining(
    RummiPokerGridSession session,
    _ConfirmChoice choice, {
    required bool boardIsFull,
  }) {
    if (!enableRetryRecoveryConfirmDelay || retryRecoveryAttempt < 2) {
      return false;
    }
    if (choice.score <= 0) return false;
    if (session.blind.bossModifier == null &&
        session.blind.targetScore < _highTargetConfirmTargetFloor) {
      return false;
    }
    if (session.hand.isEmpty && !session.canDrawFromDeck) return false;
    if (boardIsFull &&
        session.blind.boardDiscardsRemaining <= 0 &&
        session.blind.boardMovesRemaining <= 0) {
      return false;
    }
    if (session.deck.remaining > _lateDeckUtilityRemainingMax) return false;
    final remainingScore =
        session.blind.targetScore - session.blind.scoreTowardBlind;
    final shortageAfterConfirm = remainingScore - choice.score;
    if (shortageAfterConfirm <= 0) return false;
    return shortageAfterConfirm <= _lateRetryConfirmShortageWindow;
  }

  bool _shouldConfirmInsteadOfLateHandDiscard(
    RummiPokerGridSession session,
    _ConfirmChoice choice,
  ) {
    if (!enableRetryRecoveryConfirmDelay || retryRecoveryAttempt < 2) {
      return false;
    }
    if (choice.score <= 0) return false;
    if (session.blind.boardDiscardsRemaining > 0) return false;
    if (session.blind.targetScore < _strategicUtilityTargetScoreFloor &&
        session.blind.bossModifier == null) {
      return false;
    }
    return true;
  }

  _PlacementChoice? _bestPlacement(
    RummiPokerGridSession session, {
    required List<RummiJesterCard> jesters,
    required RummiJesterRuntimeSnapshot runtimeSnapshot,
  }) {
    _PlacementChoice? best;
    final remainingScore =
        session.blind.targetScore - session.blind.scoreTowardBlind;
    final blockedCellKeys = _blockedCellKeysForSession(session);
    final basePotential = _plannerBoardPotentialScoreForJesters(
      session.board,
      jesters,
      blockedCellKeys: blockedCellKeys,
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
          if (remainingScore > 0 && immediateScore >= remainingScore) {
            final action = FullRunBattleAction.place(
              handIndex: handIndex,
              row: row,
              col: col,
            );
            return _PlacementChoice(
              action: action,
              clearsTarget: true,
              immediateScore: immediateScore,
              flushAlignmentScore: _placementFlushAlignmentScore(
                session.board,
                tile,
                row,
                col,
                blockedCellKeys: blockedCellKeys,
              ),
              potentialScore: _plannerBoardPotentialScoreForJesters(
                copy.board,
                jesters,
                blockedCellKeys: blockedCellKeys,
              ),
              lookaheadScore: _placementLookaheadScore(
                copy,
                placedRow: row,
                placedCol: col,
                basePotential: basePotential,
                remainingScore: remainingScore,
                jesters: jesters,
                runtimeSnapshot: runtimeSnapshot,
              ),
              boardPressure: RummiPokerGridSession.countTilesOnBoard(
                copy.board,
              ),
              repeatsFailedRoute: _repeatsFailedRoute(action),
            );
          }

          final action = FullRunBattleAction.place(
            handIndex: handIndex,
            row: row,
            col: col,
          );
          final choice = _PlacementChoice(
            action: action,
            clearsTarget: false,
            immediateScore: immediateScore,
            flushAlignmentScore: _placementFlushAlignmentScore(
              session.board,
              tile,
              row,
              col,
              blockedCellKeys: blockedCellKeys,
            ),
            potentialScore: _plannerBoardPotentialScoreForJesters(
              copy.board,
              jesters,
              blockedCellKeys: blockedCellKeys,
            ),
            lookaheadScore: _placementLookaheadScore(
              copy,
              placedRow: row,
              placedCol: col,
              basePotential: basePotential,
              remainingScore: remainingScore,
              jesters: jesters,
              runtimeSnapshot: runtimeSnapshot,
            ),
            boardPressure: RummiPokerGridSession.countTilesOnBoard(copy.board),
            repeatsFailedRoute: _repeatsFailedRoute(action),
          );

          if (best == null || _isBetterPlacement(choice, best, session)) {
            best = choice;
          }
        }
      }
    }

    return best;
  }

  bool _isBetterPlacement(
    _PlacementChoice candidate,
    _PlacementChoice best,
    RummiPokerGridSession session,
  ) {
    if (candidate.clearsTarget != best.clearsTarget) {
      return candidate.clearsTarget;
    }
    if (_shouldAvoidRepeatedFailedRoutes() &&
        candidate.repeatsFailedRoute != best.repeatsFailedRoute) {
      return !candidate.repeatsFailedRoute;
    }
    if (_shouldAvoidRepeatedFailedRoutes()) {
      final candidateScore = _adjustedRouteScore(
        candidate.action,
        candidate.potentialScore +
            candidate.lookaheadScore ~/ 2 +
            candidate.immediateScore,
      );
      final bestScore = _adjustedRouteScore(
        best.action,
        best.potentialScore + best.lookaheadScore ~/ 2 + best.immediateScore,
      );
      if (candidateScore != bestScore) return candidateScore > bestScore;
    }
    if (candidate.immediateScore != best.immediateScore &&
        candidate.immediateScore >= _cleanConfirmScoreFloor) {
      return candidate.immediateScore > best.immediateScore;
    }
    if (_shouldUseBoardBlockTempoClear(session) &&
        candidate.immediateScore != best.immediateScore &&
        (candidate.immediateScore > 0 || best.immediateScore > 0)) {
      return candidate.immediateScore > best.immediateScore;
    }
    if (!_isRetryRecoveryPlacementMode() &&
        candidate.flushAlignmentScore != best.flushAlignmentScore) {
      return candidate.flushAlignmentScore > best.flushAlignmentScore;
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

  bool _repeatsFailedRoute(FullRunBattleAction action) {
    return _shouldAvoidRepeatedFailedRoutes() &&
        avoidedActionRouteKeys.contains(fullRunBattleActionRouteKey(action));
  }

  bool _shouldAvoidRepeatedFailedRoutes() {
    return _isRetryRecoveryPlacementMode() && avoidedActionRouteKeys.isNotEmpty;
  }

  bool _isRetryRecoveryPlacementMode() {
    return enableRetryRecoveryConfirmDelay && retryRecoveryAttempt >= 2;
  }

  int _adjustedRouteScore(FullRunBattleAction action, int baseScore) {
    if (!_shouldAvoidRepeatedFailedRoutes()) return baseScore;
    final penalty =
        avoidedActionRouteKeys.contains(fullRunBattleActionRouteKey(action))
        ? _failedRouteActionPenalty + retryRecoveryAttempt * 20
        : 0;
    return baseScore - penalty + _retryDiversityScore(action);
  }

  int _retryDiversityScore(FullRunBattleAction action) {
    if (!_shouldAvoidRepeatedFailedRoutes() || retryRecoveryAttempt < 3) {
      return 0;
    }
    final handIndex = action.handIndex ?? 0;
    final row = action.row ?? 0;
    final col = action.col ?? 0;
    final toRow = action.toRow ?? 0;
    final toCol = action.toCol ?? 0;
    // 같은 seed에서 같은 실패 prefix가 반복될 때, 후보 점수가 근접하면
    // 재시도 횟수에 따라 다른 합법 route를 먼저 보게 한다.
    return (handIndex * 19 +
            row * 31 +
            col * 37 +
            toRow * 41 +
            toCol * 43 +
            retryRecoveryAttempt * 53) %
        97;
  }

  int _placementLookaheadScore(
    RummiPokerGridSession afterPlacement, {
    required int placedRow,
    required int placedCol,
    required int basePotential,
    required int remainingScore,
    required List<RummiJesterCard> jesters,
    required RummiJesterRuntimeSnapshot runtimeSnapshot,
  }) {
    final blockedCellKeys = _blockedCellKeysForSession(afterPlacement);
    final lines = <_PlannerLine>[
      _PlannerLine(
        tiles: afterPlacement.board.row(placedRow),
        capacity: _rowCapacity(placedRow, blockedCellKeys),
      ),
      _PlannerLine(
        tiles: afterPlacement.board.col(placedCol),
        capacity: _colCapacity(placedCol, blockedCellKeys),
      ),
    ];
    if (placedRow == placedCol) {
      lines.add(
        _PlannerLine(
          tiles: afterPlacement.board.diagMain(),
          capacity: _diagMainCapacity(blockedCellKeys),
        ),
      );
    }
    if (placedRow + placedCol == kBoardSize - 1) {
      lines.add(
        _PlannerLine(
          tiles: afterPlacement.board.diagAnti(),
          capacity: _diagAntiCapacity(blockedCellKeys),
        ),
      );
    }

    var nearlyCompleteLines = 0;
    var promisingLines = 0;
    for (final line in lines) {
      final filled = line.tiles.whereType<Tile>().length;
      final potential = _plannerLinePotentialScore(
        line.tiles,
        capacity: line.capacity,
      );
      if (filled >= line.capacity - 1 && potential > 0) {
        nearlyCompleteLines++;
      }
      if (filled >= 3 && potential > 0) {
        promisingLines++;
      }
    }

    var bestNextGain = 0;
    final currentPotential = _plannerBoardPotentialScoreForJesters(
      afterPlacement.board,
      jesters,
      blockedCellKeys: _blockedCellKeysForSession(afterPlacement),
    );
    for (var index = 0; index < afterPlacement.hand.length; index++) {
      final nextPotential = _bestPlacementPotential(afterPlacement, index);
      final gain = nextPotential - currentPotential;
      if (gain > bestNextGain) bestNextGain = gain;
    }

    var bestDeckContinuation = 0;
    if (_shouldUseRetryDeckLookahead(afterPlacement)) {
      for (final tile in afterPlacement.deck.peekTop(
        _retryDeckLookaheadTileCount,
      )) {
        final score = _bestDeckTileContinuationScore(
          afterPlacement,
          tile,
          currentPotential: currentPotential,
          remainingScore: remainingScore,
          jesters: jesters,
          runtimeSnapshot: runtimeSnapshot,
        );
        if (score > bestDeckContinuation) bestDeckContinuation = score;
      }
    }

    final potentialGain = currentPotential - basePotential;
    return potentialGain +
        nearlyCompleteLines * 120 +
        promisingLines * 45 +
        bestNextGain +
        bestDeckContinuation;
  }

  bool _shouldUseRetryDeckLookahead(RummiPokerGridSession session) {
    if (!enableRetryRecoveryConfirmDelay || retryRecoveryAttempt < 2) {
      return false;
    }
    if (session.deck.isEmpty) return false;
    return session.blind.bossModifier != null ||
        session.blind.targetScore >= _highTargetConfirmTargetFloor;
  }

  int _bestDeckTileContinuationScore(
    RummiPokerGridSession session,
    Tile tile, {
    required int currentPotential,
    required int remainingScore,
    required List<RummiJesterCard> jesters,
    required RummiJesterRuntimeSnapshot runtimeSnapshot,
  }) {
    var best = 0;
    for (var row = 0; row < kBoardSize; row++) {
      for (var col = 0; col < kBoardSize; col++) {
        if (session.board.cellAt(row, col) != null) continue;
        final copy = session.copySnapshot();
        copy.hand.add(tile);
        if (!copy.tryPlaceFromHand(tile, row, col)) continue;
        final preview = copy.confirmAllFullLines(
          jesters: jesters,
          runtimeSnapshot: runtimeSnapshot,
          applyScoreToBlind: false,
        );
        final immediateScore = preview.result.scoreAdded;
        final lineCount = preview.result.lineBreakdowns.length;
        final potentialGain =
            _plannerBoardPotentialScoreForJesters(
              copy.board,
              jesters,
              blockedCellKeys: _blockedCellKeysForSession(copy),
            ) -
            currentPotential;
        final touchedPotential = _touchedLinePotential(copy, row, col);
        final finishScore = _retryFinishScore(
          immediateScore: immediateScore,
          remainingScore: remainingScore,
          deckRemaining: session.deck.remaining,
        );
        final score =
            potentialGain +
            touchedPotential ~/ 2 +
            _retryDeckLineWeight(session) * lineCount +
            _retryDeckImmediateWeight(session) * immediateScore +
            finishScore;
        if (score > best) best = score;
      }
    }
    return best;
  }

  int _retryDeckLineWeight(RummiPokerGridSession session) {
    if (enableRetryRecoveryConfirmDelay &&
        retryRecoveryAttempt >= 2 &&
        session.blind.bossModifier != null) {
      return 90;
    }
    return 140;
  }

  int _retryDeckImmediateWeight(RummiPokerGridSession session) {
    if (enableRetryRecoveryConfirmDelay &&
        retryRecoveryAttempt >= 2 &&
        session.blind.bossModifier != null) {
      return 3;
    }
    return 2;
  }

  int _retryFinishScore({
    required int immediateScore,
    required int remainingScore,
    required int deckRemaining,
  }) {
    if (!enableRetryRecoveryConfirmDelay || retryRecoveryAttempt < 2) return 0;
    if (remainingScore <= 0 || immediateScore <= 0) return 0;
    if (immediateScore >= remainingScore) return 5000 + immediateScore;
    if (deckRemaining > _lateDeckUtilityRemainingMax) return 0;
    final shortage = remainingScore - immediateScore;
    if (shortage > _lateRetryConfirmShortageWindow) return 0;
    return (_lateRetryConfirmShortageWindow - shortage) * 8;
  }

  FullRunBattleAction? chooseBoardDiscard(
    RummiPokerGridSession session, {
    int minOccupancy = kBoardSize * kBoardSize - 3,
  }) {
    if (session.blind.boardDiscardsRemaining <= 0) return null;
    final occupancy = RummiPokerGridSession.countTilesOnBoard(session.board);
    if (occupancy < minOccupancy) return null;

    (int, int)? worstCell;
    var worstLoss = 1 << 30;
    final basePotential = _plannerBoardPotentialScore(
      session.board,
      blockedCellKeys: _blockedCellKeysForSession(session),
    );
    for (var row = 0; row < kBoardSize; row++) {
      for (var col = 0; col < kBoardSize; col++) {
        if (session.board.cellAt(row, col) == null) continue;
        final copy = session.board.copy();
        copy.setCell(row, col, null);
        final loss =
            basePotential -
            _plannerBoardPotentialScore(
              copy,
              blockedCellKeys: _blockedCellKeysForSession(session),
            );
        if (loss < worstLoss) {
          worstLoss = loss;
          worstCell = (row, col);
        }
      }
    }
    if (worstCell == null) return null;
    return FullRunBattleAction.discardBoard(
      row: worstCell.$1,
      col: worstCell.$2,
    );
  }

  _ImmediateConfirmChoice _bestImmediateConfirmAfterBoardChange(
    RummiPokerGridSession session, {
    required RummiBoard movedBoard,
    required List<RummiJesterCard> jesters,
    required RummiJesterRuntimeSnapshot runtimeSnapshot,
    required Set<String> blockedCellKeys,
  }) {
    if (session.hand.isEmpty) {
      return const _ImmediateConfirmChoice(score: 0, lineCount: 0);
    }
    var best = const _ImmediateConfirmChoice(score: 0, lineCount: 0);
    for (var handIndex = 0; handIndex < session.hand.length; handIndex++) {
      final tile = session.hand[handIndex];
      for (var row = 0; row < kBoardSize; row++) {
        for (var col = 0; col < kBoardSize; col++) {
          if (movedBoard.cellAt(row, col) != null) continue;
          if (blockedCellKeys.contains(_boardCellKey(row, col))) continue;
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

  FullRunBattleAction? chooseScoringBoardDiscard(
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
        final afterDiscard = session.copySnapshot();
        afterDiscard.board.setCell(row, col, null);
        final moveCombo = chooseBoardMove(
          afterDiscard,
          jesters: jesters,
          runtimeSnapshot: runtimeSnapshot,
        );
        var combo = const _ImmediateConfirmChoice(score: 0, lineCount: 0);
        var potentialScore = _plannerBoardPotentialScore(
          afterDiscard.board,
          blockedCellKeys: _blockedCellKeysForSession(afterDiscard),
        );
        for (final tile in session.hand) {
          final copy = afterDiscard.copySnapshot();
          if (!copy.tryPlaceFromHand(tile, row, col)) continue;
          final preview = copy.confirmAllFullLines(
            jesters: jesters,
            runtimeSnapshot: runtimeSnapshot,
            applyScoreToBlind: false,
          );
          final immediateScore = preview.result.scoreAdded;
          final lineCount = preview.result.lineBreakdowns.length;
          final replacementCombo = lineCount >= 2 && immediateScore > 0
              ? _ImmediateConfirmChoice(
                  score: immediateScore,
                  lineCount: lineCount,
                )
              : _bestMoveConfirmAfterBoardDiscardPlacement(
                  copy,
                  jesters: jesters,
                  runtimeSnapshot: runtimeSnapshot,
                );
          if (replacementCombo.lineCount > combo.lineCount ||
              replacementCombo.lineCount == combo.lineCount &&
                  replacementCombo.score > combo.score) {
            combo = replacementCombo;
            potentialScore = _plannerBoardPotentialScore(
              copy.board,
              blockedCellKeys: _blockedCellKeysForSession(copy),
            );
          }
        }
        if (combo.lineCount < 2 &&
            (moveCombo == null || (moveCombo.gain ?? 0) <= 0)) {
          continue;
        }

        final choice = _BoardDiscardChoice(
          action: FullRunBattleAction.discardBoard(row: row, col: col),
          immediateScore: combo.lineCount >= 2 ? combo.score : moveCombo!.gain!,
          potentialScore: potentialScore,
        );
        if (best == null || _isBetterBoardDiscardChoice(choice, best)) {
          best = choice;
        }
      }
    }
    return best?.action;
  }

  bool _isBetterBoardDiscardChoice(
    _BoardDiscardChoice candidate,
    _BoardDiscardChoice best,
  ) {
    if (_shouldAvoidRepeatedFailedRoutes()) {
      final candidateScore = _adjustedRouteScore(
        candidate.action,
        candidate.immediateScore * 4 + candidate.potentialScore,
      );
      final bestScore = _adjustedRouteScore(
        best.action,
        best.immediateScore * 4 + best.potentialScore,
      );
      if (candidateScore != bestScore) return candidateScore > bestScore;
    }
    return candidate.immediateScore > best.immediateScore ||
        candidate.immediateScore == best.immediateScore &&
            candidate.potentialScore > best.potentialScore;
  }

  FullRunBattleAction? chooseRecoveryBoardDiscard(
    RummiPokerGridSession session, {
    required List<RummiJesterCard> jesters,
    required RummiJesterRuntimeSnapshot runtimeSnapshot,
  }) {
    if (session.blind.boardDiscardsRemaining <= 0 || session.hand.isEmpty) {
      return null;
    }
    if (!_hasNoOpenPlayableCells(session)) return null;
    final shouldRecover =
        session.blind.bossModifier != null ||
        session.blind.targetScore >= _strategicUtilityTargetScoreFloor ||
        !session.canDrawFromDeck;
    if (!shouldRecover) return null;

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
          blockedCellKeys: _blockedCellKeysForSession(afterDiscard),
        );

        for (var handIndex = 0; handIndex < session.hand.length; handIndex++) {
          final tile = session.hand[handIndex];
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
            blockedCellKeys: _blockedCellKeysForSession(copy),
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
            action: FullRunBattleAction.discardBoard(row: row, col: col),
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

  FullRunBattleAction? chooseMysticBoardDiscard(
    RummiPokerGridSession session, {
    required List<RummiJesterCard> jesters,
    required RummiJesterRuntimeSnapshot runtimeSnapshot,
  }) {
    if (session.blind.boardDiscardsRemaining <= 0 || session.hand.isEmpty) {
      return null;
    }

    final occupancy = RummiPokerGridSession.countTilesOnBoard(session.board);
    final basePotential = _plannerBoardPotentialScoreForJesters(
      session.board,
      jesters,
      blockedCellKeys: _blockedCellKeysForSession(session),
    );
    _BoardDiscardChoice? best;
    for (var row = 0; row < kBoardSize; row++) {
      for (var col = 0; col < kBoardSize; col++) {
        if (session.board.cellAt(row, col) == null) continue;
        final afterDiscard = session.copySnapshot();
        afterDiscard.board.setCell(row, col, null);
        final afterDiscardPotential = _plannerBoardPotentialScoreForJesters(
          afterDiscard.board,
          jesters,
          blockedCellKeys: _blockedCellKeysForSession(afterDiscard),
        );

        for (var handIndex = 0; handIndex < session.hand.length; handIndex++) {
          final tile = session.hand[handIndex];
          final copy = afterDiscard.copySnapshot();
          if (!copy.tryPlaceFromHand(tile, row, col)) continue;
          final preview = copy.confirmAllFullLines(
            jesters: jesters,
            runtimeSnapshot: runtimeSnapshot,
            applyScoreToBlind: false,
          );
          final score = preview.result.scoreAdded;
          final lineCount = preview.result.lineBreakdowns.length;
          final potentialScore = _plannerBoardPotentialScoreForJesters(
            copy.board,
            jesters,
            blockedCellKeys: _blockedCellKeysForSession(copy),
          );
          final potentialGain = potentialScore - basePotential;
          final recoversDiscardLoss = potentialScore >= afterDiscardPotential;
          final createsUsefulLine =
              _touchedLinePotential(copy, row, col) >= _cleanConfirmScoreFloor;
          final improvesImmediate =
              lineCount >= 2 && score >= _highTargetConfirmScoreFloor;
          final revivesNearFullLine =
              occupancy >= kBoardSize * kBoardSize - 1 && createsUsefulLine;
          if (!recoversDiscardLoss) continue;
          if (!improvesImmediate && !revivesNearFullLine) {
            continue;
          }

          final choice = _BoardDiscardChoice(
            action: FullRunBattleAction.discardBoard(row: row, col: col),
            immediateScore: score + potentialGain,
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

  int _touchedLinePotential(RummiPokerGridSession session, int row, int col) {
    final board = session.board;
    var best = max(
      _plannerLinePotentialScore(
        board.row(row),
        capacity: _rowCapacity(row, _blockedCellKeysForSession(session)),
      ),
      _plannerLinePotentialScore(
        board.col(col),
        capacity: _colCapacity(col, _blockedCellKeysForSession(session)),
      ),
    );
    if (row == col) {
      best = max(
        best,
        _plannerLinePotentialScore(
          board.diagMain(),
          capacity: _diagMainCapacity(_blockedCellKeysForSession(session)),
        ),
      );
    }
    if (row + col == kBoardSize - 1) {
      best = max(
        best,
        _plannerLinePotentialScore(
          board.diagAnti(),
          capacity: _diagAntiCapacity(_blockedCellKeysForSession(session)),
        ),
      );
    }
    return best;
  }

  _ImmediateConfirmChoice _bestMoveConfirmAfterBoardDiscardPlacement(
    RummiPokerGridSession afterDiscardPlacement, {
    required List<RummiJesterCard> jesters,
    required RummiJesterRuntimeSnapshot runtimeSnapshot,
  }) {
    if (afterDiscardPlacement.blind.boardMovesRemaining <= 0) {
      return const _ImmediateConfirmChoice(score: 0, lineCount: 0);
    }
    var best = const _ImmediateConfirmChoice(score: 0, lineCount: 0);
    for (var fromRow = 0; fromRow < kBoardSize; fromRow++) {
      for (var fromCol = 0; fromCol < kBoardSize; fromCol++) {
        if (afterDiscardPlacement.board.cellAt(fromRow, fromCol) == null) {
          continue;
        }
        for (var toRow = 0; toRow < kBoardSize; toRow++) {
          for (var toCol = 0; toCol < kBoardSize; toCol++) {
            if (afterDiscardPlacement.board.cellAt(toRow, toCol) != null) {
              continue;
            }
            final copy = afterDiscardPlacement.copySnapshot();
            final fail = copy.tryMoveBoardTile(
              fromRow: fromRow,
              fromCol: fromCol,
              toRow: toRow,
              toCol: toCol,
            );
            if (fail != null) continue;
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
                choice.lineCount == best.lineCount &&
                    choice.score > best.score) {
              best = choice;
            }
          }
        }
      }
    }
    return best;
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
    required this.flushAlignmentScore,
    required this.potentialScore,
    required this.lookaheadScore,
    required this.boardPressure,
    required this.repeatsFailedRoute,
  });

  final FullRunBattleAction action;
  final bool clearsTarget;
  final int immediateScore;
  final int flushAlignmentScore;
  final int potentialScore;
  final int lookaheadScore;
  final int boardPressure;
  final bool repeatsFailedRoute;
}

class _MoveChoice {
  const _MoveChoice({
    required this.action,
    required this.gain,
    required this.potential,
  });

  final FullRunBattleAction action;
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

  final FullRunBattleAction action;
  final int immediateScore;
  final int potentialScore;
}

class _PlannerLine {
  const _PlannerLine({required this.tiles, required this.capacity});

  final List<Tile?> tiles;
  final int capacity;
}

int _plannerBoardPotentialScore(
  RummiBoard board, {
  Set<String> blockedCellKeys = const <String>{},
}) {
  var score = 0;
  for (var row = 0; row < kBoardSize; row++) {
    score += _plannerLinePotentialScore(
      board.row(row),
      capacity: _rowCapacity(row, blockedCellKeys),
    );
  }
  for (var col = 0; col < kBoardSize; col++) {
    score += _plannerLinePotentialScore(
      board.col(col),
      capacity: _colCapacity(col, blockedCellKeys),
    );
  }
  score += _plannerLinePotentialScore(
    board.diagMain(),
    capacity: _diagMainCapacity(blockedCellKeys),
  );
  score += _plannerLinePotentialScore(
    board.diagAnti(),
    capacity: _diagAntiCapacity(blockedCellKeys),
  );
  return score;
}

int _plannerBoardPotentialScoreForJesters(
  RummiBoard board,
  List<RummiJesterCard> jesters, {
  Set<String> blockedCellKeys = const <String>{},
}) {
  var score = _plannerBoardPotentialScore(
    board,
    blockedCellKeys: blockedCellKeys,
  );
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
      capacity: _rowCapacity(row, blockedCellKeys),
      wantsFlush: wantsFlush,
      wantsFourKind: wantsFourKind,
      wantsPairs: wantsPairs,
    );
  }
  for (var col = 0; col < kBoardSize; col++) {
    score += _plannerJesterLineBonus(
      board.col(col),
      capacity: _colCapacity(col, blockedCellKeys),
      wantsFlush: wantsFlush,
      wantsFourKind: wantsFourKind,
      wantsPairs: wantsPairs,
    );
  }
  score += _plannerJesterLineBonus(
    board.diagMain(),
    capacity: _diagMainCapacity(blockedCellKeys),
    wantsFlush: wantsFlush,
    wantsFourKind: wantsFourKind,
    wantsPairs: wantsPairs,
  );
  score += _plannerJesterLineBonus(
    board.diagAnti(),
    capacity: _diagAntiCapacity(blockedCellKeys),
    wantsFlush: wantsFlush,
    wantsFourKind: wantsFourKind,
    wantsPairs: wantsPairs,
  );
  return score;
}

int _placementFlushAlignmentScore(
  RummiBoard board,
  Tile tile,
  int row,
  int col, {
  Set<String> blockedCellKeys = const <String>{},
}) {
  final lines = <_PlannerLine>[
    _PlannerLine(
      tiles: board.row(row),
      capacity: _rowCapacity(row, blockedCellKeys),
    ),
    _PlannerLine(
      tiles: board.col(col),
      capacity: _colCapacity(col, blockedCellKeys),
    ),
  ];
  if (row == col) {
    lines.add(
      _PlannerLine(
        tiles: board.diagMain(),
        capacity: _diagMainCapacity(blockedCellKeys),
      ),
    );
  }
  if (row + col == kBoardSize - 1) {
    lines.add(
      _PlannerLine(
        tiles: board.diagAnti(),
        capacity: _diagAntiCapacity(blockedCellKeys),
      ),
    );
  }

  var score = 0;
  var cleanSameColorLines = 0;
  for (final line in lines) {
    final lineScore = _placementLineFlushAlignmentScore(
      line.tiles,
      tile.color,
      capacity: line.capacity,
    );
    score += lineScore;
    final tiles = line.tiles.whereType<Tile>().toList(growable: false);
    if (line.capacity >= kBoardSize &&
        tiles.isNotEmpty &&
        tiles.every((other) => other.color == tile.color)) {
      cleanSameColorLines++;
    }
  }
  if (cleanSameColorLines >= 2) {
    score += cleanSameColorLines * 180;
  }
  return score;
}

int _placementLineFlushAlignmentScore(
  List<Tile?> line,
  TileColor color, {
  int capacity = kBoardSize,
}) {
  if (capacity < kBoardSize) return 0;
  final tiles = line.whereType<Tile>().toList(growable: false);
  if (tiles.isEmpty) return 0;
  final sameColor = tiles.where((tile) => tile.color == color).length;
  final offColor = tiles.length - sameColor;

  if (offColor == 0) {
    return sameColor * 180 + (sameColor >= 2 ? 260 : 60);
  }
  if (sameColor == 0) {
    return -offColor * 90;
  }
  return sameColor * 90 - offColor * 140;
}

int _plannerJesterLineBonus(
  List<Tile?> line, {
  int capacity = kBoardSize,
  required bool wantsFlush,
  required bool wantsFourKind,
  required bool wantsPairs,
}) {
  final tiles = line.whereType<Tile>().toList(growable: false);
  if (tiles.isEmpty) return 0;
  final missing = max(0, capacity - tiles.length);
  final colorCounts = <TileColor, int>{};
  final rankCounts = <int, int>{};
  for (final tile in tiles) {
    colorCounts[tile.color] = (colorCounts[tile.color] ?? 0) + 1;
    rankCounts[tile.number] = (rankCounts[tile.number] ?? 0) + 1;
  }

  var bonus = 0;
  if (wantsFlush && capacity >= kBoardSize) {
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

int _plannerLinePotentialScore(List<Tile?> line, {int capacity = kBoardSize}) {
  final tiles = line.whereType<Tile>().toList(growable: false);
  if (tiles.isEmpty) return 0;
  final missing = max(0, capacity - tiles.length);
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
  final allowsFiveTileHands = capacity >= kBoardSize;

  var score = 0;
  if (allowsFiveTileHands && maxSameColor + missing >= 5) {
    score += maxSameColor * 85 + (missing == 0 ? 360 : 0);
  }
  if (maxSameRank + missing >= 4) score += 70;
  if (pairCount >= 2 || pairCount == 1 && missing >= 2) score += 40;
  if (maxSameRank >= 3 && missing >= 1) score += 30;
  if (allowsFiveTileHands && straightRun + missing >= 5) score += 45;
  score += tiles.length * 2;

  if (missing <= 1 &&
      maxSameRank < 2 &&
      (allowsFiveTileHands ? maxSameColor < 4 : true) &&
      (allowsFiveTileHands ? straightRun < 4 : true)) {
    score -= 50;
  }
  return score;
}

Set<String> _blockedCellKeysForSession(RummiPokerGridSession session) {
  final modifier = session.blind.bossModifier;
  if (modifier?.category != RummiBossModifierCategory.boardCellBlock) {
    return const <String>{};
  }
  return {
    for (final cell in modifier!.blockedCells) _boardCellKey(cell.$1, cell.$2),
  };
}

bool _hasNoOpenPlayableCells(RummiPokerGridSession session) {
  return _openPlayableCellCount(session) == 0;
}

int _openPlayableCellCount(RummiPokerGridSession session) {
  final blockedCellKeys = _blockedCellKeysForSession(session);
  var count = 0;
  for (var row = 0; row < kBoardSize; row++) {
    for (var col = 0; col < kBoardSize; col++) {
      if (session.board.cellAt(row, col) != null) continue;
      if (blockedCellKeys.contains(_boardCellKey(row, col))) continue;
      count++;
    }
  }
  return count;
}

String _boardCellKey(int row, int col) => '$row:$col';

int _rowCapacity(int row, Set<String> blockedCellKeys) {
  var blocked = 0;
  for (var col = 0; col < kBoardSize; col++) {
    if (blockedCellKeys.contains(_boardCellKey(row, col))) blocked++;
  }
  return kBoardSize - blocked;
}

int _colCapacity(int col, Set<String> blockedCellKeys) {
  var blocked = 0;
  for (var row = 0; row < kBoardSize; row++) {
    if (blockedCellKeys.contains(_boardCellKey(row, col))) blocked++;
  }
  return kBoardSize - blocked;
}

int _diagMainCapacity(Set<String> blockedCellKeys) {
  var blocked = 0;
  for (var index = 0; index < kBoardSize; index++) {
    if (blockedCellKeys.contains(_boardCellKey(index, index))) blocked++;
  }
  return kBoardSize - blocked;
}

int _diagAntiCapacity(Set<String> blockedCellKeys) {
  var blocked = 0;
  for (var index = 0; index < kBoardSize; index++) {
    if (blockedCellKeys.contains(
      _boardCellKey(index, kBoardSize - 1 - index),
    )) {
      blocked++;
    }
  }
  return kBoardSize - blocked;
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
