import 'dart:math' show Random, max, min;

import 'hand_evaluator.dart';
import 'hand_rank.dart';
import 'jester_effect_runtime.dart';
import 'jester_meta.dart';
import 'line_ref.dart';
import 'models/board.dart';
import 'models/poker_deck.dart';
import 'models/tile.dart';
import 'rummi_blind_state.dart';
import 'rummi_poker_grid_engine.dart';
import 'rummi_ruleset.dart';
import '../../utils/seeded_random.dart';

/// 블라인드 목표 달성.
class BlindCleared {
  const BlindCleared();
}

/// GDD §8.4 만료 신호(후속 판정은 UI/런 레이어).
enum RummiExpirySignal {
  /// 버림(D)이 없고 보드 25칸이 모두 찼으며 확정 가능한 줄도 없을 때.
  boardFullAfterDcExhausted,

  /// 드로우 더미가 비었고, 손패/확정 가능한 줄도 더 이상 없어 진행할 카드가 없음.
  drawPileExhausted,
}

class BoardMoveRecord {
  const BoardMoveRecord({
    required this.fromRow,
    required this.fromCol,
    required this.toRow,
    required this.toCol,
  });

  factory BoardMoveRecord.fromJson(Map<String, dynamic> json) {
    return BoardMoveRecord(
      fromRow: (json['fromRow'] as num).toInt(),
      fromCol: (json['fromCol'] as num).toInt(),
      toRow: (json['toRow'] as num).toInt(),
      toCol: (json['toCol'] as num).toInt(),
    );
  }

  final int fromRow;
  final int fromCol;
  final int toRow;
  final int toCol;

  Map<String, dynamic> toJson() => {
    'fromRow': fromRow,
    'fromCol': fromCol,
    'toRow': toRow,
    'toCol': toCol,
  };
}

class RummiConfirmModifier {
  const RummiConfirmModifier({
    required this.itemId,
    required this.timing,
    required this.op,
    this.amount = 0,
    this.percent = 0,
    this.rank,
    this.tileColor,
    this.maxTiles,
    this.consumeOnApply = true,
  });

  factory RummiConfirmModifier.fromJson(Map<String, dynamic> json) {
    return RummiConfirmModifier(
      itemId: json['itemId'] as String,
      timing: json['timing'] as String,
      op: json['op'] as String,
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      percent: (json['percent'] as num?)?.toDouble() ?? 0,
      rank: json['rank'] == null
          ? null
          : RummiHandRank.values.byName(json['rank'] as String),
      tileColor: json['tileColor'] == null
          ? null
          : TileColor.values.byName(json['tileColor'] as String),
      maxTiles: (json['maxTiles'] as num?)?.toInt(),
      consumeOnApply: json['consumeOnApply'] as bool? ?? true,
    );
  }

  final String itemId;
  final String timing;
  final String op;
  final double amount;
  final double percent;
  final RummiHandRank? rank;
  final TileColor? tileColor;
  final int? maxTiles;
  final bool consumeOnApply;

  Map<String, dynamic> toJson() => {
    'itemId': itemId,
    'timing': timing,
    'op': op,
    'amount': amount,
    'percent': percent,
    if (rank != null) 'rank': rank!.name,
    if (tileColor != null) 'tileColor': tileColor!.name,
    if (maxTiles != null) 'maxTiles': maxTiles,
    'consumeOnApply': consumeOnApply,
  };
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
    required this.hasScoringFaceCard,
    required this.effects,
    this.rankBaseScore,
    this.overlapMultiplier = 1.0,
    this.overlapBonus = 0,
    this.contributingCells = const [],
  });

  final LineRef ref;
  final RummiHandRank rank;
  final int? rankBaseScore;
  final int baseScore;
  final int finalScore;
  final int jesterBonus;
  final bool hasScoringFaceCard;
  final List<RummiJesterEffectBreakdown> effects;
  final double overlapMultiplier;
  final int overlapBonus;
  final List<(int, int)> contributingCells;
}

