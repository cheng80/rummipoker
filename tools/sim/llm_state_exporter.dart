import 'package:rummipoker/logic/rummi_poker_grid/jester_meta.dart';
import 'package:rummipoker/logic/rummi_poker_grid/models/board.dart';
import 'package:rummipoker/logic/rummi_poker_grid/models/tile.dart';
import 'package:rummipoker/logic/rummi_poker_grid/rummi_poker_grid_session.dart';

import 'bot_policy.dart';
import 'llm_action_schema.dart';

const String kLlmGemmaPolicyId = 'llm_gemma4_v1';

Map<String, dynamic> exportLlmState(
  RummiPokerGridSession session, {
  required String botPolicy,
  required List<RummiJesterCard> jesters,
  required RummiJesterRuntimeSnapshot runtimeSnapshot,
  int? station,
  String? blindTier,
  int? turnCount,
}) {
  final state = <String, dynamic>{
    'schema_version': kLlmActionSchemaVersion,
    'bot_policy': botPolicy,
    'run_seed': session.runSeed,
    'target_score': session.blind.targetScore,
    'score_toward_blind': session.blind.scoreTowardBlind,
    'remaining_score': _remainingScore(session),
    'board_size': kBoardSize,
    'board': [
      for (var row = 0; row < kBoardSize; row++)
        [
          for (var col = 0; col < kBoardSize; col++)
            _tileToLlmJson(session.board.cellAt(row, col)),
        ],
    ],
    'hand': [
      for (var index = 0; index < session.hand.length; index++)
        {'hand_index': index, ..._tileToLlmJson(session.hand[index])!},
    ],
    'deck_remaining': session.deck.remaining,
    'max_hand_size': session.maxHandSize,
    'board_discards_remaining': session.blind.boardDiscardsRemaining,
    'hand_discards_remaining': session.blind.handDiscardsRemaining,
    'board_moves_remaining': session.blind.boardMovesRemaining,
    'jester_ids': [for (final jester in jesters) jester.id],
    'runtime_snapshot_summary': {
      'owned_jester_count': jesters.length,
      'confirm_modifier_count': session.confirmModifiers.length,
      'confirmed_rank_count': session.confirmedRanksThisStation.length,
      'next_board_move_slide_bonus_queued':
          session.nextBoardMoveSlideBonusQueued,
      'growth_tracked_rank_count': runtimeSnapshot.handGrowthStates.length,
    },
  };
  if (station != null) state['station'] = station;
  if (blindTier != null) state['blind_tier'] = blindTier;
  if (turnCount != null) state['turn_count'] = turnCount;
  return state;
}

LlmActionRequest buildLlmActionRequest(
  RummiPokerGridSession session, {
  required String requestId,
  String botPolicy = kLlmGemmaPolicyId,
  required List<RummiJesterCard> jesters,
  required RummiJesterRuntimeSnapshot runtimeSnapshot,
  int? station,
  String? blindTier,
  int? turnCount,
}) {
  return LlmActionRequest(
    requestId: requestId,
    botPolicy: botPolicy,
    state: exportLlmState(
      session,
      botPolicy: botPolicy,
      jesters: jesters,
      runtimeSnapshot: runtimeSnapshot,
      station: station,
      blindTier: blindTier,
      turnCount: turnCount,
    ),
    legalActions: buildLlmLegalActions(
      session,
      jesters: jesters,
      runtimeSnapshot: runtimeSnapshot,
    ),
  );
}

