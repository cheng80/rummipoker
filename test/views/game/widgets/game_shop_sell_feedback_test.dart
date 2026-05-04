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

  testWidgets('GameShopScreen shows feedback after market item sell', (
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

    final sellItem = ItemDefinition.fromJson(const <String, dynamic>{
      'id': 'score_abacus',
      'displayName': 'Score Abacus',
      'type': 'equipment',
      'rarity': 'common',
      'basePrice': 4,
      'sellPrice': 2,
      'stackable': false,
      'maxStack': 1,
      'sellable': true,
      'usableInBattle': false,
      'placement': 'quickSlot',
      'slotHint': 'q',
      'effectText': 'Gain score support.',
      'effect': <String, dynamic>{
        'timing': 'station_start',
        'op': 'add_board_move',
        'amount': 1,
        'consume': false,
      },
      'tags': <String>['gear'],
      'sourceNotes': 'Test fixture.',
    });
    var sellCalled = false;
    var currentMarket = RummiMarketRuntimeFacade(
      gold: 4,
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
          slotLabel: 'Q1',
          entry: const OwnedItemEntry(
            itemId: 'score_abacus',
            count: 1,
            placement: ItemPlacement.quickSlot,
          ),
          item: sellItem,
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
                    onUseMarketItem: (_) => null,
                    onSellOwnedJester: (_) => false,
                    onSellMarketItem: (item) {
                      sellCalled = true;
                      expect(item.id, 'score_abacus');
                      currentMarket = RummiMarketRuntimeFacade(
                        gold: 6,
                        rerollCost: 5,
                        maxOwnedSlots: currentMarket.maxOwnedSlots,
                        runtimeSnapshot: currentMarket.runtimeSnapshot,
                        ownedEntries: currentMarket.ownedEntries,
                        offers: currentMarket.offers,
                        itemOfferSlotCount: currentMarket.itemOfferSlotCount,
                        quickSlotCapacity: currentMarket.quickSlotCapacity,
                        itemOffers: currentMarket.itemOffers,
                        itemSlots: const [
                          RummiMarketItemSlotView(
                            slotIndex: 0,
                            slotLabel: 'Q1',
                            placement: ItemPlacement.quickSlot,
                          ),
                        ],
                      );
                      return true;
                    },
                    onStateChanged: () async {},
                    onOpenSettings: () async {},
                    onExitToTitle: () async {},
                    onRestartRun: () async {},
                    isDebugFixtureRun: false,
                    initialItemShopTab: false,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('market-item-slot-Q1')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('판매'));
    await tester.pump(const Duration(milliseconds: 120));

    expect(sellCalled, isTrue);
    expect(find.byKey(const ValueKey('market-sale-flight')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('market-gold-gain-badge')),
      findsOneWidget,
    );
    expect(find.text('+2G'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('market-item-slot-Q1')),
        matching: find.byKey(const ValueKey('market-item-card-face')),
      ),
      findsNothing,
    );

    await tester.pump(const Duration(milliseconds: 700));
    expect(find.byKey(const ValueKey('market-sale-flight')), findsNothing);
    expect(find.text('6'), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
  });
}