/// 덱·손패·보드·제거 더미를 묶은 퍼사드 (마이그레이션 플랜 단계 1).
class RummiPokerGridSession {
  static const int kDefaultMaxHandSize = 1;
  static const int kMinDebugMaxHandSize = 1;
  static const int kMaxDebugMaxHandSize = 3;
  static const double kOverlapAlpha = 0.3;
  static const double kOverlapMultiplierCap = 2.0;

  RummiPokerGridSession._({
    required this.runSeed,
    required this.runRandom,
    required this.ruleset,
    required this.deckCopiesPerTile,
    required this.maxHandSize,
    required this.blind,
    required this.deck,
    required this.board,
    required this.hand,
    required this.eliminated,
    required this.boardMoveHistory,
    required this.confirmModifiers,
    required this.confirmCountThisStation,
    required this.firstConfirmScoreThisStation,
    required this.expiryGuardUsedThisStation,
    required this.engine,
  });

  /// 저장·공유용. 실제 난수 스트림은 [runRandom] 한 개로 이어진다.
  final int runSeed;
  final RummiRuleset ruleset;
  final int deckCopiesPerTile;
  int maxHandSize;

  /// [runSeed]로 시드된 단일 RNG — 덱 셔플 이후에도 **같은 스트림**으로 이어짐(턴 재현).
  final SeededRandom runRandom;

  /// [runSeed] 생략 시 무작위. [deck] 생략 시 `PokerDeck.shuffled(Random(runSeed))`.
  factory RummiPokerGridSession({
    int? runSeed,
    int deckCopiesPerTile = kDefaultCopiesPerTile,
    RummiRuleset ruleset = RummiRuleset.currentDefaults,
    RummiBlindState? blind,
    PokerDeck? deck,
    RummiBoard? board,
  }) {
    final s = runSeed ?? _rollSeed();
    final rng = SeededRandom(s);
    return RummiPokerGridSession._(
      runSeed: s,
      runRandom: rng,
      ruleset: ruleset,
      deckCopiesPerTile: deckCopiesPerTile,
      maxHandSize: ruleset.defaultMaxHandSize,
      blind:
          blind ??
          RummiBlindState(
            targetScore: 300,
            boardDiscardsRemaining: 4,
            handDiscardsRemaining: 2,
          ),
      deck: deck ?? PokerDeck.shuffled(rng, null, deckCopiesPerTile),
      board: board ?? RummiBoard(),
      hand: <Tile>[],
      eliminated: <Tile>[],
      boardMoveHistory: <BoardMoveRecord>[],
      confirmModifiers: <RummiConfirmModifier>[],
      confirmCountThisStation: 0,
      firstConfirmScoreThisStation: 0,
      expiryGuardUsedThisStation: false,
      engine: RummiPokerGridEngine(),
    );
  }

  static int _rollSeed() => Random().nextInt(0x7fffffff);

  factory RummiPokerGridSession.restored({
    required int runSeed,
    required int deckCopiesPerTile,
    required int maxHandSize,
    required int runRandomState,
    RummiRuleset ruleset = RummiRuleset.currentDefaults,
    required RummiBlindState blind,
    required PokerDeck deck,
    required RummiBoard board,
    required List<Tile> hand,
    required List<Tile> eliminated,
    List<BoardMoveRecord> boardMoveHistory = const [],
    List<RummiConfirmModifier> confirmModifiers = const [],
    int confirmCountThisStation = 0,
    int firstConfirmScoreThisStation = 0,
    bool expiryGuardUsedThisStation = false,
  }) {
    return RummiPokerGridSession._(
      runSeed: runSeed,
      runRandom: SeededRandom.fromState(runRandomState),
      ruleset: ruleset,
      deckCopiesPerTile: deckCopiesPerTile,
      maxHandSize: maxHandSize,
      blind: blind,
      deck: deck,
      board: board,
      hand: List<Tile>.from(hand),
      eliminated: List<Tile>.from(eliminated),
      boardMoveHistory: List<BoardMoveRecord>.from(boardMoveHistory),
      confirmModifiers: List<RummiConfirmModifier>.from(confirmModifiers),
      confirmCountThisStation: confirmCountThisStation,
      firstConfirmScoreThisStation: firstConfirmScoreThisStation,
      expiryGuardUsedThisStation: expiryGuardUsedThisStation,
      engine: RummiPokerGridEngine(),
    );
  }

