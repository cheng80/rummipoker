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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'GameShopScreen names the grown rank after market growth item use',
    (tester) async {
      tester.view.physicalSize = const Size(1280, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final useItem = ItemDefinition.fromJson(const <String, dynamic>{
        'id': 'straight_flush_study',
        'displayName': 'Straight Flush Study',
        'type': 'consumable',
        'rarity': 'rare',
        'basePrice': 12,
        'sellPrice': 6,
        'stackable': false,
        'maxStack': 1,
        'sellable': true,
        'usableInBattle': false,
        'placement': 'inventory',
        'slotHint': 'utility',
        'effectText': 'Use in the shop to give Straight Flush growth +1.',
        'effect': <String, dynamic>{
          'timing': 'use_market',
          'op': 'add_hand_rank_progress',
          'rank': 'straightFlush',
          'amount': 1,
          'consume': true,
        },
        'tags': <String>['consumable', 'rank_growth', 'planet_like'],
        'sourceNotes': 'Test fixture.',
      });
      var useCalled = false;
      var currentMarket = RummiMarketRuntimeFacade(
        gold: 12,
        rerollCost: 5,
        maxOwnedSlots: RummiRunProgress.maxJesterSlots,
        runtimeSnapshot: const RummiJesterRuntimeSnapshot(),
        ownedEntries: const [],
        offers: const [],
        itemOfferSlotCount: 3,
        quickSlotCapacity: RunInventoryState.defaultQuickSlotCapacity,
        itemOffers: const [],
        itemSlots: [
          RummiMarketItemSlotView.fromOwnedItem(
            slotIndex: 0,
            slotLabel: 'T1',
            entry: const OwnedItemEntry(
              itemId: 'straight_flush_study',
              count: 1,
              placement: ItemPlacement.inventory,
            ),
            item: useItem,
          ),
        ],
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
                      readActiveRunSaveView: () =>
                          const RummiActiveRunSaveFacade(
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
                          ),
                      onReroll: () => null,
                      onBuyOffer: (_) => null,
                      onBuyItemOffer: (_) => null,
                      onBuyTileOffer: (_) => null,
                      onUseMarketItem: (item) {
                        useCalled = true;
                        expect(item.id, 'straight_flush_study');
                        currentMarket = RummiMarketRuntimeFacade(
                          gold: 12,
                          rerollCost: 5,
                          maxOwnedSlots: currentMarket.maxOwnedSlots,
                          runtimeSnapshot: currentMarket.runtimeSnapshot,
                          ownedEntries: currentMarket.ownedEntries,
                          offers: currentMarket.offers,
                          itemOfferSlotCount: currentMarket.itemOfferSlotCount,
                          quickSlotCapacity: currentMarket.quickSlotCapacity,
                          itemOffers: currentMarket.itemOffers,
                          itemSlots: const [],
                        );
                        return null;
                      },
                      onSellOwnedJester: (_) => false,
                      onSellMarketItem: (_) => false,
                      onStateChanged: () async {},
                      onOpenSettings: () async {},
                      onExitToTitle: () async {},
                      onRestartRun: () async {},
                      isDebugFixtureRun: false,
                      initialItemShopTab: true,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('market-item-slot-T1')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('사용'));
      await tester.pump(const Duration(milliseconds: 120));

      expect(useCalled, isTrue);
      expect(find.byKey(const ValueKey('market-use-feedback')), findsOneWidget);
      expect(find.text('스티플 연구'), findsWidgets);
      expect(find.text('스티플 성장 +1'), findsOneWidget);
      await tester.pump(const Duration(seconds: 3));
    },
  );
}
