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

/// 숫자 1~13 + 색. 덱 장수는 `(4색 × 13랭크 × copiesPerTile)`로 결정된다.
/// [id]는 `copiesPerTile > 1` 인 경우까지 포함해 물리 복제 타일 구분용이다.
class Tile {
  const Tile({
    required this.color,
    required this.number,
    this.id = 0,
  }) : assert(number >= 1 && number <= 13);

  final TileColor color;
  final int number;

  /// 덱·보드에서 동일 물리 타일 구분용 (선택).
  final int id;

  String get code => '${color.code}$number';

  Map<String, dynamic> toJson() => {
    'color': color.name,
    'number': number,
    'id': id,
  };

  static Tile fromJson(Map<String, dynamic> json) {
    return Tile(
      color: TileColor.values.byName(json['color'] as String),
      number: (json['number'] as num).toInt(),
      id: (json['id'] as num?)?.toInt() ?? 0,
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
