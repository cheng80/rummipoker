/// 루미 타일 색 (🔴🔵🟡⚫).
enum TileColor {
  red('R'),
  blue('B'),
  yellow('Y'),
  black('K');

  const TileColor(this.code);
  final String code;

  int get sortOrder => switch (this) {
    TileColor.red => 0,
    TileColor.blue => 1,
    TileColor.yellow => 2,
    TileColor.black => 3,
  };
}

enum TileEnhancement {
  chipInlaid('chip_inlaid'),
  scoreGilded('score_gilded'),
  goldTile('gold_tile'),
  glassTile('glass_tile'),
  wildPainted('wild_painted'),
  luckyTile('lucky_tile');

  const TileEnhancement(this.persistenceValue);
  final String persistenceValue;

  static TileEnhancement? fromPersistenceValue(Object? value) {
    if (value is! String || value.isEmpty) return null;
    for (final enhancement in TileEnhancement.values) {
      if (enhancement.persistenceValue == value || enhancement.name == value) {
        return enhancement;
      }
    }
    return null;
  }
}

enum TileSeal {
  blueSeal('blue_seal'),
  redSeal('red_seal'),
  lineMark('line_mark'),
  growthSeal('growth_seal'),
  goldSeal('gold_seal'),
  echoSeal('echo_seal'),
  anchorSeal('anchor_seal'),
  riskSeal('risk_seal'),
  crossMemory('cross_memory'),
  bridgeSeal('bridge_seal');

  const TileSeal(this.persistenceValue);
  final String persistenceValue;

  static TileSeal? fromPersistenceValue(Object? value) {
    if (value is! String || value.isEmpty) return null;
    for (final seal in TileSeal.values) {
      if (seal.persistenceValue == value || seal.name == value) {
        return seal;
      }
    }
    return null;
  }
}

enum TileEdition {
  silverEdition('silver_edition'),
  glowEdition('glow_edition'),
  prismEdition('prism_edition');

  const TileEdition(this.persistenceValue);
  final String persistenceValue;

  static TileEdition? fromPersistenceValue(Object? value) {
    if (value is! String || value.isEmpty) return null;
    for (final edition in TileEdition.values) {
      if (edition.persistenceValue == value || edition.name == value) {
        return edition;
      }
    }
    return null;
  }
}

/// 숫자 1~13 + 색. 덱 장수는 `(4색 × 13랭크 × copiesPerTile)`로 결정된다.
/// [id]는 `copiesPerTile > 1` 인 경우까지 포함해 물리 복제 타일 구분용이다.
class Tile {
  const Tile({
    required this.color,
    required this.number,
    this.id = 0,
    this.enhancement,
    this.seal,
    this.edition,
  }) : assert(number >= 1 && number <= 13);

  final TileColor color;
  final int number;

  /// 덱·보드에서 동일 물리 타일 구분용 (선택).
  final int id;

  final TileEnhancement? enhancement;
  final TileSeal? seal;
  final TileEdition? edition;

  bool get hasModifier =>
      enhancement != null || seal != null || edition != null;

  String get code => '${color.code}$number';

  Tile copyWith({
    TileColor? color,
    int? number,
    int? id,
    TileEnhancement? enhancement,
    TileSeal? seal,
    TileEdition? edition,
  }) {
    return Tile(
      color: color ?? this.color,
      number: number ?? this.number,
      id: id ?? this.id,
      enhancement: enhancement ?? this.enhancement,
      seal: seal ?? this.seal,
      edition: edition ?? this.edition,
    );
  }

  /// UI에서 덱 타일의 기준 가치를 보여줄 때 쓰는 값이다.
  ///
  /// 현재 점수 공식은 족보 기본 칩을 쓰며, 이 값은 아직 확정 점수 계산에
  /// 직접 더하지 않는다.
  int get baseChipValue => number;

  Map<String, dynamic> toJson() => {
    'color': color.name,
    'number': number,
    'id': id,
    if (enhancement != null) 'enhancement': enhancement!.persistenceValue,
    if (seal != null) 'seal': seal!.persistenceValue,
    if (edition != null) 'edition': edition!.persistenceValue,
  };

  static Tile fromJson(Map<String, dynamic> json) {
    return Tile(
      color: TileColor.values.byName(json['color'] as String),
      number: (json['number'] as num).toInt(),
      id: (json['id'] as num?)?.toInt() ?? 0,
      enhancement: TileEnhancement.fromPersistenceValue(json['enhancement']),
      seal: TileSeal.fromPersistenceValue(json['seal']),
      edition: TileEdition.fromPersistenceValue(json['edition']),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is Tile &&
      other.color == color &&
      other.number == number &&
      other.id == id;

  @override
  int get hashCode => Object.hash(color, number, id);

  @override
  String toString() => id == 0 ? code : '$code#$id';
}
