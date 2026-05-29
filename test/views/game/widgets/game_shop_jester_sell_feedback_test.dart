import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rummipoker/logic/rummi_poker_grid/item_definition.dart';
import 'package:rummipoker/logic/rummi_poker_grid/jester_meta.dart';
import 'package:rummipoker/logic/rummi_poker_grid/rummi_market_facade.dart';
import 'package:rummipoker/resources/item_translation_scope.dart';
import 'package:rummipoker/resources/jester_translation_scope.dart';
import 'package:rummipoker/services/active_run_save_facade.dart';
import 'package:rummipoker/views/game/widgets/game_jester_widgets.dart';
import 'package:rummipoker/views/game/widgets/game_shop_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('GameShopScreen flies sold jester card toward gold chip', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final card = RummiJesterCard(
      id: 'blue_jester',
      displayName: 'Blue Jester',
      rarity: RummiJesterRarity.common,
      baseCost: 4,
      effectText: 'Gain chips.',
      effectType: 'chips_bonus',
      trigger: 'onScore',
      conditionType: 'none',
      conditionValue: null,
      value: 12,
      xValue: null,
      mappedTileColors: const [],
      mappedTileNumbers: const [],
    );
    var sellCalled = false;
    var currentMarket = RummiMarketRuntimeFacade(
      gold: 4,
      rerollCost: 5,
      maxOwnedSlots: RummiRunProgress.maxJesterSlots,
      runtimeSnapshot: const RummiJesterRuntimeSnapshot(),
      ownedEntries: [
        RummiMarketOwnedEntryView(
          slotIndex: 0,
          category: RummiMarketCategory.jester,
          contentId: card.id,
          displayName: card.displayName,
          sellPrice: 3,
          card: card,
        ),
      ],
      offers: const [],
      itemOfferSlotCount: 3,
      quickSlotCapacity: RunInventoryState.defaultQuickSlotCapacity,
      itemOffers: const [],
      itemSlots: const [],
    );

    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: const [Locale('ko'), Locale('en')],
        path: 'assets/translations',
        fallbackLocale: const Locale('ko'),
        startLocale: const Locale('ko'),
        saveLocale: false,
        child: Builder(
          builder: (context) {
            return MaterialApp(
              locale: context.locale,
              supportedLocales: context.supportedLocales,
              localizationsDelegates: context.localizationDelegates,
              home: JesterTranslationScope(
                child: ItemTranslationScope(
                  child: GameShopScreen(
                    runSeed: 77,
                    readMarketView: () => currentMarket,
                    readActiveRunSaveView: () => const RummiActiveRunSaveFacade(
                      schemaVersion: 2,
                      activeScene: 'shop',
                      sceneAlias: RummiSaveSceneAlias.market,
                      currentStageIndex: 2,
                      currentStationIndex: 2,
                      currentRunSeed: 77,
                      currentGold: 4,
                      checkpoint: RummiStationCheckpointSaveView(
                        stageIndex: 2,
                        stationIndex: 2,
                        runSeed: 77,
                        gold: 4,
                      ),
                    ),
                    onReroll: () => null,
                    onBuyOffer: (_) => null,
                    onBuyItemOffer: (_) => null,
                    onBuyTileOffer: (_) => null,
                    onUseMarketItem: (_) => null,
                    onSellOwnedJester: (index) {
                      sellCalled = true;
                      expect(index, 0);
                      currentMarket = RummiMarketRuntimeFacade(
                        gold: 7,
                        rerollCost: 5,
                        maxOwnedSlots: currentMarket.maxOwnedSlots,
                        runtimeSnapshot: currentMarket.runtimeSnapshot,
                        ownedEntries: const [],
                        offers: currentMarket.offers,
                        itemOfferSlotCount: currentMarket.itemOfferSlotCount,
                        quickSlotCapacity: currentMarket.quickSlotCapacity,
                        itemOffers: currentMarket.itemOffers,
                        itemSlots: currentMarket.itemSlots,
                      );
                      return true;
                    },
                    onSellMarketItem: (_) => false,
                    onStateChanged: () async {},
                    onOpenSettings: () async {},
                    onExitToTitle: () async {},
                    onRestartRun: () async {},
                    isDebugFixtureRun: false,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(GameJesterSlot).first);
    await tester.pumpAndSettle();

    await tester.tap(find.text('판매'));
    await tester.pump(const Duration(milliseconds: 120));

    expect(sellCalled, isTrue);
    expect(find.byKey(const ValueKey('market-sale-flight')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('market-sale-flight-jester-card')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('market-gold-gain-badge')),
      findsOneWidget,
    );
    expect(find.text('+3G'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 700));
    expect(find.byKey(const ValueKey('market-sale-flight')), findsNothing);
    await tester.pump(const Duration(seconds: 3));
  });
}
