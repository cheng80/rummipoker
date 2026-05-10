import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rummipoker/logic/rummi_poker_grid/item_definition.dart';
import 'package:rummipoker/logic/rummi_poker_grid/jester_meta.dart';
import 'package:rummipoker/logic/rummi_poker_grid/models/tile.dart';
import 'package:rummipoker/logic/rummi_poker_grid/rummi_market_facade.dart';
import 'package:rummipoker/resources/item_translation_scope.dart';
import 'package:rummipoker/resources/jester_translation_scope.dart';
import 'package:rummipoker/services/active_run_save_facade.dart';
import 'package:rummipoker/views/game/widgets/game_shared_widgets.dart';
import 'package:rummipoker/views/game/widgets/game_shop_screen.dart';

Future<void> _pumpTileShopScreen(
  WidgetTester tester, {
  required RummiMarketRuntimeFacade Function() readMarketView,
  required String? Function(int offerIndex) onBuyTileOffer,
  required String? Function() onRerollTileOffers,
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
                  runSeed: 77,
                  readMarketView: readMarketView,
                  readActiveRunSaveView: () => const RummiActiveRunSaveFacade(
                    schemaVersion: 2,
                    activeScene: 'shop',
                    sceneAlias: RummiSaveSceneAlias.market,
                    currentStageIndex: 2,
                    currentStationIndex: 2,
                    currentRunSeed: 77,
                    currentGold: 8,
                    checkpoint: RummiStationCheckpointSaveView(
                      stageIndex: 2,
                      stationIndex: 2,
                      runSeed: 77,
                      gold: 8,
                    ),
                  ),
                  onReroll: () => null,
                  onRerollTileOffers: onRerollTileOffers,
                  onBuyOffer: (_) => null,
                  onBuyItemOffer: (_) => null,
                  onBuyTileOffer: onBuyTileOffer,
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

  testWidgets('tile lane can reroll after all tile offers are bought', (
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

    var rerolled = false;
    var currentMarket = const RummiMarketRuntimeFacade(
      gold: 8,
      rerollCost: 0,
      maxOwnedSlots: RummiRunProgress.maxJesterSlots,
      runtimeSnapshot: RummiJesterRuntimeSnapshot(),
      ownedEntries: [],
      offers: [],
      itemOfferSlotCount: 3,
      quickSlotCapacity: RunInventoryState.defaultQuickSlotCapacity,
      tileOffers: [
        RummiMarketTileOfferView(
          offerId: 'tile:0:R7',
          slotIndex: 0,
          tile: Tile(color: TileColor.red, number: 7),
          price: 3,
          currency: 'gold',
          isAffordable: true,
          isFreeReward: false,
        ),
      ],
    );

    await _pumpTileShopScreen(
      tester,
      readMarketView: () => currentMarket,
      onBuyTileOffer: (_) {
        currentMarket = const RummiMarketRuntimeFacade(
          gold: 5,
          rerollCost: 0,
          maxOwnedSlots: RummiRunProgress.maxJesterSlots,
          runtimeSnapshot: RummiJesterRuntimeSnapshot(),
          ownedEntries: [],
          offers: [],
          itemOfferSlotCount: 3,
          quickSlotCapacity: RunInventoryState.defaultQuickSlotCapacity,
          tileOffers: [],
          addedDeckTiles: [Tile(color: TileColor.red, number: 7)],
        );
        return null;
      },
      onRerollTileOffers: () {
        rerolled = true;
        currentMarket = const RummiMarketRuntimeFacade(
          gold: 5,
          rerollCost: 2,
          maxOwnedSlots: RummiRunProgress.maxJesterSlots,
          runtimeSnapshot: RummiJesterRuntimeSnapshot(),
          ownedEntries: [],
          offers: [],
          itemOfferSlotCount: 3,
          quickSlotCapacity: RunInventoryState.defaultQuickSlotCapacity,
          tileOffers: [
            RummiMarketTileOfferView(
              offerId: 'tile:0:B9',
              slotIndex: 0,
              tile: Tile(color: TileColor.blue, number: 9),
              price: 3,
              currency: 'gold',
              isAffordable: true,
              isFreeReward: false,
            ),
          ],
          addedDeckTiles: [Tile(color: TileColor.red, number: 7)],
        );
        return null;
      },
    );

    await tester.tap(find.text('구매'));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('market-tile-face')), findsNothing);

    final rerollButton = find.widgetWithText(GameActionButton, '첫 리롤 무료');
    expect(rerollButton, findsOneWidget);
    expect(tester.widget<GameActionButton>(rerollButton).onPressed, isNotNull);

    await tester.tap(rerollButton);
    await tester.pumpAndSettle();
    await tester.tap(find.text('무료 리롤'));
    await tester.pumpAndSettle();

    expect(rerolled, isTrue);
    expect(
      find.byKey(const ValueKey('market-reroll-success-feedback')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('market-tile-face'), skipOffstage: false),
      findsOneWidget,
    );
  });
}
