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
      ? '선택한 점수 타일'
      : '${selectedTile.code} 점수 타일';
  final centerTileText = centerTile == null
      ? '중앙 점수 타일'
      : '${centerTile.code} 중앙 점수 타일';
  return switch (action) {
    'prune_line_to_color' =>
      selectedTile == null
          ? '선택 색이 아닌 타일을 제거하고 같은 색 타일을 덱 맨 위에 올립니다.'
          : '${_colorLabel(selectedTile.color)}기준: 다른 색 타일 제거 후 덱 위 보충.',
    'burn_line' => '선택한 줄을 지우고 골드 +3을 얻습니다.',
    'sacrifice_line' => '선택한 줄을 지우고 앞의 타일 2장을 덱 맨 위에 복사합니다.',
    'copy_center' => '$centerTileText 복사본을 덱 맨 위에 추가합니다.',
    'copy_selected' => '$chosenTileText 복사본을 덱 맨 위에 추가합니다.',
    'copy_color' => '$chosenTileText 색상과 같은 무작위 숫자 타일을 덱 맨 위에 추가합니다.',
    'copy_rank' => '$chosenTileText 숫자와 같은 무작위 색 타일을 덱 맨 위에 추가합니다.',
    'copy_endpoint' => '$chosenTileText 끝점 복사본을 덱 맨 위에 추가합니다.',
    'growth_marker' => '$chosenTileText에 교차 기억 표식을 붙입니다. 이후 겹친 줄 정산 시 추가 성장.',
    _ => _fateLinePreviewText(item, line),
  };
}

String _fateLinePreviewText(ItemDefinition item, RummiScoringLineSummary line) {
  final action = item.effect.value('ritualAction')?.toString();
  final high = _tileByNumberForPreview(line.lineTiles, preferHigh: true);
  final low = _tileByNumberForPreview(line.lineTiles, preferHigh: false);
  final royalAnchor = _royalAnchorTileForPreview(line.lineTiles);
  String tileText(Tile? tile) =>
      tile == null ? '기준 없음' : '${_colorLabel(tile.color)}${tile.number}';
  return switch (action) {
    'fate_royal_flush' =>
      '로얄 기준 ${tileText(royalAnchor)} 색상으로 10-11-12-13-1 로얄플러시 세트.',
    'fate_straight_flush_high' => '최고 기준 ${tileText(high)}에서 가능한 가장 높은 스티플 세트.',
    'fate_straight_flush_low' => '최저 기준 ${tileText(low)}에서 가능한 가장 낮은 스티플 세트.',
    'fate_four_kind_high' => '최고 숫자 ${high?.number ?? '-'} 포카드 세트.',
    'fate_four_kind_low' => '최저 숫자 ${low?.number ?? '-'} 포카드 세트.',
    'fate_full_house_high' => '최고 숫자 triple + 차순위 높은 숫자 pair 풀하우스 세트.',
    'fate_full_house_low' => '차순위 낮은 숫자 triple + 최고 숫자 pair 풀하우스 세트.',
    'fate_flush_house' => '최고 숫자 3장 + 차순위 높은 숫자 2장을 같은 색으로 만드는 플러시 하우스 세트.',
    'fate_flush_five' => '최고 숫자 5장을 같은 색으로 만드는 플러시 파이브 세트.',
    'fate_flush_high' => '최고 기준 ${tileText(high)} 색상 플러시 세트.',
    'fate_flush_low' => '최저 기준 ${tileText(low)} 색상 플러시 세트.',
    'fate_straight_high' => '최고 기준 ${tileText(high)}에서 가능한 높은 스트레이트 세트.',
    'fate_straight_low' => '최저 기준 ${tileText(low)}에서 가능한 낮은 스트레이트 세트.',
    'fate_three_kind_high' => '최고 숫자 ${high?.number ?? '-'} 트리플 세트.',
    'fate_three_kind_low' => '차순위 낮은 숫자 트리플 세트.',
    'fate_two_pair_high' => '최고/차순위 높은 숫자 투페어 세트.',
    _ => '선택한 보드 선을 운명 세트로 변환합니다.',
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

String _lineLabel(LineRef ref) {
  return switch (ref.kind) {
    LineKind.row => '가로 ${ref.index + 1}',
    LineKind.col => '세로 ${ref.index + 1}',
    LineKind.diagMain => '대각 ↘',
    LineKind.diagAnti => '대각 ↙',
  };
}

String _rankLabel(RummiScoringLineSummary line) {
  if (!line.isScoringLine) return '미완성/무득점';
  return switch (line.rank) {
    RummiHandRank.twoPair => '투페어',
    RummiHandRank.threeOfAKind => '트리플',
    RummiHandRank.straight => '스트레이트',
    RummiHandRank.flush => '플러시',
    RummiHandRank.fullHouse => '풀하우스',
    RummiHandRank.fourOfAKind => '포카드',
    RummiHandRank.straightFlush => '스티플',
    RummiHandRank.prismStraight => '프리즘 스트레이트',
    RummiHandRank.crownFourOfAKind => '왕관 포카드',
    RummiHandRank.lowStraightFlush => '로우 스티플',
    RummiHandRank.royalStraightFlush => '로얄 스티플',
    RummiHandRank.fiveOfAKind => '파이브카드',
    RummiHandRank.flushHouse => '플러시 하우스',
    RummiHandRank.flushFive => '플러시 파이브',
    RummiHandRank.highCard => '하이카드',
    RummiHandRank.onePair => '원페어',
  };
}

String _colorLabel(TileColor color) {
  return switch (color) {
    TileColor.red => '빨강 ',
    TileColor.blue => '파랑 ',
    TileColor.yellow => '노랑 ',
    TileColor.black => '검정 ',
  };
}
