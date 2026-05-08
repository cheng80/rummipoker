import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rummipoker/logic/rummi_poker_grid/item_definition.dart';
import 'package:rummipoker/logic/rummi_poker_grid/jester_meta.dart';
import 'package:rummipoker/logic/rummi_poker_grid/rummi_market_facade.dart';
import 'package:rummipoker/resources/item_translation_scope.dart';
import 'package:rummipoker/resources/jester_translation_scope.dart';
import 'package:rummipoker/services/active_run_save_facade.dart';
import 'package:rummipoker/views/game/widgets/game_shop_screen.dart';

RummiJesterCard _jester({required String id, required String displayName}) {
  return RummiJesterCard(
    id: id,
    displayName: displayName,
    rarity: RummiJesterRarity.common,
    baseCost: 4,
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
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('다음 Station은 직전 market 저장 완료 후 route를 닫는다', (tester) async {
    tester.view.physicalSize = const Size(1280, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final offerCard = _jester(id: 'timing_card', displayName: 'Timing');
    var currentMarket = RummiMarketRuntimeFacade(
      gold: 12,
      rerollCost: 5,
      maxOwnedSlots: RummiRunProgress.maxJesterSlots,
      runtimeSnapshot: const RummiJesterRuntimeSnapshot(),
      ownedEntries: const [],
      offers: [
        RummiMarketOfferView.fromShopOffer(
          RummiShopOffer(slotIndex: 0, card: offerCard, price: 4),
          currentGold: 12,
        ),
      ],
      itemOfferSlotCount: 3,
      quickSlotCapacity: RunInventoryState.defaultQuickSlotCapacity,
    );
    const currentSave = RummiActiveRunSaveFacade(
      schemaVersion: 2,
      activeScene: 'shop',
      sceneAlias: RummiSaveSceneAlias.market,
      currentStageIndex: 2,
      currentStationIndex: 2,
      currentRunSeed: 77,
      currentGold: 12,
      checkpoint: RummiStationCheckpointSaveView(
        stageIndex: 2,
        stationIndex: 2,
        runSeed: 77,
        gold: 12,
      ),
    );
    final pendingPurchaseSave = Completer<void>();
    var saveCallCount = 0;
    bool? poppedValue;

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
              home: Scaffold(
                body: Builder(
                  builder: (context) => ElevatedButton(
                    onPressed: () {
                      Navigator.of(context)
                          .push<bool>(
                            MaterialPageRoute(
                              builder: (_) => JesterTranslationScope(
                                child: ItemTranslationScope(
                                  child: GameShopScreen(
                                    runSeed: 77,
                                    readMarketView: () => currentMarket,
                                    readActiveRunSaveView: () => currentSave,
                                    onReroll: () => null,
                                    onRerollItemOffers: (_) => null,
                                    onBuyOffer: (index) {
                                      expect(index, 0);
                                      currentMarket = RummiMarketRuntimeFacade(
                                        gold: 8,
                                        rerollCost: 5,
                                        maxOwnedSlots:
                                            RummiRunProgress.maxJesterSlots,
                                        runtimeSnapshot:
                                            const RummiJesterRuntimeSnapshot(),
                                        ownedEntries: [
                                          RummiMarketOwnedEntryView(
                                            slotIndex: 0,
                                            category:
                                                RummiMarketCategory.jester,
                                            contentId: offerCard.id,
                                            displayName: offerCard.displayName,
                                            sellPrice: 2,
                                            card: offerCard,
                                          ),
                                        ],
                                        offers: const [],
                                        itemOfferSlotCount: 3,
                                        quickSlotCapacity:
                                            currentMarket.quickSlotCapacity,
                                      );
                                      return null;
                                    },
                                    onBuyItemOffer: (_) => null,
                                    onUseMarketItem: (_) => null,
                                    onSellOwnedJester: (_) => false,
                                    onSellMarketItem: (_) => false,
                                    onStateChanged: () async {
                                      saveCallCount++;
                                      if (saveCallCount == 2) {
                                        await pendingPurchaseSave.future;
                                      }
                                    },
                                    onOpenSettings: () async {},
                                    onExitToTitle: () async {},
                                    onRestartRun: () async {},
                                    isDebugFixtureRun: false,
                                  ),
                                ),
                              ),
                            ),
                          )
                          .then((value) => poppedValue = value);
                    },
                    child: const Text('open shop'),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );

    await tester.pumpAndSettle();
    await tester.tap(find.text('open shop'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('구매'));
    await tester.pump(const Duration(milliseconds: 120));
    await tester.tap(find.text('다음 Station'));
    await tester.pump(const Duration(milliseconds: 120));

    expect(poppedValue, isNull);
    expect(find.text('다음 Station'), findsOneWidget);

    pendingPurchaseSave.complete();
    await tester.pumpAndSettle();

    expect(poppedValue, isTrue);
    expect(find.text('open shop'), findsOneWidget);
  });
}
