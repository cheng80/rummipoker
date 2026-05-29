import 'package:flutter_test/flutter_test.dart';
import 'package:rummipoker/logic/rummi_poker_grid/hand_rank.dart';
import 'package:rummipoker/logic/rummi_poker_grid/jester_meta.dart';
import 'package:rummipoker/logic/rummi_poker_grid/models/tile.dart';
import 'package:rummipoker/logic/rummi_poker_grid/rummi_battle_facade.dart';
import 'package:rummipoker/logic/rummi_poker_grid/rummi_blind_state.dart';
import 'package:rummipoker/logic/rummi_poker_grid/rummi_poker_grid_session.dart';

void main() {
  test(
    'battle facade exposes queued confirm item when preview condition misses',
    () {
      final session = _twoPairSession()
        ..addConfirmModifier(
          const RummiConfirmModifier(
            itemId: 'straight_oil',
            timing: 'next_confirm_if_rank_at_least',
            op: 'chips_bonus',
            amount: 40,
            rank: RummiHandRank.straight,
          ),
        );

      final facade = RummiBattleRuntimeFacade.fromRuntime(
        session: session,
        runProgress: RummiRunProgress(),
      );

      expect(facade.pendingConfirmItemCount, 1);
      expect(facade.scoringPreview, isNotNull);
      expect(facade.scoringPreview!.expectedItemEffectCount, 0);
    },
  );

  test('battle facade exposes queued confirm item when preview applies', () {
    final session = _twoPairSession()
      ..addConfirmModifier(
        const RummiConfirmModifier(
          itemId: 'pair_splint',
          timing: 'next_confirm_if_rank',
          op: 'chips_bonus',
          amount: 35,
          rank: RummiHandRank.twoPair,
        ),
      );

    final facade = RummiBattleRuntimeFacade.fromRuntime(
      session: session,
      runProgress: RummiRunProgress(),
    );

    expect(facade.pendingConfirmItemCount, 1);
    expect(facade.scoringPreview, isNotNull);
    expect(facade.scoringPreview!.expectedItemEffectCount, 1);
  });

  test('battle facade exposes queued board move slide bonus', () {
    final session = _twoPairSession()..queueNextBoardMoveSlideBonus();

    final facade = RummiBattleRuntimeFacade.fromRuntime(
      session: session,
      runProgress: RummiRunProgress(),
    );

    expect(facade.pendingBoardMoveSlideBonus, isTrue);
  });

  test('battle facade separates tile modifier preview effects from items', () {
    final session = RummiPokerGridSession(
      runSeed: 1,
      blind: RummiBlindState(targetScore: 999),
    );
    session.board
      ..setCell(
        0,
        0,
        const Tile(
          color: TileColor.red,
          number: 2,
          enhancement: TileEnhancement.chipInlaid,
          seal: TileSeal.blueSeal,
        ),
      )
      ..setCell(0, 1, const Tile(color: TileColor.blue, number: 2))
      ..setCell(0, 2, const Tile(color: TileColor.red, number: 3))
      ..setCell(0, 3, const Tile(color: TileColor.blue, number: 3))
      ..setCell(0, 4, const Tile(color: TileColor.black, number: 5));

    final facade = RummiBattleRuntimeFacade.fromRuntime(
      session: session,
      runProgress: RummiRunProgress(),
    );

    expect(facade.scoringPreview, isNotNull);
    expect(facade.scoringPreview!.expectedTileModifierEffectCount, 2);
    expect(facade.scoringPreview!.expectedItemEffectCount, 0);
  });
}

RummiPokerGridSession _twoPairSession() {
  final session = RummiPokerGridSession(
    runSeed: 1,
    blind: RummiBlindState(targetScore: 999),
  );
  session.board
    ..setCell(0, 0, const Tile(color: TileColor.red, number: 2))
    ..setCell(0, 1, const Tile(color: TileColor.blue, number: 2))
    ..setCell(0, 2, const Tile(color: TileColor.red, number: 3))
    ..setCell(0, 3, const Tile(color: TileColor.blue, number: 3))
    ..setCell(0, 4, const Tile(color: TileColor.black, number: 5));
  return session;
}
