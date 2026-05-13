import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:rummipoker/logic/rummi_poker_grid/hand_rank.dart';
import 'package:rummipoker/logic/rummi_poker_grid/item_definition.dart';
import 'package:rummipoker/logic/rummi_poker_grid/jester_meta.dart';
import 'package:rummipoker/logic/rummi_poker_grid/line_ref.dart';
import 'package:rummipoker/logic/rummi_poker_grid/models/tile.dart';
import 'package:rummipoker/logic/rummi_poker_grid/rummi_market_facade.dart';
import 'package:rummipoker/logic/rummi_poker_grid/rummi_poker_grid_session.dart';

RummiJesterCard _jester({
  required String id,
  String? displayName,
  int baseCost = 6,
  String effectType = 'chips_bonus',
  String conditionType = 'none',
}) {
  return RummiJesterCard(
    id: id,
    displayName: displayName ?? id,
    rarity: RummiJesterRarity.common,
    baseCost: baseCost,
    effectText: '',
    effectType: effectType,
    trigger: 'onScore',
    conditionType: conditionType,
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
      expect(facade.offers.first.price, 5);
      expect(facade.offers.first.currency, 'gold');
      expect(facade.offers.first.isAffordable, isTrue);
      expect(facade.offers.last.price, 5);
      expect(facade.offers.last.isAffordable, isTrue);
      expect(facade.runtimeSnapshot.playedHandCounts, isEmpty);
      expect(facade.itemOffers, isEmpty);
    });

    test('keeps remaining jester offer prices after buying another offer', () {
      final progress = RummiRunProgress()
        ..gold = 30
        ..shopOffers.addAll([
          RummiShopOffer(slotIndex: 0, card: _jester(id: 'jester_a'), price: 3),
          RummiShopOffer(slotIndex: 1, card: _jester(id: 'jester_b'), price: 4),
          RummiShopOffer(
            slotIndex: 2,
            card: _jester(id: 'half_jester'),
            price: 5,
          ),
        ]);

      expect(progress.buyOffer(1), isTrue);

      final facade = RummiMarketRuntimeFacade.fromRunProgress(progress);

      expect(facade.offers.map((offer) => offer.contentId), [
        'jester_a',
        'half_jester',
      ]);
      expect(facade.offers.map((offer) => offer.price), [5, 5]);
    });

    test(
      'keeps remaining jester offers normally priced after any offer purchase',
      () {
        for (final boughtIndex in [0, 1, 2]) {
          final progress = RummiRunProgress()
            ..gold = 30
            ..shopOffers.addAll([
              RummiShopOffer(
                slotIndex: 0,
                card: _jester(id: 'jester_a'),
                price: 3,
              ),
              RummiShopOffer(
                slotIndex: 1,
                card: _jester(id: 'jester_b'),
                price: 4,
              ),
              RummiShopOffer(
                slotIndex: 2,
                card: _jester(id: 'jester_c'),
                price: 5,
              ),
            ]);

          expect(progress.buyOffer(boughtIndex), isTrue);

          final facade = RummiMarketRuntimeFacade.fromRunProgress(progress);

          expect(
            facade.offers,
            everyElement(
              isA<RummiMarketOfferView>()
                  .having((offer) => offer.price, 'price', greaterThan(0))
                  .having((offer) => offer.hasDiscount, 'hasDiscount', isFalse),
            ),
            reason: 'boughtIndex=$boughtIndex',
          );
          expect(facade.offers.map((offer) => offer.price), [5, 5]);
        }
      },
    );

    test('consumes jester purchase discount after one offer purchase', () {
      final progress = RummiRunProgress()
        ..gold = 30
        ..shopOffers.addAll([
          RummiShopOffer(slotIndex: 0, card: _jester(id: 'jester_a'), price: 6),
          RummiShopOffer(slotIndex: 1, card: _jester(id: 'jester_b'), price: 6),
        ]);
      progress.queueMarketModifier(
        op: 'discount_next_purchase',
        amount: 2,
        category: 'jester',
      );

      final before = RummiMarketRuntimeFacade.fromRunProgress(progress);

      expect(before.offers.map((offer) => offer.hasDiscount), [true, true]);
      expect(before.offers.first.originalPrice, 5);
      expect(before.offers.first.price, 3);

      expect(progress.buyOffer(0), isTrue);

      final after = RummiMarketRuntimeFacade.fromRunProgress(progress);

      expect(after.offers.single.contentId, 'jester_b');
      expect(after.offers.single.originalPrice, 5);
      expect(after.offers.single.price, 5);
      expect(after.offers.single.hasDiscount, isFalse);
    });

    test('item purchase discount does not leak into jester offer prices', () {
      final progress = RummiRunProgress()
        ..gold = 30
        ..shopOffers.add(
          RummiShopOffer(slotIndex: 0, card: _jester(id: 'jester_a'), price: 6),
        );
      progress.queueMarketModifier(
        op: 'discount_next_purchase',
        amount: 2,
        category: 'item',
      );

      final facade = RummiMarketRuntimeFacade.fromRunProgress(progress);

      expect(facade.offers.single.originalPrice, 5);
      expect(facade.offers.single.price, 5);
      expect(facade.offers.single.hasDiscount, isFalse);
    });

    test('consumes item purchase discount after one item purchase', () {
      final catalog = ItemCatalog.fromJson({
        'schemaVersion': 1,
        'catalogId': 'items_test',
        'items': [
          _itemJson(
            id: 'tool_coupon_target',
            timing: 'use_market',
            op: 'gain_gold',
            placement: 'inventory',
          ),
          _itemJson(
            id: 'quick_coupon_target',
            timing: 'use_battle',
            op: 'add_board_discard',
            placement: 'quickSlot',
          ),
        ],
      });
      final progress = RummiRunProgress()..gold = 30;
      progress.queueMarketModifier(
        op: 'discount_next_purchase',
        amount: 2,
        category: 'item',
      );

      final before = RummiMarketRuntimeFacade.fromRunProgress(
        progress,
        itemCatalog: catalog,
      );

      expect(before.itemOffers, isNotEmpty);
      for (final offer in before.itemOffers) {
        expect(offer.price, max(0, offer.originalPrice - 2));
        expect(offer.hasDiscount, isTrue);
      }

      final bought = before.itemOffers.first;
      expect(
        progress.buyItem(
          bought.item,
          price: bought.price,
          itemCatalog: catalog,
        ),
        isTrue,
      );

      final after = RummiMarketRuntimeFacade.fromRunProgress(
        progress,
        itemCatalog: catalog,
      );

      expect(after.itemOffers, isNotEmpty);
      for (final offer in after.itemOffers) {
        expect(offer.price, offer.originalPrice);
        expect(offer.hasDiscount, isFalse);
      }
    });

    test('maps tile offers and added deck tiles into market facade', () {
      final progress = RummiRunProgress()
        ..gold = 3
        ..tileOffers.add(const Tile(color: TileColor.red, number: 7))
        ..addDeckTile(const Tile(color: TileColor.blue, number: 9));

      final facade = RummiMarketRuntimeFacade.fromRunProgress(progress);

      expect(facade.tileOffers.single.offerId, 'tile:0:R7');
      expect(facade.tileOffers.single.price, 3);
      expect(facade.tileOffers.single.isAffordable, isTrue);
      expect(facade.addedDeckTiles.single.code, 'B9');
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
      expect(facade.offers.single.originalPrice, 5);
      expect(facade.offers.single.price, 2);
      expect(facade.offers.single.discountAmount, 3);
      expect(facade.offers.single.hasDiscount, isTrue);
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

      expect(
        before.itemOffers.map((offer) => offer.contentId),
        containsAll(['board_scrap', 'hand_scrap']),
      );
      expect(after.itemOffers.map((offer) => offer.contentId), ['hand_scrap']);
    });

    test(
      'station band market policy keeps early economy and late boss growth',
      () {
        final early = RummiStationBandMarketPolicy.forStage(1);
        final late = RummiStationBandMarketPolicy.forStage(7);
        final economyItem = ItemDefinition.fromJson(
          _itemJson(
            id: 'coin_cache',
            timing: 'use_market',
            op: 'gain_gold',
            placement: 'inventory',
            tags: const ['gold', 'economy'],
          ),
        );
        final bossBreakerItem = ItemDefinition.fromJson(
          _itemJson(
            id: 'boss_trophy',
            timing: 'boss_blind_clear_market',
            op: 'extra_jester_offer_next_market',
            placement: 'passiveRack',
            rarity: 'rare',
            tags: const ['relic', 'boss', 'market', 'jester'],
          ),
        );

        expect(
          early.jesterRarityWeight(RummiJesterRarity.rare),
          greaterThan(0),
        );
        expect(
          late.jesterRarityWeight(RummiJesterRarity.rare),
          greaterThan(early.jesterRarityWeight(RummiJesterRarity.rare) * 4),
        );
        expect(
          early.itemOfferWeight(economyItem),
          greaterThan(early.itemOfferWeight(bossBreakerItem)),
        );
        expect(
          late.itemOfferWeight(bossBreakerItem),
          greaterThan(late.itemOfferWeight(economyItem)),
        );
      },
    );

    test('mid station market policy keeps score growth ahead of resources', () {
      final mid = RummiStationBandMarketPolicy.forStage(4);
      final scoreGrowthItem = ItemDefinition.fromJson(
        _itemJson(
          id: 'rank_chart',
          timing: 'station_start',
          op: 'add_board_move',
          placement: 'equipped',
          tags: const ['score', 'rank'],
        ),
      );
      final resourceItem = ItemDefinition.fromJson(
        _itemJson(
          id: 'resource_pouch',
          timing: 'inventory_capacity',
          op: 'extra_quick_slot',
          placement: 'passiveRack',
          tags: const ['capacity', 'discard'],
        ),
      );

      expect(
        mid.itemOfferWeight(scoreGrowthItem),
        greaterThan(mid.itemOfferWeight(resourceItem)),
      );
      expect(
        mid.jesterRarityWeight(RummiJesterRarity.legendary),
        greaterThan(0),
      );
    });

    test('final station market policy keeps shape correction available', () {
      final late = RummiStationBandMarketPolicy.forStage(6);
      final finalBand = RummiStationBandMarketPolicy.forStage(8);
      final tileShapeItem = ItemDefinition.fromJson(
        _itemJson(
          id: 'red_swatch',
          timing: 'use_battle',
          op: 'score_multiplier',
          placement: 'quickSlot',
          tags: const ['consumable', 'tile_color', 'mult'],
        ),
      );
      final drawShapeItem = ItemDefinition.fromJson(
        _itemJson(
          id: 'emergency_draw',
          timing: 'use_battle',
          op: 'draw_tile',
          placement: 'quickSlot',
          rarity: 'rare',
          tags: const ['battle', 'draw', 'safety'],
        ),
      );
      final bossBreakerItem = ItemDefinition.fromJson(
        _itemJson(
          id: 'boss_trophy',
          timing: 'boss_blind_clear_market',
          op: 'extra_jester_offer_next_market',
          placement: 'passiveRack',
          rarity: 'rare',
          tags: const ['relic', 'boss', 'market', 'jester'],
        ),
      );

      expect(
        finalBand.itemOfferWeight(tileShapeItem),
        greaterThan(late.itemOfferWeight(tileShapeItem)),
      );
      expect(
        finalBand.itemOfferWeight(drawShapeItem),
        greaterThan(late.itemOfferWeight(drawShapeItem)),
      );
      expect(
        finalBand.itemOfferWeight(bossBreakerItem),
        greaterThan(finalBand.itemOfferWeight(tileShapeItem)),
      );
    });

    test('missing growth correction only changes market appearance weight', () {
      final mid = RummiStationBandMarketPolicy.forStage(4);
      final highStakesMid = RummiStationBandMarketPolicy.forStage(
        4,
        pressureProfile: RummiMarketPressureProfile.highStakes,
      );
      final scoreGrowthItem = ItemDefinition.fromJson(
        _itemJson(
          id: 'rank_chart',
          timing: 'station_start',
          op: 'add_board_move',
          placement: 'equipped',
          tags: const ['score', 'rank'],
        ),
      );
      final resourceItem = ItemDefinition.fromJson(
        _itemJson(
          id: 'board_scrap',
          timing: 'use_battle',
          op: 'add_board_discard',
          placement: 'quickSlot',
          tags: const ['discard'],
        ),
      );

      final baseScoreWeight = mid.itemOfferWeight(scoreGrowthItem);
      final correctedScoreWeight = mid.itemOfferWeight(
        scoreGrowthItem,
        missingGrowthTags: const {'score', 'rank'},
      );
      final highStakesScoreWeight = highStakesMid.itemOfferWeight(
        scoreGrowthItem,
        missingGrowthTags: const {'score', 'rank'},
      );
      final correctedResourceWeight = mid.itemOfferWeight(
        resourceItem,
        missingGrowthTags: const {'score', 'rank'},
      );

      expect(correctedScoreWeight, greaterThan(baseScoreWeight));
      expect(highStakesScoreWeight, greaterThan(correctedScoreWeight));
      expect(correctedResourceWeight, mid.itemOfferWeight(resourceItem));
      expect(correctedScoreWeight - baseScoreWeight, lessThanOrEqualTo(90));
    });

    test('collection correction only changes market appearance weight', () {
      final mid = RummiStationBandMarketPolicy.forStage(4);
      final scoreGrowthItem = ItemDefinition.fromJson(
        _itemJson(
          id: 'rank_chart',
          timing: 'station_start',
          op: 'add_board_move',
          placement: 'equipped',
          tags: const ['score', 'rank'],
        ),
      );

      final baseWeight = mid.itemOfferWeight(scoreGrowthItem);
      final boostedWeight = mid.itemOfferWeight(
        scoreGrowthItem,
        collectionWeightBonus: 135,
      );
      final growthAndCollectionWeight = mid.itemOfferWeight(
        scoreGrowthItem,
        missingGrowthTags: const {'score', 'rank'},
        collectionWeightBonus: 135,
      );

      expect(boostedWeight - baseWeight, 135);
      expect(growthAndCollectionWeight, greaterThan(boostedWeight));
    });

    test('collection correction makes unseen jester offers observable', () {
      final catalog = [
        _jester(id: 'seen_a'),
        _jester(id: 'seen_b'),
        _jester(id: 'unseen_target'),
      ];
      var targetOfferCount = 0;
      var seenOfferCount = 0;

      for (var seed = 0; seed < 240; seed++) {
        final progress = RummiRunProgress()
          ..stageIndex = 4
          ..gold = 20
          ..seenMarketJesterIds.addAll({'seen_a', 'seen_b'})
          ..boughtJesterIds.addAll({'seen_a', 'seen_b'});
        progress.openShop(catalog: catalog, rng: Random(seed));
        for (final offer in progress.shopOffers) {
          if (offer.card.id == 'unseen_target') {
            targetOfferCount += 1;
          } else {
            seenOfferCount += 1;
          }
        }
      }

      expect(targetOfferCount, greaterThan(0));
      expect(targetOfferCount, greaterThan(seenOfferCount ~/ 3));
    });

    test('high stakes market pressure adds transient item offer room', () {
      final catalog = ItemCatalog.fromJson({
        'schemaVersion': 1,
        'catalogId': 'items_test',
        'items': [
          _itemJson(
            id: 'coin_cache',
            timing: 'use_market',
            op: 'gain_gold',
            placement: 'inventory',
            tags: const ['economy'],
          ),
          _itemJson(
            id: 'reroll_token',
            timing: 'market_reroll',
            op: 'free_next_reroll',
            placement: 'inventory',
            tags: const ['market'],
          ),
          _itemJson(
            id: 'rank_chart',
            timing: 'station_start',
            op: 'add_board_move',
            placement: 'equipped',
            tags: const ['score', 'rank'],
          ),
          _itemJson(
            id: 'board_scrap',
            timing: 'use_battle',
            op: 'add_board_discard',
            placement: 'quickSlot',
            tags: const ['discard'],
          ),
        ],
      });
      final progress = RummiRunProgress()
        ..stageIndex = 4
        ..gold = 20;

      final standard = RummiMarketRuntimeFacade.fromRunProgress(
        progress,
        itemCatalog: catalog,
      );
      final highStakes = RummiMarketRuntimeFacade.fromRunProgress(
        progress,
        itemCatalog: catalog,
        pressureProfile: RummiMarketPressureProfile.highStakes,
      );

      expect(standard.itemOfferSlotCount, 3);
      expect(highStakes.itemOfferSlotCount, 4);
      expect(standard.itemOffers.length, 4);
      expect(highStakes.itemOffers.length, 4);
      expect(progress.marketModifiers.extraItemOfferSlots, 0);
    });

    test('full passive rack still shows sell-and-replace passive offers', () {
      final catalog = ItemCatalog.fromJson({
        'schemaVersion': 1,
        'catalogId': 'items_test',
        'items': [
          _itemJson(
            id: 'owned_passive',
            timing: 'enter_market',
            op: 'discount_first_reroll',
            placement: 'passiveRack',
            tags: const ['relic', 'market'],
          ),
          _itemJson(
            id: 'upgrade_passive',
            timing: 'second_confirm_each_station',
            op: 'add_percent_of_first_confirm_score',
            placement: 'passiveRack',
            rarity: 'rare',
            tags: const ['relic', 'battle', 'score'],
          ),
        ],
      });
      final progress = RummiRunProgress()
        ..stageIndex = 4
        ..gold = 20
        ..itemInventory = const RunInventoryState(
          ownedItems: [
            OwnedItemEntry(
              itemId: 'owned_passive',
              count: 1,
              placement: ItemPlacement.passiveRack,
            ),
          ],
          passiveRelicIds: ['owned_passive'],
        );

      final facade = RummiMarketRuntimeFacade.fromRunProgress(
        progress,
        itemCatalog: catalog,
      );

      expect(
        facade.itemOffers.map((offer) => offer.contentId),
        contains('upgrade_passive'),
      );
      expect(
        facade.itemOffers.map((offer) => offer.contentId),
        isNot(contains('owned_passive')),
      );
      expect(progress.buyItem(catalog.findById('upgrade_passive')!), isFalse);

      expect(
        progress.sellOwnedItem(catalog.findById('owned_passive')!),
        isTrue,
      );
      expect(progress.buyItem(catalog.findById('upgrade_passive')!), isTrue);
    });

    test('full quick slots still show sell-and-replace quick item offers', () {
      final catalog = ItemCatalog.fromJson({
        'schemaVersion': 1,
        'catalogId': 'items_test',
        'items': [
          _itemJson(
            id: 'owned_quick_a',
            timing: 'use_battle',
            op: 'add_board_discard',
            placement: 'quickSlot',
            tags: const ['battle'],
          ),
          _itemJson(
            id: 'owned_quick_b',
            timing: 'use_battle',
            op: 'add_hand_discard',
            placement: 'quickSlot',
            tags: const ['battle'],
          ),
          _itemJson(
            id: 'upgrade_quick',
            timing: 'use_battle',
            op: 'peek_deck_top',
            placement: 'quickSlot',
            rarity: 'rare',
            tags: const ['battle', 'control'],
          ),
        ],
      });
      final progress = RummiRunProgress()
        ..stageIndex = 4
        ..gold = 20
        ..itemInventory = const RunInventoryState(
          ownedItems: [
            OwnedItemEntry(
              itemId: 'owned_quick_a',
              count: 1,
              placement: ItemPlacement.quickSlot,
            ),
            OwnedItemEntry(
              itemId: 'owned_quick_b',
              count: 1,
              placement: ItemPlacement.quickSlot,
            ),
          ],
          quickSlotItemIds: ['owned_quick_a', 'owned_quick_b'],
        );

      final facade = RummiMarketRuntimeFacade.fromRunProgress(
        progress,
        itemCatalog: catalog,
      );

      expect(
        facade.itemOffers.map((offer) => offer.contentId),
        contains('upgrade_quick'),
      );
      expect(
        facade.itemOffers.map((offer) => offer.contentId),
        isNot(contains('owned_quick_a')),
      );
      expect(progress.buyItem(catalog.findById('upgrade_quick')!), isFalse);

      expect(
        progress.sellOwnedItem(catalog.findById('owned_quick_a')!),
        isTrue,
      );
      expect(progress.buyItem(catalog.findById('upgrade_quick')!), isTrue);
    });

    test('missing growth exposure can focus a random item offer slot', () {
      final catalog = ItemCatalog.fromJson({
        'schemaVersion': 1,
        'catalogId': 'items_test',
        'items': [
          _itemJson(
            id: 'coin_cache',
            timing: 'use_market',
            op: 'gain_gold',
            placement: 'inventory',
            tags: const ['economy'],
          ),
          _itemJson(
            id: 'reroll_token',
            timing: 'market_reroll',
            op: 'free_next_reroll',
            placement: 'inventory',
            tags: const ['market'],
          ),
          _itemJson(
            id: 'rank_chart',
            timing: 'station_start',
            op: 'add_board_move',
            placement: 'equipped',
            tags: const ['score', 'rank'],
          ),
        ],
      });
      final progress = RummiRunProgress()
        ..stageIndex = 3
        ..gold = 20;

      final facade = RummiMarketRuntimeFacade.fromRunProgress(
        progress,
        itemCatalog: catalog,
      );

      expect(
        facade.itemOffers.map((offer) => offer.contentId),
        contains('rank_chart'),
      );
    });

    test('missing growth exposure can focus a random jester offer slot', () {
      final catalog = [
        _jester(id: 'golden_jester', effectType: 'economy'),
        _jester(id: 'egg', effectType: 'economy'),
        _jester(id: 'rank_jester', conditionType: 'rank_scored'),
      ];
      final progress = RummiRunProgress()
        ..stageIndex = 4
        ..gold = 20;

      var foundNonFirstFocusedOffer = false;
      for (var seed = 0; seed < 80; seed++) {
        progress.openShop(catalog: catalog, rng: Random(seed));
        final focusedIndex = progress.shopOffers.indexWhere(
          (offer) => offer.card.id == 'rank_jester',
        );
        if (focusedIndex > 0) {
          foundNonFirstFocusedOffer = true;
          break;
        }
      }

      expect(foundNonFirstFocusedOffer, isTrue);
    });

    test('marks unaffordable offers and carries runtime snapshot values', () {
      final progress = RummiRunProgress()
        ..gold = 4
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

    test('base run leaves the fifth jester slot locked until boss reward', () {
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

      progress
        ..stageIndex = 6
        ..claimBossSlotUnlockRewards();

      final unlockedFacade = RummiMarketRuntimeFacade.fromRunProgress(progress);
      expect(progress.jesterSlotCapacity(), 5);
      expect(unlockedFacade.jesterSlotCapacity, 5);
      expect(
        unlockedFacade.pendingSlotUnlockPresentations,
        contains(RummiSlotUnlockKind.jester),
      );
      expect(progress.buyOffer(0), isTrue);
      expect(progress.ownedJesters.length, 5);
    });

    test('boss slot rewards unlock quick and passive capacities', () {
      final progress = RummiRunProgress();

      progress
        ..stageIndex = 2
        ..claimBossSlotUnlockRewards();
      expect(progress.quickSlotCapacity(), 3);
      expect(
        progress.snapshotPendingSlotUnlockPresentations(),
        contains(RummiSlotUnlockKind.quickSlot),
      );

      progress
        ..stageIndex = 4
        ..claimBossSlotUnlockRewards();
      expect(progress.passiveRelicCapacity(), 2);
      expect(
        progress.snapshotPendingSlotUnlockPresentations(),
        contains(RummiSlotUnlockKind.passiveRelic),
      );
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

    test('jester and item reroll costs advance independently', () {
      final catalog = List<RummiJesterCard>.generate(
        5,
        (index) => _jester(id: 'offer_$index'),
      );
      final progress = RummiRunProgress()
        ..gold = 30
        ..rerollCost = 5
        ..itemRerollCost = 5;
      progress.openShop(catalog: catalog, rng: Random(1));
      final originalItemOffset = progress.marketModifiers.itemOfferRerollOffset;

      expect(progress.rerollShop(catalog: catalog, rng: Random(2)), isTrue);

      expect(progress.gold, 30);
      expect(progress.rerollCost, 7);
      expect(progress.itemRerollCost, 5);
      expect(
        progress.marketModifiers.itemOfferRerollOffset,
        originalItemOffset,
      );

      final jesterOfferIds = progress.shopOffers
          .map((offer) => offer.card.id)
          .toList(growable: false);

      expect(progress.rerollItemOffers(), isTrue);

      expect(progress.gold, 25);
      expect(progress.rerollCost, 7);
      expect(progress.itemRerollCost, 7);
      expect(
        progress.marketModifiers.itemOfferRerollOffset,
        originalItemOffset + progress.marketModifiers.itemOfferSlotCount,
      );
      expect(progress.shopOffers.map((offer) => offer.card.id), jesterOfferIds);
    });

    test('first free jester reroll is not restored on the next market', () {
      final catalog = List<RummiJesterCard>.generate(
        5,
        (index) => _jester(id: 'offer_$index'),
      );
      final progress = RummiRunProgress()..gold = 20;

      progress.openShop(catalog: catalog, rng: Random(1));
      expect(progress.effectiveRerollCost(), 0);

      expect(progress.rerollShop(catalog: catalog, rng: Random(2)), isTrue);
      expect(progress.gold, 20);

      progress.openShop(catalog: catalog, rng: Random(3));

      expect(
        progress.effectiveRerollCost(),
        RummiRunProgress.shopBaseRerollCost,
      );
    });

    test(
      'tile reroll refills only tile offers and consumes first free reroll',
      () {
        final progress = RummiRunProgress()..gold = 5;
        progress.openShop(catalog: const [], rng: Random(1));
        progress.tileOffers.clear();

        final rerolled = progress.rerollTileOffers(rng: Random(2));

        expect(rerolled, isTrue);
        expect(progress.gold, 5);
        expect(progress.rerollCost, 7);
        expect(progress.shopOffers, isEmpty);
        expect(progress.tileOffers, hasLength(3));
        expect(progress.marketModifiers.firstRerollDiscount, 0);
      },
    );

    test('tile reroll keeps tile card offers available after bought tiles', () {
      final progress = RummiRunProgress()..gold = 30;
      progress.openShop(catalog: const [], rng: Random(1));

      while (progress.tileOffers.isNotEmpty) {
        expect(progress.buyTileOffer(0), isTrue);
      }
      expect(progress.addedDeckTiles, isNotEmpty);

      final rerolled = progress.rerollTileOffers(rng: Random(2));

      expect(rerolled, isTrue);
      expect(progress.tileOffers, hasLength(3));
    });

    test(
      'facade is snapshot-based and requires re-creation after mutations',
      () {
        final progress = RummiRunProgress()
          ..gold = 25
          ..shopOffers.add(
            RummiShopOffer(
              slotIndex: 0,
              card: _jester(id: 'ice_cream', displayName: 'Ice Cream'),
              price: 10,
            ),
          );
        final before = RummiMarketRuntimeFacade.fromRunProgress(progress);

        expect(progress.buyOffer(0), isTrue);

        expect(before.gold, 25);
        expect(before.offers.length, 1);
        expect(before.ownedEntries, isEmpty);

        final after = RummiMarketRuntimeFacade.fromRunProgress(progress);
        expect(after.gold, 20);
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
  String rarity = 'common',
  List<String> tags = const ['market'],
}) {
  return <String, dynamic>{
    'id': id,
    'displayName': id,
    'displayNameKey': 'data.items.$id.displayName',
    'type': 'utility',
    'rarity': rarity,
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
    'tags': tags,
    'sourceNotes': 'Test fixture.',
  };
}
