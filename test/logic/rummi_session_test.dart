import 'package:rummipoker/logic/rummi_poker_grid/models/board.dart';
import 'dart:math';

import 'package:rummipoker/logic/rummi_poker_grid/jester_meta.dart';
import 'package:rummipoker/logic/rummi_poker_grid/models/poker_deck.dart';
import 'package:rummipoker/logic/rummi_poker_grid/models/tile.dart';
import 'package:rummipoker/logic/rummi_poker_grid/rummi_blind_state.dart';
import 'package:rummipoker/logic/rummi_poker_grid/rummi_poker_grid_session.dart';
import 'package:flutter_test/flutter_test.dart';

Tile t(TileColor c, int n) => Tile(color: c, number: n);

RummiJesterCard jester({
  required String id,
  required String effectType,
  required String conditionType,
  Object? conditionValue,
  int? value,
  double? xValue,
  List<TileColor> mappedTileColors = const [],
  List<int> mappedTileNumbers = const [],
}) {
  return RummiJesterCard(
    id: id,
    displayName: id,
    rarity: RummiJesterRarity.common,
    baseCost: 3,
    effectText: id,
    effectType: effectType,
    trigger: 'passive',
    conditionType: conditionType,
    conditionValue: conditionValue,
    value: value,
    xValue: xValue,
    mappedTileColors: mappedTileColors,
    mappedTileNumbers: mappedTileNumbers,
  );
}

