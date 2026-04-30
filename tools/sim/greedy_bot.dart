import 'package:rummipoker/logic/rummi_poker_grid/jester_meta.dart';
import 'package:rummipoker/logic/rummi_poker_grid/models/board.dart';
import 'package:rummipoker/logic/rummi_poker_grid/rummi_poker_grid_session.dart';

import 'bot_policy.dart';

/// 즉시 확정 점수가 가장 큰 배치를 고르는 첫 기준선 bot.
class GreedyBotPolicy extends BalanceSimBotPolicy {
  const GreedyBotPolicy();

  @override
  String get id => 'greedy_v1';

  @override
  BalanceSimAction chooseAction(
    RummiPokerGridSession session, {
    required List<RummiJesterCard> jesters,
  }) {
    if (session.canConfirmAllFullLines) {
      return const BalanceSimAction.confirm();
    }
    if (session.hand.isEmpty) {
      return session.canDrawFromDeck
          ? const BalanceSimAction.draw()
          : const BalanceSimAction.stop('no_hand_and_cannot_draw');
    }

    final placement = _bestPlacement(session, jesters: jesters);
    if (placement != null) return placement;

    if (session.blind.boardDiscardsRemaining > 0) {
      final occupied = _firstOccupiedCell(session);
      if (occupied != null) {
        return BalanceSimAction.discardBoard(
          row: occupied.$1,
          col: occupied.$2,
        );
      }
    }

    return const BalanceSimAction.stop('no_legal_action');
  }

  BalanceSimAction? _bestPlacement(
    RummiPokerGridSession session, {
    required List<RummiJesterCard> jesters,
  }) {
    BalanceSimAction? bestAction;
    var bestScore = -1;

    for (var handIndex = 0; handIndex < session.hand.length; handIndex++) {
      final tile = session.hand[handIndex];
      for (var row = 0; row < kBoardSize; row++) {
        for (var col = 0; col < kBoardSize; col++) {
          if (session.board.cellAt(row, col) != null) continue;
          final copy = session.copySnapshot();
          final placed = copy.tryPlaceFromHand(tile, row, col);
          if (!placed) continue;
          final preview = copy.confirmAllFullLines(
            jesters: jesters,
            applyScoreToBlind: false,
          );
          final score = preview.result.scoreAdded;
          if (score > bestScore) {
            bestScore = score;
            bestAction = BalanceSimAction.place(
              handIndex: handIndex,
              row: row,
              col: col,
            );
          }
        }
      }
    }

    return bestAction;
  }

  (int, int)? _firstOccupiedCell(RummiPokerGridSession session) {
    for (var row = 0; row < kBoardSize; row++) {
      for (var col = 0; col < kBoardSize; col++) {
        if (session.board.cellAt(row, col) != null) return (row, col);
      }
    }
    return null;
  }
}
