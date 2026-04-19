import 'hand_rank.dart';
import 'models/board.dart';
import 'models/poker_deck.dart';
import 'rummi_poker_grid_session.dart';

/// Current build line count: rows 5 + cols 5 + diagonals 2.
const int kCurrentEvaluationLineCount = 12;

/// Lightweight ruleset/config skeleton for future migration work.
///
/// Important:
/// - This file does not change current runtime behavior.
/// - It mirrors the current baseline so future adapter/config work has a
///   single, explicit source of default combat constants.
class RummiRuleset {
  const RummiRuleset({
    required this.boardSize,
    required this.evaluationLineCount,
    required this.copiesPerTile,
    required this.defaultMaxHandSize,
    required this.minDebugMaxHandSize,
    required this.maxDebugMaxHandSize,
    required this.defaultBoardDiscards,
    required this.defaultHandDiscards,
    required this.overlapAlpha,
    required this.overlapMultiplierCap,
    required this.instantConfirmAllScoringLines,
    required this.removeContributorUnionOnly,
    required this.wheelStraightAllowed,
    required this.highCardIsDeadLine,
    required this.onePairIsDeadLine,
  });

  final int boardSize;
  final int evaluationLineCount;
  final int copiesPerTile;
  final int defaultMaxHandSize;
  final int minDebugMaxHandSize;
  final int maxDebugMaxHandSize;
  final int defaultBoardDiscards;
  final int defaultHandDiscards;
  final double overlapAlpha;
  final double overlapMultiplierCap;
  final bool instantConfirmAllScoringLines;
  final bool removeContributorUnionOnly;
  final bool wheelStraightAllowed;
  final bool highCardIsDeadLine;
  final bool onePairIsDeadLine;

  static const RummiRuleset currentDefaults = RummiRuleset(
    boardSize: kBoardSize,
    evaluationLineCount: kCurrentEvaluationLineCount,
    copiesPerTile: kDefaultCopiesPerTile,
    defaultMaxHandSize: RummiPokerGridSession.kDefaultMaxHandSize,
    minDebugMaxHandSize: RummiPokerGridSession.kMinDebugMaxHandSize,
    maxDebugMaxHandSize: RummiPokerGridSession.kMaxDebugMaxHandSize,
    defaultBoardDiscards: 4,
    defaultHandDiscards: 2,
    overlapAlpha: RummiPokerGridSession.kOverlapAlpha,
    overlapMultiplierCap: RummiPokerGridSession.kOverlapMultiplierCap,
    instantConfirmAllScoringLines: true,
    removeContributorUnionOnly: true,
    wheelStraightAllowed: true,
    highCardIsDeadLine: true,
    onePairIsDeadLine: true,
  );

  int baseScoreFor(RummiHandRank rank) => gddBaseScore(rank);
}
