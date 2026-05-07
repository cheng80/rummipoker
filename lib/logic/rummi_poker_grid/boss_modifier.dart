import 'hand_rank.dart';
import 'line_ref.dart';
import 'models/tile.dart';

enum RummiBossModifierCategory {
  tileColorWeaken,
  lineKindWeaken,
  faceTileWeaken,
  allScoreWeaken,
  firstConfirmWeaken,
  confirmCountWeaken,
  repeatHandRankWeaken,
  singleHandRankPressure,
}

class RummiBossModifier {
  const RummiBossModifier({
    required this.id,
    required this.category,
    required this.title,
    required this.ruleText,
    required this.markerText,
    required this.scoreMultiplier,
    this.affectedTileColors = const [],
    this.affectedLineKinds = const [],
    this.firstAffectedConfirmOrdinal = 3,
  });

  factory RummiBossModifier.fromJson(Map<String, dynamic> json) {
    final id = json['id'] as String?;
    if (id == redDampener.id) return redDampener;
    if (id == blueDampener.id) return blueDampener;
    if (id == blackDampener.id) return blackDampener;
    if (id == yellowDampener.id) return yellowDampener;
    if (id == rowDampener.id) return rowDampener;
    if (id == columnDampener.id) return columnDampener;
    if (id == diagonalDampener.id) return diagonalDampener;
    if (id == faceDampener.id) return faceDampener;
    if (id == allScoreDampener.id) return allScoreDampener;
    if (id == firstConfirmTax.id) return firstConfirmTax;
    if (id == confirmCountTax.id) return confirmCountTax;
    if (id == confirmLimitTax.id) return confirmLimitTax;
    if (id == repeatRankPressure.id) return repeatRankPressure;
    if (id == singleRankPressure.id) return singleRankPressure;
    return RummiBossModifier(
      id: id ?? redDampener.id,
      category: RummiBossModifierCategory.values.byName(
        json['category'] as String? ?? redDampener.category.name,
      ),
      title: json['title'] as String? ?? redDampener.title,
      ruleText: json['ruleText'] as String? ?? redDampener.ruleText,
      markerText: json['markerText'] as String? ?? redDampener.markerText,
      affectedTileColors:
          (json['affectedTileColors'] as List<dynamic>?)
              ?.map((value) => TileColor.values.byName(value as String))
              .toList(growable: false) ??
          redDampener.affectedTileColors,
      affectedLineKinds:
          (json['affectedLineKinds'] as List<dynamic>?)
              ?.map((value) => LineKind.values.byName(value as String))
              .toList(growable: false) ??
          const [],
      scoreMultiplier:
          (json['scoreMultiplier'] as num?)?.toDouble() ??
          redDampener.scoreMultiplier,
      firstAffectedConfirmOrdinal:
          (json['firstAffectedConfirmOrdinal'] as num?)?.toInt() ?? 3,
    );
  }

  static const redDampener = RummiBossModifier(
    id: 'red_dampener_v1',
    category: RummiBossModifierCategory.tileColorWeaken,
    title: '빨간 타일 약화',
    ruleText: '빨간 타일이 포함된 점수 라인은 35% 감소합니다.',
    markerText: '약화',
    affectedTileColors: [TileColor.red],
    scoreMultiplier: 0.65,
  );

  static const rowDampener = RummiBossModifier(
    id: 'row_line_dampener_v1',
    category: RummiBossModifierCategory.lineKindWeaken,
    title: '가로줄 약화',
    ruleText: '가로줄 점수가 25% 감소합니다.',
    markerText: '약화',
    affectedLineKinds: [LineKind.row],
    scoreMultiplier: 0.75,
  );

  static const blueDampener = RummiBossModifier(
    id: 'blue_dampener_v1',
    category: RummiBossModifierCategory.tileColorWeaken,
    title: '파란 타일 약화',
    ruleText: '파란 타일이 포함된 점수 라인은 40% 감소합니다.',
    markerText: '약화',
    affectedTileColors: [TileColor.blue],
    scoreMultiplier: 0.6,
  );

  static const blackDampener = RummiBossModifier(
    id: 'black_dampener_v1',
    category: RummiBossModifierCategory.tileColorWeaken,
    title: '검은 타일 약화',
    ruleText: '검은 타일이 포함된 점수 라인은 40% 감소합니다.',
    markerText: '약화',
    affectedTileColors: [TileColor.black],
    scoreMultiplier: 0.6,
  );

  static const yellowDampener = RummiBossModifier(
    id: 'yellow_dampener_v1',
    category: RummiBossModifierCategory.tileColorWeaken,
    title: '노란 타일 약화',
    ruleText: '노란 타일이 포함된 점수 라인은 40% 감소합니다.',
    markerText: '약화',
    affectedTileColors: [TileColor.yellow],
    scoreMultiplier: 0.6,
  );

  static const columnDampener = RummiBossModifier(
    id: 'column_line_dampener_v1',
    category: RummiBossModifierCategory.lineKindWeaken,
    title: '세로줄 약화',
    ruleText: '세로줄 점수가 25% 감소합니다.',
    markerText: '약화',
    affectedLineKinds: [LineKind.col],
    scoreMultiplier: 0.75,
  );

  static const diagonalDampener = RummiBossModifier(
    id: 'diagonal_line_dampener_v1',
    category: RummiBossModifierCategory.lineKindWeaken,
    title: '대각선 약화',
    ruleText: '대각선 점수가 25% 감소합니다.',
    markerText: '약화',
    affectedLineKinds: [LineKind.diagMain, LineKind.diagAnti],
    scoreMultiplier: 0.75,
  );

