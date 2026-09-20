import 'package:flutter_test/flutter_test.dart';

import 'package:rummipoker/logic/rummi_poker_grid/item_definition.dart';
import 'package:rummipoker/logic/rummi_poker_grid/jester_meta.dart';
import 'package:rummipoker/logic/rummi_poker_grid/rummi_market_facade.dart';

/// 시뮬 감사 도구가 쓰는 구매 계약을 지킨다.
///
/// `tools/sim/runtime_market_offer_audit.dart`는 화면과 같은 facade에서 후보를
/// 고르고, 그 offer의 가격으로 청구하면서 나침반 할인 대상일 때만 할인을
/// 소비한다. 소비를 빠뜨리면 Market에 들어갈 때마다 같은 할인이 다시 붙어서
/// 한 번만 쓰여야 하는 할인이 무한히 재사용된다.

RummiJesterCard _jester({required String id, required int baseCost}) {
  return RummiJesterCard(
    id: id,
    displayName: id,
    rarity: RummiJesterRarity.common,
    baseCost: baseCost,
    effectText: '',
    // 성장 접근 가격 상한에 눌리지 않는 effectType을 써서 가격을 통제한다.
    effectType: 'gold_bonus',
    trigger: 'onScore',
    conditionType: 'none',
    conditionValue: null,
    value: 1,
    xValue: null,
    mappedTileColors: const [],
    mappedTileNumbers: const [],
  );
}

ItemCatalog _catalog() {
  return ItemCatalog.fromJson(const <String, dynamic>{
    'schemaVersion': 1,
    'catalogId': 'audit_discount_test',
    'items': <Map<String, dynamic>>[
      <String, dynamic>{
        'id': 'audit_tool_a',
        'displayName': 'audit_tool_a',
        'type': 'utility',
        'rarity': 'common',
        'basePrice': 3,
        'sellPrice': 1,
        'stackable': false,
        'maxStack': 1,
        'sellable': true,
        'usableInBattle': false,
        'placement': 'inventory',
        'slotHint': 'q',
        'effectText': 'Test effect.',
        'effect': <String, dynamic>{
          'timing': 'use_market',
          'op': 'gain_gold',
          'amount': 1,
          'consume': false,
        },
        'tags': <String>['test'],
      },
      <String, dynamic>{
        'id': 'audit_tool_b',
        'displayName': 'audit_tool_b',
        'type': 'utility',
        'rarity': 'common',
        'basePrice': 6,
        'sellPrice': 1,
        'stackable': false,
        'maxStack': 1,
        'sellable': true,
        'usableInBattle': false,
        'placement': 'passiveRack',
        'slotHint': 'p',
        'effectText': 'Test effect.',
        'effect': <String, dynamic>{
          'timing': 'use_market',
          'op': 'gain_gold',
          'amount': 1,
          'consume': false,
        },
        'tags': <String>['test'],
      },
    ],
  });
}

RummiRunProgress _progress() {
  return RummiRunProgress()
    ..gold = 200
    ..shopOffers.addAll([
      RummiShopOffer(
        slotIndex: 0,
        card: _jester(id: 'audit_jester_a', baseCost: 1),
        price: 1,
      ),
      RummiShopOffer(
        slotIndex: 1,
        card: _jester(id: 'audit_jester_b', baseCost: 20),
        price: 20,
      ),
    ]);
}

void main() {
  test('시뮬 구매는 진열 가격대로 청구하고 나침반 할인을 한 번만 쓴다', () {
    final catalog = _catalog();
    final progress = _progress();
    progress.queueMarketModifier(
      op: 'discount_cheapest_first_offer',
      amount: 2,
    );

    final firstMarket = RummiMarketRuntimeFacade.fromRunProgress(
      progress,
      itemCatalog: catalog,
    );
    final firstOffer = firstMarket.offers.first;
    expect(firstOffer.isCompassDiscounted, isTrue);

    final goldBeforeFirst = progress.gold;
    expect(
      progress.buyOffer(
        0,
        price: firstOffer.price,
        consumeCheapestFirstOfferDiscount: firstOffer.isCompassDiscounted,
      ),
      isTrue,
    );
    expect(goldBeforeFirst - progress.gold, firstOffer.price);
    expect(progress.marketModifiers.cheapestFirstOfferDiscount, 0);

    // 다음 Market 진입에 해당한다. 할인을 이미 썼으므로 다시 붙지 않는다.
    final secondMarket = RummiMarketRuntimeFacade.fromRunProgress(
      progress,
      itemCatalog: catalog,
    );
    expect(
      secondMarket.offers.every((offer) => !offer.isCompassDiscounted),
      isTrue,
    );
    expect(
      secondMarket.itemOffers.every((offer) => !offer.isCompassDiscounted),
      isTrue,
    );

    final nextItem = secondMarket.itemOffers.first;
    final goldBeforeSecond = progress.gold;
    expect(
      progress.buyItem(
        nextItem.item,
        price: nextItem.price,
        itemCatalog: catalog,
        consumeCheapestFirstOfferDiscount: nextItem.isCompassDiscounted,
      ),
      isTrue,
    );
    expect(goldBeforeSecond - progress.gold, nextItem.price);
  });

  test('Item이 나침반 대상이어도 진열 가격만 청구하고 할인을 소비한다', () {
    final catalog = _catalog();
    final progress = RummiRunProgress()
      ..gold = 200
      ..shopOffers.add(
        RummiShopOffer(
          slotIndex: 0,
          card: _jester(id: 'audit_jester_pricey', baseCost: 30),
          price: 30,
        ),
      );
    progress.queueMarketModifier(
      op: 'discount_cheapest_first_offer',
      amount: 2,
    );

    final market = RummiMarketRuntimeFacade.fromRunProgress(
      progress,
      itemCatalog: catalog,
    );
    final target = market.itemOffers.firstWhere(
      (offer) => offer.isCompassDiscounted,
    );

    final goldBefore = progress.gold;
    expect(
      progress.buyItem(
        target.item,
        price: target.price,
        itemCatalog: catalog,
        consumeCheapestFirstOfferDiscount: target.isCompassDiscounted,
      ),
      isTrue,
    );

    expect(goldBefore - progress.gold, target.price);
    expect(progress.marketModifiers.cheapestFirstOfferDiscount, 0);
  });
}
