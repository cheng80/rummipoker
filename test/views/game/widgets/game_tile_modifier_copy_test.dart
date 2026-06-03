import 'package:flutter_test/flutter_test.dart';
import 'package:rummipoker/logic/rummi_poker_grid/models/tile.dart';
import 'package:rummipoker/views/game/widgets/game_shared_widgets.dart';

void main() {
  group('tile modifier copy', () {
    test('every persisted modifier has concrete display and effect text', () {
      const blockedCopy = ['예정', '준비 중'];

      for (final enhancement in TileEnhancement.values) {
        final values = [
          tileEnhancementShortLabel(enhancement),
          tileEnhancementDisplayName(enhancement),
          tileEnhancementEffectText(enhancement),
        ];
        for (final value in values) {
          expect(value.trim(), isNotEmpty, reason: enhancement.name);
          for (final blocked in blockedCopy) {
            expect(value, isNot(contains(blocked)), reason: enhancement.name);
          }
        }
      }

      for (final seal in TileSeal.values) {
        final values = [
          tileSealShortLabel(seal),
          tileSealDisplayName(seal),
          tileSealEffectText(seal),
        ];
        for (final value in values) {
          expect(value.trim(), isNotEmpty, reason: seal.name);
          for (final blocked in blockedCopy) {
            expect(value, isNot(contains(blocked)), reason: seal.name);
          }
        }
      }

      for (final edition in TileEdition.values) {
        final values = [
          tileEditionShortLabel(edition),
          tileEditionDisplayName(edition),
          tileEditionEffectText(edition),
        ];
        for (final value in values) {
          expect(value.trim(), isNotEmpty, reason: edition.name);
          for (final blocked in blockedCopy) {
            expect(value, isNot(contains(blocked)), reason: edition.name);
          }
        }
      }
    });
  });
}
