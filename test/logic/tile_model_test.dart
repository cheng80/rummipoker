import 'package:flutter_test/flutter_test.dart';
import 'package:rummipoker/logic/rummi_poker_grid/models/tile.dart';

void main() {
  group('Tile modifier persistence', () {
    test('legacy tile json restores without modifiers', () {
      final tile = Tile.fromJson(const {'color': 'red', 'number': 7, 'id': 2});

      expect(tile.color, TileColor.red);
      expect(tile.number, 7);
      expect(tile.id, 2);
      expect(tile.enhancement, isNull);
      expect(tile.seal, isNull);
      expect(tile.hasModifier, isFalse);
      expect(tile.toJson(), const {'color': 'red', 'number': 7, 'id': 2});
    });

    test('enhancement seal and edition survive json roundtrip', () {
      const tile = Tile(
        color: TileColor.blue,
        number: 11,
        id: 3,
        enhancement: TileEnhancement.glassTile,
        seal: TileSeal.blueSeal,
        edition: TileEdition.prismEdition,
      );

      final restored = Tile.fromJson(tile.toJson());

      expect(restored.color, TileColor.blue);
      expect(restored.number, 11);
      expect(restored.id, 3);
      expect(restored.enhancement, TileEnhancement.glassTile);
      expect(restored.seal, TileSeal.blueSeal);
      expect(restored.edition, TileEdition.prismEdition);
      expect(restored.hasModifier, isTrue);
      expect(restored.toJson(), {
        'color': 'blue',
        'number': 11,
        'id': 3,
        'enhancement': 'glass_tile',
        'seal': 'blue_seal',
        'edition': 'prism_edition',
      });
    });

    test('all persisted modifier values survive json roundtrip', () {
      for (final enhancement in TileEnhancement.values) {
        final restored = Tile.fromJson(
          Tile(
            color: TileColor.red,
            number: 1,
            enhancement: enhancement,
          ).toJson(),
        );
        expect(restored.enhancement, enhancement, reason: enhancement.name);
      }

      for (final seal in TileSeal.values) {
        final restored = Tile.fromJson(
          Tile(color: TileColor.blue, number: 2, seal: seal).toJson(),
        );
        expect(restored.seal, seal, reason: seal.name);
      }

      for (final edition in TileEdition.values) {
        final restored = Tile.fromJson(
          Tile(color: TileColor.yellow, number: 3, edition: edition).toJson(),
        );
        expect(restored.edition, edition, reason: edition.name);
      }

      expect(TileSeal.fromPersistenceValue('risk_seal'), TileSeal.fractureSeal);
      expect(TileSeal.fromPersistenceValue('riskSeal'), TileSeal.fractureSeal);
    });

    test('physical equality ignores modifiers', () {
      const base = Tile(color: TileColor.red, number: 7, id: 1);
      const enhanced = Tile(
        color: TileColor.red,
        number: 7,
        id: 1,
        enhancement: TileEnhancement.chipInlaid,
        edition: TileEdition.silverEdition,
      );

      expect(enhanced, base);
      expect(enhanced.hashCode, base.hashCode);
    });
  });
}
