import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:rummipoker/app_config.dart';
import 'package:rummipoker/logic/rummi_poker_grid/item_definition.dart';
import 'package:rummipoker/logic/rummi_poker_grid/rummi_market_facade.dart';
import 'package:rummipoker/main.dart' as app;
import 'package:rummipoker/providers/features/rummi_poker_grid/game_session_notifier.dart';
import 'package:rummipoker/providers/features/rummi_poker_grid/game_session_state.dart';
import 'package:rummipoker/router.dart';
import 'package:rummipoker/services/debug_run_fixture_service.dart';
import 'package:rummipoker/services/game_settings.dart';
import 'package:rummipoker/services/tutorial_state_service.dart';
import 'package:rummipoker/utils/storage_helper.dart';
import 'package:rummipoker/views/game_view.dart';
import 'package:rummipoker/views/game/widgets/game_shop_screen.dart';
import 'package:rummipoker/views/game/widgets/game_shared_widgets.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'market discount visual bot checks repeated fixture interactions',
    (tester) async {
      binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;
      binding.shouldPropagateDevicePointerEvents = true;
      final bot = _MarketDiscountVisualBot(
        tester: tester,
        config: _MarketDiscountBotConfig.fromEnvironment(),
      );
      try {
        await bot.run();
      } finally {
        binding.shouldPropagateDevicePointerEvents = false;
      }
    },
    timeout: const Timeout(Duration(minutes: 30)),
  );
}

class _MarketDiscountBotConfig {
  const _MarketDiscountBotConfig({
    required this.iterations,
    required this.localeName,
    required this.actionDelay,
    required this.scenario,
  });

  factory _MarketDiscountBotConfig.fromEnvironment() {
    return _MarketDiscountBotConfig(
      iterations: const int.fromEnvironment(
        'MARKET_DISCOUNT_BOT_ITERATIONS',
        defaultValue: 1,
      ),
      localeName: const String.fromEnvironment(
        'MARKET_DISCOUNT_BOT_LOCALE',
        defaultValue: 'ko',
      ),
      scenario: const String.fromEnvironment(
        'MARKET_DISCOUNT_BOT_SCENARIO',
        defaultValue: 'jester_discount_purchase_sale',
      ),
      actionDelay: Duration(
        milliseconds: const int.fromEnvironment(
          'MARKET_DISCOUNT_BOT_ACTION_DELAY_MS',
          defaultValue: 220,
        ),
      ),
    );
  }

  final int iterations;
  final String localeName;
  final Duration actionDelay;
  final String scenario;

  Locale get locale => switch (localeName) {
    'en' => const Locale('en'),
    'ja' => const Locale('ja'),
    'zh-CN' || 'zh_CN' => const Locale('zh', 'CN'),
    'zh-TW' || 'zh_TW' => const Locale('zh', 'TW'),
    _ => const Locale('ko'),
  };
}

/// 상점 할인 표시와 구매/리롤/판매 피드백을 실제 Chrome UI 조작으로 확인한다.
///
/// `market_modifier_shop` fixture는 full-play 증거가 아니라 최근 상점 회귀를
/// 반복 눈검증하기 위한 고정 상태다.
class _MarketDiscountVisualBot {
  _MarketDiscountVisualBot({required this.tester, required this.config});

  final WidgetTester tester;
  final _MarketDiscountBotConfig config;
  final List<String> log = <String>[];
  int _openSequence = 0;

  Future<void> run() async {
    expect(config.iterations, greaterThan(0));
    app.main();
    await _pumpFor(const Duration(seconds: 5));
    await StorageHelper.erase();
    await TutorialStateService.markBattleIntroSeen();
    await TutorialStateService.markMarketIntroSeen();
    await tester.element(find.byType(MaterialApp)).setLocale(config.locale);
    GameSettings.bgmMuted = true;
    GameSettings.sfxMuted = true;
    await _pumpFor(const Duration(seconds: 1));
    _record(
      'start scenario=${config.scenario} iterations=${config.iterations} '
      'locale=${config.localeName}',
    );

    for (var i = 1; i <= config.iterations; i++) {
      await _runScenario(config.scenario, i);
    }

    debugPrint('MARKET_DISCOUNT_VISUAL_BOT_PASS');
    for (final entry in log) {
      debugPrint('MARKET_DISCOUNT_VISUAL_BOT: $entry');
    }
  }