  static const faceDampener = RummiBossModifier(
    id: 'face_tile_dampener_v1',
    category: RummiBossModifierCategory.faceTileWeaken,
    title: '그림 타일 약화',
    ruleText: '11~13 타일이 포함된 점수 라인은 35% 감소합니다.',
    markerText: '약화',
    scoreMultiplier: 0.65,
  );

  static const allScoreDampener = RummiBossModifier(
    id: 'all_score_dampener_v1',
    category: RummiBossModifierCategory.allScoreWeaken,
    title: '전체 점수 약화',
    ruleText: '모든 점수 라인이 20% 감소합니다.',
    markerText: '약화',
    scoreMultiplier: 0.8,
  );

  static const firstConfirmTax = RummiBossModifier(
    id: 'first_confirm_tax_v1',
    category: RummiBossModifierCategory.firstConfirmWeaken,
    title: '첫 확정 약화',
    ruleText: '첫 확정 점수 라인은 30% 감소합니다.',
    markerText: '첫확정',
    scoreMultiplier: 0.7,
  );

  static const confirmCountTax = RummiBossModifier(
    id: 'confirm_count_tax_v2',
    category: RummiBossModifierCategory.confirmCountWeaken,
    title: '누적 확정 약화',
    ruleText: '세 번째 확정부터 점수 라인이 25% 감소합니다.',
    markerText: '3+',
    scoreMultiplier: 0.75,
  );

  static const confirmLimitTax = RummiBossModifier(
    id: 'confirm_limit_tax_v1',
    category: RummiBossModifierCategory.confirmCountWeaken,
    title: '연속 확정 제한',
    ruleText: '두 번째 확정부터 점수 라인이 30% 감소합니다.',
    markerText: '2+',
    scoreMultiplier: 0.7,
    firstAffectedConfirmOrdinal: 2,
  );

  static const repeatRankPressure = RummiBossModifier(
    id: 'repeat_rank_pressure_v4',
    category: RummiBossModifierCategory.repeatHandRankWeaken,
    title: '반복 족보 약화',
    ruleText: '이전 확정에서 사용한 족보를 다시 확정하면 점수 라인이 20% 감소합니다.',
    markerText: '반복',
    scoreMultiplier: 0.8,
  );

  static const singleRankPressure = RummiBossModifier(
    id: 'single_rank_pressure',
    category: RummiBossModifierCategory.singleHandRankPressure,
    title: '첫 족보 제한',
    ruleText: '첫 확정 족보를 다시 확정하면 점수 라인이 30% 감소합니다.',
    markerText: '첫족보',
    scoreMultiplier: 0.7,
  );

  final String id;
  final RummiBossModifierCategory category;
  final String title;
  final String ruleText;
  final String markerText;
  final List<TileColor> affectedTileColors;
  final List<LineKind> affectedLineKinds;
  final double scoreMultiplier;
  final int firstAffectedConfirmOrdinal;

  bool affectsTile(Tile tile) {
    return affectedTileColors.contains(tile.color) ||
        (category == RummiBossModifierCategory.faceTileWeaken &&
            tile.number >= 11);
  }

  bool affectsAnyTile(Iterable<Tile> tiles) => tiles.any(affectsTile);

  bool affectsLineKind(LineKind kind) => affectedLineKinds.contains(kind);

  bool affectsConfirmOrdinal(int ordinal) {
    return switch (category) {
      RummiBossModifierCategory.firstConfirmWeaken => ordinal == 1,
      RummiBossModifierCategory.confirmCountWeaken =>
        ordinal >= firstAffectedConfirmOrdinal,
      _ => false,
    };
  }

  bool affectsRepeatedRank(
    RummiHandRank rank, {
    required Iterable<RummiHandRank> confirmedRanks,
  }) {
    return category == RummiBossModifierCategory.repeatHandRankWeaken &&
        confirmedRanks.contains(rank);
  }

  bool affectsFirstRankAgain(
    RummiHandRank rank, {
    required Iterable<RummiHandRank> confirmedRanks,
  }) {
    final firstRank = confirmedRanks.isEmpty ? null : confirmedRanks.first;
    return category == RummiBossModifierCategory.singleHandRankPressure &&
        firstRank != null &&
        rank == firstRank;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'category': category.name,
    'title': title,
    'ruleText': ruleText,
    'markerText': markerText,
    'affectedTileColors': [for (final color in affectedTileColors) color.name],
    'affectedLineKinds': [for (final kind in affectedLineKinds) kind.name],
    'scoreMultiplier': scoreMultiplier,
    'firstAffectedConfirmOrdinal': firstAffectedConfirmOrdinal,
  };
}

class RummiConstraintPenaltyBreakdown {
  const RummiConstraintPenaltyBreakdown({
    required this.modifierId,
    required this.title,
    required this.ruleText,
    required this.markerText,
    required this.scoreDelta,
    required this.scoreMultiplier,
    this.affectedTileColors = const [],
    this.affectedLineKinds = const [],
  });

  final String modifierId;
  final String title;
  final String ruleText;
  final String markerText;
  final int scoreDelta;
  final double scoreMultiplier;
  final List<TileColor> affectedTileColors;
  final List<LineKind> affectedLineKinds;
}
