import 'package:flutter_test/flutter_test.dart';

import 'package:rummipoker/logic/rummi_poker_grid/jester_meta.dart';
import 'package:rummipoker/logic/rummi_poker_grid/rummi_market_facade.dart';

RummiJesterCard _jester({
  required String id,
  String? displayName,
  int baseCost = 6,
}) {
  return RummiJesterCard(
    id: id,
    displayName: displayName ?? id,
    rarity: RummiJesterRarity.common,
    baseCost: baseCost,
    effectText: '',
    effectType: 'chips_bonus',
    trigger: 'onScore',
    conditionType: 'none',
    conditionValue: null,
    value: 5,
    xValue: null,
    mappedTileColors: const [],
    mappedTileNumbers: const [],
  );
}

void main() {
  group('RummiMarketRuntimeFacade', () {
    test('maps current shop offers into market offers', () {
      final progress = RummiRunProgress()
        ..gold = 19
        ..rerollCost = 7
        ..shopOffers.addAll([
          RummiShopOffer(
            slotIndex: 0,
            card: _jester(id: 'green_jester', displayName: 'Green Jester'),
            price: 8,
          ),
          RummiShopOffer(
            slotIndex: 1,
            card: _jester(id: 'popcorn', displayName: 'Popcorn'),
            price: 11,
          ),
        ]);

      final facade = RummiMarketRuntimeFacade.fromRunProgress(progress);

      expect(facade.gold, 19);
      expect(facade.rerollCost, 7);
      expect(facade.maxOwnedSlots, RummiRunProgress.maxJesterSlots);
      expect(facade.offers.length, 2);
      expect(facade.offers.first.offerId, 'jester:0:green_jester');
      expect(facade.offers.first.slotIndex, 0);
      expect(facade.offers.first.category, RummiMarketCategory.jester);
      expect(facade.offers.first.contentId, 'green_jester');
      expect(facade.offers.first.displayName, 'Green Jester');
      expect(facade.offers.first.price, 8);
      expect(facade.offers.first.currency, 'gold');
    });

    test('maps owned jesters into sellable market entries', () {
      final progress = RummiRunProgress()
        ..ownedJesters.addAll([
          _jester(id: 'egg', displayName: 'Egg', baseCost: 5),
          _jester(
            id: 'golden_jester',
            displayName: 'Golden Jester',
            baseCost: 9,
          ),
        ]);

      final facade = RummiMarketRuntimeFacade.fromRunProgress(progress);

      expect(facade.ownedEntries.length, 2);
      expect(facade.ownedEntries[0].slotIndex, 0);
      expect(facade.ownedEntries[0].contentId, 'egg');
      expect(facade.ownedEntries[0].sellPrice, 2);
      expect(facade.ownedEntries[1].slotIndex, 1);
      expect(facade.ownedEntries[1].contentId, 'golden_jester');
      expect(facade.ownedEntries[1].sellPrice, 4);
    });

    test(
      'facade is snapshot-based and requires re-creation after mutations',
      () {
        final progress = RummiRunProgress()
          ..gold = 15
          ..shopOffers.add(
            RummiShopOffer(
              slotIndex: 0,
              card: _jester(id: 'ice_cream', displayName: 'Ice Cream'),
              price: 10,
            ),
          );
        final before = RummiMarketRuntimeFacade.fromRunProgress(progress);

        expect(progress.buyOffer(0), isTrue);

        expect(before.gold, 15);
        expect(before.offers.length, 1);
        expect(before.ownedEntries, isEmpty);

        final after = RummiMarketRuntimeFacade.fromRunProgress(progress);
        expect(after.gold, 5);
        expect(after.offers, isEmpty);
        expect(after.ownedEntries.length, 1);
        expect(after.ownedEntries.first.contentId, 'ice_cream');
      },
    );
  });
}
