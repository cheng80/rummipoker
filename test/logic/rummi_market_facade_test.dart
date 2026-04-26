import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:rummipoker/logic/rummi_poker_grid/hand_rank.dart';
import 'package:rummipoker/logic/rummi_poker_grid/item_definition.dart';
import 'package:rummipoker/logic/rummi_poker_grid/jester_meta.dart';
import 'package:rummipoker/logic/rummi_poker_grid/line_ref.dart';
import 'package:rummipoker/logic/rummi_poker_grid/rummi_market_facade.dart';
import 'package:rummipoker/logic/rummi_poker_grid/rummi_poker_grid_session.dart';

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
      expect(facade.offers.first.isAffordable, isTrue);
      expect(facade.offers.last.isAffordable, isTrue);
      expect(facade.runtimeSnapshot.playedHandCounts, isEmpty);
      expect(facade.itemOffers, isEmpty);
    });

    test(
      'maps item definitions into item market offers without jester slots',
      () {
        final catalog = ItemCatalog.fromJsonString('''
{
  "schemaVersion": 1,
  "catalogId": "items_test",
  "rarityWeights": {"common": 48},
  "items": [
    {
      "id": "reroll_token",
      "displayName": "Reroll Token",
      "displayNameKey": "data.items.reroll_token.displayName",
      "type": "utility",
      "rarity": "common",
      "basePrice": 3,
      "sellPrice": 1,
      "stackable": true,
      "maxStack": 3,
      "sellable": true,
      "usableInBattle": false,
      "placement": "inventory",
      "slotHint": "utility",
      "effectText": "The next Market reroll costs no Gold.",
      "effectTextKey": "data.items.reroll_token.effectText",
      "effect": {
        "timing": "market_reroll",
        "op": "free_next_reroll",
        "amount": 1,
        "consume": true
      },
      "tags": ["market", "economy", "discount"],
      "sourceNotes": "Test fixture."
    }
  ]
}
''');
        final itemOffer = RummiMarketItemOfferView.fromItemDefinition(
          catalog.findById('reroll_token')!,
          slotIndex: 0,
          currentGold: 2,
        );
        final facade = RummiMarketRuntimeFacade(
          gold: 2,
          rerollCost: 5,
          maxOwnedSlots: RummiRunProgress.maxJesterSlots,
          runtimeSnapshot: const RummiJesterRuntimeSnapshot(),
          ownedEntries: const [],
          offers: const [],
          itemOfferSlotCount: 3,
          quickSlotCapacity: RunInventoryState.defaultQuickSlotCapacity,
          itemOffers: [itemOffer],
        );

        expect(facade.maxOwnedSlots, RummiRunProgress.maxJesterSlots);
        expect(facade.offers, isEmpty);
        expect(facade.itemOffers.single.offerId, 'item:0:reroll_token');
        expect(facade.itemOffers.single.category, RummiMarketCategory.item);
        expect(facade.itemOffers.single.contentId, 'reroll_token');
        expect(facade.itemOffers.single.displayName, 'Reroll Token');
        expect(
          facade.itemOffers.single.displayNameKey,
          'data.items.reroll_token.displayName',
        );
        expect(facade.itemOffers.single.price, 3);
        expect(facade.itemOffers.single.currency, 'gold');
        expect(facade.itemOffers.single.isAffordable, isFalse);
        expect(facade.itemOffers.single.item.type, ItemType.utility);
      },
    );

    test('maps market modifiers into displayed reroll and offer prices', () {
      final progress = RummiRunProgress()
        ..gold = 10
        ..rerollCost = 5
        ..shopOffers.add(
          RummiShopOffer(
            slotIndex: 0,
            card: _jester(id: 'discounted', displayName: 'Discounted'),
            price: 6,
          ),
        );
      progress.queueMarketModifier(op: 'discount_next_reroll', amount: 2);
      progress.queueMarketModifier(
        op: 'discount_next_purchase',
        amount: 3,
        category: 'jester',
      );

      final facade = RummiMarketRuntimeFacade.fromRunProgress(progress);

      expect(facade.rerollCost, 3);
      expect(facade.offers.single.price, 3);
      expect(facade.offers.single.isAffordable, isTrue);
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

    test('applies owned sell and quick slot item modifiers', () {
      final catalog = ItemCatalog.fromJson({
        'schemaVersion': 1,
        'catalogId': 'items_test',
        'items': [
          _itemJson(
            id: 'jester_hook',
            timing: 'sell_jester',
            op: 'sell_price_bonus',
            placement: 'passiveRack',
          ),
          _itemJson(
            id: 'spare_pouch',
            timing: 'inventory_capacity',
            op: 'extra_quick_slot',
            placement: 'passiveRack',
          ),
        ],
      });
      final progress = RummiRunProgress()
        ..gold = 0
        ..ownedJesters.add(_jester(id: 'egg', displayName: 'Egg', baseCost: 5))
        ..itemInventory = const RunInventoryState(
          ownedItems: [
            OwnedItemEntry(
              itemId: 'jester_hook',
              count: 1,
              placement: ItemPlacement.passiveRack,
            ),
            OwnedItemEntry(
              itemId: 'spare_pouch',
              count: 1,
              placement: ItemPlacement.passiveRack,
            ),
          ],
          passiveRelicIds: ['jester_hook', 'spare_pouch'],
        );

      final facade = RummiMarketRuntimeFacade.fromRunProgress(
        progress,
        itemCatalog: catalog,
      );

      expect(facade.ownedEntries.single.sellPrice, 3);
      expect(facade.quickSlotCapacity, 3);

      expect(progress.sellOwnedJester(0, itemCatalog: catalog), isTrue);
      expect(progress.gold, 3);
    });

    test('maps owned item inventory into market item slots', () {
      final catalog = ItemCatalog.fromJson({
        'schemaVersion': 1,
        'catalogId': 'items_test',
        'items': [
          _itemJson(
            id: 'board_scrap',
            timing: 'use_battle',
            op: 'add_board_discard',
            placement: 'quickSlot',
          ),
          _itemJson(
            id: 'safety_net',
            timing: 'expiry_guard',
            op: 'rescue_first_expiry_each_station',
            placement: 'passiveRack',
          ),
          _itemJson(
            id: 'reroll_token',
            timing: 'market_reroll',
            op: 'free_next_reroll',
            placement: 'inventory',
          ),
          _itemJson(
            id: 'score_abacus',
            timing: 'station_start',
            op: 'add_board_move',
            placement: 'equipped',
          ),
        ],
      });
      final progress = RummiRunProgress()
        ..itemInventory = const RunInventoryState(
          ownedItems: [
            OwnedItemEntry(
              itemId: 'board_scrap',
              count: 1,
              placement: ItemPlacement.quickSlot,
            ),
            OwnedItemEntry(
              itemId: 'safety_net',
              count: 1,
              placement: ItemPlacement.passiveRack,
            ),
            OwnedItemEntry(
              itemId: 'reroll_token',
              count: 1,
              placement: ItemPlacement.inventory,
            ),
            OwnedItemEntry(
              itemId: 'score_abacus',
              count: 1,
              placement: ItemPlacement.equipped,
            ),
          ],
          quickSlotItemIds: ['board_scrap'],
          passiveRelicIds: ['safety_net'],
          equippedItemIds: ['score_abacus'],
        );

      final facade = RummiMarketRuntimeFacade.fromRunProgress(
        progress,
        itemCatalog: catalog,
      );

      expect(facade.itemSlots.map((slot) => slot.slotLabel), [
        'Q1',
        'Q2',
        'Q3',
        'P1',
        'P2',
        'T1',
        'T2',
        'T3',
        'G1',
        'G2',
      ]);
      expect(facade.itemSlots[0].contentId, 'board_scrap');
      expect(facade.itemSlots[0].locked, isFalse);
      expect(facade.itemSlots[2].locked, isTrue);
      expect(facade.itemSlots[3].contentId, 'safety_net');
      expect(facade.itemSlots[4].locked, isTrue);
      expect(facade.itemSlots[5].contentId, 'reroll_token');
      expect(facade.itemSlots[8].contentId, 'score_abacus');
    });

    test('consumed item offers are removed from market item offers', () {
      final catalog = ItemCatalog.fromJson({
        'schemaVersion': 1,
        'catalogId': 'items_test',
        'items': [
          _itemJson(
            id: 'board_scrap',
            timing: 'use_battle',
            op: 'add_board_discard',
            placement: 'quickSlot',
          ),
          _itemJson(
            id: 'hand_scrap',
            timing: 'use_battle',
            op: 'add_hand_discard',
            placement: 'quickSlot',
          ),
        ],
      });
      final progress = RummiRunProgress()..gold = 20;

      final before = RummiMarketRuntimeFacade.fromRunProgress(
        progress,
        itemCatalog: catalog,
      );
      progress.markItemOfferConsumed('board_scrap');
      final after = RummiMarketRuntimeFacade.fromRunProgress(
        progress,
        itemCatalog: catalog,
      );

      expect(before.itemOffers.map((offer) => offer.contentId), [
        'board_scrap',
        'hand_scrap',
      ]);
      expect(after.itemOffers.map((offer) => offer.contentId), ['hand_scrap']);
    });

    test('marks unaffordable offers and carries runtime snapshot values', () {
      final progress = RummiRunProgress()
        ..gold = 6
        ..shopOffers.add(
          RummiShopOffer(
            slotIndex: 0,
            card: _jester(id: 'supernova', displayName: 'Supernova'),
            price: 8,
          ),
        )
        ..ownedJesters.add(
          _jester(id: 'green_jester', displayName: 'Green Jester'),
        );

      progress.onConfirmedLines([
        ConfirmedLineBreakdown(
          ref: LineRef.row(0),
          rank: RummiHandRank.twoPair,
          rankBaseScore: 20,
          baseScore: 20,
          finalScore: 20,
          jesterBonus: 0,
          contributingCells: [],
          effects: [],
          hasScoringFaceCard: false,
        ),
      ]);

      final facade = RummiMarketRuntimeFacade.fromRunProgress(progress);

      expect(facade.offers.single.isAffordable, isFalse);
      expect(facade.runtimeSnapshot.stateValueForSlot(0), 1);
      expect(
        facade.runtimeSnapshot.playedCountForRank(RummiHandRank.twoPair),
        1,
      );
    });

    test('base run leaves the fifth jester slot locked for future unlocks', () {
      final progress = RummiRunProgress()
        ..gold = 20
        ..ownedJesters.addAll([
          _jester(id: 'slot_1'),
          _jester(id: 'slot_2'),
          _jester(id: 'slot_3'),
          _jester(id: 'slot_4'),
        ])
        ..shopOffers.add(
          RummiShopOffer(
            slotIndex: 0,
            card: _jester(id: 'slot_5_offer'),
            price: 1,
          ),
        );

      final facade = RummiMarketRuntimeFacade.fromRunProgress(progress);

      expect(facade.maxOwnedSlots, RummiRunProgress.maxJesterSlots);
      expect(progress.jesterSlotCapacity(), 4);
      expect(progress.buyOffer(0), isFalse);
      expect(progress.ownedJesters.length, 4);
    });

    test('boss trophy next-market jester slot applies for one market', () {
      final catalog = List<RummiJesterCard>.generate(
        6,
        (index) => _jester(id: 'offer_$index'),
      );
      final progress = RummiRunProgress()
        ..marketModifiers = const RummiMarketModifierState(
          nextMarketExtraJesterOfferSlots: 1,
        );

      progress.openShop(catalog: catalog, rng: Random(1));

      expect(progress.shopOffers.length, 4);
      expect(progress.marketModifiers.extraJesterOfferSlots, 1);
      expect(progress.marketModifiers.nextMarketExtraJesterOfferSlots, 0);

      progress.gold = 99;
      final rerolled = progress.rerollShop(catalog: catalog, rng: Random(2));

      expect(rerolled, isTrue);
      expect(progress.shopOffers.length, 4);
      expect(progress.rerollCost, 7);

      progress.openShop(catalog: catalog, rng: Random(3));

      expect(progress.shopOffers.length, 3);
      expect(progress.marketModifiers.extraJesterOfferSlots, 0);
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

Map<String, dynamic> _itemJson({
  required String id,
  required String timing,
  required String op,
  required String placement,
}) {
  return <String, dynamic>{
    'id': id,
    'displayName': id,
    'displayNameKey': 'data.items.$id.displayName',
    'type': 'utility',
    'rarity': 'common',
    'basePrice': 4,
    'sellPrice': 2,
    'stackable': false,
    'maxStack': 1,
    'sellable': true,
    'usableInBattle': false,
    'placement': placement,
    'slotHint': 'p',
    'effectText': 'Test effect.',
    'effectTextKey': 'data.items.$id.effectText',
    'effect': <String, dynamic>{
      'timing': timing,
      'op': op,
      'amount': 1,
      'consume': false,
    },
    'tags': <String>['market'],
    'sourceNotes': 'Test fixture.',
  };
}
