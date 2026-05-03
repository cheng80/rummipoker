import 'line_ref.dart';
import 'models/tile.dart';

enum RummiBossModifierCategory { tileColorWeaken, lineKindWeaken }

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
    );
  }

  static const redDampener = RummiBossModifier(
    id: 'red_dampener_v1',
    category: RummiBossModifierCategory.tileColorWeaken,
    title: '빨간 타일 약화',
    ruleText: '빨간 타일이 포함된 점수 라인은 40% 감소합니다.',
    markerText: '약화',
    affectedTileColors: [TileColor.red],
    scoreMultiplier: 0.6,
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

  final String id;
  final RummiBossModifierCategory category;
  final String title;
  final String ruleText;
  final String markerText;
  final List<TileColor> affectedTileColors;
  final List<LineKind> affectedLineKinds;
  final double scoreMultiplier;

  bool affectsTile(Tile tile) => affectedTileColors.contains(tile.color);

  bool affectsAnyTile(Iterable<Tile> tiles) => tiles.any(affectsTile);

  bool affectsLineKind(LineKind kind) => affectedLineKinds.contains(kind);

  Map<String, dynamic> toJson() => {
    'id': id,
    'category': category.name,
    'title': title,
    'ruleText': ruleText,
    'markerText': markerText,
    'affectedTileColors': [for (final color in affectedTileColors) color.name],
    'affectedLineKinds': [for (final kind in affectedLineKinds) kind.name],
    'scoreMultiplier': scoreMultiplier,
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
