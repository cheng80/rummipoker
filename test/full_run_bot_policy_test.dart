import 'package:flutter_test/flutter_test.dart';
import 'package:rummipoker/logic/rummi_poker_grid/boss_modifier.dart';
import 'package:rummipoker/logic/rummi_poker_grid/hand_rank.dart';
import 'package:rummipoker/logic/rummi_poker_grid/jester_meta.dart';
import 'package:rummipoker/logic/rummi_poker_grid/models/board.dart';
import 'package:rummipoker/logic/rummi_poker_grid/models/poker_deck.dart';
import 'package:rummipoker/logic/rummi_poker_grid/models/tile.dart';
import 'package:rummipoker/logic/rummi_poker_grid/rummi_blind_state.dart';
import 'package:rummipoker/logic/rummi_poker_grid/rummi_poker_grid_session.dart';

import '../integration_test/full_run_bot_policy.dart';

void main() {
  test('battle item use must support the planned battle action', () {
    expect(
      fullRunBattleItemOpSupportsPlannedAction(
        'add_board_move',
        FullRunBattleActionType.moveBoard,
      ),
      isTrue,
    );
    expect(
      fullRunBattleItemOpSupportsPlannedAction(
        'add_board_move',
        FullRunBattleActionType.draw,
      ),
      isFalse,
    );
    expect(
      fullRunBattleItemOpSupportsPlannedAction(
        'mark_next_board_move_bonus',
        FullRunBattleActionType.moveBoard,
      ),
      isTrue,
    );
    expect(
      fullRunBattleItemOpSupportsPlannedAction(
        'mark_next_board_move_bonus',
        FullRunBattleActionType.draw,
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

    final action = const FullRunPlannerV2Policy().chooseAction(
      session,
      jesters: const [],
      runtimeSnapshot: const RummiJesterRuntimeSnapshot(),
    );

    expect(action.type, isNot(FullRunBattleActionType.confirm));
  });

  test('high target waits instead of taking a small early confirm', () {
    final session = RummiPokerGridSession.restored(
      runSeed: 91460,
      deckCopiesPerTile: 1,
      maxHandSize: 2,
      runRandomState: 1,
      blind: RummiBlindState(
        targetScore: 1738,
        boardDiscardsRemaining: 3,
        handDiscardsRemaining: 2,
        boardMovesRemaining: 3,
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

    final action = const FullRunPlannerV2Policy().chooseAction(
      session,
      jesters: const [],
      runtimeSnapshot: const RummiJesterRuntimeSnapshot(),
    );

    expect(action.type, isNot(FullRunBattleActionType.confirm));
  });

  test('growth score can make a single line confirm clear the target', () {
    final session = RummiPokerGridSession.restored(
      runSeed: 91460,
      deckCopiesPerTile: 1,
      maxHandSize: 2,
      runRandomState: 1,
      blind: RummiBlindState(
        targetScore: 170,
        boardDiscardsRemaining: 3,
        handDiscardsRemaining: 2,
        boardMovesRemaining: 3,
      ),
      deck: PokerDeck.fromSnapshot(const []),
      board: RummiBoard.fromSnapshot([
        _tile(TileColor.blue, 1),
        _tile(TileColor.blue, 2),
        _tile(TileColor.blue, 3),
        _tile(TileColor.blue, 4),
        _tile(TileColor.blue, 5),
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
        null,
        null,
        null,
      ]),
      hand: const [],
      eliminated: const [],
    );

    final action = const FullRunPlannerV2Policy().chooseAction(
      session,
      jesters: const [],
      runtimeSnapshot: const RummiJesterRuntimeSnapshot(
        playedHandCounts: {RummiHandRank.straightFlush: 1},
      ),
    );

    expect(action.type, FullRunBattleActionType.confirm);
  });

  test('placement policy prefers building same-color flush lines', () {
    final session = RummiPokerGridSession.restored(
      runSeed: 91460,
      deckCopiesPerTile: 1,
      maxHandSize: 2,
      runRandomState: 1,
      blind: RummiBlindState(targetScore: 439),
      deck: PokerDeck.fromSnapshot(const []),
      board: RummiBoard.fromSnapshot([
        _tile(TileColor.red, 1),
        _tile(TileColor.red, 2),
        _tile(TileColor.red, 3),
        null,
        null,
        _tile(TileColor.blue, 9),
        null,
        null,
        null,
        null,
        _tile(TileColor.black, 9),
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
      hand: [_tile(TileColor.red, 4), _tile(TileColor.yellow, 9)],
      eliminated: const [],
    );

    final action = const FullRunPlannerV2Policy().bestPlacementForTest(
      session,
      jesters: const [],
      runtimeSnapshot: const RummiJesterRuntimeSnapshot(),
    );

    expect(action?.type, FullRunBattleActionType.place);
    expect(action?.handIndex, 0);
    expect(action?.row, 0);
  });

  test('placement policy prefers same-color line intersections', () {
    final session = RummiPokerGridSession.restored(
      runSeed: 91460,
      deckCopiesPerTile: 1,
      maxHandSize: 2,
      runRandomState: 1,
      blind: RummiBlindState(targetScore: 720),
      deck: PokerDeck.fromSnapshot(const []),
      board: RummiBoard.fromSnapshot([
        _tile(TileColor.red, 1),
        _tile(TileColor.red, 2),
        null,
        null,
        null,
        null,
        null,
        _tile(TileColor.red, 7),
        null,
        null,
        null,
        null,
        _tile(TileColor.red, 8),
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
      hand: [_tile(TileColor.red, 3), _tile(TileColor.yellow, 13)],
      eliminated: const [],
    );

    final action = const FullRunPlannerV2Policy().bestPlacementForTest(
      session,
      jesters: const [],
      runtimeSnapshot: const RummiJesterRuntimeSnapshot(),
    );

    expect(action?.type, FullRunBattleActionType.place);
    expect(action?.handIndex, 0);
    expect((action?.row, action?.col), anyOf(const (0, 2), const (1, 1)));
  });

  test('battle late is based on target progress, not station number', () {
    final early = RummiPokerGridSession.restored(
      runSeed: 91460,
      deckCopiesPerTile: 1,
      maxHandSize: 1,
      runRandomState: 1,
      blind: RummiBlindState(targetScore: 1200, scoreTowardBlind: 240),
      deck: PokerDeck.fromSnapshot(const []),
      board: RummiBoard.fromSnapshot(List<Tile?>.filled(25, null)),
      hand: const [],
      eliminated: const [],
    );
    final late = RummiPokerGridSession.restored(
      runSeed: 91460,
      deckCopiesPerTile: 1,
      maxHandSize: 1,
      runRandomState: 1,
      blind: RummiBlindState(targetScore: 1200, scoreTowardBlind: 840),
      deck: PokerDeck.fromSnapshot(const []),
      board: RummiBoard.fromSnapshot(List<Tile?>.filled(25, null)),
      hand: const [],
      eliminated: const [],
    );

    const policy = FullRunPlannerV2Policy();

    expect(policy.isBattleTargetLateForTest(early), isFalse);
    expect(policy.isBattleTargetLateForTest(late), isTrue);
  });

  test('full board confirms early score instead of discard move loop', () {
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

    final action = const FullRunPlannerV2Policy().chooseAction(
      session,
      jesters: const [],
      runtimeSnapshot: const RummiJesterRuntimeSnapshot(),
    );

    expect(action.type, FullRunBattleActionType.confirm);
  });

  test('retry recovery full board does not force a low confirm', () {
    final session = RummiPokerGridSession.restored(
      runSeed: 91460,
      deckCopiesPerTile: 1,
      maxHandSize: 1,
      runRandomState: 1,
      blind: RummiBlindState(
        targetScore: 1391,
        boardDiscardsRemaining: 3,
        handDiscardsRemaining: 2,
        boardMovesRemaining: 0,
      ),
      deck: PokerDeck.fromSnapshot([_tile(TileColor.red, 2)]),
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
      hand: const [],
      eliminated: const [],
    );

    final action =
        const FullRunPlannerV2Policy(
          enableRetryRecoveryConfirmDelay: true,
        ).chooseAction(
          session,
          jesters: const [],
          runtimeSnapshot: const RummiJesterRuntimeSnapshot(),
        );

    expect(action.type, isNot(FullRunBattleActionType.confirm));
  });

  test('early full board high target confirms instead of utility discard', () {
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
        const FullRunPlannerV2Policy(
          enableRetryRecoveryConfirmDelay: true,
        ).chooseAction(
          session,
          jesters: const [],
          runtimeSnapshot: const RummiJesterRuntimeSnapshot(),
        );

    expect(action.type, FullRunBattleActionType.confirm);
  });

  test('retry recovery delays a low value high target two-line confirm', () {
    final session = RummiPokerGridSession.restored(
      runSeed: 91460,
      deckCopiesPerTile: 1,
      maxHandSize: 1,
      runRandomState: 1,
      blind: RummiBlindState(
        targetScore: 1391,
        boardDiscardsRemaining: 4,
        handDiscardsRemaining: 2,
        boardMovesRemaining: 0,
      ),
      deck: PokerDeck.fromSnapshot([_tile(TileColor.red, 7)]),
      board: RummiBoard.fromSnapshot([
        _tile(TileColor.red, 1),
        _tile(TileColor.blue, 1),
        _tile(TileColor.red, 2),
        _tile(TileColor.blue, 2),
        _tile(TileColor.yellow, 5),
        _tile(TileColor.red, 3),
        _tile(TileColor.blue, 3),
        _tile(TileColor.red, 4),
        _tile(TileColor.blue, 4),
        _tile(TileColor.yellow, 6),
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
      hand: const [],
      eliminated: const [],
    );

    final action =
        const FullRunPlannerV2Policy(
          enableRetryRecoveryConfirmDelay: true,
        ).chooseAction(
          session,
          jesters: const [],
          runtimeSnapshot: const RummiJesterRuntimeSnapshot(),
        );

    expect(action.type, isNot(FullRunBattleActionType.confirm));
  });

  test('second retry raises the medium three-line confirm threshold', () {
    expect(
      const FullRunPlannerV2Policy(
        enableRetryRecoveryConfirmDelay: true,
      ).isHighTargetRecoveryBundleForTest(score: 266, lineCount: 3),
      isTrue,
    );
    expect(
      const FullRunPlannerV2Policy(
        enableRetryRecoveryConfirmDelay: true,
        retryRecoveryAttempt: 2,
      ).isHighTargetRecoveryBundleForTest(score: 266, lineCount: 3),
      isFalse,
    );
  });

  test('second retry boss does not tempo confirm a low tax bundle', () {
    final session = RummiPokerGridSession.restored(
      runSeed: 91460,
      deckCopiesPerTile: 1,
      maxHandSize: 1,
      runRandomState: 1,
      blind: RummiBlindState(
        targetScore: 1401,
        boardDiscardsRemaining: 3,
        handDiscardsRemaining: 1,
        boardMovesRemaining: 3,
        bossModifier: RummiBossModifier.confirmCountTax,
      ),
      deck: PokerDeck.fromSnapshot([_tile(TileColor.red, 2)]),
      board: RummiBoard.fromSnapshot([
        _tile(TileColor.blue, 10),
        null,
        _tile(TileColor.blue, 4),
        _tile(TileColor.yellow, 12),
        null,
        _tile(TileColor.black, 1),
        null,
        _tile(TileColor.black, 4),
        _tile(TileColor.black, 12),
        _tile(TileColor.black, 8),
        _tile(TileColor.red, 6),
        _tile(TileColor.red, 3),
        _tile(TileColor.blue, 8),
        _tile(TileColor.black, 11),
        _tile(TileColor.black, 7),
        _tile(TileColor.red, 13),
        _tile(TileColor.blue, 13),
        _tile(TileColor.black, 9),
        _tile(TileColor.blue, 12),
        _tile(TileColor.black, 13),
        null,
        _tile(TileColor.red, 10),
        _tile(TileColor.red, 5),
        null,
        null,
      ]),
      hand: const [],
      eliminated: const [],
    );

    final secondRecoveryAction =
        const FullRunPlannerV2Policy(
          enableRetryRecoveryConfirmDelay: true,
          retryRecoveryAttempt: 2,
        ).chooseAction(
          session,
          jesters: const [],
          runtimeSnapshot: const RummiJesterRuntimeSnapshot(),
        );

    expect(secondRecoveryAction.type, FullRunBattleActionType.draw);
  });

  test('second retry boss places before a medium confirm if hand remains', () {
    final session = RummiPokerGridSession.restored(
      runSeed: 91460,
      deckCopiesPerTile: 1,
      maxHandSize: 1,
      runRandomState: 1,
      blind: RummiBlindState(
        targetScore: 1401,
        boardDiscardsRemaining: 3,
        handDiscardsRemaining: 1,
        boardMovesRemaining: 0,
        bossModifier: RummiBossModifier.confirmCountTax,
      ),
      deck: PokerDeck.fromSnapshot([_tile(TileColor.red, 2)]),
      board: RummiBoard.fromSnapshot([
        _tile(TileColor.blue, 10),
        null,
        _tile(TileColor.blue, 4),
        _tile(TileColor.yellow, 12),
        null,
        _tile(TileColor.black, 1),
        null,
        _tile(TileColor.black, 4),
        _tile(TileColor.black, 12),
        _tile(TileColor.black, 8),
        _tile(TileColor.red, 6),
        _tile(TileColor.red, 3),
        _tile(TileColor.blue, 8),
        _tile(TileColor.black, 11),
        _tile(TileColor.black, 7),
        _tile(TileColor.red, 13),
        _tile(TileColor.blue, 13),
        _tile(TileColor.black, 9),
        _tile(TileColor.blue, 12),
        _tile(TileColor.black, 13),
        null,
        _tile(TileColor.red, 10),
        _tile(TileColor.red, 5),
        null,
        null,
      ]),
      hand: [_tile(TileColor.red, 2)],
      eliminated: const [],
    );

    final action =
        const FullRunPlannerV2Policy(
          enableRetryRecoveryConfirmDelay: true,
          retryRecoveryAttempt: 2,
        ).chooseAction(
          session,
          jesters: const [],
          runtimeSnapshot: const RummiJesterRuntimeSnapshot(),
        );

    expect(action.type, isNot(FullRunBattleActionType.confirm));
  });

  test('second retry boss draws before a medium confirm if deck remains', () {
    final session = RummiPokerGridSession.restored(
      runSeed: 91460,
      deckCopiesPerTile: 1,
      maxHandSize: 1,
      runRandomState: 1,
      blind: RummiBlindState(
        targetScore: 1401,
        boardDiscardsRemaining: 3,
        handDiscardsRemaining: 1,
        boardMovesRemaining: 0,
        bossModifier: RummiBossModifier.confirmCountTax,
      ),
      deck: PokerDeck.fromSnapshot([_tile(TileColor.red, 2)]),
      board: RummiBoard.fromSnapshot([
        _tile(TileColor.red, 10),
        _tile(TileColor.blue, 10),
        _tile(TileColor.red, 11),
        _tile(TileColor.blue, 11),
        _tile(TileColor.yellow, 9),
        _tile(TileColor.red, 12),
        _tile(TileColor.blue, 12),
        _tile(TileColor.red, 13),
        _tile(TileColor.blue, 13),
        _tile(TileColor.yellow, 8),
        _tile(TileColor.red, 7),
        _tile(TileColor.blue, 7),
        _tile(TileColor.red, 8),
        _tile(TileColor.blue, 8),
        _tile(TileColor.yellow, 6),
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
      hand: const [],
      eliminated: const [],
    );

    final action =
        const FullRunPlannerV2Policy(
          enableRetryRecoveryConfirmDelay: true,
          retryRecoveryAttempt: 2,
        ).chooseAction(
          session,
          jesters: const [],
          runtimeSnapshot: const RummiJesterRuntimeSnapshot(),
        );

    expect(action.type, FullRunBattleActionType.draw);
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
        scoreTowardBlind: 840,
        boardDiscardsRemaining: 3,
        handDiscardsRemaining: 2,
        boardMovesRemaining: 3,
      ),
      deck: PokerDeck.fromSnapshot([_tile(TileColor.blue, 9)]),
      board: board,
      hand: [_tile(TileColor.black, 13)],
      eliminated: const [],
    );

    final action = const FullRunPlannerV2Policy().chooseScoringBoardDiscard(
      session,
      jesters: const [],
      runtimeSnapshot: const RummiJesterRuntimeSnapshot(),
    );

    expect(action?.type, FullRunBattleActionType.discardBoard);
  });

  test('near full board continues discard move combo before placing', () {
    final session = RummiPokerGridSession.restored(
      runSeed: 91460,
      deckCopiesPerTile: 1,
      maxHandSize: 1,
      runRandomState: 1,
      blind: RummiBlindState(
        targetScore: 1200,
        scoreTowardBlind: 840,
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

    final action = const FullRunPlannerV2Policy().chooseAction(
      session,
      jesters: const [],
      runtimeSnapshot: const RummiJesterRuntimeSnapshot(),
    );

    expect(action.type, FullRunBattleActionType.moveBoard);
  });

  test(
    'full boss board discards to revive a scoring line instead of stopping',
    () {
      final session = RummiPokerGridSession.restored(
        runSeed: 91460,
        deckCopiesPerTile: 1,
        maxHandSize: 1,
        runRandomState: 1,
        blind: RummiBlindState(
          targetScore: 1121,
          boardDiscardsRemaining: 3,
          handDiscardsRemaining: 0,
          boardMovesRemaining: 0,
          bossModifier: RummiBossModifier.confirmCountTax,
        ),
        deck: PokerDeck.fromSnapshot([
          _tile(TileColor.blue, 8),
          _tile(TileColor.yellow, 4),
          _tile(TileColor.red, 2),
        ]),
        board: RummiBoard.fromSnapshot([
          _tile(TileColor.yellow, 2),
          _tile(TileColor.black, 2),
          _tile(TileColor.yellow, 3),
          _tile(TileColor.red, 7),
          _tile(TileColor.blue, 4),
          _tile(TileColor.red, 9),
          _tile(TileColor.black, 10),
          _tile(TileColor.red, 1),
          _tile(TileColor.black, 4),
          _tile(TileColor.blue, 9),
          _tile(TileColor.red, 11),
          _tile(TileColor.black, 1),
          _tile(TileColor.blue, 12),
          _tile(TileColor.black, 5),
          _tile(TileColor.blue, 7),
          _tile(TileColor.red, 5),
          _tile(TileColor.black, 13),
          _tile(TileColor.red, 4),
          _tile(TileColor.black, 12),
          _tile(TileColor.black, 8),
          _tile(TileColor.yellow, 11),
          _tile(TileColor.blue, 13),
          _tile(TileColor.yellow, 1),
          _tile(TileColor.yellow, 6),
          _tile(TileColor.black, 6),
        ]),
        hand: [_tile(TileColor.yellow, 5)],
        eliminated: const [],
      );

      final action =
          const FullRunPlannerV2Policy(
            enableRetryRecoveryConfirmDelay: true,
          ).chooseAction(
            session,
            jesters: const [],
            runtimeSnapshot: const RummiJesterRuntimeSnapshot(),
          );

      expect(action.type, FullRunBattleActionType.discardBoard);
    },
  );

  test('mid board places a direct flush before spending a useful move', () {
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

    final action = const FullRunPlannerV2Policy().chooseAction(
      session,
      jesters: const [],
      runtimeSnapshot: const RummiJesterRuntimeSnapshot(),
    );

    expect(action.type, FullRunBattleActionType.place);
    expect(action.handIndex, 0);
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

      final action = const FullRunPlannerV2Policy().chooseAction(
        session,
        jesters: const [],
        runtimeSnapshot: const RummiJesterRuntimeSnapshot(),
      );

      expect(action.type, isNot(FullRunBattleActionType.moveBoard));
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
        scoreTowardBlind: 840,
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

    final action = const FullRunPlannerV2Policy().chooseAction(
      session,
      jesters: const [],
      runtimeSnapshot: const RummiJesterRuntimeSnapshot(),
    );

    expect(action.type, isNot(FullRunBattleActionType.moveBoard));
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

    final action = const FullRunPlannerV2Policy().chooseAction(
      session,
      jesters: const [],
      runtimeSnapshot: const RummiJesterRuntimeSnapshot(),
    );

    expect(action.type, isNot(FullRunBattleActionType.moveBoard));
  });

  test(
    'retry recovery boss still places a direct flush before another move',
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
          const FullRunPlannerV2Policy(
            enableRetryRecoveryConfirmDelay: true,
            retryRecoveryAttempt: 2,
          ).chooseAction(
            session,
            jesters: const [],
            runtimeSnapshot: const RummiJesterRuntimeSnapshot(),
          );

      expect(action.type, FullRunBattleActionType.place);
      expect(action.handIndex, 0);
    },
  );

  test(
    'retry recovery does not chain early board moves before late pressure',
    () {
      final session = RummiPokerGridSession.restored(
        runSeed: 91460,
        deckCopiesPerTile: 1,
        maxHandSize: 1,
        runRandomState: 1,
        blind: RummiBlindState(
          targetScore: 1738,
          boardDiscardsRemaining: 3,
          handDiscardsRemaining: 2,
          boardMovesRemaining: 2,
          boardMovesMax: 3,
          bossModifier: RummiBossModifier.confirmCountTax,
        ),
        deck: PokerDeck.fromSnapshot([
          _tile(TileColor.red, 13),
          _tile(TileColor.yellow, 13),
          _tile(TileColor.yellow, 3),
          _tile(TileColor.blue, 9),
          _tile(TileColor.red, 1),
          _tile(TileColor.red, 10),
          _tile(TileColor.black, 11),
          _tile(TileColor.blue, 11),
          _tile(TileColor.red, 11),
          _tile(TileColor.red, 8),
          _tile(TileColor.yellow, 8),
          _tile(TileColor.black, 4),
          _tile(TileColor.red, 4),
        ]),
        board: RummiBoard.fromSnapshot([
          _tile(TileColor.red, 1),
          null,
          _tile(TileColor.blue, 4),
          _tile(TileColor.red, 9),
          _tile(TileColor.black, 9),
          _tile(TileColor.blue, 9),
          _tile(TileColor.red, 5),
          _tile(TileColor.black, 5),
          _tile(TileColor.black, 12),
          _tile(TileColor.yellow, 12),
          _tile(TileColor.red, 3),
          _tile(TileColor.black, 3),
          _tile(TileColor.yellow, 3),
          _tile(TileColor.black, 13),
          _tile(TileColor.red, 13),
          _tile(TileColor.yellow, 13),
          _tile(TileColor.blue, 2),
          null,
          null,
          null,
          null,
          null,
          null,
          null,
          null,
        ]),
        hand: [_tile(TileColor.yellow, 3)],
        eliminated: const [],
        boardMoveHistory: const [
          BoardMoveRecord(fromRow: 0, fromCol: 1, toRow: 2, toCol: 3),
        ],
      );

      final action =
          const FullRunPlannerV2Policy(
            enableRetryRecoveryConfirmDelay: true,
            retryRecoveryAttempt: 2,
          ).chooseAction(
            session,
            jesters: const [],
            runtimeSnapshot: const RummiJesterRuntimeSnapshot(),
          );

      expect(action.type, isNot(FullRunBattleActionType.moveBoard));
    },
  );

  test('retry recovery boss delays a medium two-line confirm', () {
    final session = RummiPokerGridSession.restored(
      runSeed: 91460,
      deckCopiesPerTile: 1,
      maxHandSize: 1,
      runRandomState: 1,
      blind: RummiBlindState(
        targetScore: 1121,
        boardDiscardsRemaining: 3,
        handDiscardsRemaining: 1,
        boardMovesRemaining: 0,
        bossModifier: RummiBossModifier.confirmCountTax,
      ),
      deck: PokerDeck.fromSnapshot([_tile(TileColor.blue, 7)]),
      board: RummiBoard.fromSnapshot([
        _tile(TileColor.blue, 3),
        _tile(TileColor.black, 3),
        _tile(TileColor.red, 3),
        _tile(TileColor.yellow, 3),
        null,
        _tile(TileColor.red, 1),
        _tile(TileColor.blue, 1),
        _tile(TileColor.black, 1),
        _tile(TileColor.yellow, 1),
        null,
        null,
        null,
        _tile(TileColor.red, 9),
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
      hand: [_tile(TileColor.red, 5)],
      eliminated: const [],
    );

    final action =
        const FullRunPlannerV2Policy(
          enableRetryRecoveryConfirmDelay: true,
        ).chooseAction(
          session,
          jesters: const [],
          runtimeSnapshot: const RummiJesterRuntimeSnapshot(),
        );

    expect(action.type, isNot(FullRunBattleActionType.confirm));
  });

  test('retry recovery boss delays a low score three-line confirm', () {
    final session = RummiPokerGridSession.restored(
      runSeed: 91460,
      deckCopiesPerTile: 1,
      maxHandSize: 1,
      runRandomState: 1,
      blind: RummiBlindState(
        targetScore: 685,
        boardDiscardsRemaining: 3,
        handDiscardsRemaining: 1,
        boardMovesRemaining: 0,
        bossModifier: RummiBossModifier.singleRankPressure,
      ),
      deck: PokerDeck.fromSnapshot([_tile(TileColor.black, 13)]),
      board: RummiBoard.fromSnapshot([
        null,
        _tile(TileColor.red, 1),
        _tile(TileColor.yellow, 5),
        _tile(TileColor.red, 5),
        _tile(TileColor.black, 5),
        _tile(TileColor.red, 2),
        null,
        _tile(TileColor.yellow, 8),
        _tile(TileColor.black, 3),
        null,
        _tile(TileColor.black, 11),
        _tile(TileColor.yellow, 11),
        _tile(TileColor.black, 6),
        _tile(TileColor.blue, 6),
        _tile(TileColor.red, 9),
        _tile(TileColor.yellow, 12),
        null,
        _tile(TileColor.red, 4),
        _tile(TileColor.blue, 4),
        _tile(TileColor.blue, 12),
        _tile(TileColor.black, 8),
        _tile(TileColor.blue, 9),
        _tile(TileColor.red, 9),
        null,
        null,
      ]),
      hand: [_tile(TileColor.black, 12)],
      eliminated: const [],
    );

    final action =
        const FullRunPlannerV2Policy(
          enableRetryRecoveryConfirmDelay: true,
        ).chooseAction(
          session,
          jesters: const [],
          runtimeSnapshot: const RummiJesterRuntimeSnapshot(),
        );

    expect(action.type, isNot(FullRunBattleActionType.confirm));
  });

  test('retry recovery boss skips a low value repeated board move', () {
    final session = RummiPokerGridSession.restored(
      runSeed: 91460,
      deckCopiesPerTile: 1,
      maxHandSize: 1,
      runRandomState: 1,
      blind: RummiBlindState(
        targetScore: 685,
        boardDiscardsRemaining: 3,
        handDiscardsRemaining: 1,
        boardMovesRemaining: 3,
        boardMovesMax: 3,
        bossModifier: RummiBossModifier.singleRankPressure,
      ),
      deck: PokerDeck.fromSnapshot([_tile(TileColor.black, 13)]),
      board: RummiBoard.fromSnapshot([
        _tile(TileColor.black, 5),
        _tile(TileColor.red, 1),
        _tile(TileColor.yellow, 5),
        _tile(TileColor.red, 5),
        null,
        _tile(TileColor.red, 2),
        _tile(TileColor.red, 4),
        _tile(TileColor.yellow, 8),
        _tile(TileColor.black, 3),
        _tile(TileColor.blue, 6),
        _tile(TileColor.black, 11),
        _tile(TileColor.yellow, 11),
        _tile(TileColor.black, 6),
        null,
        _tile(TileColor.red, 9),
        _tile(TileColor.yellow, 12),
        null,
        null,
        _tile(TileColor.blue, 4),
        _tile(TileColor.blue, 12),
        _tile(TileColor.black, 8),
        _tile(TileColor.blue, 9),
        _tile(TileColor.red, 9),
        null,
        null,
      ]),
      hand: [_tile(TileColor.black, 12)],
      eliminated: const [],
    );

    final action =
        const FullRunPlannerV2Policy(
          enableRetryRecoveryConfirmDelay: true,
        ).chooseAction(
          session,
          jesters: const [],
          runtimeSnapshot: const RummiJesterRuntimeSnapshot(),
        );

    expect(action.type, isNot(FullRunBattleActionType.moveBoard));
  });

  test('retry recovery confirms instead of burning late hand discards', () {
    final session = RummiPokerGridSession.restored(
      runSeed: 91460,
      deckCopiesPerTile: 1,
      maxHandSize: 1,
      runRandomState: 1,
      blind: RummiBlindState(
        targetScore: 1738,
        scoreTowardBlind: 648,
        boardDiscardsRemaining: 0,
        handDiscardsRemaining: 2,
        boardMovesRemaining: 0,
        bossModifier: RummiBossModifier.confirmCountTax,
      ),
      deck: PokerDeck.fromSnapshot([
        _tile(TileColor.black, 5),
        _tile(TileColor.black, 8),
      ]),
      board: RummiBoard.fromSnapshot([
        _tile(TileColor.red, 1),
        _tile(TileColor.blue, 1),
        _tile(TileColor.black, 1),
        _tile(TileColor.yellow, 1),
        _tile(TileColor.red, 2),
        _tile(TileColor.blue, 3),
        _tile(TileColor.red, 4),
        _tile(TileColor.yellow, 8),
        _tile(TileColor.black, 3),
        _tile(TileColor.blue, 6),
        _tile(TileColor.black, 11),
        _tile(TileColor.yellow, 11),
        _tile(TileColor.black, 6),
        _tile(TileColor.red, 10),
        _tile(TileColor.red, 9),
        _tile(TileColor.yellow, 12),
        _tile(TileColor.blue, 13),
        _tile(TileColor.yellow, 13),
        _tile(TileColor.blue, 4),
        _tile(TileColor.blue, 12),
        _tile(TileColor.black, 8),
        _tile(TileColor.blue, 9),
        _tile(TileColor.red, 9),
        _tile(TileColor.black, 10),
        _tile(TileColor.yellow, 7),
      ]),
      hand: [_tile(TileColor.blue, 7)],
      eliminated: const [],
    );

    final action =
        const FullRunPlannerV2Policy(
          enableRetryRecoveryConfirmDelay: true,
          retryRecoveryAttempt: 4,
        ).chooseAction(
          session,
          jesters: const [],
          runtimeSnapshot: const RummiJesterRuntimeSnapshot(),
        );

    expect(action.type, FullRunBattleActionType.confirm);
  });

  test(
    'retry recovery tries board discard before a low full-board confirm',
    () {
      final session = RummiPokerGridSession.restored(
        runSeed: 91460,
        deckCopiesPerTile: 1,
        maxHandSize: 1,
        runRandomState: 1,
        blind: RummiBlindState(
          targetScore: 1738,
          scoreTowardBlind: 248,
          boardDiscardsRemaining: 3,
          handDiscardsRemaining: 2,
          boardMovesRemaining: 0,
          bossModifier: RummiBossModifier.confirmCountTax,
        ),
        deck: PokerDeck.fromSnapshot([_tile(TileColor.black, 5)]),
        board: RummiBoard.fromSnapshot([
          _tile(TileColor.red, 1),
          _tile(TileColor.red, 2),
          _tile(TileColor.red, 3),
          _tile(TileColor.red, 4),
          _tile(TileColor.black, 9),
          _tile(TileColor.blue, 1),
          _tile(TileColor.black, 2),
          _tile(TileColor.yellow, 3),
          _tile(TileColor.blue, 5),
          _tile(TileColor.black, 6),
          _tile(TileColor.blue, 4),
          _tile(TileColor.black, 5),
          _tile(TileColor.yellow, 6),
          _tile(TileColor.red, 8),
          _tile(TileColor.blue, 11),
          _tile(TileColor.blue, 7),
          _tile(TileColor.black, 8),
          _tile(TileColor.red, 12),
          _tile(TileColor.yellow, 11),
          _tile(TileColor.black, 12),
          _tile(TileColor.yellow, 10),
          _tile(TileColor.blue, 12),
          _tile(TileColor.black, 13),
          _tile(TileColor.yellow, 13),
          _tile(TileColor.black, 1),
        ]),
        hand: [_tile(TileColor.red, 5)],
        eliminated: const [],
      );

      final action =
          const FullRunPlannerV2Policy(
            enableRetryRecoveryConfirmDelay: true,
            retryRecoveryAttempt: 3,
          ).chooseAction(
            session,
            jesters: const [],
            runtimeSnapshot: const RummiJesterRuntimeSnapshot(),
          );

      expect(action.type, FullRunBattleActionType.discardBoard);
    },
  );

  test('retry recovery boss spends useful board discard for mystic summit', () {
    final session = RummiPokerGridSession.restored(
      runSeed: 91460,
      deckCopiesPerTile: 1,
      maxHandSize: 1,
      runRandomState: 1,
      blind: RummiBlindState(
        targetScore: 1401,
        boardDiscardsRemaining: 3,
        handDiscardsRemaining: 1,
        boardMovesRemaining: 0,
        bossModifier: RummiBossModifier.confirmCountTax,
      ),
      deck: PokerDeck.fromSnapshot([_tile(TileColor.blue, 9)]),
      board: RummiBoard.fromSnapshot([
        _tile(TileColor.red, 1),
        _tile(TileColor.red, 2),
        _tile(TileColor.red, 3),
        _tile(TileColor.red, 4),
        _tile(TileColor.black, 9),
        _tile(TileColor.blue, 1),
        _tile(TileColor.black, 2),
        _tile(TileColor.yellow, 3),
        _tile(TileColor.blue, 5),
        _tile(TileColor.black, 6),
        _tile(TileColor.blue, 4),
        _tile(TileColor.black, 5),
        _tile(TileColor.yellow, 6),
        _tile(TileColor.red, 8),
        _tile(TileColor.blue, 11),
        _tile(TileColor.blue, 7),
        _tile(TileColor.black, 8),
        _tile(TileColor.red, 12),
        _tile(TileColor.yellow, 11),
        _tile(TileColor.black, 12),
        _tile(TileColor.yellow, 10),
        _tile(TileColor.blue, 12),
        _tile(TileColor.black, 13),
        _tile(TileColor.yellow, 13),
        null,
      ]),
      hand: [_tile(TileColor.red, 5)],
      eliminated: const [],
    );

    final action =
        const FullRunPlannerV2Policy(
          enableRetryRecoveryConfirmDelay: true,
          retryRecoveryAttempt: 2,
        ).chooseAction(
          session,
          jesters: [_jester('mystic_summit')],
          runtimeSnapshot: const RummiJesterRuntimeSnapshot(),
        );

    expect(action.type, FullRunBattleActionType.discardBoard);
    expect(action.row, isNotNull);
    expect(action.col, isNotNull);
    expect(session.board.cellAt(action.row!, action.col!), isNotNull);
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

    final action = const FullRunPlannerV2Policy().chooseAction(
      session,
      jesters: [_jester('mystic_summit')],
      runtimeSnapshot: const RummiJesterRuntimeSnapshot(),
    );

    expect(action.type, isNot(FullRunBattleActionType.discardHand));
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

    final action = const FullRunPlannerV2Policy().chooseAction(
      session,
      jesters: [_jester('mystic_summit')],
      runtimeSnapshot: const RummiJesterRuntimeSnapshot(),
    );

    expect(action.type, isNot(FullRunBattleActionType.discardHand));
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

    final action = const FullRunPlannerV2Policy().chooseAction(
      session,
      jesters: const [],
      runtimeSnapshot: const RummiJesterRuntimeSnapshot(),
    );

    expect(action.type, isNot(FullRunBattleActionType.moveBoard));
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

    final action = const FullRunPlannerV2Policy().chooseAction(
      session,
      jesters: const [],
      runtimeSnapshot: const RummiJesterRuntimeSnapshot(),
    );

    expect(action.type, FullRunBattleActionType.moveBoard);
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

    final action = const FullRunPlannerV2Policy().chooseAction(
      session,
      jesters: [_jester('mystic_summit')],
      runtimeSnapshot: const RummiJesterRuntimeSnapshot(),
    );

    expect(action.type, isNot(FullRunBattleActionType.discardBoard));
  });

  test(
    'early full board confirms existing line instead of discard move combo',
    () {
      final session = RummiPokerGridSession.restored(
        runSeed: 91460,
        deckCopiesPerTile: 1,
        maxHandSize: 1,
        runRandomState: 1,
        blind: RummiBlindState(
          targetScore: 2450,
          boardDiscardsRemaining: 4,
          handDiscardsRemaining: 2,
          boardMovesRemaining: 3,
          boardMovesMax: 3,
        ),
        deck: PokerDeck.fromSnapshot([_tile(TileColor.yellow, 9)]),
        board: RummiBoard.fromSnapshot([
          _tile(TileColor.red, 1),
          _tile(TileColor.red, 2),
          _tile(TileColor.red, 3),
          _tile(TileColor.red, 4),
          _tile(TileColor.red, 5),
          _tile(TileColor.blue, 1),
          _tile(TileColor.yellow, 3),
          _tile(TileColor.black, 5),
          _tile(TileColor.red, 7),
          _tile(TileColor.blue, 9),
          _tile(TileColor.black, 2),
          _tile(TileColor.yellow, 4),
          _tile(TileColor.blue, 6),
          _tile(TileColor.red, 8),
          _tile(TileColor.black, 10),
          _tile(TileColor.yellow, 1),
          _tile(TileColor.blue, 3),
          _tile(TileColor.red, 6),
          _tile(TileColor.black, 8),
          _tile(TileColor.yellow, 10),
          _tile(TileColor.black, 1),
          _tile(TileColor.red, 9),
          _tile(TileColor.yellow, 11),
          _tile(TileColor.blue, 13),
          _tile(TileColor.black, 7),
        ]),
        hand: [_tile(TileColor.blue, 11)],
        eliminated: const [],
      );

      final action = const FullRunPlannerV2Policy().chooseAction(
        session,
        jesters: const [],
        runtimeSnapshot: const RummiJesterRuntimeSnapshot(),
      );

      expect(action.type, FullRunBattleActionType.confirm);
    },
  );

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

      final action = const FullRunPlannerV2Policy().bestPlacementForTest(
        session,
        jesters: const [],
        runtimeSnapshot: const RummiJesterRuntimeSnapshot(),
      );

      expect(action?.type, FullRunBattleActionType.place);
      expect(action?.row, 0);
      expect(action?.col, 4);
    },
  );

  test('retry placement lookahead uses known deck order after failures', () {
    final session = RummiPokerGridSession.restored(
      runSeed: 91460,
      deckCopiesPerTile: 1,
      maxHandSize: 1,
      runRandomState: 1,
      blind: RummiBlindState(
        targetScore: 1738,
        boardDiscardsRemaining: 3,
        handDiscardsRemaining: 2,
        boardMovesRemaining: 3,
        bossModifier: RummiBossModifier.confirmCountTax,
      ),
      deck: PokerDeck.fromSnapshot([
        _tile(TileColor.black, 4),
        _tile(TileColor.red, 9),
        _tile(TileColor.blue, 7),
      ]),
      board: RummiBoard.fromSnapshot([
        _tile(TileColor.red, 7),
        _tile(TileColor.black, 7),
        _tile(TileColor.yellow, 7),
        null,
        null,
        _tile(TileColor.red, 1),
        _tile(TileColor.blue, 2),
        _tile(TileColor.black, 3),
        null,
        null,
        _tile(TileColor.yellow, 10),
        _tile(TileColor.black, 11),
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
      hand: [_tile(TileColor.blue, 1)],
      eliminated: const [],
    );

    final action =
        const FullRunPlannerV2Policy(
          enableRetryRecoveryConfirmDelay: true,
          retryRecoveryAttempt: 2,
        ).bestPlacementForTest(
          session,
          jesters: const [],
          runtimeSnapshot: const RummiJesterRuntimeSnapshot(),
        );

    expect(action?.type, FullRunBattleActionType.place);
    expect(action?.row, 0);
    expect(action?.col, 4);
  });

  test('late retry delays a confirm that would leave a small shortage', () {
    final session = RummiPokerGridSession.restored(
      runSeed: 91460,
      deckCopiesPerTile: 1,
      maxHandSize: 1,
      runRandomState: 1,
      blind: RummiBlindState(
        targetScore: 1739,
        scoreTowardBlind: 1079,
        boardDiscardsRemaining: 0,
        handDiscardsRemaining: 1,
        boardMovesRemaining: 0,
        bossModifier: RummiBossModifier.allScoreDampener,
      ),
      deck: PokerDeck.fromSnapshot([
        _tile(TileColor.blue, 10),
        _tile(TileColor.red, 4),
        _tile(TileColor.black, 8),
        _tile(TileColor.blue, 13),
      ]),
      board: RummiBoard(),
      hand: [_tile(TileColor.yellow, 8)],
      eliminated: const [],
    );

    final policy = const FullRunPlannerV2Policy(
      enableRetryRecoveryConfirmDelay: true,
      retryRecoveryAttempt: 2,
    );

    expect(
      policy.delaysLateRetryConfirmForTest(session, score: 463, lineCount: 3),
      isTrue,
    );
    expect(
      policy.delaysLateRetryConfirmForTest(session, score: 660, lineCount: 3),
      isFalse,
    );
  });

  test('boss retry rejects weak four-line confirms', () {
    final policy = const FullRunPlannerV2Policy(
      enableRetryRecoveryConfirmDelay: true,
      retryRecoveryAttempt: 2,
    );

    expect(
      policy.isBossRetryRecoveryBundleForTest(score: 353, lineCount: 4),
      isFalse,
    );
    expect(
      policy.isBossRetryRecoveryBundleForTest(score: 470, lineCount: 4),
      isTrue,
    );
    expect(
      policy.isBossRetryRecoveryBundleForTest(score: 365, lineCount: 5),
      isTrue,
    );
  });

  test('later retries avoid repeating failed placement routes', () {
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

    final firstAction = const FullRunPlannerV2Policy().bestPlacementForTest(
      session,
      jesters: const [],
      runtimeSnapshot: const RummiJesterRuntimeSnapshot(),
    );
    final secondRetryAction =
        FullRunPlannerV2Policy(
          enableRetryRecoveryConfirmDelay: true,
          retryRecoveryAttempt: 2,
          avoidedActionRouteKeys: {fullRunBattleActionRouteKey(firstAction!)},
        ).bestPlacementForTest(
          session,
          jesters: const [],
          runtimeSnapshot: const RummiJesterRuntimeSnapshot(),
        );
    final thirdRetryAction =
        FullRunPlannerV2Policy(
          enableRetryRecoveryConfirmDelay: true,
          retryRecoveryAttempt: 3,
          avoidedActionRouteKeys: {
            fullRunBattleActionRouteKey(firstAction),
            fullRunBattleActionRouteKey(secondRetryAction!),
          },
        ).bestPlacementForTest(
          session,
          jesters: const [],
          runtimeSnapshot: const RummiJesterRuntimeSnapshot(),
        );

    expect(secondRetryAction.type, FullRunBattleActionType.place);
    expect(
      fullRunBattleActionRouteKey(secondRetryAction),
      isNot(fullRunBattleActionRouteKey(firstAction)),
    );
    expect(thirdRetryAction?.type, FullRunBattleActionType.place);
    expect(
      fullRunBattleActionRouteKey(thirdRetryAction!),
      isNot(fullRunBattleActionRouteKey(firstAction)),
    );
    expect(
      fullRunBattleActionRouteKey(thirdRetryAction),
      isNot(fullRunBattleActionRouteKey(secondRetryAction)),
    );
  });

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

    final action = const FullRunPlannerV2Policy().chooseAction(
      session,
      jesters: const [],
      runtimeSnapshot: const RummiJesterRuntimeSnapshot(),
    );

    expect(action.type, FullRunBattleActionType.draw);
  });

  test('late low deck retry uses board move before spending the hand tile', () {
    final session = RummiPokerGridSession.restored(
      runSeed: 91460,
      deckCopiesPerTile: 1,
      maxHandSize: 1,
      runRandomState: 1,
      blind: RummiBlindState(
        targetScore: 1738,
        scoreTowardBlind: 1200,
        boardDiscardsRemaining: 3,
        handDiscardsRemaining: 2,
        boardMovesRemaining: 3,
      ),
      deck: PokerDeck.fromSnapshot([
        _tile(TileColor.red, 2),
        _tile(TileColor.black, 8),
        _tile(TileColor.blue, 5),
        _tile(TileColor.black, 7),
        _tile(TileColor.blue, 7),
        _tile(TileColor.blue, 10),
      ]),
      board: RummiBoard.fromSnapshot([
        _tile(TileColor.red, 10),
        _tile(TileColor.yellow, 10),
        _tile(TileColor.black, 10),
        _tile(TileColor.red, 1),
        null,
        _tile(TileColor.black, 2),
        null,
        null,
        null,
        _tile(TileColor.blue, 6),
        _tile(TileColor.black, 3),
        null,
        null,
        null,
        _tile(TileColor.blue, 7),
        _tile(TileColor.black, 4),
        null,
        null,
        null,
        null,
        _tile(TileColor.blue, 8),
        null,
        null,
        null,
        _tile(TileColor.blue, 9),
      ]),
      hand: [_tile(TileColor.blue, 10)],
      eliminated: const [],
    );

    final action =
        const FullRunPlannerV2Policy(
          enableRetryRecoveryConfirmDelay: true,
          retryRecoveryAttempt: 2,
        ).chooseAction(
          session,
          jesters: const [],
          runtimeSnapshot: const RummiJesterRuntimeSnapshot(),
        );

    expect(action.type, FullRunBattleActionType.moveBoard);
  });

  test('late retry starts using board move before the final six cards', () {
    final session = RummiPokerGridSession.restored(
      runSeed: 91460,
      deckCopiesPerTile: 1,
      maxHandSize: 1,
      runRandomState: 1,
      blind: RummiBlindState(
        targetScore: 1738,
        scoreTowardBlind: 1200,
        boardDiscardsRemaining: 3,
        handDiscardsRemaining: 2,
        boardMovesRemaining: 3,
      ),
      deck: PokerDeck.fromSnapshot([
        _tile(TileColor.red, 2),
        _tile(TileColor.black, 8),
        _tile(TileColor.blue, 5),
        _tile(TileColor.black, 7),
        _tile(TileColor.blue, 7),
        _tile(TileColor.blue, 10),
        _tile(TileColor.blue, 1),
        _tile(TileColor.red, 12),
        _tile(TileColor.blue, 8),
        _tile(TileColor.yellow, 10),
        _tile(TileColor.yellow, 5),
        _tile(TileColor.blue, 3),
      ]),
      board: RummiBoard.fromSnapshot([
        _tile(TileColor.red, 10),
        _tile(TileColor.yellow, 10),
        _tile(TileColor.black, 10),
        _tile(TileColor.red, 1),
        null,
        _tile(TileColor.black, 2),
        null,
        null,
        null,
        _tile(TileColor.blue, 6),
        _tile(TileColor.black, 3),
        null,
        null,
        null,
        _tile(TileColor.blue, 7),
        _tile(TileColor.black, 4),
        null,
        null,
        null,
        null,
        _tile(TileColor.blue, 8),
        null,
        null,
        null,
        _tile(TileColor.blue, 9),
      ]),
      hand: [_tile(TileColor.blue, 10)],
      eliminated: const [],
    );

    final action =
        const FullRunPlannerV2Policy(
          enableRetryRecoveryConfirmDelay: true,
          retryRecoveryAttempt: 2,
        ).chooseAction(
          session,
          jesters: const [],
          runtimeSnapshot: const RummiJesterRuntimeSnapshot(),
        );

    expect(action.type, FullRunBattleActionType.moveBoard);
  });
}

Tile _tile(TileColor color, int number) => Tile(color: color, number: number);

RummiJesterCard _jester(
  String id, {
  String effectType = '',
  Object? conditionValue,
  int? value,
  double? xValue,
}) {
  return RummiJesterCard(
    id: id,
    displayName: id,
    rarity: RummiJesterRarity.common,
    baseCost: 1,
    effectText: '',
    effectType: effectType,
    trigger: '',
    conditionType: '',
    conditionValue: conditionValue,
    value: value,
    xValue: xValue,
    mappedTileColors: const [],
    mappedTileNumbers: const [],
  );
}
