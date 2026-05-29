import 'package:rummipoker/logic/rummi_poker_grid/jester_meta.dart';
import 'package:rummipoker/logic/rummi_poker_grid/rummi_poker_grid_session.dart';

import 'bot_policy.dart';

class BalanceActionExecutionResult {
  const BalanceActionExecutionResult({
    required this.ok,
    required this.reason,
    required this.scoreBefore,
    required this.scoreAfter,
    required this.handSizeAfter,
    required this.deckRemainingAfter,
    required this.boardOccupancyAfter,
  });

  final bool ok;
  final String reason;
  final int scoreBefore;
  final int scoreAfter;
  final int handSizeAfter;
  final int deckRemainingAfter;
  final int boardOccupancyAfter;

  int get scoreDelta => scoreAfter - scoreBefore;
}

BalanceActionExecutionResult executeBalanceAction(
  RummiPokerGridSession session,
  BalanceSimAction action, {
  List<RummiJesterCard> jesters = const [],
  RummiJesterRuntimeSnapshot runtimeSnapshot =
      const RummiJesterRuntimeSnapshot(),
}) {
  final scoreBefore = session.blind.scoreTowardBlind;
  final result = _execute(session, action, jesters, runtimeSnapshot);
  return BalanceActionExecutionResult(
    ok: result.ok,
    reason: result.reason,
    scoreBefore: scoreBefore,
    scoreAfter: session.blind.scoreTowardBlind,
    handSizeAfter: session.hand.length,
    deckRemainingAfter: session.deck.remaining,
    boardOccupancyAfter: RummiPokerGridSession.countTilesOnBoard(
      session.board,
    ),
  );
}

({bool ok, String reason}) _execute(
  RummiPokerGridSession session,
  BalanceSimAction action,
  List<RummiJesterCard> jesters,
  RummiJesterRuntimeSnapshot runtimeSnapshot,
) {
  switch (action.type) {
    case BalanceSimActionType.draw:
      return (ok: session.drawToHand() != null, reason: 'draw');
    case BalanceSimActionType.place:
      final handIndex = action.handIndex;
      final row = action.row;
      final col = action.col;
      if (handIndex == null ||
          row == null ||
          col == null ||
          handIndex < 0 ||
          handIndex >= session.hand.length) {
        return (ok: false, reason: 'invalid_place_action');
      }
      final tile = session.hand[handIndex];
      return (ok: session.tryPlaceFromHand(tile, row, col), reason: 'place');
    case BalanceSimActionType.confirm:
      final out = session.confirmAllFullLines(
        jesters: jesters,
        runtimeSnapshot: runtimeSnapshot,
      );
      return (ok: out.result.ok, reason: 'confirm');
    case BalanceSimActionType.discardHand:
      final handIndex = action.handIndex;
      if (handIndex == null ||
          handIndex < 0 ||
          handIndex >= session.hand.length) {
        return (ok: false, reason: 'invalid_discard_hand_action');
      }
      final discard = session.tryDiscardFromHand(session.hand[handIndex]);
      return (ok: discard.fail == null, reason: 'discardHand');
    case BalanceSimActionType.discardBoard:
      final row = action.row;
      final col = action.col;
      if (row == null || col == null) {
        return (ok: false, reason: 'invalid_discard_board_action');
      }
      final discard = session.tryDiscardFromBoard(row, col);
      return (ok: discard.fail == null, reason: 'discardBoard');
    case BalanceSimActionType.moveBoard:
      final row = action.row;
      final col = action.col;
      final toRow = action.toRow;
      final toCol = action.toCol;
      if (row == null || col == null || toRow == null || toCol == null) {
        return (ok: false, reason: 'invalid_move_board_action');
      }
      final fail = session.tryMoveBoardTile(
        fromRow: row,
        fromCol: col,
        toRow: toRow,
        toCol: toCol,
      );
      return (ok: fail == null, reason: fail?.name ?? 'moveBoard');
    case BalanceSimActionType.stop:
      return (ok: true, reason: action.reason ?? 'stop');
  }
}