  static int deriveStageShuffleSeed(int runSeed, int stageIndex) {
    final mixed =
        (runSeed * 1103515245 + 12345 + stageIndex * 1013904223) & 0x7fffffff;
    return mixed == 0 ? stageIndex + 1 : mixed;
  }

  /// 타이틀·URL에서 런 시작 시드로 쓸 무작위 값.
  static int rollNewRunSeed() => _rollSeed();

  final RummiBlindState blind;
  final PokerDeck deck;
  final RummiBoard board;
  final List<Tile> hand;

  /// 확정·버림으로 영구 제거된 타일(다시 드로우되지 않음).
  final List<Tile> eliminated;
  final List<BoardMoveRecord> boardMoveHistory;
  final List<RummiConfirmModifier> confirmModifiers;
  int confirmCountThisStation;
  int firstConfirmScoreThisStation;
  bool expiryGuardUsedThisStation;
  final RummiPokerGridEngine engine;

  int get totalDeckSize => totalDeckSizeForCopies(deckCopiesPerTile);

  /// 드로우 버튼 활성 조건: 덱 잔량 + 손패 여유.
  bool get canDrawFromDeck => hand.length < maxHandSize && !deck.isEmpty;

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

  /// 덱 + 손 + 보드 + 제거 더미 = 전체 덱 장수 유지 검증용.
  int get conservationTotal =>
      deck.remaining +
      hand.length +
      eliminated.length +
      countTilesOnBoard(board);

  /// 드로우 더미에서 손으로 1장. 손패가 [maxHandSize]장이면 추가하지 않고 `null`.
  /// 덱이 비면 `null`.
  Tile? drawToHand() {
    if (hand.length >= maxHandSize) return null;
    final t = deck.draw();
    if (t != null) {
      hand.add(t);
    }
    return t;
  }

  List<Tile> peekDeckTop(int count) => deck.peekTop(count);

  Tile? discardFromDeckTopWindow({
    required int topIndex,
    required int windowSize,
  }) {
    final tile = deck.discardFromTopWindow(
      topIndex: topIndex,
      windowSize: windowSize,
    );
    if (tile != null) {
      eliminated.add(tile);
    }
    return tile;
  }

  /// 손패의 타일을 보드 빈 칸에 놓는다.
  bool tryPlaceFromHand(Tile tile, int row, int col) {
    final i = hand.indexWhere((t) => t == tile);
    if (i < 0) return false;
    if (board.cellAt(row, col) != null) return false;
    boardMoveHistory.clear();
    hand.removeAt(i);
    board.setCell(row, col, tile);
    return true;
  }

  /// 보드 버림: \(D\) 1 소모, 해당 칸 타일은 제거 더미로, 손패에 여유가 있으면 덱에서 1장 보충.
  ({Tile? drew, DiscardFailReason? fail}) tryDiscardFromBoard(
    int row,
    int col,
  ) {
    if (blind.boardDiscardsRemaining <= 0) {
      return (drew: null, fail: DiscardFailReason.noBoardDiscardsLeft);
    }
    final tile = board.cellAt(row, col);
    if (tile == null) {
      return (drew: null, fail: DiscardFailReason.cellEmpty);
    }
    blind.boardDiscardsRemaining--;
    boardMoveHistory.clear();
    board.setCell(row, col, null);
    eliminated.add(tile);
    Tile? drew;
    if (hand.length < maxHandSize) {
      drew = deck.draw();
      if (drew != null) {
        hand.add(drew);
      }
    }
    return (drew: drew, fail: null);
  }