List<LlmLegalAction> buildLlmLegalActions(
  RummiPokerGridSession session, {
  required List<RummiJesterCard> jesters,
  required RummiJesterRuntimeSnapshot runtimeSnapshot,
}) {
  final actions = <LlmLegalAction>[];
  final boardPressure = RummiPokerGridSession.countTilesOnBoard(session.board);
  final remainingScore = _remainingScore(session);

  if (session.canDrawFromDeck) {
    actions.add(
      LlmLegalAction(
        id: 'draw_deck',
        type: 'draw',
        action: const BalanceSimAction.draw(),
        boardPressure: boardPressure,
        reasonHint: 'draw into available hand slot',
      ),
    );
  }

  if (session.canConfirmAllFullLines) {
    final preview = session.copySnapshot().confirmAllFullLines(
      jesters: jesters,
      runtimeSnapshot: runtimeSnapshot,
      applyScoreToBlind: false,
    );
    final previewScore = preview.result.scoreAdded;
    actions.add(
      LlmLegalAction(
        id: 'confirm_current',
        type: 'confirm',
        action: const BalanceSimAction.confirm(),
        previewScore: previewScore,
        boardPressure: boardPressure,
        clearsTarget: previewScore >= remainingScore,
        reasonHint: 'confirm all currently scoring lines',
      ),
    );
  }

  for (var handIndex = 0; handIndex < session.hand.length; handIndex++) {
    final tile = session.hand[handIndex];
    for (var row = 0; row < kBoardSize; row++) {
      for (var col = 0; col < kBoardSize; col++) {
        if (session.board.cellAt(row, col) != null) continue;
        final preview = _previewPlacementScore(
          session,
          tile: tile,
          row: row,
          col: col,
          jesters: jesters,
          runtimeSnapshot: runtimeSnapshot,
        );
        actions.add(
          LlmLegalAction(
            id: 'place_h${handIndex}_r${row}_c$col',
            type: 'place',
            action: BalanceSimAction.place(
              handIndex: handIndex,
              row: row,
              col: col,
            ),
            handIndex: handIndex,
            row: row,
            col: col,
            previewScore: preview,
            potentialScore: preview,
            boardPressure: boardPressure + 1,
            clearsTarget: preview >= remainingScore,
          ),
        );
      }
    }
  }

  if (session.blind.handDiscardsRemaining > 0) {
    for (var handIndex = 0; handIndex < session.hand.length; handIndex++) {
      actions.add(
        LlmLegalAction(
          id: 'discard_hand_h$handIndex',
          type: 'discardHand',
          action: BalanceSimAction.discardHand(handIndex: handIndex),
          handIndex: handIndex,
          boardPressure: boardPressure,
          reasonHint: 'spend hand discard to replace a hand tile',
        ),
      );
    }
  }

  final occupiedCells = <(int, int)>[];
  final emptyCells = <(int, int)>[];
  for (var row = 0; row < kBoardSize; row++) {
    for (var col = 0; col < kBoardSize; col++) {
      if (session.board.cellAt(row, col) == null) {
        emptyCells.add((row, col));
      } else {
        occupiedCells.add((row, col));
      }
    }
  }

  if (session.blind.boardDiscardsRemaining > 0) {
    for (final cell in occupiedCells) {
      actions.add(
        LlmLegalAction(
          id: 'discard_board_r${cell.$1}_c${cell.$2}',
          type: 'discardBoard',
          action: BalanceSimAction.discardBoard(row: cell.$1, col: cell.$2),
          row: cell.$1,
          col: cell.$2,
          boardPressure: boardPressure - 1,
          reasonHint: 'spend board discard to open a board cell',
        ),
      );
    }
  }

  if (session.blind.boardMovesRemaining > 0) {
    for (final from in occupiedCells) {
      for (final to in emptyCells) {
        actions.add(
          LlmLegalAction(
            id: 'move_r${from.$1}_c${from.$2}_to_r${to.$1}_c${to.$2}',
            type: 'moveBoard',
            action: BalanceSimAction.moveBoard(
              row: from.$1,
              col: from.$2,
              toRow: to.$1,
              toCol: to.$2,
            ),
            row: from.$1,
            col: from.$2,
            toRow: to.$1,
            toCol: to.$2,
            boardPressure: boardPressure,
            reasonHint: 'spend board move to reposition an existing tile',
          ),
        );
      }
    }
  }

  if (actions.isEmpty) {
    actions.add(
      const LlmLegalAction(
        id: 'stop_no_legal_action',
        type: 'stop',
        action: BalanceSimAction.stop('llm_no_legal_action'),
        reasonHint: 'no legal action is available',
      ),
    );
  }

  return actions;
}

int _previewPlacementScore(
  RummiPokerGridSession session, {
  required Tile tile,
  required int row,
  required int col,
  required List<RummiJesterCard> jesters,
  required RummiJesterRuntimeSnapshot runtimeSnapshot,
}) {
  final copy = session.copySnapshot();
  if (!copy.tryPlaceFromHand(tile, row, col)) return 0;
  final preview = copy.confirmAllFullLines(
    jesters: jesters,
    runtimeSnapshot: runtimeSnapshot,
    applyScoreToBlind: false,
  );
  return preview.result.scoreAdded;
}

int _remainingScore(RummiPokerGridSession session) {
  final remaining = session.blind.targetScore - session.blind.scoreTowardBlind;
  return remaining < 0 ? 0 : remaining;
}

Map<String, dynamic>? _tileToLlmJson(Tile? tile) {
  if (tile == null) return null;
  return {
    'code': tile.code,
    'rank': tile.number,
    'color': tile.color.name,
    'id': tile.id,
    if (tile.enhancement != null)
      'enhancement': tile.enhancement!.persistenceValue,
    if (tile.seal != null) 'seal': tile.seal!.persistenceValue,
    if (tile.edition != null) 'edition': tile.edition!.persistenceValue,
  };
}
