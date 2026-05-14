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

Future<void> _pumpShopScreen(
  WidgetTester tester, {
  required RummiMarketRuntimeFacade Function() readMarketView,
  required String? Function() onReroll,
  String? Function(RummiMarketOfferView offer)? onBuyOffer,
}) async {
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
                  key: UniqueKey(),
                  runSeed: 77,
                  readMarketView: readMarketView,
                  readActiveRunSaveView: () => const RummiActiveRunSaveFacade(
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
                      gold: 10,
                    ),
                  ),
                  onReroll: onReroll,
                  onBuyOffer: onBuyOffer ?? ((_) => null),
                  onBuyItemOffer: (_) => null,
                  onBuyTileOffer: (_) => null,
                  onUseMarketItem: (_) => null,
                  onSellOwnedJester: (_) => false,
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
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Market reroll reveals refreshed offers without layout shift', (
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

    final firstOffer = _jester(id: 'first_offer', displayName: 'First');
    final secondOffer = _jester(id: 'second_offer', displayName: 'Second');
    var currentMarket = RummiMarketRuntimeFacade(
      gold: 12,
      rerollCost: 5,
      maxOwnedSlots: RummiRunProgress.maxJesterSlots,
      runtimeSnapshot: const RummiJesterRuntimeSnapshot(),
      ownedEntries: const [],
      offers: [
        RummiMarketOfferView.fromShopOffer(
          RummiShopOffer(slotIndex: 0, card: firstOffer, price: 4),
          currentGold: 12,
        ),
      ],
      itemOfferSlotCount: 3,
      quickSlotCapacity: RunInventoryState.defaultQuickSlotCapacity,
      itemOffers: const [],
    );

    await _pumpShopScreen(
      tester,
      readMarketView: () => currentMarket,
      onReroll: () {
        currentMarket = RummiMarketRuntimeFacade(
          gold: 7,
          rerollCost: 5,
          maxOwnedSlots: RummiRunProgress.maxJesterSlots,
          runtimeSnapshot: const RummiJesterRuntimeSnapshot(),
          ownedEntries: const [],
          offers: [
            RummiMarketOfferView.fromShopOffer(
              RummiShopOffer(slotIndex: 0, card: secondOffer, price: 4),
              currentGold: 7,
            ),
          ],
          itemOfferSlotCount: 3,
          quickSlotCapacity: RunInventoryState.defaultQuickSlotCapacity,
          itemOffers: const [],
        );
        return null;
      },
    );

    final offerReveal = find.byKey(
      const ValueKey<String>('market-offer-stagger-0'),
    );
    expect(offerReveal, findsOneWidget);
    final initialOfferSize = tester.getSize(offerReveal);

    await tester.tap(find.text('리롤 5'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('리롤').last);
    await tester.pump(const Duration(milliseconds: 80));

    expect(offerReveal, findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('market-reroll-success-feedback')),
      findsOneWidget,
    );
    expect(tester.getSize(offerReveal), initialOfferSize);

    await tester.pumpAndSettle();
  });
}