  /// 손패 버림: 손패 버림 자원 1 소모 후 선택한 손패 타일을 제거하고 즉시 1장 보충한다.
  ({Tile? drew, DiscardFailReason? fail}) tryDiscardFromHand(Tile tile) {
    if (blind.handDiscardsRemaining <= 0) {
      return (drew: null, fail: DiscardFailReason.noHandDiscardsLeft);
    }
    final index = hand.indexWhere((candidate) => candidate == tile);
    if (index < 0) {
      return (drew: null, fail: DiscardFailReason.tileNotInHand);
    }

    blind.handDiscardsRemaining--;
    eliminated.add(hand.removeAt(index));

    final drew = deck.draw();
    if (drew != null) {
      hand.add(drew);
    }
    return (drew: drew, fail: null);
  }

  BoardMoveFailReason? tryMoveBoardTile({
    required int fromRow,
    required int fromCol,
    required int toRow,
    required int toCol,
  }) {
    if (blind.boardMovesRemaining <= 0) {
      return BoardMoveFailReason.noBoardMovesLeft;
    }
    if (board.cellAt(fromRow, fromCol) == null) {
      return BoardMoveFailReason.sourceCellEmpty;
    }
    if (board.cellAt(toRow, toCol) != null) {
      return BoardMoveFailReason.destinationOccupied;
    }
    final moved = board.moveCell(
      fromRow: fromRow,
      fromCol: fromCol,
      toRow: toRow,
      toCol: toCol,
    );
    if (!moved) return BoardMoveFailReason.sourceCellEmpty;
    boardMoveHistory.add(
      BoardMoveRecord(
        fromRow: fromRow,
        fromCol: fromCol,
        toRow: toRow,
        toCol: toCol,
      ),
    );
    blind.boardMovesRemaining--;
    return null;
  }

  BoardMoveUndoFailReason? undoLastBoardMove() {
    if (boardMoveHistory.isEmpty) {
      return BoardMoveUndoFailReason.noMoveHistory;
    }
    final last = boardMoveHistory.last;
    if (board.cellAt(last.fromRow, last.fromCol) != null) {
      return BoardMoveUndoFailReason.sourceOccupied;
    }
    if (board.cellAt(last.toRow, last.toCol) == null) {
      return BoardMoveUndoFailReason.destinationEmpty;
    }
    final moved = board.moveCell(
      fromRow: last.toRow,
      fromCol: last.toCol,
      toRow: last.fromRow,
      toCol: last.fromCol,
    );
    if (!moved) return BoardMoveUndoFailReason.sourceOccupied;
    boardMoveHistory.removeLast();
    blind.boardMovesRemaining++;
    return null;
  }

  void setDebugMaxHandSize(int value) {
    maxHandSize = value.clamp(
      ruleset.minDebugMaxHandSize,
      ruleset.maxDebugMaxHandSize,
    );
  }

  void addConfirmModifier(RummiConfirmModifier modifier) {
    confirmModifiers.add(modifier);
  }

  RummiPokerGridSession copySnapshot() {
    return RummiPokerGridSession.restored(
      runSeed: runSeed,
      deckCopiesPerTile: deckCopiesPerTile,
      maxHandSize: maxHandSize,
      runRandomState: runRandom.state,
      ruleset: ruleset,
      blind: blind.copyWith(),
      deck: PokerDeck.fromSnapshot(deck.snapshotPile()),
      board: RummiBoard.fromSnapshot(board.snapshotCells()),
      hand: List<Tile>.from(hand),
      eliminated: List<Tile>.from(eliminated),
      boardMoveHistory: List<BoardMoveRecord>.from(boardMoveHistory),
      confirmModifiers: List<RummiConfirmModifier>.from(confirmModifiers),
      confirmCountThisStation: confirmCountThisStation,
      firstConfirmScoreThisStation: firstConfirmScoreThisStation,
      expiryGuardUsedThisStation: expiryGuardUsedThisStation,
    );
  }

  bool tryUseExpiryGuard() {
    if (expiryGuardUsedThisStation) return false;
    expiryGuardUsedThisStation = true;
    return true;
  }

  Tile? recycleEliminatedIntoDeckAndDraw() {
    if (eliminated.isEmpty || hand.length >= maxHandSize) return null;
    final recycled = List<Tile>.from(eliminated);
    eliminated.clear();
    deck.resetShuffled(random: runRandom, source: recycled);
    return drawToHand();
  }

