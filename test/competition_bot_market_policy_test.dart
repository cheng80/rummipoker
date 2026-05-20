import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rummipoker/logic/rummi_poker_grid/item_definition.dart';
import 'package:rummipoker/logic/rummi_poker_grid/jester_meta.dart';

import '../integration_test/competition_bot_market_policy.dart';

void main() {
  group('contestFullRunBotJesterScore', () {
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
        contestFullRunBotJesterScore(drollJester, stage: 8),
        greaterThan(contestFullRunBotJesterScore(rideTheBus, stage: 8)),
      );
    });

    test(
      'prefers color-scored Jester over zero-stack ride before final market',
      () {
        final rideTheBus = catalog.findById('ride_the_bus')!;
        final gluttonousJester = catalog.findById('gluttonous_jester')!;

        expect(
          contestFullRunBotJesterScore(gluttonousJester, stage: 7),
          greaterThan(contestFullRunBotJesterScore(rideTheBus, stage: 7)),
        );
      },
    );

    test('prefers flush scoring over broad clever scoring in S8', () {
      final cleverJester = catalog.findById('clever_jester')!;
      final drollJester = catalog.findById('droll_jester')!;

      expect(
        contestFullRunBotJesterScore(drollJester, stage: 8),
        greaterThan(contestFullRunBotJesterScore(cleverJester, stage: 8)),
      );
    });

    test(
      'keeps stacked ride valuable when it already survived confirmations',
      () {
        final rideTheBus = catalog.findById('ride_the_bus')!;
        final drollJester = catalog.findById('droll_jester')!;

        expect(
          contestFullRunBotJesterScore(rideTheBus, stage: 8, stateValue: 35),
          greaterThan(contestFullRunBotJesterScore(drollJester, stage: 8)),
        );
      },
    );

    test('prioritizes flush scoring for the post-contest bot policy', () {
      final drollJester = catalog.findById('droll_jester')!;
      final jollyJester = catalog.findById('jolly_jester')!;

      expect(drollJester.conditionType, 'flush');
      expect(
        contestFullRunBotJesterScore(drollJester, stage: 7),
        greaterThan(contestFullRunBotJesterScore(jollyJester, stage: 7)),
      );
    });
  });

  group('contestFullRunBotItemScore', () {
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
        contestFullRunBotItemScore(straightStudy, stage: 6),
        greaterThan(contestFullRunBotItemScore(boardLift, stage: 6)),
      );
    });

    test(
      'keeps deck control useful but below direct growth in late market',
      () {
        final flushStudy = catalog.findById('flush_study')!;
        final deckNeedle = catalog.findById('deck_needle')!;

        expect(
          contestFullRunBotItemScore(flushStudy, stage: 8),
          greaterThan(contestFullRunBotItemScore(deckNeedle, stage: 8)),
        );
      },
    );

    test('values flush growth above straight growth in late market', () {
      final flushStudy = catalog.findById('flush_study')!;
      final straightStudy = catalog.findById('straight_study')!;

      expect(
        contestFullRunBotItemScore(flushStudy, stage: 7),
        greaterThan(contestFullRunBotItemScore(straightStudy, stage: 7)),
      );
    });
  });
}
