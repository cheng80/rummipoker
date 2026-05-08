import 'package:flutter_test/flutter_test.dart';
import 'package:rummipoker/logic/rummi_poker_grid/boss_modifier.dart';
import 'package:rummipoker/logic/rummi_poker_grid/jester_meta.dart';
import 'package:rummipoker/logic/rummi_poker_grid/models/board.dart';
import 'package:rummipoker/logic/rummi_poker_grid/models/poker_deck.dart';
import 'package:rummipoker/logic/rummi_poker_grid/models/tile.dart';
import 'package:rummipoker/logic/rummi_poker_grid/rummi_blind_state.dart';
import 'package:rummipoker/logic/rummi_poker_grid/rummi_poker_grid_session.dart';

import '../integration_test/competition_bot_policy.dart';

void main() {
  test('battle item use must support the planned battle action', () {
    expect(
      contestBattleItemOpSupportsPlannedAction(
        'add_board_move',
        CompetitionBattleActionType.moveBoard,
      ),
      isTrue,
    );
    expect(
      contestBattleItemOpSupportsPlannedAction(
        'add_board_move',
        CompetitionBattleActionType.draw,
      ),
      isFalse,
    );
    expect(
      contestBattleItemOpSupportsPlannedAction(
        'mark_next_board_move_bonus',
        CompetitionBattleActionType.moveBoard,
      ),
      isTrue,
    );
    expect(
      contestBattleItemOpSupportsPlannedAction(
        'mark_next_board_move_bonus',
        CompetitionBattleActionType.draw,
      ),
      isFalse,
    );
  });

  test('boss battle waits instead of taking a small early confirm', () {
    final session = RummiPokerGridSession.restored(
      runSeed: 91460,
      deckCopiesPerTile: 1,
      maxHandSize: 2,
      runRandomState: 1,
      blind: RummiBlindState(
        targetScore: 1739,
        boardDiscardsRemaining: 3,
        handDiscardsRemaining: 2,
        boardMovesRemaining: 3,
        bossModifier: RummiBossModifier.confirmCountTax,
      ),
      deck: PokerDeck.fromSnapshot([_tile(TileColor.blue, 6)]),
      board: RummiBoard.fromSnapshot([
        _tile(TileColor.red, 1),
        _tile(TileColor.blue, 1),
        _tile(TileColor.black, 1),
        _tile(TileColor.red, 2),
        _tile(TileColor.blue, 2),
        _tile(TileColor.red, 3),
        _tile(TileColor.blue, 3),
        _tile(TileColor.black, 3),
        _tile(TileColor.red, 4),
        _tile(TileColor.blue, 4),
        null,
        null,
        null,
        null,
        null,
        null,
        null,
        null,
        null,
        null,
        null,
        null,
        null,
        null,
        null,
      ]),
      hand: [_tile(TileColor.yellow, 6)],
      eliminated: const [],
    );

    final action = const CompetitionPlannerV2Policy().chooseAction(
      session,
      jesters: const [],
      runtimeSnapshot: const RummiJesterRuntimeSnapshot(),
    );

    expect(action.type, isNot(CompetitionBattleActionType.confirm));
  });

  test('full board chooses a scoring board discard over the loop cell', () {
    final board = RummiBoard.fromSnapshot([
      _tile(TileColor.red, 3),
      _tile(TileColor.blue, 12),
      _tile(TileColor.black, 3),
      _tile(TileColor.red, 10),
      _tile(TileColor.blue, 3),
      _tile(TileColor.blue, 10),
      _tile(TileColor.black, 9),
      _tile(TileColor.black, 2),
      _tile(TileColor.blue, 6),
      _tile(TileColor.blue, 7),
      _tile(TileColor.red, 9),
      _tile(TileColor.yellow, 5),
      _tile(TileColor.blue, 4),
      _tile(TileColor.black, 13),
      _tile(TileColor.yellow, 6),
      _tile(TileColor.yellow, 11),
      _tile(TileColor.black, 8),
      _tile(TileColor.yellow, 10),
      _tile(TileColor.black, 4),
      _tile(TileColor.yellow, 9),
      _tile(TileColor.blue, 8),
      _tile(TileColor.yellow, 12),
      _tile(TileColor.black, 10),
      _tile(TileColor.red, 1),
      _tile(TileColor.red, 6),
    ]);
    final session = RummiPokerGridSession.restored(
      runSeed: 91460,
      deckCopiesPerTile: 1,
      maxHandSize: 1,
      runRandomState: 1,
      blind: RummiBlindState(
        targetScore: 537,
        boardDiscardsRemaining: 3,
        handDiscardsRemaining: 2,
        boardMovesRemaining: 3,
      ),
      deck: PokerDeck.fromSnapshot([_tile(TileColor.red, 2)]),
      board: board,
      hand: [_tile(TileColor.red, 13), _tile(TileColor.yellow, 4)],
      eliminated: const [],
    );

    final action = const CompetitionPlannerV2Policy().chooseAction(
      session,
      jesters: const [],
      runtimeSnapshot: const RummiJesterRuntimeSnapshot(),
    );

    expect(action.type, CompetitionBattleActionType.discardBoard);
  });

  test('retry recovery delays a small high target confirm for utility', () {
    final session = RummiPokerGridSession.restored(
      runSeed: 91460,
      deckCopiesPerTile: 1,
      maxHandSize: 1,
      runRandomState: 1,
      blind: RummiBlindState(
        targetScore: 672,
        boardDiscardsRemaining: 3,
        handDiscardsRemaining: 2,
        boardMovesRemaining: 3,
      ),
      deck: PokerDeck.fromSnapshot([_tile(TileColor.red, 7)]),
      board: RummiBoard.fromSnapshot([
        _tile(TileColor.red, 3),
        _tile(TileColor.blue, 12),
        _tile(TileColor.black, 3),
        _tile(TileColor.red, 10),
        _tile(TileColor.blue, 3),
        _tile(TileColor.blue, 10),
        _tile(TileColor.black, 9),
        _tile(TileColor.black, 2),
        _tile(TileColor.blue, 6),
        _tile(TileColor.blue, 7),
        _tile(TileColor.red, 9),
        _tile(TileColor.yellow, 5),
        _tile(TileColor.blue, 4),
        _tile(TileColor.black, 13),
        _tile(TileColor.yellow, 6),
        _tile(TileColor.yellow, 11),
        _tile(TileColor.black, 8),
        _tile(TileColor.yellow, 10),
        _tile(TileColor.black, 4),
        _tile(TileColor.yellow, 9),
        _tile(TileColor.blue, 8),
        _tile(TileColor.yellow, 12),
        _tile(TileColor.black, 10),
        _tile(TileColor.red, 1),
        _tile(TileColor.red, 6),
      ]),
      hand: [_tile(TileColor.red, 13), _tile(TileColor.yellow, 4)],
      eliminated: const [],
    );

    final action =
        const CompetitionPlannerV2Policy(
          enableRetryRecoveryConfirmDelay: true,
        ).chooseAction(
          session,
          jesters: const [],
          runtimeSnapshot: const RummiJesterRuntimeSnapshot(),
        );

    expect(action.type, CompetitionBattleActionType.discardBoard);
  });

  test('full board can discard to set up discard move place combo', () {
    final board = RummiBoard.fromSnapshot([
      _tile(TileColor.red, 5),
      _tile(TileColor.blue, 2),
      _tile(TileColor.black, 3),
      _tile(TileColor.yellow, 4),
      _tile(TileColor.red, 6),
      _tile(TileColor.blue, 5),
      _tile(TileColor.black, 6),
      _tile(TileColor.yellow, 7),
      _tile(TileColor.blue, 8),
      _tile(TileColor.red, 7),
      _tile(TileColor.black, 9),
      _tile(TileColor.yellow, 10),
      _tile(TileColor.blue, 11),
      _tile(TileColor.black, 12),
      _tile(TileColor.red, 8),
      _tile(TileColor.yellow, 13),
      _tile(TileColor.blue, 1),
      _tile(TileColor.black, 2),
      _tile(TileColor.yellow, 3),
      _tile(TileColor.red, 9),
      _tile(TileColor.red, 1),
      _tile(TileColor.red, 2),
      _tile(TileColor.red, 3),
      _tile(TileColor.red, 4),
      _tile(TileColor.blue, 13),
    ]);
    final session = RummiPokerGridSession.restored(
      runSeed: 91460,
      deckCopiesPerTile: 1,
      maxHandSize: 1,
      runRandomState: 1,
      blind: RummiBlindState(
        targetScore: 1200,
        boardDiscardsRemaining: 3,
        handDiscardsRemaining: 2,
        boardMovesRemaining: 3,
      ),
      deck: PokerDeck.fromSnapshot([_tile(TileColor.blue, 9)]),
      board: board,
      hand: [_tile(TileColor.black, 13)],
      eliminated: const [],
    );

    final action = const CompetitionPlannerV2Policy().chooseScoringBoardDiscard(
      session,
      jesters: const [],
      runtimeSnapshot: const RummiJesterRuntimeSnapshot(),
    );

    expect(action?.type, CompetitionBattleActionType.discardBoard);
  });

  test('near full board continues discard move combo before placing', () {
    final session = RummiPokerGridSession.restored(
      runSeed: 91460,
      deckCopiesPerTile: 1,
      maxHandSize: 1,
      runRandomState: 1,
      blind: RummiBlindState(
        targetScore: 1200,
        boardDiscardsRemaining: 2,
        handDiscardsRemaining: 2,
        boardMovesRemaining: 3,
      ),
      deck: PokerDeck.fromSnapshot([_tile(TileColor.blue, 9)]),
      board: RummiBoard.fromSnapshot([
        _tile(TileColor.red, 1),
        _tile(TileColor.red, 2),
        _tile(TileColor.red, 3),
        _tile(TileColor.red, 4),
        null,
        _tile(TileColor.red, 9),
        _tile(TileColor.blue, 7),
        _tile(TileColor.black, 8),
        _tile(TileColor.yellow, 9),
        _tile(TileColor.red, 6),
        _tile(TileColor.blue, 1),
        _tile(TileColor.black, 5),
        _tile(TileColor.blue, 10),
        _tile(TileColor.black, 11),
        _tile(TileColor.red, 7),
        _tile(TileColor.yellow, 10),
        _tile(TileColor.black, 12),
        _tile(TileColor.yellow, 13),
        _tile(TileColor.blue, 12),
        _tile(TileColor.red, 8),
        _tile(TileColor.black, 1),
        _tile(TileColor.black, 2),
        _tile(TileColor.black, 3),
        _tile(TileColor.black, 4),
        _tile(TileColor.yellow, 1),
      ]),
      hand: [_tile(TileColor.red, 5)],
      eliminated: const [],
    );

    final action = const CompetitionPlannerV2Policy().chooseAction(
      session,
      jesters: const [],
      runtimeSnapshot: const RummiJesterRuntimeSnapshot(),
    );

    expect(action.type, CompetitionBattleActionType.moveBoard);
  });

  test('mid board uses a useful move instead of spending it as evidence', () {
    final session = RummiPokerGridSession.restored(
      runSeed: 91460,
      deckCopiesPerTile: 1,
      maxHandSize: 1,
      runRandomState: 1,
      blind: RummiBlindState(
        targetScore: 1200,
        boardDiscardsRemaining: 3,
        handDiscardsRemaining: 2,
        boardMovesRemaining: 3,
      ),
      deck: PokerDeck.fromSnapshot([_tile(TileColor.blue, 9)]),
      board: RummiBoard.fromSnapshot([
        _tile(TileColor.red, 1),
        _tile(TileColor.red, 2),
        _tile(TileColor.red, 3),
        _tile(TileColor.red, 4),
        null,
        _tile(TileColor.red, 9),
        _tile(TileColor.blue, 7),
        _tile(TileColor.black, 8),
        _tile(TileColor.yellow, 9),
        _tile(TileColor.red, 6),
        _tile(TileColor.blue, 1),
        _tile(TileColor.black, 5),
        _tile(TileColor.blue, 10),
        _tile(TileColor.black, 11),
        _tile(TileColor.red, 7),
        _tile(TileColor.yellow, 10),
        _tile(TileColor.black, 12),
        _tile(TileColor.yellow, 13),
        null,
        _tile(TileColor.red, 8),
        null,
        null,
        null,
        null,
        null,
      ]),
      hand: [_tile(TileColor.red, 5)],
      eliminated: const [],
    );

    final action = const CompetitionPlannerV2Policy().chooseAction(
      session,
      jesters: const [],
      runtimeSnapshot: const RummiJesterRuntimeSnapshot(),
    );

    expect(action.type, CompetitionBattleActionType.moveBoard);
    expect(action.gain, greaterThanOrEqualTo(20));
  });

  test(
    'mid board does not move for potential without duplicate confirm setup',
    () {
      final session = RummiPokerGridSession.restored(
        runSeed: 91460,
        deckCopiesPerTile: 1,
        maxHandSize: 1,
        runRandomState: 1,
        blind: RummiBlindState(
          targetScore: 1200,
          boardDiscardsRemaining: 3,
          handDiscardsRemaining: 2,
          boardMovesRemaining: 3,
        ),
        deck: PokerDeck.fromSnapshot([_tile(TileColor.blue, 9)]),
        board: RummiBoard.fromSnapshot([
          _tile(TileColor.red, 1),
          _tile(TileColor.red, 2),
          _tile(TileColor.red, 3),
          _tile(TileColor.red, 4),
          null,
          _tile(TileColor.blue, 7),
          _tile(TileColor.black, 8),
          _tile(TileColor.yellow, 9),
          null,
          null,
          _tile(TileColor.blue, 1),
          _tile(TileColor.black, 5),
          _tile(TileColor.blue, 10),
          _tile(TileColor.black, 11),
          null,
          _tile(TileColor.red, 5),
          null,
          null,
          null,
          null,
          null,
          null,
          null,
          null,
          null,
        ]),
        hand: [_tile(TileColor.black, 13)],
        eliminated: const [],
      );

      final action = const CompetitionPlannerV2Policy().chooseAction(
        session,
        jesters: const [],
        runtimeSnapshot: const RummiJesterRuntimeSnapshot(),
      );

      expect(action.type, isNot(CompetitionBattleActionType.moveBoard));
    },
  );

  test('board move is not chained within the same station', () {
    final session = RummiPokerGridSession.restored(
      runSeed: 91460,
      deckCopiesPerTile: 1,
      maxHandSize: 1,
      runRandomState: 1,
      blind: RummiBlindState(
        targetScore: 1200,
        boardDiscardsRemaining: 3,
        handDiscardsRemaining: 2,
        boardMovesRemaining: 2,
      ),
      deck: PokerDeck.fromSnapshot([_tile(TileColor.blue, 9)]),
      board: RummiBoard.fromSnapshot([
        _tile(TileColor.red, 1),
        _tile(TileColor.red, 2),
        _tile(TileColor.red, 3),
        _tile(TileColor.red, 4),
        null,
        _tile(TileColor.blue, 7),
        _tile(TileColor.black, 8),
        _tile(TileColor.yellow, 9),
        null,
        null,
        _tile(TileColor.blue, 1),
        _tile(TileColor.black, 5),
        _tile(TileColor.blue, 10),
        _tile(TileColor.black, 11),
        null,
        _tile(TileColor.red, 5),
        null,
        null,
        null,
        null,
        null,
        null,
        null,
        null,
        null,
      ]),
      hand: [_tile(TileColor.black, 13)],
      eliminated: const [],
      boardMoveHistory: const [
        BoardMoveRecord(fromRow: 0, fromCol: 0, toRow: 0, toCol: 4),
      ],
    );

    final action = const CompetitionPlannerV2Policy().chooseAction(
      session,
      jesters: const [],
      runtimeSnapshot: const RummiJesterRuntimeSnapshot(),
    );

    expect(action.type, isNot(CompetitionBattleActionType.moveBoard));
  });

  test('board move is not repeated after placement clears undo history', () {
    final session = RummiPokerGridSession.restored(
      runSeed: 91460,
      deckCopiesPerTile: 1,
      maxHandSize: 1,
      runRandomState: 1,
      blind: RummiBlindState(
        targetScore: 1200,
        boardDiscardsRemaining: 3,
        handDiscardsRemaining: 2,
        boardMovesRemaining: 2,
      ),
      deck: PokerDeck.fromSnapshot([_tile(TileColor.blue, 9)]),
      board: RummiBoard.fromSnapshot([
        _tile(TileColor.red, 1),
        _tile(TileColor.red, 2),
        _tile(TileColor.red, 3),
        _tile(TileColor.red, 4),
        null,
        _tile(TileColor.blue, 7),
        _tile(TileColor.black, 8),
        _tile(TileColor.yellow, 9),
        null,
        null,
        _tile(TileColor.blue, 1),
        _tile(TileColor.black, 5),
        _tile(TileColor.blue, 10),
        _tile(TileColor.black, 11),
        null,
        _tile(TileColor.red, 5),
        null,
        null,
        null,
        null,
        null,
        null,
        null,
        null,
        null,
      ]),
      hand: [_tile(TileColor.black, 13)],
      eliminated: const [],
      boardMoveHistory: const [],
    );

    final action = const CompetitionPlannerV2Policy().chooseAction(
      session,
      jesters: const [],
      runtimeSnapshot: const RummiJesterRuntimeSnapshot(),
    );

    expect(action.type, isNot(CompetitionBattleActionType.moveBoard));
  });

  test('retry recovery boss can spend another move for duplicate setup', () {
    final session = RummiPokerGridSession.restored(
      runSeed: 91460,
      deckCopiesPerTile: 1,
      maxHandSize: 1,
      runRandomState: 1,
      blind: RummiBlindState(
        targetScore: 1200,
        boardDiscardsRemaining: 3,
        handDiscardsRemaining: 2,
        boardMovesRemaining: 2,
        boardMovesMax: 3,
        bossModifier: RummiBossModifier.singleRankPressure,
      ),
      deck: PokerDeck.fromSnapshot([_tile(TileColor.blue, 9)]),
      board: RummiBoard.fromSnapshot([
        _tile(TileColor.red, 1),
        _tile(TileColor.red, 2),
        _tile(TileColor.red, 3),
        _tile(TileColor.red, 4),
        null,
        _tile(TileColor.red, 9),
        _tile(TileColor.blue, 7),
        _tile(TileColor.black, 8),
        _tile(TileColor.yellow, 9),
        _tile(TileColor.red, 6),
        _tile(TileColor.blue, 1),
        _tile(TileColor.black, 5),
        _tile(TileColor.blue, 10),
        _tile(TileColor.black, 11),
        _tile(TileColor.red, 7),
        _tile(TileColor.yellow, 10),
        _tile(TileColor.black, 12),
        _tile(TileColor.yellow, 13),
        null,
        _tile(TileColor.red, 8),
        null,
        null,
        null,
        null,
        null,
      ]),
      hand: [_tile(TileColor.red, 5)],
      eliminated: const [],
      boardMoveHistory: const [
        BoardMoveRecord(fromRow: 0, fromCol: 0, toRow: 0, toCol: 4),
      ],
    );

    final action =
        const CompetitionPlannerV2Policy(
          enableRetryRecoveryConfirmDelay: true,
        ).chooseAction(
          session,
          jesters: const [],
          runtimeSnapshot: const RummiJesterRuntimeSnapshot(),
        );

    expect(action.type, CompetitionBattleActionType.moveBoard);
    expect(action.gain, greaterThanOrEqualTo(70));
  });

  test('early low target does not spend hand discard for evidence', () {
    final session = RummiPokerGridSession.restored(
      runSeed: 91460,
      deckCopiesPerTile: 1,
      maxHandSize: 3,
      runRandomState: 1,
      blind: RummiBlindState(
        targetScore: 240,
        boardDiscardsRemaining: 3,
        handDiscardsRemaining: 2,
        boardMovesRemaining: 3,
      ),
      deck: PokerDeck.fromSnapshot([_tile(TileColor.blue, 9)]),
      board: RummiBoard.fromSnapshot([
        _tile(TileColor.red, 1),
        _tile(TileColor.red, 2),
        _tile(TileColor.red, 3),
        _tile(TileColor.red, 4),
        null,
        _tile(TileColor.blue, 7),
        _tile(TileColor.black, 8),
        _tile(TileColor.yellow, 9),
        null,
        null,
        null,
        null,
        null,
        null,
        null,
        null,
        null,
        null,
        null,
        null,
        null,
        null,
        null,
        null,
        null,
      ]),
      hand: [_tile(TileColor.black, 13)],
      eliminated: const [],
    );

    final action = const CompetitionPlannerV2Policy().chooseAction(
      session,
      jesters: [_jester('mystic_summit')],
      runtimeSnapshot: const RummiJesterRuntimeSnapshot(),
    );

    expect(action.type, isNot(CompetitionBattleActionType.discardHand));
  });

  test('early low target keeps hand discard even near a full board', () {
    final session = RummiPokerGridSession.restored(
      runSeed: 91460,
      deckCopiesPerTile: 1,
      maxHandSize: 1,
      runRandomState: 1,
      blind: RummiBlindState(
        targetScore: 431,
        boardDiscardsRemaining: 3,
        handDiscardsRemaining: 2,
        boardMovesRemaining: 3,
      ),
      deck: PokerDeck.fromSnapshot([_tile(TileColor.red, 7)]),
      board: RummiBoard.fromSnapshot([
        _tile(TileColor.red, 1),
        _tile(TileColor.blue, 2),
        _tile(TileColor.black, 3),
        _tile(TileColor.yellow, 4),
        null,
        _tile(TileColor.red, 5),
        _tile(TileColor.blue, 6),
        _tile(TileColor.black, 7),
        _tile(TileColor.yellow, 8),
        null,
        _tile(TileColor.red, 9),
        _tile(TileColor.blue, 10),
        _tile(TileColor.black, 11),
        _tile(TileColor.yellow, 12),
        null,
        _tile(TileColor.red, 13),
        _tile(TileColor.blue, 1),
        _tile(TileColor.black, 2),
        _tile(TileColor.yellow, 3),
        null,
        _tile(TileColor.red, 4),
        _tile(TileColor.blue, 5),
        _tile(TileColor.black, 6),
        _tile(TileColor.yellow, 7),
        null,
      ]),
      hand: [_tile(TileColor.black, 13)],
      eliminated: const [],
    );

    final action = const CompetitionPlannerV2Policy().chooseAction(
      session,
      jesters: [_jester('mystic_summit')],
      runtimeSnapshot: const RummiJesterRuntimeSnapshot(),
    );

    expect(action.type, isNot(CompetitionBattleActionType.discardHand));
  });

  test('early low target does not spend board move for evidence', () {
    final session = RummiPokerGridSession.restored(
      runSeed: 91460,
      deckCopiesPerTile: 1,
      maxHandSize: 1,
      runRandomState: 1,
      blind: RummiBlindState(
        targetScore: 240,
        boardDiscardsRemaining: 3,
        handDiscardsRemaining: 2,
        boardMovesRemaining: 3,
      ),
      deck: PokerDeck.fromSnapshot([_tile(TileColor.blue, 9)]),
      board: RummiBoard.fromSnapshot([
        _tile(TileColor.red, 1),
        _tile(TileColor.red, 2),
        _tile(TileColor.red, 3),
        _tile(TileColor.red, 4),
        null,
        _tile(TileColor.blue, 7),
        _tile(TileColor.black, 8),
        _tile(TileColor.yellow, 9),
        null,
        null,
        _tile(TileColor.blue, 1),
        _tile(TileColor.black, 5),
        _tile(TileColor.blue, 10),
        _tile(TileColor.black, 11),
        null,
        _tile(TileColor.red, 5),
        null,
        null,
        null,
        null,
        null,
        null,
        null,
        null,
        null,
      ]),
      hand: [_tile(TileColor.black, 13)],
      eliminated: const [],
    );

    final action = const CompetitionPlannerV2Policy().chooseAction(
      session,
      jesters: const [],
      runtimeSnapshot: const RummiJesterRuntimeSnapshot(),
    );

    expect(action.type, isNot(CompetitionBattleActionType.moveBoard));
  });

  test('early low target boss can move for duplicate confirm setup', () {
    final session = RummiPokerGridSession.restored(
      runSeed: 91460,
      deckCopiesPerTile: 1,
      maxHandSize: 1,
      runRandomState: 1,
      blind: RummiBlindState(
        targetScore: 265,
        boardDiscardsRemaining: 3,
        handDiscardsRemaining: 2,
        boardMovesRemaining: 3,
        bossModifier: RummiBossModifier.confirmLimitTax,
      ),
      deck: PokerDeck.fromSnapshot([_tile(TileColor.blue, 9)]),
      board: RummiBoard.fromSnapshot([
        _tile(TileColor.red, 1),
        _tile(TileColor.red, 2),
        _tile(TileColor.red, 3),
        _tile(TileColor.red, 4),
        null,
        _tile(TileColor.red, 9),
        _tile(TileColor.blue, 7),
        _tile(TileColor.black, 8),
        _tile(TileColor.yellow, 9),
        _tile(TileColor.red, 6),
        _tile(TileColor.blue, 1),
        _tile(TileColor.black, 5),
        _tile(TileColor.blue, 10),
        _tile(TileColor.black, 11),
        _tile(TileColor.red, 7),
        _tile(TileColor.yellow, 10),
        _tile(TileColor.black, 12),
        _tile(TileColor.yellow, 13),
        null,
        _tile(TileColor.red, 8),
        null,
        null,
        null,
        null,
        null,
      ]),
      hand: [_tile(TileColor.red, 5)],
      eliminated: const [],
    );

    final action = const CompetitionPlannerV2Policy().chooseAction(
      session,
      jesters: const [],
      runtimeSnapshot: const RummiJesterRuntimeSnapshot(),
    );

    expect(action.type, CompetitionBattleActionType.moveBoard);
  });

  test('early low target does not spend board discard for evidence', () {
    final session = RummiPokerGridSession.restored(
      runSeed: 91460,
      deckCopiesPerTile: 1,
      maxHandSize: 1,
      runRandomState: 1,
      blind: RummiBlindState(
        targetScore: 240,
        boardDiscardsRemaining: 3,
        handDiscardsRemaining: 0,
        boardMovesRemaining: 0,
      ),
      deck: PokerDeck.fromSnapshot(const []),
      board: RummiBoard.fromSnapshot([
        _tile(TileColor.red, 1),
        _tile(TileColor.blue, 2),
        _tile(TileColor.black, 3),
        _tile(TileColor.yellow, 4),
        null,
        _tile(TileColor.red, 5),
        _tile(TileColor.blue, 6),
        _tile(TileColor.black, 7),
        _tile(TileColor.yellow, 8),
        null,
        _tile(TileColor.red, 9),
        _tile(TileColor.blue, 10),
        _tile(TileColor.black, 11),
        _tile(TileColor.yellow, 12),
        null,
        _tile(TileColor.red, 13),
        _tile(TileColor.blue, 1),
        _tile(TileColor.black, 2),
        _tile(TileColor.yellow, 3),
        null,
        _tile(TileColor.red, 4),
        _tile(TileColor.blue, 5),
        _tile(TileColor.black, 6),
        _tile(TileColor.yellow, 7),
        null,
      ]),
      hand: const [],
      eliminated: const [],
    );

    final action = const CompetitionPlannerV2Policy().chooseAction(
      session,
      jesters: [_jester('mystic_summit')],
      runtimeSnapshot: const RummiJesterRuntimeSnapshot(),
    );

    expect(action.type, isNot(CompetitionBattleActionType.discardBoard));
  });

  test(
    'placement lookahead picks the cell that sets up the next hand tile',
    () {
      final session = RummiPokerGridSession.restored(
        runSeed: 91460,
        deckCopiesPerTile: 1,
        maxHandSize: 2,
        runRandomState: 1,
        blind: RummiBlindState(
          targetScore: 1200,
          boardDiscardsRemaining: 3,
          handDiscardsRemaining: 2,
          boardMovesRemaining: 3,
        ),
        deck: PokerDeck.fromSnapshot(const []),
        board: RummiBoard.fromSnapshot([
          _tile(TileColor.red, 1),
          _tile(TileColor.red, 2),
          _tile(TileColor.red, 3),
          null,
          null,
          _tile(TileColor.blue, 9),
          _tile(TileColor.black, 9),
          null,
          null,
          null,
          _tile(TileColor.yellow, 11),
          _tile(TileColor.black, 12),
          null,
          null,
          null,
          null,
          null,
          null,
          null,
          null,
          null,
          null,
          null,
          null,
          null,
        ]),
        hand: [_tile(TileColor.red, 4), _tile(TileColor.red, 5)],
        eliminated: const [],
      );

      final action = const CompetitionPlannerV2Policy().bestPlacementForTest(
        session,
        jesters: const [],
        runtimeSnapshot: const RummiJesterRuntimeSnapshot(),
      );

      expect(action?.type, CompetitionBattleActionType.place);
      expect(action?.row, 0);
      expect(action?.col, 4);
    },
  );

  test('larger hand draws for options before placing the first tile', () {
    final session = RummiPokerGridSession.restored(
      runSeed: 91460,
      deckCopiesPerTile: 1,
      maxHandSize: 3,
      runRandomState: 1,
      blind: RummiBlindState(
        targetScore: 1200,
        boardDiscardsRemaining: 3,
        handDiscardsRemaining: 2,
        boardMovesRemaining: 3,
      ),
      deck: PokerDeck.fromSnapshot([
        _tile(TileColor.blue, 7),
        _tile(TileColor.red, 7),
      ]),
      board: RummiBoard(),
      hand: [_tile(TileColor.black, 7)],
      eliminated: const [],
    );

    final action = const CompetitionPlannerV2Policy().chooseAction(
      session,
      jesters: const [],
      runtimeSnapshot: const RummiJesterRuntimeSnapshot(),
    );

    expect(action.type, CompetitionBattleActionType.draw);
  });
}

Tile _tile(TileColor color, int number) => Tile(color: color, number: number);

RummiJesterCard _jester(String id) {
  return RummiJesterCard(
    id: id,
    displayName: id,
    rarity: RummiJesterRarity.common,
    baseCost: 1,
    effectText: '',
    effectType: '',
    trigger: '',
    conditionType: '',
    conditionValue: null,
    value: null,
    xValue: null,
    mappedTileColors: const [],
    mappedTileNumbers: const [],
  );
}
