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
import 'package:rummipoker/views/game/widgets/game_shop_screen.dart';

Future<void> _pumpTileShopScreen(
  WidgetTester tester, {
  required RummiMarketRuntimeFacade Function() readMarketView,
  required String? Function(int offerIndex) onBuyTileOffer,
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
                  onRerollTileOffers: null,
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

  testWidgets('tile offer uses real tile face and flies toward deck edge', (
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

    const tile = Tile(
      color: TileColor.red,
      number: 7,
      enhancement: TileEnhancement.glassTile,
      seal: TileSeal.redSeal,
    );
    var boughtTileIndex = -1;
    var currentMarket = const RummiMarketRuntimeFacade(
      gold: 12,
      rerollCost: 5,
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
          tile: tile,
          price: 10,
          currency: 'gold',
          isAffordable: true,
          isFreeReward: false,
        ),
      ],
    );

    await _pumpTileShopScreen(
      tester,
      readMarketView: () => currentMarket,
      onBuyTileOffer: (offerIndex) {
        boughtTileIndex = offerIndex;
        currentMarket = const RummiMarketRuntimeFacade(
          gold: 2,
          rerollCost: 5,
          maxOwnedSlots: RummiRunProgress.maxJesterSlots,
          runtimeSnapshot: RummiJesterRuntimeSnapshot(),
          ownedEntries: [],
          offers: [],
          itemOfferSlotCount: 3,
          quickSlotCapacity: RunInventoryState.defaultQuickSlotCapacity,
          tileOffers: [],
          addedDeckTiles: [tile],
        );
        return null;
      },
    );

    expect(
      find.byKey(const ValueKey('market-tile-face'), skipOffstage: false),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('market-tile-selector'), skipOffstage: false),
      findsNothing,
    );

    await tester.tap(
      find.byKey(const ValueKey('market-tile-face'), skipOffstage: false),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('market-tile-selector'), skipOffstage: false),
      findsOneWidget,
    );
    expect(find.text('유리 · 10G'), findsOneWidget);
    expect(find.text('칩 7'), findsOneWidget);
    expect(find.textContaining('확정 시 점수 x1.5'), findsOneWidget);
    expect(find.textContaining('타일 효과 1회 재발동'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('tile-enhancement-badge'), skipOffstage: false),
      findsWidgets,
    );
    expect(
      find.byKey(const ValueKey('tile-seal-badge'), skipOffstage: false),
      findsWidgets,
    );

    await tester.tap(find.text('구매'));
    await tester.pump(const Duration(milliseconds: 120));

    expect(boughtTileIndex, 0);
    expect(
      find.byKey(const ValueKey('market-purchase-flight')),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('market-purchase-flight')),
        matching: find.byKey(const ValueKey('market-tile-face')),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('market-purchase-flight')),
        matching: find.byKey(const ValueKey('market-tile-selector')),
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('market-purchase-source-empty')),
      findsOneWidget,
    );
    expect(find.text('-10G'), findsOneWidget);

    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 3));

    expect(find.byKey(const ValueKey('market-purchase-flight')), findsNothing);
    expect(
      find.byKey(const ValueKey('market-purchase-source-empty')),
      findsNothing,
    );
    expect(find.text('2'), findsOneWidget);
  });
}
