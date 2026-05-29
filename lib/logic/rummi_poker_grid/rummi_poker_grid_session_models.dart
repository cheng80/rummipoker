part of 'rummi_poker_grid_session.dart';

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
    this.slideBonusTriggered = false,
  });

  factory BoardMoveRecord.fromJson(Map<String, dynamic> json) {
    return BoardMoveRecord(
      fromRow: (json['fromRow'] as num).toInt(),
      fromCol: (json['fromCol'] as num).toInt(),
      toRow: (json['toRow'] as num).toInt(),
      toCol: (json['toCol'] as num).toInt(),
      slideBonusTriggered: json['slideBonusTriggered'] as bool? ?? false,
    );
  }

  final int fromRow;
  final int fromCol;
  final int toRow;
  final int toCol;
  final bool slideBonusTriggered;

  Map<String, dynamic> toJson() => {
    'fromRow': fromRow,
    'fromCol': fromCol,
    'toRow': toRow,
    'toCol': toCol,
    'slideBonusTriggered': slideBonusTriggered,
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
    this.grownRankBaseScore,
    this.growthLevel = 0,
    this.growthBonus = 0,
    this.overlapMultiplier = 1.0,
    this.overlapBonus = 0,
    this.tileGoldBonus = 0,
    this.bonusRankProgress = 0,
    this.contributingCells = const [],
    this.constraintPenalties = const [],
  });

  final LineRef ref;
  final RummiHandRank rank;
  final int? rankBaseScore;
  final int? grownRankBaseScore;
  final int growthLevel;
  final int growthBonus;
  final int baseScore;
  final int finalScore;
  final int jesterBonus;
  final bool hasScoringFaceCard;
  final List<RummiJesterEffectBreakdown> effects;
  final double overlapMultiplier;
  final int overlapBonus;
  final int tileGoldBonus;
  final int bonusRankProgress;
  final List<(int, int)> contributingCells;
  final List<RummiConstraintPenaltyBreakdown> constraintPenalties;
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