void main() {
  test('표준 덱은 기본 52장', () {
    expect(buildStandardPokerDeck().length, 52);
  });

  test('세션 보존: 덱+손+보드+제거 = 52', () {
    final session = RummiPokerGridSession(
      blind: RummiBlindState(targetScore: 9999, discardsRemaining: 4),
    );
    expect(session.conservationTotal, 52);

    for (var i = 0; i < 10; i++) {
      session.drawToHand();
    }
    expect(session.hand.length, RummiPokerGridSession.kMaxHandSize);
    expect(session.conservationTotal, 52);

    expect(session.tryPlaceFromHand(session.hand.first, 0, 0), true);
    expect(session.conservationTotal, 52);
  });

  test('보드 버림: D 소모·칸 비움·손패 여유 시 덱에서 1장', () {
    final session = RummiPokerGridSession(
      blind: RummiBlindState(targetScore: 9999, discardsRemaining: 4),
    );
    expect(session.drawToHand(), isNotNull);
    final placed = session.hand.first;
    expect(session.tryPlaceFromHand(placed, 1, 2), true);
    expect(session.board.cellAt(1, 2), placed);
    final beforeD = session.blind.discardsRemaining;
    final beforeHand = session.hand.length;
    final r = session.tryDiscardFromBoard(1, 2);
    expect(r.fail, isNull);
    expect(session.board.cellAt(1, 2), isNull);
    expect(session.blind.discardsRemaining, beforeD - 1);
    expect(beforeHand, 0);
    expect(session.hand.length, 1);
    expect(session.conservationTotal, 52);
  });

  test('손패는 최대 1장까지만 드로우', () {
    final session = RummiPokerGridSession(
      blind: RummiBlindState(targetScore: 9999, discardsRemaining: 4),
    );
    expect(session.drawToHand(), isNotNull);
    expect(session.hand.length, 1);
    expect(session.drawToHand(), isNull);
    expect(session.hand.length, 1);
  });

  test('덱이 비면 drawPileExhausted', () {
    final emptyDeck = PokerDeck.shuffled(Random(1), <Tile>[]);
    final session = RummiPokerGridSession(
      blind: RummiBlindState(targetScore: 9999, discardsRemaining: 4),
      deck: emptyDeck,
    );
    expect(session.drawToHand(), isNull);
    final sig = session.evaluateExpirySignals();
    expect(sig.contains(RummiExpirySignal.drawPileExhausted), true);
  });

  test('다음 스테이지 진입 시 덱이 시드 기반으로 리셋·셔플된다', () {
    final a = RummiPokerGridSession(runSeed: 4242);
    final b = RummiPokerGridSession(runSeed: 4242);

    expect(a.drawToHand(), isNotNull);
    expect(a.hand, isNotEmpty);
    expect(a.tryPlaceFromHand(a.hand.first, 0, 0), true);
    expect(a.board.cellAt(0, 0), isNotNull);

    final stageSeed = RummiPokerGridSession.deriveStageShuffleSeed(4242, 2);
    a.prepareNextBlind(
      targetScore: 480,
      discardsRemaining: 4,
      shuffleSeed: stageSeed,
    );
    b.prepareNextBlind(
      targetScore: 480,
      discardsRemaining: 4,
      shuffleSeed: stageSeed,
    );

    expect(a.hand, isEmpty);
    expect(a.board.cellAt(0, 0), isNull);
    expect(a.eliminated, isEmpty);
    expect(a.deck.remaining, 52);
    expect(a.conservationTotal, 52);
    expect(a.drawToHand(), isNotNull);
    expect(b.drawToHand(), isNotNull);
    expect(a.hand.first, b.hand.first);
  });

  test('가득 찬 행 일괄 확정 시 스트레이트 점수 가산', () {
    final board = RummiBoard();
    for (var i = 0; i < kBoardSize; i++) {
      board.setCell(2, i, t(i.isEven ? TileColor.red : TileColor.blue, i + 1));
    }
    final deck = PokerDeck.remainingAfterPlaced(board: board);
    final session = RummiPokerGridSession(
      blind: RummiBlindState(targetScore: 40, discardsRemaining: 4),
      deck: deck,
      board: board,
    );
    expect(session.conservationTotal, 52);
    final out = session.confirmAllFullLines();
    expect(out.result.ok, true);
    expect(out.result.scoreAdded, 70);
    expect(session.blind.scoreTowardBlind, 70);
    expect(out.cleared, isNotNull);
    for (var i = 0; i < kBoardSize; i++) {
      expect(session.board.cellAt(2, i), isNull);
    }
  });

  test('투페어 확정 시 매칭된 4장만 제거되고 키커는 남는다', () {
    final board = RummiBoard();
    board.setCell(1, 0, t(TileColor.red, 4));
    board.setCell(1, 1, t(TileColor.blue, 4));
    board.setCell(1, 2, t(TileColor.yellow, 9));
    board.setCell(1, 3, t(TileColor.black, 9));
    board.setCell(1, 4, t(TileColor.red, 12));
    final keeper = board.cellAt(1, 4);
    final deck = PokerDeck.remainingAfterPlaced(board: board);
    final session = RummiPokerGridSession(
      blind: RummiBlindState(targetScore: 999, discardsRemaining: 4),
      deck: deck,
      board: board,
    );

    final out = session.confirmAllFullLines();

    expect(out.result.ok, true);
    expect(out.result.scoreAdded, 25);
    expect(session.board.cellAt(1, 0), isNull);
    expect(session.board.cellAt(1, 1), isNull);
    expect(session.board.cellAt(1, 2), isNull);
    expect(session.board.cellAt(1, 3), isNull);
    expect(session.board.cellAt(1, 4), same(keeper));
  });

  test('포카드 확정 시 4장만 제거되고 남는 1장은 유지된다', () {
    final board = RummiBoard();
    board.setCell(3, 0, t(TileColor.red, 8));
    board.setCell(3, 1, t(TileColor.blue, 8));
    board.setCell(3, 2, t(TileColor.yellow, 8));
    board.setCell(3, 3, t(TileColor.black, 8));
    board.setCell(3, 4, t(TileColor.red, 2));
    final kicker = board.cellAt(3, 4);
    final deck = PokerDeck.remainingAfterPlaced(board: board);
    final session = RummiPokerGridSession(
      blind: RummiBlindState(targetScore: 999, discardsRemaining: 4),
      deck: deck,
      board: board,
    );

    final out = session.confirmAllFullLines();

    expect(out.result.ok, true);
    expect(out.result.scoreAdded, 100);
    for (var c = 0; c < 4; c++) {
      expect(session.board.cellAt(3, c), isNull);
    }
    expect(session.board.cellAt(3, 4), same(kicker));
  });

  test('죽은 줄만 있으면 족보 확정 없음 — 죽은 줄은 버림으로만 칸 비움', () {
    final board = RummiBoard();
    // 원페어(죽은 줄) — 포커 덱에서 가능한 5장.
    board.setCell(0, 0, t(TileColor.red, 7));
    board.setCell(0, 1, t(TileColor.blue, 7));
    board.setCell(0, 2, t(TileColor.yellow, 3));
    board.setCell(0, 3, t(TileColor.black, 9));
    board.setCell(0, 4, t(TileColor.red, 11));
    final deck = PokerDeck.remainingAfterPlaced(board: board);
    final session = RummiPokerGridSession(
      blind: RummiBlindState(targetScore: 999, discardsRemaining: 4),
      deck: deck,
      board: board,
    );
    expect(session.canConfirmAllFullLines, false);
    final out = session.confirmAllFullLines();
    expect(out.result.ok, false);
    expect(out.result.scoreAdded, 0);
    expect(session.board.cellAt(0, 0), isNotNull);
  });

  test('기본 Jester의 mult_bonus가 줄 확정 점수에 반영된다', () {
    final board = RummiBoard();
    board.setCell(1, 0, t(TileColor.red, 4));
    board.setCell(1, 1, t(TileColor.blue, 4));
    board.setCell(1, 2, t(TileColor.yellow, 9));
    board.setCell(1, 3, t(TileColor.black, 9));
    board.setCell(1, 4, t(TileColor.red, 12));
    final session = RummiPokerGridSession(
      blind: RummiBlindState(targetScore: 999, discardsRemaining: 4),
      deck: PokerDeck.remainingAfterPlaced(board: board),
      board: board,
    );

    final out = session.confirmAllFullLines(
      jesters: [
        jester(
          id: 'jester',
          effectType: 'mult_bonus',
          conditionType: 'none',
          value: 4,
        ),
      ],
    );

    expect(out.result.ok, true);
    expect(out.result.baseScore, 25);
    expect(out.result.scoreAdded, 30);
    expect(out.result.jesterBonus, 5);
  });

  test('Blue Jester류 cards_remaining_in_deck chips_bonus가 반영된다', () {
    final board = RummiBoard();
    for (var i = 0; i < kBoardSize; i++) {
      board.setCell(2, i, t(i.isEven ? TileColor.red : TileColor.blue, i + 1));
    }
    final deck = PokerDeck.remainingAfterPlaced(board: board);
    final session = RummiPokerGridSession(
      blind: RummiBlindState(targetScore: 999, discardsRemaining: 4),
      deck: deck,
      board: board,
    );

    final out = session.confirmAllFullLines(
      jesters: [
        jester(
          id: 'blue_jester',
          effectType: 'chips_bonus',
          conditionType: 'other',
          conditionValue: 'cards_remaining_in_deck',
          value: 1,
        ),
      ],
    );

    expect(out.result.baseScore, 70);
    expect(out.result.scoreAdded, 117);
    expect(out.result.jesterBonus, 47);
  });

  test('Jester Stencil류 empty_jester_slots xmult_bonus가 반영된다', () {
    final board = RummiBoard();
    for (var i = 0; i < kBoardSize; i++) {
      board.setCell(
        3,
        i,
        t(
          i.isEven ? TileColor.red : TileColor.blue,
          const [10, 11, 12, 13, 1][i],
        ),
      );
    }
    final session = RummiPokerGridSession(
      blind: RummiBlindState(targetScore: 999, discardsRemaining: 4),
      deck: PokerDeck.remainingAfterPlaced(board: board),
      board: board,
    );

    final out = session.confirmAllFullLines(
      jesters: [
        jester(
          id: 'jester_stencil',
          effectType: 'xmult_bonus',
          conditionType: 'other',
          conditionValue: 'empty_jester_slots',
          xValue: 1.1,
        ),
      ],
    );

    expect(out.result.baseScore, 70);
    expect(out.result.scoreAdded, 102);
    expect(out.result.jesterBonus, 32);
  });

  test('Scholar는 scored ace에 chips와 mult를 함께 준다', () {
    final board = RummiBoard();
    board.setCell(0, 0, t(TileColor.red, 1));
    board.setCell(0, 1, t(TileColor.blue, 1));
    board.setCell(0, 2, t(TileColor.yellow, 8));
    board.setCell(0, 3, t(TileColor.black, 8));
    board.setCell(0, 4, t(TileColor.red, 12));
    final session = RummiPokerGridSession(
      blind: RummiBlindState(targetScore: 999, discardsRemaining: 4),
      deck: PokerDeck.remainingAfterPlaced(board: board),
      board: board,
    );

    final out = session.confirmAllFullLines(
      jesters: [
        jester(
          id: 'scholar',
          effectType: 'chips_bonus',
          conditionType: 'rank_scored',
          conditionValue: 'ace',
          value: 20,
        ),
      ],
    );

    expect(out.result.baseScore, 25);
    expect(out.result.scoreAdded, 91);
    expect(out.result.jesterBonus, 66);
  });
}
