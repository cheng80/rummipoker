import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:rummipoker/logic/rummi_poker_grid/item_definition.dart';
import 'package:rummipoker/logic/rummi_poker_grid/jester_meta.dart';
import 'package:rummipoker/logic/rummi_poker_grid/rummi_market_facade.dart';
import 'package:rummipoker/providers/features/rummi_poker_grid/game_session_notifier.dart';

/// 마켓 가격 라벨과 실제 청구 금액이 같은지 검사한다.
///
/// 화면에 보이는 가격은 `RummiMarketRuntimeFacade`가 만들고, 실제 청구는
/// `GameSessionNotifier`의 구매 명령이 한다. 두 경로가 "가장 싼 첫 offer 할인"
/// 대상을 다르게 고르면 라벨과 청구 금액이 어긋난다. 이 테스트는 표시된 모든
/// offer를 하나씩 실제로 사 보고 줄어든 gold가 표시 가격과 같은지 확인한다.

/// 성장 접근 가격 상한(common 5골드)에 걸리지 않는 effectType을 쓴다.
/// 상한에 걸리면 서로 다른 baseCost가 같은 가격으로 눌려서 "가장 싼 offer"를
/// 구분할 수 없다.
RummiJesterCard _jester({
  required String id,
  required int baseCost,
  String effectType = 'gold_bonus',
}) {
  return RummiJesterCard(
    id: id,
    displayName: id,
    rarity: RummiJesterRarity.common,
    baseCost: baseCost,
    effectText: '',
    effectType: effectType,
    trigger: 'onScore',
    conditionType: 'none',
    conditionValue: null,
    value: 1,
    xValue: null,
    mappedTileColors: const [],
    mappedTileNumbers: const [],
  );
}

Map<String, dynamic> _itemJson({
  required String id,
  required int basePrice,
  required String placement,
}) {
  return <String, dynamic>{
    'id': id,
    'displayName': id,
    'type': 'utility',
    'rarity': 'common',
    'basePrice': basePrice,
    'sellPrice': 1,
    'stackable': false,
    'maxStack': 1,
    'sellable': true,
    'usableInBattle': false,
    'placement': placement,
    'slotHint': 'q',
    'effectText': 'Test effect.',
    'effect': <String, dynamic>{
      'timing': 'use_market',
      'op': 'gain_gold',
      'amount': 1,
      'consume': false,
    },
    'tags': <String>['test'],
    'sourceNotes': 'Test fixture.',
  };
}

/// 가격을 통제하려고 성장 접근 tag가 없는 아이템만 담은 카탈로그를 쓴다.
ItemCatalog _catalog(List<Map<String, dynamic>> items) {
  return ItemCatalog.fromJson(<String, dynamic>{
    'schemaVersion': 1,
    'catalogId': 'discount_parity_test',
    'items': items,
  });
}

/// 하나의 Market 상황을 만드는 설정이다.
///
/// 구매는 상태를 바꾸므로 offer 하나를 살 때마다 이 설정으로 새 런을 만든다.
class _MarketCase {
  const _MarketCase({
    required this.name,
    required this.jesterPrices,
    required this.itemPrices,
    required this.discount,
    this.rerollBeforeDisplay = false,
  });

  final String name;
  final List<int> jesterPrices;
  final List<int> itemPrices;
  final int discount;
  final bool rerollBeforeDisplay;

  /// 가격 하한과 슬롯 한도에 걸리지 않도록 넉넉히 준다.
  static const int gold = 200;

  ItemCatalog buildCatalog() {
    // placement가 같은 아이템은 한 slot만 진열되므로 하나씩 다른 placement에 둔다.
    const placements = ['quickSlot', 'passiveRack', 'inventory', 'equipped'];
    return _catalog([
      for (var i = 0; i < itemPrices.length; i++)
        _itemJson(
          id: 'parity_item_$i',
          basePrice: itemPrices[i],
          placement: placements[i % placements.length],
        ),
    ]);
  }

  void applyTo(RummiRunProgress progress) {
    progress
      ..gold = gold
      ..shopOffers.clear();
    for (var i = 0; i < jesterPrices.length; i++) {
      progress.shopOffers.add(
        RummiShopOffer(
          slotIndex: i,
          card: _jester(id: 'parity_jester_$i', baseCost: jesterPrices[i]),
          price: jesterPrices[i],
        ),
      );
    }
    if (discount > 0) {
      progress.queueMarketModifier(
        op: 'discount_cheapest_first_offer',
        amount: discount,
      );
    }
  }
}

/// 새 런을 만들고 케이스 설정을 적용한다.
({
  ProviderContainer container,
  GameSessionNotifier notifier,
  RummiRunProgress progress,
  ItemCatalog catalog,
})
_boot(_MarketCase marketCase, int seed) {
  final container = ProviderContainer();
  final args = GameSessionArgs(runSeed: seed);
  final notifier = container.read(gameSessionNotifierProvider(args).notifier);
  final progress = container
      .read(gameSessionNotifierProvider(args))
      .runProgress!;
  final catalog = marketCase.buildCatalog();
  marketCase.applyTo(progress);
  notifier.markDirty();
  if (marketCase.rerollBeforeDisplay) {
    // 진열을 한 번 갱신한 뒤의 상태를 본다. 리롤은 pin된 Item offer를 버리고
    // 새로 뽑으므로, 표시와 청구가 다른 후보를 고를 여지가 생긴다.
    _displayedMarket(progress, catalog);
    notifier.rerollItemOffersFromState(itemCatalog: catalog);
    notifier.markDirty();
  }
  return (
    container: container,
    notifier: notifier,
    progress: progress,
    catalog: catalog,
  );
}

