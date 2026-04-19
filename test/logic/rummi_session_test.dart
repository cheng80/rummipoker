import 'package:rummipoker/logic/rummi_poker_grid/models/board.dart';
import 'dart:math';

import 'package:rummipoker/logic/rummi_poker_grid/jester_meta.dart';
import 'package:rummipoker/logic/rummi_poker_grid/hand_rank.dart';
import 'package:rummipoker/logic/rummi_poker_grid/line_ref.dart';
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
  String trigger = 'passive',
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
    trigger: trigger,
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
    expect(session.hand.length, session.maxHandSize);
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

  test('손패 버림: 별도 손패 버림 횟수를 소모하고 즉시 1장 보충한다', () {
    final session = RummiPokerGridSession(
      blind: RummiBlindState(
        targetScore: 9999,
        boardDiscardsRemaining: 4,
        handDiscardsRemaining: 2,
      ),
    );
    final first = session.drawToHand();
    expect(first, isNotNull);
    final beforeHandDiscard = session.blind.handDiscardsRemaining;
    final beforeBoardDiscard = session.blind.boardDiscardsRemaining;

    final result = session.tryDiscardFromHand(first!);

    expect(result.fail, isNull);
    expect(session.blind.handDiscardsRemaining, beforeHandDiscard - 1);
    expect(session.blind.boardDiscardsRemaining, beforeBoardDiscard);
    expect(session.hand.length, 1);
    expect(session.hand.first, isNot(first));
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

  test('덱이 비고 손패/확정 줄도 없을 때만 drawPileExhausted', () {
    final emptyDeck = PokerDeck.shuffled(Random(1), <Tile>[]);
    final session = RummiPokerGridSession(
      blind: RummiBlindState(targetScore: 9999, discardsRemaining: 4),
      deck: emptyDeck,
    );
    expect(session.drawToHand(), isNull);
    final sig = session.evaluateExpirySignals();
    expect(sig.contains(RummiExpirySignal.drawPileExhausted), true);
  });

  test('덱이 비어도 손패가 남아 있으면 drawPileExhausted가 아니다', () {
    final lastCard = t(TileColor.red, 7);
    final session = RummiPokerGridSession(
      blind: RummiBlindState(targetScore: 9999, discardsRemaining: 4),
      deck: PokerDeck.fromSnapshot([lastCard]),
    );

    expect(session.drawToHand(), lastCard);
    expect(session.deck.isEmpty, true);
    expect(session.hand, [lastCard]);
    expect(
      session.evaluateExpirySignals().contains(
        RummiExpirySignal.drawPileExhausted,
      ),
      false,
    );
  });

  test('덱이 비고 원페어만 있으면 drawPileExhausted다', () {
    final board = RummiBoard();
    board.setCell(4, 2, t(TileColor.blue, 5));
    board.setCell(4, 3, t(TileColor.black, 5));
    board.setCell(4, 4, t(TileColor.red, 12));
    final session = RummiPokerGridSession(
      blind: RummiBlindState(targetScore: 9999, discardsRemaining: 4),
      deck: PokerDeck.shuffled(Random(1), <Tile>[]),
      board: board,
    );

    expect(session.hand, isEmpty);
    expect(session.canConfirmAllFullLines, false);
    expect(
      session.evaluateExpirySignals().contains(
        RummiExpirySignal.drawPileExhausted,
      ),
      true,
    );
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
      boardDiscardsRemaining: 4,
      handDiscardsRemaining: 2,
      shuffleSeed: stageSeed,
    );
    b.prepareNextBlind(
      targetScore: 480,
      boardDiscardsRemaining: 4,
      handDiscardsRemaining: 2,
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

  test('확정 점수 적용을 지연할 수 있고, 이후 줄별로 누적할 수 있다', () {
    final board = RummiBoard();
    for (var i = 0; i < kBoardSize; i++) {
      board.setCell(2, i, t(i.isEven ? TileColor.red : TileColor.blue, i + 1));
    }
    final session = RummiPokerGridSession(
      blind: RummiBlindState(targetScore: 40, discardsRemaining: 4),
      deck: PokerDeck.remainingAfterPlaced(board: board),
      board: board,
    );

    final out = session.confirmAllFullLines(applyScoreToBlind: false);

    expect(out.result.ok, true);
    expect(out.result.scoreAdded, 70);
    expect(session.blind.scoreTowardBlind, 0);

    session.addScoreToBlind(out.result.lineBreakdowns.single.finalScore);
    expect(session.blind.scoreTowardBlind, 70);
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

  test('하이카드만 있으면 족보 확정 없음', () {
    final board = RummiBoard();
    board.setCell(0, 0, t(TileColor.red, 7));
    board.setCell(0, 1, t(TileColor.blue, 2));
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

  test('부분 줄 원페어는 더 이상 즉시 확정되지 않는다', () {
    final board = RummiBoard();
    board.setCell(2, 0, t(TileColor.red, 7));
    board.setCell(2, 3, t(TileColor.blue, 7));
    final session = RummiPokerGridSession(
      blind: RummiBlindState(targetScore: 999, discardsRemaining: 4),
      deck: PokerDeck.remainingAfterPlaced(board: board),
      board: board,
    );

    expect(session.canConfirmAllFullLines, false);

    final out = session.confirmAllFullLines();

    expect(out.result.ok, false);
    expect(out.result.baseScore, 0);
    expect(out.result.scoreAdded, 0);
    expect(session.board.cellAt(2, 0), isNotNull);
    expect(session.board.cellAt(2, 3), isNotNull);
  });

  test('3장 줄 원페어도 더 이상 즉시 확정되지 않는다', () {
    final board = RummiBoard();
    board.setCell(4, 2, t(TileColor.blue, 5));
    board.setCell(4, 3, t(TileColor.black, 5));
    board.setCell(4, 4, t(TileColor.red, 12));
    final kicker = board.cellAt(4, 4);
    final session = RummiPokerGridSession(
      blind: RummiBlindState(targetScore: 999, discardsRemaining: 4),
      deck: PokerDeck.remainingAfterPlaced(board: board),
      board: board,
    );

    final out = session.confirmAllFullLines();

    expect(out.result.ok, false);
    expect(out.result.baseScore, 0);
    expect(out.result.scoreAdded, 0);
    expect(session.board.cellAt(4, 2), isNotNull);
    expect(session.board.cellAt(4, 3), isNotNull);
    expect(session.board.cellAt(4, 4), same(kicker));
  });

  test('4장 줄 트리플도 즉시 확정되고 키커는 남는다', () {
    final board = RummiBoard();
    board.setCell(2, 0, t(TileColor.red, 3));
    board.setCell(2, 1, t(TileColor.blue, 3));
    board.setCell(2, 2, t(TileColor.yellow, 3));
    board.setCell(2, 3, t(TileColor.black, 10));
    final kicker = board.cellAt(2, 3);
    final session = RummiPokerGridSession(
      blind: RummiBlindState(targetScore: 999, discardsRemaining: 4),
      deck: PokerDeck.remainingAfterPlaced(board: board),
      board: board,
    );

    final out = session.confirmAllFullLines();

    expect(out.result.ok, true);
    expect(out.result.baseScore, 40);
    expect(out.result.scoreAdded, 40);
    expect(session.board.cellAt(2, 0), isNull);
    expect(session.board.cellAt(2, 1), isNull);
    expect(session.board.cellAt(2, 2), isNull);
    expect(session.board.cellAt(2, 3), same(kicker));
  });

  test('플러시 확정 시 contributor 5장 전체가 제거된다', () {
    final board = RummiBoard();
    board.setCell(0, 0, t(TileColor.blue, 1));
    board.setCell(0, 1, t(TileColor.blue, 3));
    board.setCell(0, 2, t(TileColor.blue, 5));
    board.setCell(0, 3, t(TileColor.blue, 7));
    board.setCell(0, 4, t(TileColor.blue, 9));
    final session = RummiPokerGridSession(
      blind: RummiBlindState(targetScore: 999, discardsRemaining: 4),
      deck: PokerDeck.remainingAfterPlaced(board: board),
      board: board,
    );

    final out = session.confirmAllFullLines();

    expect(out.result.ok, true);
    expect(out.result.baseScore, 50);
    expect(out.result.scoreAdded, 50);
    for (var col = 0; col < kBoardSize; col++) {
      expect(session.board.cellAt(0, col), isNull);
    }
  });

  test('풀하우스 확정 시 contributor 5장 전체가 제거된다', () {
    final board = RummiBoard();
    board.setCell(4, 0, t(TileColor.red, 8));
    board.setCell(4, 1, t(TileColor.blue, 8));
    board.setCell(4, 2, t(TileColor.yellow, 8));
    board.setCell(4, 3, t(TileColor.black, 4));
    board.setCell(4, 4, t(TileColor.red, 4));
    final session = RummiPokerGridSession(
      blind: RummiBlindState(targetScore: 999, discardsRemaining: 4),
      deck: PokerDeck.remainingAfterPlaced(board: board),
      board: board,
    );

    final out = session.confirmAllFullLines();

    expect(out.result.ok, true);
    expect(out.result.baseScore, 80);
    expect(out.result.scoreAdded, 80);
    for (var col = 0; col < kBoardSize; col++) {
      expect(session.board.cellAt(4, col), isNull);
    }
  });

  test('겹침 기여 타일이 있으면 각 라인에 overlap 배수가 적용된다', () {
    final board = RummiBoard();
    board.setCell(1, 2, t(TileColor.yellow, 7));
    board.setCell(2, 1, t(TileColor.blue, 7));
    board.setCell(2, 2, t(TileColor.red, 7));
    board.setCell(2, 3, t(TileColor.black, 7));
    board.setCell(3, 2, t(TileColor.red, 7));
    final session = RummiPokerGridSession(
      blind: RummiBlindState(targetScore: 999, discardsRemaining: 4),
      deck: PokerDeck.remainingAfterPlaced(board: board),
      board: board,
    );

    final out = session.confirmAllFullLines();

    expect(out.result.ok, true);
    expect(out.result.lineBreakdowns.length, 2);
    expect(out.result.baseScore, 104);
    expect(out.result.scoreAdded, 104);
    expect(
      out.result.lineBreakdowns.map((line) => line.overlapMultiplier),
      everyElement(1.3),
    );
    expect(
      out.result.lineBreakdowns.map((line) => line.overlapBonus),
      everyElement(12),
    );
    expect(session.board.cellAt(1, 2), isNull);
    expect(session.board.cellAt(2, 1), isNull);
    expect(session.board.cellAt(2, 2), isNull);
    expect(session.board.cellAt(2, 3), isNull);
    expect(session.board.cellAt(3, 2), isNull);
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

  test('상점 카탈로그는 현재 점수 정산 지원 Jester만 노출한다', () {
    final catalog = RummiJesterCatalog.fromJsonString('''
[
  {
    "id": "chips_ok",
    "displayName": "chips_ok",
    "rarity": "common",
    "baseCost": 3,
    "effectText": "",
    "effectType": "chips_bonus",
    "trigger": "passive",
    "conditionType": "none"
  },
  {
    "id": "scholar",
    "displayName": "scholar",
    "rarity": "common",
    "baseCost": 3,
    "effectText": "",
    "effectType": "rule_modifier",
    "trigger": "passive",
    "conditionType": "rank_scored"
  },
  {
    "id": "economy_future",
    "displayName": "economy_future",
    "rarity": "common",
    "baseCost": 3,
    "effectText": "",
    "effectType": "economy",
    "trigger": "passive",
    "conditionType": "none"
  }
]
''');

    expect(catalog.shopCatalog.map((card) => card.id).toList(), [
      'chips_ok',
      'scholar',
    ]);
    expect(catalog.findById('chips_ok')!.isSupportedInCurrentScoringMeta, true);
    expect(
      catalog.findById('economy_future')!.isSupportedInCurrentScoringMeta,
      false,
    );
  });

  test('캐시아웃은 보드 버림과 손패 버림을 따로 계산해 합산한다', () {
    final session = RummiPokerGridSession(
      blind: RummiBlindState(
        targetScore: 300,
        boardDiscardsRemaining: 3,
        handDiscardsRemaining: 2,
      ),
    );
    final progress = RummiRunProgress();

    final breakdown = progress.buildCashOutBreakdown(session);

    expect(breakdown.blindReward, RummiRunProgress.stageClearGoldBase);
    expect(
      breakdown.boardDiscardGold,
      3 * RummiRunProgress.remainingBoardDiscardGoldBonus,
    );
    expect(
      breakdown.handDiscardGold,
      2 * RummiRunProgress.remainingHandDiscardGoldBonus,
    );
    expect(
      breakdown.totalGold,
      breakdown.blindReward +
          breakdown.boardDiscardGold +
          breakdown.handDiscardGold,
    );
  });

  test('라운드 종료 economy Jester 보너스가 캐시아웃에 합산된다', () {
    final session = RummiPokerGridSession(
      blind: RummiBlindState(
        targetScore: 300,
        boardDiscardsRemaining: 3,
        handDiscardsRemaining: 2,
      ),
    );
    final progress = RummiRunProgress()
      ..ownedJesters.addAll([
        jester(
          id: 'golden_jester',
          effectType: 'economy',
          trigger: 'onRoundEnd',
          conditionType: 'none',
          value: 4,
        ),
        jester(
          id: 'egg',
          effectType: 'economy',
          trigger: 'onRoundEnd',
          conditionType: 'none',
          value: 3,
        ),
        jester(
          id: 'delayed_gratification',
          effectType: 'economy',
          trigger: 'onRoundEnd',
          conditionType: 'other',
          conditionValue: 'unused_discards',
          value: 2,
        ),
      ]);

    final breakdown = progress.buildCashOutBreakdown(session);

    expect(breakdown.economyBonuses.map((e) => e.jesterId).toList(), [
      'golden_jester',
      'egg',
      'delayed_gratification',
    ]);
    expect(breakdown.economyGold, 17);
    expect(
      breakdown.totalGold,
      breakdown.blindReward +
          breakdown.boardDiscardGold +
          breakdown.handDiscardGold +
          breakdown.economyGold,
    );
  });

  test('상점은 기본적으로 3개의 오퍼를 생성한다', () {
    final progress = RummiRunProgress();
    final catalog = List<RummiJesterCard>.generate(
      5,
      (index) => jester(
        id: 'shop_$index',
        effectType: 'chips_bonus',
        conditionType: 'none',
        value: 5 + index,
      ),
    );

    progress.openShop(catalog: catalog, rng: Random(7));

    expect(progress.shopOffers.length, 3);
  });

  test('상점은 preferredOfferIds가 있으면 해당 Jester를 우선 노출한다', () {
    final progress = RummiRunProgress();
    final catalog = [
      jester(
        id: 'green_jester',
        effectType: 'stateful_growth',
        conditionType: 'stateful',
      ),
      jester(
        id: 'popcorn',
        effectType: 'stateful_growth',
        conditionType: 'stateful',
      ),
      jester(
        id: 'ice_cream',
        effectType: 'stateful_growth',
        conditionType: 'stateful',
      ),
      jester(
        id: 'filler_one',
        effectType: 'chips_bonus',
        conditionType: 'none',
        value: 10,
      ),
      jester(
        id: 'filler_two',
        effectType: 'mult_bonus',
        conditionType: 'none',
        value: 4,
      ),
    ];

    progress.openShop(
      catalog: catalog,
      rng: Random(3),
      preferredOfferIds: const ['green_jester', 'popcorn', 'ice_cream'],
    );

    expect(progress.shopOffers.map((offer) => offer.card.id).toList(), [
      'green_jester',
      'popcorn',
      'ice_cream',
    ]);
  });

  test('상점은 offerCountOverride가 있으면 3장보다 많이 노출할 수 있다', () {
    final progress = RummiRunProgress();
    final catalog = List<RummiJesterCard>.generate(
      6,
      (index) => jester(
        id: 'inspect_$index',
        effectType: 'chips_bonus',
        conditionType: 'none',
        value: 5 + index,
      ),
    );

    progress.openShop(
      catalog: catalog,
      rng: Random(1),
      preferredOfferIds: const [
        'inspect_0',
        'inspect_1',
        'inspect_2',
        'inspect_3',
        'inspect_4',
      ],
      offerCountOverride: 5,
    );

    expect(progress.shopOffers.length, 5);
    expect(progress.shopOffers.take(5).map((offer) => offer.card.id).toList(), [
      'inspect_0',
      'inspect_1',
      'inspect_2',
      'inspect_3',
      'inspect_4',
    ]);
  });

  test('상점 카탈로그는 지원된 라운드 종료 economy Jester도 노출한다', () {
    final catalog = RummiJesterCatalog.fromJsonString('''
[
  {
    "id": "chips_ok",
    "displayName": "chips_ok",
    "rarity": "common",
    "baseCost": 3,
    "effectText": "",
    "effectType": "chips_bonus",
    "trigger": "passive",
    "conditionType": "none"
  },
  {
    "id": "golden_jester",
    "displayName": "golden_jester",
    "rarity": "common",
    "baseCost": 6,
    "effectText": "",
    "effectType": "economy",
    "trigger": "onRoundEnd",
    "conditionType": "none",
    "value": 4
  },
  {
    "id": "credit_card",
    "displayName": "credit_card",
    "rarity": "common",
    "baseCost": 1,
    "effectText": "",
    "effectType": "economy",
    "trigger": "passive",
    "conditionType": "none",
    "value": -20
  }
]
''');

    expect(catalog.shopCatalog.map((card) => card.id).toList(), [
      'chips_ok',
      'golden_jester',
    ]);
  });

  test('Supernova는 같은 족보를 다시 확정할수록 mult가 증가한다', () {
    final progress = RummiRunProgress()
      ..ownedJesters.add(
        jester(
          id: 'supernova',
          effectType: 'stateful_growth',
          conditionType: 'stateful',
        ),
      );

    RummiPokerGridSession buildSession() {
      final board = RummiBoard();
      board.setCell(1, 0, t(TileColor.red, 4));
      board.setCell(1, 1, t(TileColor.blue, 4));
      board.setCell(1, 2, t(TileColor.yellow, 9));
      board.setCell(1, 3, t(TileColor.black, 9));
      board.setCell(1, 4, t(TileColor.red, 12));
      return RummiPokerGridSession(
        blind: RummiBlindState(targetScore: 999, discardsRemaining: 4),
        deck: PokerDeck.remainingAfterPlaced(board: board),
        board: board,
      );
    }

    final firstSession = buildSession();
    final first = firstSession.confirmAllFullLines(
      jesters: progress.ownedJesters,
      runtimeSnapshot: progress.buildRuntimeSnapshot(),
    );
    progress.onConfirmedLines(first.result.lineBreakdowns);

    final secondSession = buildSession();
    final second = secondSession.confirmAllFullLines(
      jesters: progress.ownedJesters,
      runtimeSnapshot: progress.buildRuntimeSnapshot(),
    );

    expect(first.result.scoreAdded, 26);
    expect(second.result.scoreAdded, 28);
    expect(second.result.jesterBonus, greaterThan(first.result.jesterBonus));
  });

  test('장착 Jester는 슬롯 인덱스 순서대로 조건 검사와 효과 적용을 기록한다', () {
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
          id: 'slot_0_first',
          effectType: 'mult_bonus',
          conditionType: 'none',
          value: 4,
        ),
        jester(
          id: 'slot_1_second',
          effectType: 'chips_bonus',
          conditionType: 'none',
          value: 20,
        ),
      ],
    );

    expect(
      out.result.lineBreakdowns.single.effects.map((e) => e.jesterId).toList(),
      ['slot_0_first', 'slot_1_second'],
    );
  });

  test('Popcorn은 초기 state mult를 주고 스테이지 종료 후 감소한다', () {
    final progress = RummiRunProgress()
      ..shopOffers.add(
        RummiShopOffer(
          slotIndex: 0,
          card: jester(
            id: 'popcorn',
            effectType: 'stateful_growth',
            conditionType: 'stateful',
            value: 20,
          ),
        ),
      );
    expect(progress.buyOffer(0), true);

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

    final before = session.confirmAllFullLines(
      jesters: progress.ownedJesters,
      runtimeSnapshot: progress.buildRuntimeSnapshot(),
    );

    progress.advanceStage(session, runSeed: 1234);

    expect(before.result.scoreAdded, 50);
    expect(progress.buildRuntimeSnapshot().stateValueForSlot(0), 16);
  });

  test('Ice Cream은 확정 액션마다 chips state가 감소한다', () {
    final progress = RummiRunProgress()
      ..shopOffers.add(
        RummiShopOffer(
          slotIndex: 0,
          card: jester(
            id: 'ice_cream',
            effectType: 'stateful_growth',
            conditionType: 'stateful',
            value: 100,
          ),
        ),
      );
    expect(progress.buyOffer(0), true);

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
      jesters: progress.ownedJesters,
      runtimeSnapshot: progress.buildRuntimeSnapshot(),
    );
    progress.onConfirmedLines(out.result.lineBreakdowns);

    expect(out.result.scoreAdded, 125);
    expect(progress.buildRuntimeSnapshot().stateValueForSlot(0), 95);
  });

  test('Green Jester는 줄 확정 액션마다 +1, 버림마다 -1을 누적한다', () {
    final progress = RummiRunProgress()
      ..shopOffers.add(
        RummiShopOffer(
          slotIndex: 0,
          card: jester(
            id: 'green_jester',
            effectType: 'stateful_growth',
            conditionType: 'stateful',
            value: 1,
          ),
        ),
      );
    expect(progress.buyOffer(0), true);

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

    final first = session.confirmAllFullLines(
      jesters: progress.ownedJesters,
      runtimeSnapshot: progress.buildRuntimeSnapshot(),
    );
    progress.onConfirmedLines(first.result.lineBreakdowns);
    expect(progress.buildRuntimeSnapshot().stateValueForSlot(0), 1);

    progress.onDiscardUsed();
    expect(progress.buildRuntimeSnapshot().stateValueForSlot(0), 0);

    final nextBoard = RummiBoard();
    nextBoard.setCell(1, 0, t(TileColor.red, 4));
    nextBoard.setCell(1, 1, t(TileColor.blue, 4));
    nextBoard.setCell(1, 2, t(TileColor.yellow, 9));
    nextBoard.setCell(1, 3, t(TileColor.black, 9));
    nextBoard.setCell(1, 4, t(TileColor.red, 12));
    final nextSession = RummiPokerGridSession(
      blind: RummiBlindState(targetScore: 999, discardsRemaining: 4),
      deck: PokerDeck.remainingAfterPlaced(board: nextBoard),
      board: nextBoard,
    );

    final second = nextSession.confirmAllFullLines(
      jesters: progress.ownedJesters,
      runtimeSnapshot: progress.buildRuntimeSnapshot(),
    );

    expect(first.result.scoreAdded, 25);
    expect(second.result.scoreAdded, 25);
  });

  test('Ride the Bus는 페이스 카드 없는 확정에서 증가하고 페이스 카드가 나오면 초기화된다', () {
    final progress = RummiRunProgress()
      ..shopOffers.add(
        RummiShopOffer(
          slotIndex: 0,
          card: jester(
            id: 'ride_the_bus',
            effectType: 'stateful_growth',
            conditionType: 'face_card',
            conditionValue: 'consecutive_hands_without_scoring_face_card',
            value: 1,
          ),
        ),
      );
    expect(progress.buyOffer(0), true);

    final firstBoard = RummiBoard();
    firstBoard.setCell(1, 0, t(TileColor.red, 4));
    firstBoard.setCell(1, 1, t(TileColor.blue, 4));
    firstBoard.setCell(1, 2, t(TileColor.yellow, 9));
    firstBoard.setCell(1, 3, t(TileColor.black, 9));
    firstBoard.setCell(1, 4, t(TileColor.red, 10));
    final firstSession = RummiPokerGridSession(
      blind: RummiBlindState(targetScore: 999, discardsRemaining: 4),
      deck: PokerDeck.remainingAfterPlaced(board: firstBoard),
      board: firstBoard,
    );

    final first = firstSession.confirmAllFullLines(
      jesters: progress.ownedJesters,
      runtimeSnapshot: progress.buildRuntimeSnapshot(),
    );
    progress.onConfirmedLines(first.result.lineBreakdowns);
    expect(progress.buildRuntimeSnapshot().stateValueForSlot(0), 1);

    final secondBoard = RummiBoard();
    secondBoard.setCell(1, 0, t(TileColor.red, 12));
    secondBoard.setCell(1, 1, t(TileColor.blue, 12));
    secondBoard.setCell(1, 2, t(TileColor.yellow, 9));
    secondBoard.setCell(1, 3, t(TileColor.black, 9));
    secondBoard.setCell(1, 4, t(TileColor.red, 10));
    final secondSession = RummiPokerGridSession(
      blind: RummiBlindState(targetScore: 999, discardsRemaining: 4),
      deck: PokerDeck.remainingAfterPlaced(board: secondBoard),
      board: secondBoard,
    );

    final second = secondSession.confirmAllFullLines(
      jesters: progress.ownedJesters,
      runtimeSnapshot: progress.buildRuntimeSnapshot(),
    );
    progress.onConfirmedLines(second.result.lineBreakdowns);

    expect(progress.buildRuntimeSnapshot().stateValueForSlot(0), 0);
    expect(first.result.scoreAdded, 25);
    expect(second.result.scoreAdded, 26);
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

  test('세션 RNG 상태를 복원하면 다음 난수 흐름이 이어진다', () {
    final session = RummiPokerGridSession(runSeed: 98765);
    final first = session.runRandom.nextInt(100000);
    final second = session.runRandom.nextInt(100000);

    final restored = RummiPokerGridSession.restored(
      runSeed: session.runSeed,
      deckCopiesPerTile: session.deckCopiesPerTile,
      maxHandSize: session.maxHandSize,
      runRandomState: session.runRandom.state,
      blind: session.blind.copyWith(),
      deck: PokerDeck.fromSnapshot(session.deck.snapshotPile()),
      board: session.board.copy(),
      hand: List<Tile>.from(session.hand),
      eliminated: List<Tile>.from(session.eliminated),
    );

    expect(first, isNot(equals(second)));
    expect(
      restored.runRandom.nextInt(100000),
      session.runRandom.nextInt(100000),
    );
  });

  test('RummiRunProgress.restore는 stateful 값과 누적 족보 카운트를 유지한다', () {
    final original = RummiRunProgress();
    original.ownedJesters.addAll([
      jester(
        id: 'ride_the_bus',
        effectType: 'stateful_growth',
        conditionType: 'none',
      ),
      jester(
        id: 'supernova',
        effectType: 'stateful_growth',
        conditionType: 'none',
      ),
    ]);
    original.onConfirmedLines([
      ConfirmedLineBreakdown(
        ref: LineRef.row(0),
        rank: RummiHandRank.straight,
        baseScore: 70,
        finalScore: 70,
        jesterBonus: 0,
        hasScoringFaceCard: false,
        effects: [],
      ),
    ]);

    final restored = RummiRunProgress.restore(
      stageIndex: original.stageIndex,
      gold: original.gold,
      rerollCost: original.rerollCost,
      ownedJesters: List<RummiJesterCard>.from(original.ownedJesters),
      shopOffers: List<RummiShopOffer>.from(original.shopOffers),
      statefulValuesBySlot: original.snapshotStatefulValuesBySlot(),
      playedHandCounts: original.snapshotPlayedHandCounts(),
    );

    final snapshot = restored.buildRuntimeSnapshot();
    expect(snapshot.stateValueForSlot(0), 1);
    expect(snapshot.playedCountForRank(RummiHandRank.straight), 1);
  });

  test('fromJson: originalSuitRefs만으로 tile_color 색을 합성한다', () {
    final card = RummiJesterCard.fromJson({
      'id': 'greedy_jester',
      'displayName': 'Greedy Jester',
      'rarity': 'common',
      'baseCost': 5,
      'effectText': '',
      'effectType': 'mult_bonus',
      'trigger': 'onScore',
      'conditionType': 'tile_color_scored',
      'conditionValue': null,
      'value': 3,
      'originalSuitRefs': ['diamonds'],
    });
    expect(card.mappedTileColors, [TileColor.yellow]);
  });

  test('fromJson: originalRankRefs와 토큰 문자열로 랭크를 합성한다', () {
    final card = RummiJesterCard.fromJson({
      'id': 'walkie_talkie',
      'displayName': 'Walkie Talkie',
      'rarity': 'common',
      'baseCost': 4,
      'effectText': '',
      'effectType': 'mult_bonus',
      'trigger': 'onScore',
      'conditionType': 'rank_scored',
      'conditionValue': [10, 4],
      'value': 4,
      'originalRankRefs': ['10', '4'],
    });
    expect(card.mappedTileNumbers, [4, 10]);
  });
}
