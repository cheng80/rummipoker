import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../logic/rummi_poker_grid/hand_rank.dart';
import '../../../logic/rummi_poker_grid/models/tile.dart';
import '../../../logic/rummi_poker_grid/models/poker_deck.dart';
import '../../../logic/rummi_poker_grid/rummi_hand_growth.dart';
import '../../../resources/asset_paths.dart';
import '../../../utils/common_ui.dart';
import 'game_cashout_widgets.dart';
import 'game_shared_widgets.dart';

Future<void> showGameRunInfoDialog({
  required BuildContext context,
  required Map<RummiHandRank, int> playedHandCounts,
  List<Tile> addedDeckTiles = const [],
}) {
  return showGameFramedDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => GameModalCard(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 560),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    context.tr('runInfoTitle'),
                    style: TextStyle(
                      fontFamily: AssetPaths.fontNexonLv2Gothic,
                      color: Colors.white.withValues(alpha: 0.96),
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                GameIconButtonChip(
                  tooltip: context.tr('cancel'),
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  icon: Icons.close_rounded,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _RunInfoDeckSummary(addedDeckTiles: addedDeckTiles),
                    const SizedBox(height: 8),
                    for (final row in _buildRunInfoRows(playedHandCounts))
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: _RunInfoRankRow(row: row),
                      ),
                    ..._buildHiddenRunInfoRows(playedHandCounts).map(
                      (row) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: _RunInfoRankRow(row: row),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

List<_RunInfoRankRowData> _buildHiddenRunInfoRows(
  Map<RummiHandRank, int> playedHandCounts,
) {
  final rows = [
    for (final rank in RummiHandGrowth.hiddenRanks)
      if (RummiHandGrowth.completedCountFor(playedHandCounts, rank) > 0)
        _RunInfoRankRowData.fromRank(
          rank: rank,
          completedCount: RummiHandGrowth.completedCountFor(
            playedHandCounts,
            rank,
          ),
        ),
  ];
  rows.sort((a, b) => b.currentScore.compareTo(a.currentScore));
  return rows;
}

List<_RunInfoRankRowData> _buildRunInfoRows(
  Map<RummiHandRank, int> playedHandCounts,
) {
  final rows = [
    for (final rank in RummiHandGrowth.scoringRanks)
      _RunInfoRankRowData.fromRank(
        rank: rank,
        completedCount: RummiHandGrowth.completedCountFor(
          playedHandCounts,
          rank,
        ),
      ),
  ];
  rows.sort((a, b) {
    final completedCompare = b.completedCount.compareTo(a.completedCount);
    if (completedCompare != 0) return completedCompare;
    final scoreCompare = b.currentScore.compareTo(a.currentScore);
    if (scoreCompare != 0) return scoreCompare;
    return RummiHandGrowth.scoringRanks
        .indexOf(a.rank)
        .compareTo(RummiHandGrowth.scoringRanks.indexOf(b.rank));
  });
  return rows;
}

class _RunInfoRankRowData {
  const _RunInfoRankRowData({
    required this.rank,
    required this.completedCount,
    required this.level,
    required this.currentScore,
    required this.nextScore,
  });

  factory _RunInfoRankRowData.fromRank({
    required RummiHandRank rank,
    required int completedCount,
  }) {
    final baseScore = gddBaseScore(rank);
    final level = RummiHandGrowth.levelForCompletedCount(rank, completedCount);
    return _RunInfoRankRowData(
      rank: rank,
      completedCount: completedCount,
      level: level,
      currentScore: RummiHandGrowth.grownBaseScoreFor(
        rank: rank,
        baseScore: baseScore,
        completedCount: completedCount,
      ),
      nextScore: RummiHandGrowth.grownBaseScoreFor(
        rank: rank,
        baseScore: baseScore,
        completedCount: completedCount + 1,
      ),
    );
  }

  final RummiHandRank rank;
  final int completedCount;
  final int level;
  final int currentScore;
  final int nextScore;
}

class _RunInfoRankRow extends StatelessWidget {
  const _RunInfoRankRow({required this.row});

  final _RunInfoRankRowData row;

  @override
  Widget build(BuildContext context) {
    final accent = row.completedCount > 0
        ? const Color(0xFFF2C14E)
        : const Color(0xFF8FAFA4);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF12362D),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: accent.withValues(alpha: 0.45)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          children: [
            SizedBox(
              width: 54,
              child: Text(
                context.tr(
                  'runInfoRankLevel',
                  namedArgs: {'level': '${row.level}'},
                ),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: accent,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    gameHandRankLabel(row.rank),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.94),
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    context.tr(
                      'runInfoCompletedCount',
                      namedArgs: {'count': '${row.completedCount}'},
                    ),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.62),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 82,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${row.currentScore}',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.95),
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    context.tr(
                      'runInfoNextScore',
                      namedArgs: {'score': '${row.nextScore}'},
                    ),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.58),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RunInfoDeckSummary extends StatelessWidget {
  const _RunInfoDeckSummary({required this.addedDeckTiles});

  final List<Tile> addedDeckTiles;

  @override
  Widget build(BuildContext context) {
    final summary = addedDeckTiles.isEmpty
        ? '기본 덱 $kBasePokerTileCount장'
        : '덱 ${kBasePokerTileCount + addedDeckTiles.length}장 · 추가 ${addedDeckTiles.length}장';
    final tileText = addedDeckTiles.isEmpty
        ? '추가 타일 없음'
        : addedDeckTiles
              .map((tile) => '${tile.color.code}${tile.number}')
              .join(' ');
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF0F2F29),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFF6BAF9B).withValues(alpha: 0.45),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              summary,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.94),
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              tileText,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.62),
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
