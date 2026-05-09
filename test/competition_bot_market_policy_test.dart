import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
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

    test(
      'does not replace zero-stack ride with single-condition droll in S8',
      () {
        final rideTheBus = catalog.findById('ride_the_bus')!;
        final drollJester = catalog.findById('droll_jester')!;

        expect(
          contestFullRunBotJesterScore(rideTheBus, stage: 8),
          greaterThan(contestFullRunBotJesterScore(drollJester, stage: 8) + 40),
        );
      },
    );

    test('keeps zero-stack ride through S7 before the final market', () {
      final rideTheBus = catalog.findById('ride_the_bus')!;
      final gluttonousJester = catalog.findById('gluttonous_jester')!;

      expect(
        contestFullRunBotJesterScore(rideTheBus, stage: 7),
        greaterThan(
          contestFullRunBotJesterScore(gluttonousJester, stage: 7) + 40,
        ),
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
  });
}
