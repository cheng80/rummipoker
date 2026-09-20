part of '../game_view.dart';

bool _isValidRitualTileTarget(
  ItemDefinition item,
  RummiScoringLineSummary line,
  Tile tile,
  (int, int) cell,
) {
  return switch (item.effect.value('ritualAction')?.toString()) {
    'prune_line_to_color' => line.lineTiles.any(
      (candidate) => candidate.color != tile.color,
    ),
    'copy_selected' when item.id == 'sealed_copy' =>
      tile.seal != null || tile.enhancement != null,
    'copy_selected' when item.id == 'edge_copy' => _isLineEndpoint(
      line.ref,
      cell,
    ),
    _ => true,
  };
}

bool _isLineEndpoint(LineRef ref, (int, int) cell) {
  final cells = ref.cells();
  return cell == cells.first || cell == cells.last;
}

bool _isFateLineTransformDefinition(ItemDefinition item) {
  return switch (item.effect.value('ritualAction')?.toString()) {
    'fate_royal_flush' ||
    'fate_straight_flush_high' ||
    'fate_straight_flush_low' ||
    'fate_four_kind_high' ||
    'fate_four_kind_low' ||
    'fate_full_house_high' ||
    'fate_full_house_low' ||
    'fate_flush_house' ||
    'fate_flush_five' ||
    'fate_flush_high' ||
    'fate_flush_low' ||
    'fate_straight_high' ||
    'fate_straight_low' ||
    'fate_three_kind_high' ||
    'fate_three_kind_low' ||
    'fate_two_pair_high' => true,
    _ => false,
  };
}

String _ritualSelectionPreviewText(
  BuildContext context,
  ItemDefinition item,
  RummiScoringLineSummary line,
  Tile? selectedTile,
) {
  final action = item.effect.value('ritualAction')?.toString();
  final centerCell = line.ref.cells()[2];
  final centerIndex = line.contributingCells.indexWhere(
    (cell) => cell == centerCell,
  );
  final centerTile = centerIndex >= 0 && centerIndex < line.scoringTiles.length
      ? line.scoringTiles[centerIndex]
      : null;
  final chosenTileText = selectedTile == null
      ? context.translate('battleSelectedScoreTile')
      : context.translate(
          'battleScoreTile',
          namedArgs: {'tile': selectedTile.code},
        );
  final centerTileText = centerTile == null
      ? context.translate('battleCenterScoreTile')
      : context.translate(
          'battleCenterTile',
          namedArgs: {'tile': centerTile.code},
        );
  return switch (action) {
    'prune_line_to_color' =>
      selectedTile == null
          ? context.translate('battlePrunePreview')
          : context.translate(
              'battlePruneColorPreview',
              namedArgs: {'color': _colorLabel(context, selectedTile.color)},
            ),
    'burn_line' => context.translate('battleBurnPreview'),
    'sacrifice_line' => context.translate('battleSacrificePreview'),
    'copy_center' => context.translate(
      'battleCopyTilePreview',
      namedArgs: {'tile': centerTileText},
    ),
    'copy_selected' => context.translate(
      'battleCopyTilePreview',
      namedArgs: {'tile': chosenTileText},
    ),
    'copy_color' => context.translate(
      'battleCopyColorPreview',
      namedArgs: {'tile': chosenTileText},
    ),
    'copy_rank' => context.translate(
      'battleCopyNumberPreview',
      namedArgs: {'tile': chosenTileText},
    ),
    'copy_endpoint' => context.translate(
      'battleCopyEndpointPreview',
      namedArgs: {'tile': chosenTileText},
    ),
    'growth_marker' => context.translate(
      'battleGrowthMarkerPreview',
      namedArgs: {'tile': chosenTileText},
    ),
    _ => _fateLinePreviewText(context, item, line),
  };
}