RummiMarketRuntimeFacade _displayedMarket(
  RummiRunProgress progress,
  ItemCatalog catalog,
) {
  // `game_view.dart`의 `_readMarketViewWithItemOffers()`와 같은 방식이다.
  return RummiMarketRuntimeFacade.fromRunProgress(
    progress,
    itemCatalog: catalog,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final cases = <_MarketCase>[
    const _MarketCase(
      name: '가장 싼 것이 Jester',
      jesterPrices: [3, 9],
      itemPrices: [12, 15],
      discount: 2,
    ),
    const _MarketCase(
      name: '가장 싼 것이 Item',
      jesterPrices: [12, 15],
      itemPrices: [3, 9],
      discount: 2,
    ),
    const _MarketCase(
      name: 'Jester와 Item 가격이 같음',
      jesterPrices: [6, 14],
      itemPrices: [6, 14],
      discount: 2,
    ),
    const _MarketCase(
      name: '할인이 가격보다 큼(가격 하한)',
      jesterPrices: [3, 9],
      itemPrices: [12, 15],
      discount: 99,
    ),
    const _MarketCase(
      name: '할인 없음',
      jesterPrices: [3, 9],
      itemPrices: [12, 15],
      discount: 0,
    ),
    const _MarketCase(
      name: '리롤 뒤',
      jesterPrices: [3, 9],
      itemPrices: [12, 15],
      discount: 2,
      rerollBeforeDisplay: true,
    ),
  ];

  group('마켓 표시 가격과 청구 금액 대조', () {
    for (final marketCase in cases) {
      test('${marketCase.name}: 표시된 모든 offer의 청구 금액이 표시 가격과 같다', () {
        final probe = _boot(marketCase, 9100);
        addTearDown(probe.container.dispose);
        final displayed = _displayedMarket(probe.progress, probe.catalog);
        final jesterCount = displayed.offers.length;
        final itemCount = displayed.itemOffers.length;
        expect(jesterCount, greaterThan(0));
        expect(itemCount, greaterThan(0));

        for (var index = 0; index < jesterCount; index++) {
          final run = _boot(marketCase, 9200 + index);
          addTearDown(run.container.dispose);
          final market = _displayedMarket(run.progress, run.catalog);
          final offer = market.offers[index];
          final goldBefore = run.progress.gold;

          final fail = run.notifier.buyShopOfferView(
            offer,
            itemCatalog: run.catalog,
          );

          expect(fail, isNull, reason: '${marketCase.name} jester#$index');
          expect(
            goldBefore - run.progress.gold,
            offer.price,
            reason: '${marketCase.name} jester#$index(${offer.contentId})',
          );
        }

        for (var index = 0; index < itemCount; index++) {
          final run = _boot(marketCase, 9300 + index);
          addTearDown(run.container.dispose);
          final market = _displayedMarket(run.progress, run.catalog);
          final offer = market.itemOffers[index];
          final goldBefore = run.progress.gold;

          final fail = run.notifier.buyItemOffer(
            offer,
            itemCatalog: run.catalog,
          );

          expect(fail, isNull, reason: '${marketCase.name} item#$index');
          expect(
            goldBefore - run.progress.gold,
            offer.price,
            reason: '${marketCase.name} item#$index(${offer.contentId})',
          );
        }
      });

      test('${marketCase.name}: slot index로 사도 표시 가격대로 청구한다', () {
        final probe = _boot(marketCase, 9600);
        addTearDown(probe.container.dispose);
        final count = _displayedMarket(
          probe.progress,
          probe.catalog,
        ).offers.length;

        for (var index = 0; index < count; index++) {
          final run = _boot(marketCase, 9700 + index);
          addTearDown(run.container.dispose);
          final offer = _displayedMarket(
            run.progress,
            run.catalog,
          ).offers[index];
          final goldBefore = run.progress.gold;

          final fail = run.notifier.buyShopOffer(
            index,
            itemCatalog: run.catalog,
          );

          expect(fail, isNull, reason: '${marketCase.name} index#$index');
          expect(
            goldBefore - run.progress.gold,
            offer.price,
            reason: '${marketCase.name} index#$index(${offer.contentId})',
          );
        }
      });

      test('${marketCase.name}: 할인을 쓴 뒤 다음 구매도 표시 가격대로 청구한다', () {
        final probe = _boot(marketCase, 9400);
        addTearDown(probe.container.dispose);
        final firstMarket = _displayedMarket(probe.progress, probe.catalog);
        final firstCount = firstMarket.offers.length;

        for (var first = 0; first < firstCount; first++) {
          final run = _boot(marketCase, 9500 + first);
          addTearDown(run.container.dispose);
          final market = _displayedMarket(run.progress, run.catalog);
          expect(
            run.notifier.buyShopOfferView(
              market.offers[first],
              itemCatalog: run.catalog,
            ),
            isNull,
          );

          final afterMarket = _displayedMarket(run.progress, run.catalog);
          if (afterMarket.offers.isNotEmpty) {
            final next = afterMarket.offers.first;
            final goldBefore = run.progress.gold;
            expect(
              run.notifier.buyShopOfferView(next, itemCatalog: run.catalog),
              isNull,
            );
            expect(
              goldBefore - run.progress.gold,
              next.price,
              reason: '${marketCase.name} 첫 구매 jester#$first 뒤 jester',
            );
          }

          final itemMarket = _displayedMarket(run.progress, run.catalog);
          if (itemMarket.itemOffers.isNotEmpty) {
            final next = itemMarket.itemOffers.first;
            final goldBefore = run.progress.gold;
            expect(
              run.notifier.buyItemOffer(next, itemCatalog: run.catalog),
              isNull,
            );
            expect(
              goldBefore - run.progress.gold,
              next.price,
              reason: '${marketCase.name} 첫 구매 jester#$first 뒤 item',
            );
          }
        }
      });
    }
  });
}
