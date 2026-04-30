import 'models/tile.dart';

enum RummiBossModifierCategory { tileColorWeaken }

class RummiBossModifier {
  const RummiBossModifier({
    required this.id,
    required this.category,
    required this.title,
    required this.ruleText,
    required this.markerText,
    required this.affectedTileColors,
    required this.scoreMultiplier,
  });

  factory RummiBossModifier.fromJson(Map<String, dynamic> json) {
    final id = json['id'] as String?;
    if (id == redDampener.id) return redDampener;
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
      scoreMultiplier:
          (json['scoreMultiplier'] as num?)?.toDouble() ??
          redDampener.scoreMultiplier,
    );
  }

  static const redDampener = RummiBossModifier(
    id: 'red_dampener_v1',
    category: RummiBossModifierCategory.tileColorWeaken,
    title: '빨간 타일 약화',
    ruleText: '빨간 타일이 포함된 점수 라인은 절반만 적용됩니다.',
    markerText: '약화',
    affectedTileColors: [TileColor.red],
    scoreMultiplier: 0.5,
  );

  final String id;
  final RummiBossModifierCategory category;
  final String title;
  final String ruleText;
  final String markerText;
  final List<TileColor> affectedTileColors;
  final double scoreMultiplier;

  bool affectsTile(Tile tile) => affectedTileColors.contains(tile.color);

  bool affectsAnyTile(Iterable<Tile> tiles) => tiles.any(affectsTile);

  Map<String, dynamic> toJson() => {
    'id': id,
    'category': category.name,
    'title': title,
    'ruleText': ruleText,
    'markerText': markerText,
    'affectedTileColors': [for (final color in affectedTileColors) color.name],
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
  });

  final String modifierId;
  final String title;
  final String ruleText;
  final String markerText;
  final int scoreDelta;
  final double scoreMultiplier;
  final List<TileColor> affectedTileColors;
}