  Future<void> _runScenario(String scenario, int iteration) async {
    switch (scenario) {
      case 'jester_discount_purchase_sale':
        await _runJesterPurchaseAndSaleCycle(iteration);
      case 'item_discount_offer_visual':
        await _runItemOfferVisualCycle(iteration);
      case 'passive_sell_offer_stability':
        await _runItemSellOfferStabilityCycle(iteration);
      case 'reroll_discount_feedback':
        await _runRerollCycle(iteration);
      case 'baseline_jester_prices':
        await _runBaselineJesterPriceCycle(iteration);
      case 'baseline_item_prices':
        await _runBaselineItemPriceCycle(iteration);
      case 'slot_unlock_market_visual':
        await _runSlotUnlockMarketCycle(iteration);
      default:
        fail('Unknown MARKET_DISCOUNT_BOT_SCENARIO: $scenario');
    }
  }

  Future<void> _openMarketFixture({
    String fixtureId = DebugRunFixtureService.marketModifierShop,
    String? extraQuery,
  }) async {
    final query = StringBuffer('fixture=$fixtureId');
    query.write('&bot_open=${_openSequence++}');
    if (extraQuery != null && extraQuery.isNotEmpty) {
      query.write('&$extraQuery');
    }
    appRouter.go('${RoutePaths.game}?$query');
    await _pumpUntilVisible(find.text('Market'));
    await _pumpFor(const Duration(seconds: 1));
    expect(find.text('다음'), findsNothing);
    expect(find.text('Next'), findsNothing);
  }

  Future<void> _runJesterPurchaseAndSaleCycle(int iteration) async {
    await _openMarketFixture();
    final before = _readGameState();
    final market = _readShopMarketView();
    final progress = before.runProgress!;
    expect(market.gold, 18);
    expect(market.rerollCost, 4);
    expect(progress.marketModifiers.nextJesterPurchaseDiscount, greaterThan(0));
    expect(progress.marketModifiers.cheapestFirstOfferDiscount, greaterThan(0));
    expect(market.offers, isNotEmpty);
    final offer = market.offers.first;
    expect(offer.hasDiscount, isTrue);
    expect(offer.price, lessThan(offer.originalPrice));
    await _verifyDiscountLabel(
      price: offer.price,
      originalPrice: offer.originalPrice,
    );
    await _verifyVisibleText('리롤 ${market.rerollCost}');
    _record(
      'iter=$iteration jester before gold=${market.gold} '
      'price=${offer.price}/${offer.originalPrice} '
      'discounts=next:${progress.marketModifiers.nextJesterPurchaseDiscount} '
      'cheapest:${progress.marketModifiers.cheapestFirstOfferDiscount}',
    );

    await _tapText('${offer.price}G');
    await _tapText('구매');
    await _pumpUntilState(
      (state) => state.marketView!.ownedEntries.any(
        (entry) => entry.contentId == offer.contentId,
      ),
    );
    final bought = _readGameState();
    expect(_readShopMarketView().gold, market.gold - offer.price);
    expect(bought.runProgress!.marketModifiers.nextJesterPurchaseDiscount, 0);
    expect(bought.runProgress!.marketModifiers.cheapestFirstOfferDiscount, 0);
    _record(
      'iter=$iteration jester bought gold=${bought.marketView!.gold} '
      'owned=${bought.marketView!.ownedEntries.length}',
    );

    await _tapText('판매');
    await _pumpUntilVisible(find.byKey(const ValueKey('market-sale-flight')));
    await _pumpUntilState(
      (state) => state.marketView!.ownedEntries.every(
        (entry) => entry.contentId != offer.contentId,
      ),
    );
    final sold = _readGameState();
    expect(_readShopMarketView().gold, greaterThan(bought.marketView!.gold));
    _record(
      'iter=$iteration jester sold gold=${sold.marketView!.gold} '
      'saleFlight=visible',
    );
  }