  /// 현재 보드의 점수 성립 라인을 즉시 확정한다.
  ///
  /// 이 메서드의 책임은 전투 중 실시간 정산까지만이다.
  /// - 줄별 기본 점수/Jester 보정을 계산한다.
  /// - 족보 성립 카드만 제거한다.
  /// - 블라인드 누적 점수와 클리어 여부를 갱신한다.
  ///
  /// `Cash Out`, 상점 진입, 다음 스테이지 준비는 UI/메타 레이어가 후속으로 처리한다.
  /// 하이카드 줄은 제거하지 않으며, 칸을 비우려면 **보드 버림(D)** 만 사용한다.
  ({ConfirmClearResult result, BlindCleared? cleared}) confirmAllFullLines({
    List<RummiJesterCard> jesters = const [],
    RummiJesterRuntimeSnapshot runtimeSnapshot =
        const RummiJesterRuntimeSnapshot(),
    bool applyScoreToBlind = true,
  }) {
    final lines = engine.listEvaluatedLines(board, ruleset: ruleset);
    final scoringLines = <_ScoringLineCandidate>[
      for (final entry in lines)
        if (!entry.report.evaluation.isDeadLine)
          _buildScoringLineCandidate(
            ref: entry.ref,
            evaluation: entry.report.evaluation,
          ),
    ];
    if (scoringLines.isEmpty) {
      return (result: ConfirmClearResult.nothing(), cleared: null);
    }

    final contributionCounts = <(int, int), int>{};
    for (final line in scoringLines) {
      for (final cell in line.contributingCells) {
        contributionCounts.update(
          cell,
          (value) => value + 1,
          ifAbsent: () => 1,
        );
      }
    }

    var scoreSum = 0;
    var baseScoreSum = 0;
    var jesterBonusSum = 0;
    final lineBreakdowns = <ConfirmedLineBreakdown>[];
    final jesterContext = RummiJesterScoreContext(
      discardsRemaining: blind.boardDiscardsRemaining,
      cardsRemainingInDeck: deck.remaining,
      ownedJesterCount: jesters.length,
    );
    final currentConfirmRankCounts = <RummiHandRank, int>{};
    final consumedConfirmModifiers = <RummiConfirmModifier>{};
    final confirmOrdinal = confirmCountThisStation + 1;

    for (var lineIndex = 0; lineIndex < scoringLines.length; lineIndex++) {
      final line = scoringLines[lineIndex];
      final evaluation = line.evaluation;
      final hasScoringFaceCard = line.scoringTiles.any(
        (tile) => tile.number >= 11 && tile.number <= 13,
      );

      final peakContribution = line.contributingCells.fold<int>(
        1,
        (currentMax, cell) => max(currentMax, contributionCounts[cell] ?? 1),
      );
      final overlapMultiplier = _overlapMultiplierForCount(
        peakContribution,
        ruleset: ruleset,
      );
      final int baseLineScore = (evaluation.baseScore * overlapMultiplier)
          .round();
      final int overlapBonus = baseLineScore - evaluation.baseScore;
      int lineScore = baseLineScore;
      final effects = <RummiJesterEffectBreakdown>[];
      currentConfirmRankCounts.update(
        evaluation.rank,
        (value) => value + 1,
        ifAbsent: () => 1,
      );
      // Jester는 항상 장착 슬롯 인덱스(0 -> N-1) 순서대로 순차 적용한다.
      // 각 카드의 조건 판정과 상태 조회도 같은 인덱스를 기준으로 맞춘다.
      for (var jesterIndex = 0; jesterIndex < jesters.length; jesterIndex++) {
        final jester = jesters[jesterIndex];
        final resolved = JesterEffectRuntime.applyToLine(
          slotIndex: jesterIndex,
          jester: jester,
          rank: evaluation.rank,
          baseScore: baseLineScore,
          scoringTiles: line.scoringTiles,
          context: RummiJesterScoreContext(
            discardsRemaining: jesterContext.discardsRemaining,
            cardsRemainingInDeck: jesterContext.cardsRemainingInDeck,
            ownedJesterCount: jesterContext.ownedJesterCount,
            maxJesterSlots: jesterContext.maxJesterSlots,
            stateValue: runtimeSnapshot.stateValueForSlot(jesterIndex),
            currentHandPlayedCount:
                runtimeSnapshot.playedCountForRank(evaluation.rank) +
                currentConfirmRankCounts[evaluation.rank]!,
          ),
        );
        final scored = resolved.score;
        if (scored.effect != null) {
          effects.add(scored.effect!);
        }
        lineScore += scored.finalScore - scored.baseScore;
      }
      final itemResult = _applyConfirmModifiersToLine(
        lineScore: lineScore,
        rank: evaluation.rank,
        scoringTiles: line.scoringTiles,
        lineIndex: lineIndex,
        confirmOrdinal: confirmOrdinal,
        consumedModifiers: consumedConfirmModifiers,
      );
      lineScore = itemResult.score;
      effects.addAll(itemResult.effects);
      baseScoreSum += baseLineScore;
      scoreSum += lineScore;
      jesterBonusSum += lineScore - baseLineScore;
      lineBreakdowns.add(
        ConfirmedLineBreakdown(
          ref: line.ref,
          rank: evaluation.rank,
          rankBaseScore: evaluation.baseScore,
          baseScore: baseLineScore,
          finalScore: lineScore,
          jesterBonus: lineScore - baseLineScore,
          hasScoringFaceCard: hasScoringFaceCard,
          effects: List<RummiJesterEffectBreakdown>.unmodifiable(effects),
          overlapMultiplier: overlapMultiplier,
          overlapBonus: overlapBonus,
          contributingCells: List<(int, int)>.unmodifiable(
            line.contributingCells,
          ),
        ),
      );
    }

    final nextBlindScore = blind.scoreTowardBlind + scoreSum;
    if (applyScoreToBlind) {
      blind.scoreTowardBlind = nextBlindScore;
    }

    final cells = <(int, int)>{};
    for (final line in scoringLines) {
      cells.addAll(line.contributingCells);
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
    if (cells.isNotEmpty) {
      boardMoveHistory.clear();
    }
    if (consumedConfirmModifiers.isNotEmpty) {
      confirmModifiers.removeWhere(consumedConfirmModifiers.contains);
    }
    confirmCountThisStation += 1;
    if (confirmCountThisStation == 1) {
      firstConfirmScoreThisStation = scoreSum;
    }

    BlindCleared? cleared;
    if (nextBlindScore >= blind.targetScore) {
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

  void addScoreToBlind(int score) {
    if (score <= 0) return;
    blind.scoreTowardBlind += score;
  }

  /// 드로우/배치/버림 직후 등 호출 — GDD §8.4 만료 트리거 감지.
  List<RummiExpirySignal> evaluateExpirySignals() {
    final s = <RummiExpirySignal>[];
    if (_isOutOfCards()) {
      s.add(RummiExpirySignal.drawPileExhausted);
    }
    if (blind.boardDiscardsRemaining <= 0 &&
        countTilesOnBoard(board) == kBoardSize * kBoardSize &&
        !canConfirmAllFullLines) {
      s.add(RummiExpirySignal.boardFullAfterDcExhausted);
    }
    return s;
  }

  /// 확정 가능: 완성된 **족보(점수) 줄**이 하나라도 있을 때.
  bool get canConfirmAllFullLines {
    final lines = engine.listEvaluatedLines(board, ruleset: ruleset);
    return lines.any((e) => !e.report.evaluation.isDeadLine);
  }

  bool _isOutOfCards() {
    if (!deck.isEmpty) return false;
    if (hand.isNotEmpty) return false;
    if (canConfirmAllFullLines) return false;
    return true;
  }

  /// 스테이지 종료 시 남은 보드/손패를 정리한다.
  void discardStageRemainder() {
    boardMoveHistory.clear();
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
    required int boardDiscardsRemaining,
    int? handDiscardsRemaining,
    int? shuffleSeed,
  }) {
    discardStageRemainder();
    eliminated.clear();
    deck.resetShuffled(
      random: SeededRandom(shuffleSeed ?? deriveStageShuffleSeed(runSeed, 1)),
      copiesPerTile: deckCopiesPerTile,
    );
    blind.targetScore = targetScore;
    blind.boardDiscardsRemaining = boardDiscardsRemaining;
    blind.handDiscardsRemaining =
        handDiscardsRemaining ?? blind.handDiscardsMax;
    blind.boardMovesRemaining = blind.boardMovesMax;
    blind.scoreTowardBlind = 0;
    confirmModifiers.clear();
    confirmCountThisStation = 0;
    firstConfirmScoreThisStation = 0;
    expiryGuardUsedThisStation = false;
  }

  ({int score, List<RummiJesterEffectBreakdown> effects})
  _applyConfirmModifiersToLine({
    required int lineScore,
    required RummiHandRank rank,
    required List<Tile> scoringTiles,
    required int lineIndex,
    required int confirmOrdinal,
    required Set<RummiConfirmModifier> consumedModifiers,
  }) {
    var score = lineScore;
    final effects = <RummiJesterEffectBreakdown>[];
    for (final modifier in List<RummiConfirmModifier>.from(confirmModifiers)) {
      final applied = _scoreWithConfirmModifier(
        modifier: modifier,
        lineScore: score,
        rank: rank,
        scoringTiles: scoringTiles,
        lineIndex: lineIndex,
        confirmOrdinal: confirmOrdinal,
      );
      if (applied == null) continue;
      score = applied.score;
      effects.add(applied.effect);
      if (modifier.consumeOnApply) {
        consumedModifiers.add(modifier);
      }
    }
    return (score: score, effects: effects);
  }

  ({int score, RummiJesterEffectBreakdown effect})? _scoreWithConfirmModifier({
    required RummiConfirmModifier modifier,
    required int lineScore,
    required RummiHandRank rank,
    required List<Tile> scoringTiles,
    required int lineIndex,
    required int confirmOrdinal,
  }) {
    if (!_confirmModifierMatches(
      modifier,
      rank: rank,
      scoringTiles: scoringTiles,
      lineIndex: lineIndex,
      confirmOrdinal: confirmOrdinal,
    )) {
      return null;
    }

    var chipsBonus = 0;
    var multBonus = 0;
    var xmultBonus = 1.0;
    var scoreBonus = 0;
    switch (modifier.op) {
      case 'chips_bonus':
        chipsBonus =
            _confirmModifierUnitCount(modifier, scoringTiles) *
            modifier.amount.round();
      case 'mult_bonus':
        multBonus =
            _confirmModifierUnitCount(modifier, scoringTiles) *
            modifier.amount.round();
      case 'xmult_bonus':
        xmultBonus = modifier.amount <= 0 ? 1.0 : modifier.amount;
      case 'temporary_overlap_cap_bonus':
        xmultBonus = 1 + modifier.amount;
      case 'add_percent_of_first_confirm_score':
        scoreBonus = (firstConfirmScoreThisStation * modifier.percent).round();
      default:
        return null;
    }

    final nextScore = scoreBonus > 0
        ? lineScore + scoreBonus
        : _composeScore(
            baseScore: lineScore,
            chipsBonus: chipsBonus,
            multBonus: multBonus,
            xmultBonus: xmultBonus,
          );
    final delta = max(0, nextScore - lineScore);
    if (delta <= 0) return null;
    return (
      score: nextScore,
      effect: RummiJesterEffectBreakdown(
        jesterId: modifier.itemId,
        displayName: modifier.itemId,
        chipsBonus: chipsBonus + scoreBonus,
        multBonus: multBonus,
        xmultBonus: xmultBonus,
        scoreDelta: delta,
      ),
    );
  }

  bool _confirmModifierMatches(
    RummiConfirmModifier modifier, {
    required RummiHandRank rank,
    required List<Tile> scoringTiles,
    required int lineIndex,
    required int confirmOrdinal,
  }) {
    switch (modifier.timing) {
      case 'next_confirm':
        return true;
      case 'next_confirm_if_rank':
        return modifier.rank == rank;
      case 'next_confirm_if_rank_at_least':
        final threshold = modifier.rank;
        return threshold != null && rank.index >= threshold.index;
      case 'next_confirm_per_tile_color':
        final color = modifier.tileColor;
        return color != null && scoringTiles.any((tile) => tile.color == color);
      case 'next_confirm_per_repeated_rank_tile':
        return _repeatedRankTileCount(scoringTiles) > 0;
      case 'first_confirm_each_station':
        return confirmOrdinal == 1;
      case 'first_scored_tile_each_station':
        return confirmOrdinal == 1 && lineIndex == 0;
      case 'on_confirm_if_played_hand_size_lte':
        final maxTiles = modifier.maxTiles;
        return maxTiles != null && scoringTiles.length <= maxTiles;
      case 'second_confirm_each_station':
        return confirmOrdinal == 2 && firstConfirmScoreThisStation > 0;
      default:
        return false;
    }
  }

  int _confirmModifierUnitCount(
    RummiConfirmModifier modifier,
    List<Tile> scoringTiles,
  ) {
    return switch (modifier.timing) {
      'next_confirm_per_tile_color' =>
        scoringTiles.where((tile) => tile.color == modifier.tileColor).length,
      'next_confirm_per_repeated_rank_tile' => _repeatedRankTileCount(
        scoringTiles,
      ),
      _ => 1,
    };
  }

  static int _repeatedRankTileCount(List<Tile> tiles) {
    final counts = <int, int>{};
    for (final tile in tiles) {
      counts.update(tile.number, (value) => value + 1, ifAbsent: () => 1);
    }
    return tiles.where((tile) => (counts[tile.number] ?? 0) >= 2).length;
  }

  static int _composeScore({
    required int baseScore,
    required int chipsBonus,
    required int multBonus,
    required double xmultBonus,
  }) {
    final chips = baseScore + chipsBonus;
    if (chips <= 0) return 0;
    final multFactor = 1 + (multBonus / 20.0);
    return max(0, (chips * multFactor * xmultBonus).round());
  }

  _ScoringLineCandidate _buildScoringLineCandidate({
    required LineRef ref,
    required HandEvaluation evaluation,
  }) {
    final lineCells = ref.cells();
    final contributingCells = <(int, int)>[];
    final scoringTiles = <Tile>[];
    for (final index in evaluation.contributingIndexes) {
      if (index < 0 || index >= lineCells.length) continue;
      final (row, col) = lineCells[index];
      final tile = board.cellAt(row, col);
      if (tile == null) continue;
      contributingCells.add((row, col));
      scoringTiles.add(tile);
    }
    return _ScoringLineCandidate(
      ref: ref,
      evaluation: evaluation,
      contributingCells: List<(int, int)>.unmodifiable(contributingCells),
      scoringTiles: List<Tile>.unmodifiable(scoringTiles),
    );
  }

  static double _overlapMultiplierForCount(
    int contributionCount, {
    required RummiRuleset ruleset,
  }) {
    final overlapCount = max(1, contributionCount);
    return min(
      1 + (ruleset.overlapAlpha * (overlapCount - 1)),
      ruleset.overlapMultiplierCap,
    );
  }
}

enum DiscardFailReason {
  noBoardDiscardsLeft,
  noHandDiscardsLeft,
  cellEmpty,
  tileNotInHand,
}

enum BoardMoveFailReason {
  noBoardMovesLeft,
  sourceCellEmpty,
  destinationOccupied,
}

enum BoardMoveUndoFailReason { noMoveHistory, sourceOccupied, destinationEmpty }

class _ScoringLineCandidate {
  const _ScoringLineCandidate({
    required this.ref,
    required this.evaluation,
    required this.contributingCells,
    required this.scoringTiles,
  });

  final LineRef ref;
  final HandEvaluation evaluation;
  final List<(int, int)> contributingCells;
  final List<Tile> scoringTiles;
}
