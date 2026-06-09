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

  testWidgets('GameShopScreen shows feedback after market item use', (
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

    final useItem = ItemDefinition.fromJson(const <String, dynamic>{
      'id': 'coin_cache',
      'displayName': 'Coin Cache',
      'type': 'utility',
      'rarity': 'common',
      'basePrice': 3,
      'sellPrice': 1,
      'stackable': true,
      'maxStack': 3,
      'sellable': true,
      'usableInBattle': false,
      'placement': 'inventory',
      'slotHint': 'utility',
      'effectText': 'Gain 3 Gold.',
      'effect': <String, dynamic>{
        'timing': 'use_market',
        'op': 'gain_gold',
        'amount': 3,
        'consume': true,
      },
      'tags': <String>['market', 'gold'],
      'sourceNotes': 'Test fixture.',
    });
    var useCalled = false;
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
          slotLabel: 'T1',
          entry: const OwnedItemEntry(
            itemId: 'coin_cache',
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
                    key: UniqueKey(),
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
                    onUseMarketItem: (item) {
                      useCalled = true;
                      expect(item.id, 'coin_cache');
                      currentMarket = RummiMarketRuntimeFacade(
                        gold: 7,
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
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('market-item-slot-T1')));
    await tester.pumpAndSettle();
    final noticeText = tester.widget<Text>(find.text('상점에서 수동 사용').first);
    expect(noticeText.overflow, isNot(TextOverflow.ellipsis));
    expect(find.text('판매'), findsOneWidget);

    await tester.tap(find.text('사용'));
    await tester.pump(const Duration(milliseconds: 120));

    expect(useCalled, isTrue);
    expect(
      find.byKey(const ValueKey('market-item-use-flight')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('market-gold-gain-badge')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('market-use-feedback')), findsOneWidget);
    expect(find.text('금화 보관함'), findsWidgets);
    expect(find.text('+3G'), findsWidgets);
    expect(find.text('선택된 카드 없음'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 700));
    expect(find.byKey(const ValueKey('market-item-use-flight')), findsNothing);
    expect(
      find.byKey(const ValueKey('market-gold-gain-badge')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('market-use-feedback')), findsOneWidget);
    expect(find.text('7'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1200));
    expect(
      find.byKey(const ValueKey('market-gold-gain-badge')),
      findsNothing,
    );
    expect(find.byKey(const ValueKey('market-use-feedback')), findsNothing);
    expect(find.text('7'), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
  });
}