  Future<void> _runItemOfferVisualCycle(int iteration) async {
    await _openMarketFixture(extraQuery: 'debug_shop_tab=items');
    await _tapTextIfVisible('Tool / Gear');
    final before = _readShopMarketView();
    final offers = before.itemOffers;
    expect(offers, isNotEmpty);

    var verified = false;
    for (final offer in offers) {
      await _selectItemOfferLaneForPlacement(offer.item.placement);
      await _pumpFor(config.actionDelay);
      final itemCardFinder = find.byWidgetPredicate(
        (widget) => widget.runtimeType.toString() == '_MarketItemOfferCard',
        description: 'market item offer card',
      );
      await _pumpUntilVisible(itemCardFinder);
      await tester.tap(itemCardFinder.first, warnIfMissed: false);
      await _pumpFor(const Duration(milliseconds: 600));
      if (!_discountLabelVisible(
        price: offer.price,
        originalPrice: offer.originalPrice,
      )) {
        continue;
      }
      _record(
        'iter=$iteration item offer visible id=${offer.item.id} '
        'placement=${offer.item.placement.name} '
        'price=${offer.price}/${offer.originalPrice} '
        'discounted=${offer.hasDiscount}',
      );
      verified = true;
      break;
    }
    expect(
      verified,
      isTrue,
      reason: 'item offer price label should be visible',
    );
  }

  Future<void> _runItemSellOfferStabilityCycle(int iteration) async {
    await _openMarketFixture();
    await _tapTextIfVisible('Jester / Slots');
    await _tapTextIfVisible('Passive');
    final before = _readShopMarketView();
    final passiveOffers = before.itemOffers
        .where((offer) => offer.item.placement == ItemPlacement.passiveRack)
        .toList();
    expect(passiveOffers, isNotEmpty);
    final trackedOffer = passiveOffers.first;
    await _verifyDiscountLabel(
      price: trackedOffer.price,
      originalPrice: trackedOffer.originalPrice,
    );
    final slotFinder = find.byKey(const ValueKey('market-item-slot-P1'));
    expect(slotFinder, findsWidgets);
    await tester.tap(slotFinder.first, warnIfMissed: false);
    await _pumpFor(const Duration(milliseconds: 500));
    await _tapText('판매');
    await _pumpUntilVisible(find.byKey(const ValueKey('market-sale-flight')));
    await _verifyDiscountLabel(
      price: trackedOffer.price,
      originalPrice: trackedOffer.originalPrice,
    );
    expect(find.text('할인'), findsWidgets);
    _record(
      'iter=$iteration passive sell kept offer visible '
      'price=${trackedOffer.price}/${trackedOffer.originalPrice}',
    );
  }

  Future<void> _runRerollCycle(int iteration) async {
    await _openMarketFixture();
    final before = _readShopMarketView();
    final oldIds = before.offers.map((offer) => offer.contentId).join(',');
    final rerollCost = before.rerollCost;
    expect(rerollCost, 4);
    await _tapText('리롤 $rerollCost');
    await _pumpUntilVisible(find.text('리롤 확인'));
    await _tapText('리롤');
    await _pumpUntilVisible(
      find.byKey(const ValueKey('market-reroll-success-feedback')),
    );
    await _pumpUntilState((state) => _readShopMarketView().gold < before.gold);
    final after = _readShopMarketView();
    final chargedGold = before.gold - after.gold;
    expect(chargedGold, greaterThan(0));
    expect(chargedGold, lessThanOrEqualTo(rerollCost));
    final nextIds = after.offers.map((offer) => offer.contentId).join(',');
    _record(
      'iter=$iteration reroll cost=$rerollCost '
      'charged=$chargedGold gold=${before.gold}->${after.gold} '
      'offers=$oldIds->$nextIds',
    );
  }

