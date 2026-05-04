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

Future<void> _pumpShopScreen(
  WidgetTester tester, {
  required RummiMarketRuntimeFacade Function() readMarketView,
  required RummiActiveRunSaveFacade Function() readActiveRunSaveView,
  required bool Function(ItemDefinition item) onSellMarketItem,
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
                  readActiveRunSaveView: readActiveRunSaveView,
                  onReroll: () => null,
                  onBuyOffer: (_) => null,
                  onBuyItemOffer: (_) => null,
                  onUseMarketItem: (_) => null,
                  onSellOwnedJester: (_) => false,
                  onSellMarketItem: onSellMarketItem,
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

  testWidgets('GameShopScreen animates owned item sale toward gold HUD', (
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

    final item = ItemDefinition.fromJson(const <String, dynamic>{
      'id': 'reroll_token',
      'displayName': 'Reroll Token',
      'displayNameKey': 'data.items.reroll_token.displayName',
      'type': 'utility',
      'rarity': 'common',
      'basePrice': 3,
      'sellPrice': 1,
      'stackable': true,
      'maxStack': 3,
      'sellable': true,
      'usableInBattle': false,
      'placement': 'quickSlot',
      'slotHint': 'quick',
      'effectText': 'The next Market reroll costs no Gold.',
      'effectTextKey': 'data.items.reroll_token.effectText',
      'effect': <String, dynamic>{
        'timing': 'market_reroll',
        'op': 'free_next_reroll',
        'amount': 1,
        'consume': true,
      },
      'tags': <String>['market', 'economy', 'discount'],
      'sourceNotes': 'Test fixture.',
    });
    var currentMarket = RummiMarketRuntimeFacade(
      gold: 9,
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
            itemId: 'reroll_token',
            count: 1,
            placement: ItemPlacement.quickSlot,
          ),
          item: item,
        ),
      ],
    );
    const currentSave = RummiActiveRunSaveFacade(
      schemaVersion: 2,
      activeScene: 'shop',
      sceneAlias: RummiSaveSceneAlias.market,
      currentStageIndex: 2,
      currentStationIndex: 2,
      currentRunSeed: 77,
      currentGold: 9,
      checkpoint: RummiStationCheckpointSaveView(
        stageIndex: 2,
        stationIndex: 2,
        runSeed: 77,
        gold: 10,
      ),
    );
    String? soldItemId;

    await _pumpShopScreen(
      tester,
      readMarketView: () => currentMarket,
      readActiveRunSaveView: () => currentSave,
      onSellMarketItem: (soldItem) {
        soldItemId = soldItem.id;
        currentMarket = RummiMarketRuntimeFacade(
          gold: 10,
          rerollCost: currentMarket.rerollCost,
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
    );

    await tester.tap(find.byKey(const ValueKey('market-item-slot-Q1')));
    await tester.pumpAndSettle();

    expect(find.text('판매'), findsOneWidget);
    await tester.tap(find.text('판매'));
    await tester.pump(const Duration(milliseconds: 120));

    expect(soldItemId, 'reroll_token');
    expect(find.byKey(const ValueKey('market-sale-flight')), findsOneWidget);
    expect(find.text('+1G'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('market-item-slot-Q1')),
        matching: find.byKey(const ValueKey('market-item-card-face')),
      ),
      findsNothing,
    );

    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 3));

    expect(find.byKey(const ValueKey('market-sale-flight')), findsNothing);
    expect(find.text('10'), findsOneWidget);
  });
}
