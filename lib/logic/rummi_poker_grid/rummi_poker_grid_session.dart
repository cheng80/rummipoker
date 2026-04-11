import 'dart:math' show Random;

import 'hand_rank.dart';
import 'jester_meta.dart';
import 'line_ref.dart';
import 'models/board.dart';
import 'models/poker_deck.dart';
import 'models/tile.dart';
import 'models/waste_tray.dart';
import 'rummi_blind_state.dart';
import 'rummi_poker_grid_engine.dart';

/// 블라인드 목표 달성.
class BlindCleared {
  const BlindCleared();
}

/// GDD §8.4 만료 신호(후속 판정은 UI/런 레이어).
enum RummiExpirySignal {
  /// 버림(D)이 없는데 보드 25칸이 모두 찼을 때(칸을 비울 수 없음).
  boardFullAfterDcExhausted,

  /// 드로우 더미 소진.
  drawPileExhausted,
}

/// 족보 줄 일괄 확정 결과.
class ConfirmClearResult {
  ConfirmClearResult._({
    required this.ok,
    this.scoreAdded = 0,
    this.baseScore = 0,
    this.jesterBonus = 0,
    this.lineBreakdowns = const [],
  });

  factory ConfirmClearResult.nothing() => ConfirmClearResult._(
    ok: false,
    scoreAdded: 0,
    baseScore: 0,
    jesterBonus: 0,
    lineBreakdowns: const [],
  );

  factory ConfirmClearResult.success({
    required int scoreAdded,
    required int baseScore,
    required int jesterBonus,
    required List<ConfirmedLineBreakdown> lineBreakdowns,
  }) => ConfirmClearResult._(
    ok: true,
    scoreAdded: scoreAdded,
    baseScore: baseScore,
    jesterBonus: jesterBonus,
    lineBreakdowns: lineBreakdowns,
  );

  final bool ok;
  final int scoreAdded;
  final int baseScore;
  final int jesterBonus;
  final List<ConfirmedLineBreakdown> lineBreakdowns;
}

class ConfirmedLineBreakdown {
  const ConfirmedLineBreakdown({
    required this.ref,
    required this.rank,
    required this.baseScore,
    required this.finalScore,
    required this.jesterBonus,
    required this.effects,
  });

  final LineRef ref;
  final RummiHandRank rank;
  final int baseScore;
  final int finalScore;
  final int jesterBonus;
  final List<RummiJesterEffectBreakdown> effects;
}

/// 덱·손패·보드·웨이스트·제거 더미를 묶은 퍼사드 (마이그레이션 플랜 단계 1).
class RummiPokerGridSession {
  RummiPokerGridSession._({
    required this.runSeed,
    required this.runRandom,
    required this.deckCopiesPerTile,
    required this.blind,
    required this.deck,
    required this.board,
    required this.hand,
    required this.waste,
    required this.eliminated,
    required this.engine,
  });

  /// 저장·공유용. 실제 난수 스트림은 [runRandom] 한 개로 이어진다.
  final int runSeed;
  final int deckCopiesPerTile;

  /// [runSeed]로 시드된 단일 RNG — 덱 셔플 이후에도 **같은 스트림**으로 이어짐(턴 재현).
  final Random runRandom;

  /// [runSeed] 생략 시 무작위. [deck] 생략 시 `PokerDeck.shuffled(Random(runSeed))`.
  factory RummiPokerGridSession({
    int? runSeed,
    int deckCopiesPerTile = kDefaultCopiesPerTile,
    RummiBlindState? blind,
    PokerDeck? deck,
    RummiBoard? board,
  }) {
    final s = runSeed ?? _rollSeed();
    final rng = Random(s);
    return RummiPokerGridSession._(
      runSeed: s,
      runRandom: rng,
      deckCopiesPerTile: deckCopiesPerTile,
      blind: blind ?? RummiBlindState(targetScore: 300, discardsRemaining: 4),
      deck: deck ?? PokerDeck.shuffled(rng, null, deckCopiesPerTile),
      board: board ?? RummiBoard(),
      hand: <Tile>[],
      waste: WasteTray(),
      eliminated: <Tile>[],
      engine: RummiPokerGridEngine(),
    );
  }

  static int _rollSeed() => Random().nextInt(0x7fffffff);

  static int deriveStageShuffleSeed(int runSeed, int stageIndex) {
    final mixed = (runSeed * 1103515245 + 12345 + stageIndex * 1013904223) &
        0x7fffffff;
    return mixed == 0 ? stageIndex + 1 : mixed;
  }

