import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rummipoker/logic/rummi_poker_grid/item_definition.dart';
import 'package:rummipoker/logic/rummi_poker_grid/jester_meta.dart';
import 'package:rummipoker/logic/rummi_poker_grid/models/tile.dart';

import '../integration_test/full_run_bot_market_policy.dart';

void main() {
  group('fullRunBotJesterScore', () {
    late RummiJesterCatalog catalog;

    setUpAll(() {
      catalog = RummiJesterCatalog.fromJsonString(
        File('data/common/jesters_common_phase5.json').readAsStringSync(),
      );
    });

    test('prefers late flush scoring over zero-stack ride in S8', () {
      final rideTheBus = catalog.findById('ride_the_bus')!;
      final drollJester = catalog.findById('droll_jester')!;

      expect(
        fullRunBotJesterScore(drollJester, stage: 8),
        greaterThan(fullRunBotJesterScore(rideTheBus, stage: 8)),
      );
    });

    test(
      'prefers color-scored Jester over zero-stack ride before final market',
      () {
        final rideTheBus = catalog.findById('ride_the_bus')!;
        final gluttonousJester = catalog.findById('gluttonous_jester')!;

        expect(
          fullRunBotJesterScore(gluttonousJester, stage: 7),
          greaterThan(fullRunBotJesterScore(rideTheBus, stage: 7)),
        );
      },
    );

    test('prefers flush scoring over broad clever scoring in S8', () {
      final cleverJester = catalog.findById('clever_jester')!;
      final drollJester = catalog.findById('droll_jester')!;

      expect(
        fullRunBotJesterScore(drollJester, stage: 8),
        greaterThan(fullRunBotJesterScore(cleverJester, stage: 8)),
      );
    });

    test(
      'keeps stacked ride valuable when it already survived confirmations',
      () {
        final rideTheBus = catalog.findById('ride_the_bus')!;
        final drollJester = catalog.findById('droll_jester')!;

        expect(
          fullRunBotJesterScore(rideTheBus, stage: 8, stateValue: 35),
          greaterThan(fullRunBotJesterScore(drollJester, stage: 8)),
        );
      },
    );

    test('prioritizes flush scoring for the full-run bot policy', () {
      final drollJester = catalog.findById('droll_jester')!;
      final jollyJester = catalog.findById('jolly_jester')!;

      expect(drollJester.conditionType, 'flush');
      expect(
        fullRunBotJesterScore(drollJester, stage: 7),
        greaterThan(fullRunBotJesterScore(jollyJester, stage: 7)),
      );
    });
  });

  group('fullRunBotItemScore', () {
    late ItemCatalog catalog;

    setUpAll(() {
      catalog = ItemCatalog.fromJsonString(
        File('data/common/items_common_v1.json').readAsStringSync(),
      );
    });

    test('prioritizes direct hand growth Tool over evidence-only Q-Slot', () {
      final straightStudy = catalog.findById('straight_study')!;
      final boardLift = catalog.findById('board_lift')!;

      expect(straightStudy.placement, ItemPlacement.inventory);
      expect(
        fullRunBotItemScore(straightStudy, stage: 6),
        greaterThan(fullRunBotItemScore(boardLift, stage: 6)),
      );
    });

    test(
      'keeps deck control useful but below direct growth in late market',
      () {
        final flushStudy = catalog.findById('flush_study')!;
        final deckNeedle = catalog.findById('deck_needle')!;

        expect(
          fullRunBotItemScore(flushStudy, stage: 8),
          greaterThan(fullRunBotItemScore(deckNeedle, stage: 8)),
        );
      },
    );

    test('values flush growth above straight growth in late market', () {
      final flushStudy = catalog.findById('flush_study')!;
      final straightStudy = catalog.findById('straight_study')!;

      expect(
        fullRunBotItemScore(flushStudy, stage: 7),
        greaterThan(fullRunBotItemScore(straightStudy, stage: 7)),
      );
    });
  });

  group('fullRunBotDeckTileScore', () {
    test('prioritizes special tile modifiers over plain high-rank tiles', () {
      const plainHighRank = Tile(color: TileColor.red, number: 13);
      const specialLowRank = Tile(
        color: TileColor.blue,
        number: 4,
        enhancement: TileEnhancement.chipInlaid,
      );

      expect(
        fullRunBotDeckTileScore(specialLowRank),
        greaterThan(fullRunBotDeckTileScore(plainHighRank)),
      );
    });
  });
}