  Future<void> _runBaselineJesterPriceCycle(int iteration) async {
    await _openMarketFixture(
      fixtureId: DebugRunFixtureService.stage2MarketResume,
    );
    await _tapTextIfVisible('Jester / Slots');
    final market = _readShopMarketView();
    expect(market.offers, isNotEmpty);
    final offer = market.offers.first;
    expect(offer.hasDiscount, isFalse);
    await _verifyDiscountLabel(
      price: offer.price,
      originalPrice: offer.originalPrice,
    );
    expect(find.text('할인'), findsNothing);
    _record(
      'iter=$iteration baseline jester price visible '
      'id=${offer.contentId} price=${offer.price}/${offer.originalPrice}',
    );
  }

  Future<void> _runBaselineItemPriceCycle(int iteration) async {
    await _openMarketFixture(
      fixtureId: DebugRunFixtureService.stage2MarketResume,
      extraQuery: 'debug_shop_tab=items',
    );
    await _tapTextIfVisible('Tool / Gear');
    final market = _readShopMarketView();
    expect(market.itemOffers, isNotEmpty);
    var verified = false;
    for (final offer in market.itemOffers) {
      expect(offer.hasDiscount, isFalse);
      await _selectItemOfferLaneForPlacement(offer.item.placement);
      await _pumpFor(config.actionDelay);
      if (!_discountLabelVisible(
        price: offer.price,
        originalPrice: offer.originalPrice,
      )) {
        continue;
      }
      expect(find.text('할인'), findsNothing);
      _record(
        'iter=$iteration baseline item price visible '
        'id=${offer.contentId} placement=${offer.item.placement.name} '
        'price=${offer.price}/${offer.originalPrice}',
      );
      verified = true;
      break;
    }
    expect(
      verified,
      isTrue,
      reason: 'baseline item price label should be visible',
    );
  }

  Future<void> _runSlotUnlockMarketCycle(int iteration) async {
    await _openMarketFixture(
      fixtureId: DebugRunFixtureService.slotUnlockMarket,
      extraQuery: 'debug_shop_tab=items',
    );
    final market = _readShopMarketView();
    expect(market.jesterSlotCapacity, greaterThanOrEqualTo(3));
    expect(market.quickSlotCapacity, greaterThanOrEqualTo(1));
    expect(market.itemSlots, isNotEmpty);
    await _tapTextIfVisible('Jester / Slots');
    await _verifyVisibleText('Jester / Slots');
    await _tapTextIfVisible('Tool / Gear');
    await _verifyVisibleText('Tool / Gear');
    _record(
      'iter=$iteration slot unlock market visible '
      'jesterSlots=${market.jesterSlotCapacity} '
      'quickSlots=${market.quickSlotCapacity} '
      'itemSlots=${market.itemSlots.length}',
    );
  }

  Future<void> _selectItemOfferLaneForPlacement(ItemPlacement placement) async {
    switch (placement) {
      case ItemPlacement.quickSlot:
        await _tapTextIfVisible('Jester / Slots');
        await _tapTextIfVisible('Q-Slot');
      case ItemPlacement.passiveRack:
        await _tapTextIfVisible('Jester / Slots');
        await _tapTextIfVisible('Passive');
      case ItemPlacement.inventory:
        await _tapTextIfVisible('Tool / Gear');
        await _tapTextIfVisible('Tool');
      case ItemPlacement.equipped:
        await _tapTextIfVisible('Tool / Gear');
        await _tapTextIfVisible('Gear');
    }
  }