  /// 타이틀·URL에서 런 시작 시드로 쓸 무작위 값.
  static int rollNewRunSeed() => _rollSeed();

  final RummiBlindState blind;
  final PokerDeck deck;
  final RummiBoard board;
  final List<Tile> hand;
  final WasteTray waste;

  /// 확정·버림으로 영구 제거된 타일(다시 드로우되지 않음).
  final List<Tile> eliminated;
  final RummiPokerGridEngine engine;

  int get totalDeckSize => totalDeckSizeForCopies(deckCopiesPerTile);

  /// 손패 최대 장수. 임시 테스트용으로 1장 허용.
  static const int kMaxHandSize = 1;

  /// 드로우 버튼 활성 조건: 덱 잔량 + 손패 여유.
  bool get canDrawFromDeck => hand.length < kMaxHandSize && !deck.isEmpty;

  /// 보드 위 타일 수.
  static int countTilesOnBoard(RummiBoard b) {
    var n = 0;
    for (var r = 0; r < kBoardSize; r++) {
      for (var c = 0; c < kBoardSize; c++) {
        if (b.cellAt(r, c) != null) n++;
      }
    }
    return n;
  }

  /// 덱 + 손 + 보드 + 웨이스트 + 제거 더미 = 전체 덱 장수 유지 검증용.
  int get conservationTotal =>
      deck.remaining +
      hand.length +
      waste.occupiedCount +
      eliminated.length +
      countTilesOnBoard(board);

  /// 드로우 더미에서 손으로 1장. 손패가 [kMaxHandSize]장이면 추가하지 않고 `null`.
  /// 덱이 비면 `null`.
  Tile? drawToHand() {
    if (hand.length >= kMaxHandSize) return null;
    final t = deck.draw();
    if (t != null) {
      hand.add(t);
    }
    return t;
  }

  /// 손패의 타일을 보드 빈 칸에 놓는다.
  bool tryPlaceFromHand(Tile tile, int row, int col) {
    final i = hand.indexWhere((t) => t == tile);
    if (i < 0) return false;
    if (board.cellAt(row, col) != null) return false;
    hand.removeAt(i);
    board.setCell(row, col, tile);
    return true;
  }

  /// 보드 버림: \(D\) 1 소모, 해당 칸 타일은 제거 더미로, 손패에 여유가 있으면 덱에서 1장 보충.
  ({Tile? drew, DiscardFailReason? fail}) tryDiscardFromBoard(
    int row,
    int col,
  ) {
    if (blind.discardsRemaining <= 0) {
      return (drew: null, fail: DiscardFailReason.noDiscardsLeft);
    }
    final tile = board.cellAt(row, col);
    if (tile == null) {
      return (drew: null, fail: DiscardFailReason.cellEmpty);
    }
    blind.discardsRemaining--;
    board.setCell(row, col, null);
    eliminated.add(tile);
    Tile? drew;
    if (hand.length < kMaxHandSize) {
      drew = deck.draw();
      if (drew != null) {
        hand.add(drew);
      }
    }
    return (drew: drew, fail: null);
  }