String _fateLinePreviewText(
  BuildContext context,
  ItemDefinition item,
  RummiScoringLineSummary line,
) {
  final action = item.effect.value('ritualAction')?.toString();
  final high = _tileByNumberForPreview(line.lineTiles, preferHigh: true);
  final low = _tileByNumberForPreview(line.lineTiles, preferHigh: false);
  final royalAnchor = _royalAnchorTileForPreview(line.lineTiles);
  String tileText(Tile? tile) => tile == null
      ? context.translate('battleNoAnchor')
      : context.translate(
          'battleColorNumber',
          namedArgs: {
            'color': _colorLabel(context, tile.color),
            'number': '${tile.number}',
          },
        );
  return switch (action) {
    'fate_royal_flush' => context.translate(
      'battleRoyalPreview',
      namedArgs: {'tile': tileText(royalAnchor)},
    ),
    'fate_straight_flush_high' => context.translate(
      'battleStraightFlushHighPreview',
      namedArgs: {'tile': tileText(high)},
    ),
    'fate_straight_flush_low' => context.translate(
      'battleStraightFlushLowPreview',
      namedArgs: {'tile': tileText(low)},
    ),
    'fate_four_kind_high' => context.translate(
      'battleFourHighPreview',
      namedArgs: {'number': '${high?.number ?? '-'}'},
    ),
    'fate_four_kind_low' => context.translate(
      'battleFourLowPreview',
      namedArgs: {'number': '${low?.number ?? '-'}'},
    ),
    'fate_full_house_high' => context.translate('battleFullHouseHighPreview'),
    'fate_full_house_low' => context.translate('battleFullHouseLowPreview'),
    'fate_flush_house' => context.translate('battleFlushHousePreview'),
    'fate_flush_five' => context.translate('battleFlushFivePreview'),
    'fate_flush_high' => context.translate(
      'battleFlushHighPreview',
      namedArgs: {'tile': tileText(high)},
    ),
    'fate_flush_low' => context.translate(
      'battleFlushLowPreview',
      namedArgs: {'tile': tileText(low)},
    ),
    'fate_straight_high' => context.translate(
      'battleStraightHighPreview',
      namedArgs: {'tile': tileText(high)},
    ),
    'fate_straight_low' => context.translate(
      'battleStraightLowPreview',
      namedArgs: {'tile': tileText(low)},
    ),
    'fate_three_kind_high' => context.translate(
      'battleThreeHighPreview',
      namedArgs: {'number': '${high?.number ?? '-'}'},
    ),
    'fate_three_kind_low' => context.translate('battleThreeLowPreview'),
    'fate_two_pair_high' => context.translate('battleTwoPairPreview'),
    _ => context.translate('battleFatePreview'),
  };
}

Tile? _tileByNumberForPreview(List<Tile> tiles, {required bool preferHigh}) {
  if (tiles.isEmpty) return null;
  return tiles.reduce((a, b) {
    final compare = a.number.compareTo(b.number);
    if (compare == 0) return a;
    return preferHigh ? (compare > 0 ? a : b) : (compare < 0 ? a : b);
  });
}

Tile? _royalAnchorTileForPreview(List<Tile> tiles) {
  for (final tile in tiles) {
    if (tile.number == 1) return tile;
  }
  return _tileByNumberForPreview(tiles, preferHigh: true);
}

String _lineLabel(BuildContext context, LineRef ref) {
  return switch (ref.kind) {
    LineKind.row => context.translate(
      'battleLineRow',
      namedArgs: {'index': '${ref.index + 1}'},
    ),
    LineKind.col => context.translate(
      'battleLineColumn',
      namedArgs: {'index': '${ref.index + 1}'},
    ),
    LineKind.diagMain => context.translate('battleLineDiagMain'),
    LineKind.diagAnti => context.translate('battleLineDiagAnti'),
  };
}

String _rankLabel(BuildContext context, RummiScoringLineSummary line) {
  if (!line.isScoringLine) return context.translate('battleNoScoringLine');
  return context.translate(rummiHandRankKey(line.rank));
}

String _colorLabel(BuildContext context, TileColor color) {
  return switch (color) {
    TileColor.red => context.translate('battleColorRed'),
    TileColor.blue => context.translate('battleColorBlue'),
    TileColor.yellow => context.translate('battleColorYellow'),
    TileColor.black => context.translate('battleColorBlack'),
  };
}
