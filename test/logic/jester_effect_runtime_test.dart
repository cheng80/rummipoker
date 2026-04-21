import 'package:flutter_test/flutter_test.dart';
import 'package:rummipoker/logic/rummi_poker_grid/hand_rank.dart';
import 'package:rummipoker/logic/rummi_poker_grid/jester_effect_runtime.dart';
import 'package:rummipoker/logic/rummi_poker_grid/jester_meta.dart';
import 'package:rummipoker/logic/rummi_poker_grid/models/tile.dart';

void main() {
  group('JesterEffectRuntime', () {
    test('applyToLine delegates score effect and emits animation event', () {
      const jester = RummiJesterCard(
        id: 'flat_chips',
        displayName: 'Flat Chips',
        rarity: RummiJesterRarity.common,
        baseCost: 3,
        effectText: '',
        effectType: 'chips_bonus',
        trigger: 'onScore',
        conditionType: 'none',
        conditionValue: null,
        value: 5,
        xValue: null,
        mappedTileColors: [],
        mappedTileNumbers: [],
      );

      final result = JesterEffectRuntime.applyToLine(
        slotIndex: 1,
        jester: jester,
        rank: RummiHandRank.flush,
        baseScore: 20,
        scoringTiles: const [
          Tile(id: 1, color: TileColor.red, number: 1),
          Tile(id: 2, color: TileColor.red, number: 7),
        ],
        context: const RummiJesterScoreContext(
          discardsRemaining: 2,
          cardsRemainingInDeck: 30,
          ownedJesterCount: 2,
          maxJesterSlots: 5,
        ),
      );

      expect(result.score.chipsBonus, 5);
      expect(result.score.finalScore, 25);
      expect(result.scoreDelta, 5);
      expect(result.events.length, 1);
      expect(result.events.single.kind, JesterEffectEventKind.scoreApplied);
      expect(result.events.single.jesterId, 'flat_chips');
      expect(result.events.single.slotIndex, 1);
      expect(result.events.single.scoreDelta, 5);
    });

    test('applyToLine emits no event when no score delta is produced', () {
      const jester = RummiJesterCard(
        id: 'pair_only',
        displayName: 'Pair Only',
        rarity: RummiJesterRarity.common,
        baseCost: 3,
        effectText: '',
        effectType: 'chips_bonus',
        trigger: 'onScore',
        conditionType: 'pair',
        conditionValue: null,
        value: 5,
        xValue: null,
        mappedTileColors: [],
        mappedTileNumbers: [],
      );

      final result = JesterEffectRuntime.applyToLine(
        slotIndex: 0,
        jester: jester,
        rank: RummiHandRank.highCard,
        baseScore: 0,
        scoringTiles: const [Tile(id: 1, color: TileColor.red, number: 1)],
        context: const RummiJesterScoreContext(
          discardsRemaining: 2,
          cardsRemainingInDeck: 30,
          ownedJesterCount: 2,
          maxJesterSlots: 5,
        ),
      );

      expect(result.scoreDelta, 0);
      expect(result.events, isEmpty);
    });
  });
}