  /// 현재 보드에서 5칸 완성된 **족보(점수) 줄만** 일괄 확정한다.
  /// 죽은 줄은 **한 줄씩 일괄 제거 없음** — 칸을 비우려면 **보드 버림(D)** 만 사용.
  ({ConfirmClearResult result, BlindCleared? cleared}) confirmAllFullLines({
    List<RummiJesterCard> jesters = const [],
  }) {
    final lines = engine.listFullLines(board);
    final scoringLines = [
      for (final e in lines)
        if (!e.report.evaluation.isDeadLine) e,
    ];
    if (scoringLines.isEmpty) {
      return (result: ConfirmClearResult.nothing(), cleared: null);
    }

    var scoreSum = 0;
    var baseScoreSum = 0;
    var jesterBonusSum = 0;
    final lineBreakdowns = <ConfirmedLineBreakdown>[];
    final jesterContext = RummiJesterScoreContext(
      discardsRemaining: blind.discardsRemaining,
      cardsRemainingInDeck: deck.remaining,
      ownedJesterCount: jesters.length,
    );

    for (final e in scoringLines) {
      final evaluation = e.report.evaluation;
      final lineCells = e.ref.cells();
      final scoringTiles = <Tile>[];
      for (final index in evaluation.contributingIndexes) {
        if (index < 0 || index >= lineCells.length) continue;
        final (r, c) = lineCells[index];
        final tile = board.cellAt(r, c);
        if (tile != null) {
          scoringTiles.add(tile);
        }
      }

      var lineScore = evaluation.baseScore;
      final baseLineScore = evaluation.baseScore;
      final effects = <RummiJesterEffectBreakdown>[];
      for (final jester in jesters) {
        final scored = jester.applyToLine(
          rank: evaluation.rank,
          baseScore: evaluation.baseScore,
          scoringTiles: scoringTiles,
          context: jesterContext,
        );
        if (scored.effect != null) {
          effects.add(scored.effect!);
        }
        lineScore += scored.finalScore - scored.baseScore;
      }
      baseScoreSum += baseLineScore;
      scoreSum += lineScore;
      jesterBonusSum += lineScore - baseLineScore;
      lineBreakdowns.add(
        ConfirmedLineBreakdown(
          ref: e.ref,
          rank: evaluation.rank,
          baseScore: baseLineScore,
          finalScore: lineScore,
          jesterBonus: lineScore - baseLineScore,
          effects: List<RummiJesterEffectBreakdown>.unmodifiable(effects),
        ),
      );
    }

    blind.scoreTowardBlind += scoreSum;

    final cells = <(int, int)>{};
    for (final e in scoringLines) {
      final lineCells = e.ref.cells();
      for (final index in e.report.evaluation.contributingIndexes) {
        if (index < 0 || index >= lineCells.length) continue;
        cells.add(lineCells[index]);
      }
    }
    for (final rc in cells) {
      final (r, c) = rc;
      final t = board.cellAt(r, c);
      if (t != null) {
        eliminated.add(t);
        // Future FX hook: confirm settlement ends, then play vanish/burst effect
        // for these contributing cells before the board visually clears them.
        board.setCell(r, c, null);
      }
    }

    BlindCleared? cleared;
    if (blind.isTargetMet) {
      cleared = const BlindCleared();
    }

    return (
      result: ConfirmClearResult.success(
        scoreAdded: scoreSum,
        baseScore: baseScoreSum,
        jesterBonus: jesterBonusSum,
        lineBreakdowns: List<ConfirmedLineBreakdown>.unmodifiable(
          lineBreakdowns,
        ),
      ),
      cleared: cleared,
    );
  }

  /// 드로우/배치/버림 직후 등 호출 — GDD §8.4 만료 트리거 감지.
  List<RummiExpirySignal> evaluateExpirySignals() {
    final s = <RummiExpirySignal>[];
    if (deck.isEmpty) {
      s.add(RummiExpirySignal.drawPileExhausted);
    }
    if (blind.discardsRemaining <= 0 &&
        countTilesOnBoard(board) == kBoardSize * kBoardSize) {
      s.add(RummiExpirySignal.boardFullAfterDcExhausted);
    }
    return s;
  }

  /// 확정 가능: 완성된 **족보(점수) 줄**이 하나라도 있을 때.
  bool get canConfirmAllFullLines {
    final lines = engine.listFullLines(board);
    return lines.any((e) => !e.report.evaluation.isDeadLine);
  }

  /// 스테이지 종료 시 남은 보드/손패를 정리한다.
  void discardStageRemainder() {
    for (final tile in hand) {
      eliminated.add(tile);
    }
    hand.clear();

    for (var row = 0; row < kBoardSize; row++) {
      for (var col = 0; col < kBoardSize; col++) {
        final tile = board.cellAt(row, col);
        if (tile == null) continue;
        eliminated.add(tile);
        board.setCell(row, col, null);
      }
    }
  }

  /// 다음 블라인드 진입을 위해 목표/자원을 초기화한다.
  void prepareNextBlind({
    required int targetScore,
    required int discardsRemaining,
    int? shuffleSeed,
  }) {
    discardStageRemainder();
    eliminated.clear();
    waste.clear();
    deck.resetShuffled(
      random: Random(shuffleSeed ?? deriveStageShuffleSeed(runSeed, 1)),
      copiesPerTile: deckCopiesPerTile,
    );
    blind.targetScore = targetScore;
    blind.discardsRemaining = discardsRemaining;
    blind.scoreTowardBlind = 0;
  }
}

enum DiscardFailReason { noDiscardsLeft, cellEmpty }