  GameSessionState _readGameState() {
    final gameViewFinder = find.byType(GameView, skipOffstage: false);
    expect(gameViewFinder, findsOneWidget);
    final gameView = tester.widget<GameView>(gameViewFinder.first);
    final element = tester.element(gameViewFinder.first);
    final container = ProviderScope.containerOf(element);
    final args = GameSessionArgs(
      runSeed: gameView.runSeed,
      restoredRun: gameView.restoredRun,
      debugFixtureId: gameView.debugFixtureId,
      difficulty: gameView.difficulty,
      runModifier: gameView.runModifier,
      blindTier: gameView.blindTier,
    );
    final state = container.read(gameSessionNotifierProvider(args));
    expect(state.marketView, isNotNull);
    expect(state.runProgress, isNotNull);
    return state;
  }

  RummiMarketRuntimeFacade _readShopMarketView() {
    final shopFinder = find.byType(GameShopScreen, skipOffstage: false);
    expect(shopFinder, findsOneWidget);
    final shop = tester.widget<GameShopScreen>(shopFinder.first);
    return shop.readMarketView();
  }

  Future<void> _tapText(String text) async {
    final finder = await _pumpUntilTappableText(text);
    await tester.tap(finder.first, warnIfMissed: false);
    await _pumpFor(config.actionDelay);
  }

  Future<void> _tapTextIfVisible(String text) async {
    final finder = _visibleButtonOrTextFinder(text);
    if (finder.evaluate().isEmpty) return;
    await tester.tap(finder.first, warnIfMissed: false);
    await _pumpFor(config.actionDelay);
  }

  Future<void> _verifyVisibleText(String text) async {
    await _pumpUntilVisible(_visibleButtonOrTextFinder(text));
  }

  Future<void> _verifyDiscountLabel({
    required int price,
    required int originalPrice,
  }) async {
    await _verifyVisibleText('${price}G');
    if (originalPrice > price) {
      await _verifyVisibleText('${originalPrice}G');
      await _verifyVisibleText('할인');
    }
  }

  bool _discountLabelVisible({required int price, required int originalPrice}) {
    if (find.text('${price}G').evaluate().isEmpty) return false;
    if (originalPrice <= price) return true;
    return find.text('${originalPrice}G').evaluate().isNotEmpty &&
        find.text('할인').evaluate().isNotEmpty;
  }

  Finder _visibleButtonOrTextFinder(String text) {
    final actionButton = find.widgetWithText(GameActionButton, text);
    if (actionButton.evaluate().isNotEmpty) return actionButton;
    return find.text(text);
  }

  Future<Finder> _pumpUntilTappableText(
    String text, {
    Duration timeout = const Duration(seconds: 20),
  }) async {
    final end = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(end)) {
      await tester.pump(const Duration(milliseconds: 100));
      final finder = _visibleButtonOrTextFinder(text);
      if (finder.evaluate().isNotEmpty) return finder;
    }
    fail('Timed out waiting for tappable text "$text"');
  }

  Future<void> _pumpUntilVisible(
    Finder finder, {
    Duration timeout = const Duration(seconds: 20),
  }) async {
    final end = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(end)) {
      await tester.pump(const Duration(milliseconds: 100));
      if (finder.evaluate().isNotEmpty) return;
    }
    fail('Timed out waiting for $finder');
  }

  Future<void> _pumpUntilState(
    bool Function(GameSessionState state) predicate, {
    Duration timeout = const Duration(seconds: 20),
  }) async {
    final end = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(end)) {
      await tester.pump(const Duration(milliseconds: 100));
      if (predicate(_readGameState())) return;
    }
    fail('Timed out waiting for market state update');
  }

  Future<void> _pumpFor(Duration duration) async {
    final end = DateTime.now().add(duration);
    while (DateTime.now().isBefore(end)) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  void _record(String entry) {
    log.add(entry);
    debugPrint('MARKET_DISCOUNT_VISUAL_BOT: $entry');
  }
}
