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

RummiJesterCard _jester({
  required String id,
  required String displayName,
  int baseCost = 4,
}) {
  return RummiJesterCard(
    id: id,
    displayName: displayName,
    rarity: RummiJesterRarity.common,
    baseCost: baseCost,
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
  required RummiActiveRunSaveFacade Function() readActiveRunSaveView,
  required String? Function(int offerIndex) onBuyOffer,
  String? Function(RummiMarketItemOfferView offer)? onBuyItemOffer,
  String? Function(ItemDefinition item)? onUseMarketItem,
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
                  onBuyOffer: onBuyOffer,
                  onBuyItemOffer: onBuyItemOffer ?? ((_) => null),
                  onUseMarketItem: onUseMarketItem ?? ((_) => null),
                  onSellOwnedJester: (_) => false,
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
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('GameShopScreen reads refreshed market/save facades after buy', (
    tester,
  ) async {
    final previousOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      final exceptionText = details.exceptionAsString();
      if (exceptionText.contains('A RenderFlex overflowed by 4.0 pixels')) {
        return;
      }
      previousOnError?.call(details);
    };
    tester.view.physicalSize = const Size(1280, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      FlutterError.onError = previousOnError;
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final offerCard = _jester(id: 'test_card', displayName: 'T');
    final itemOffer = RummiMarketItemOfferView.fromItemDefinition(
      ItemDefinition.fromJson(const <String, dynamic>{
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
        'placement': 'inventory',
        'slotHint': 'utility',
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
      }),
      slotIndex: 0,
      currentGold: 12,
    );
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
      itemOffers: [itemOffer],
    );
    var currentSave = const RummiActiveRunSaveFacade(
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
    );
    String? boughtItemId;

    await _pumpShopScreen(
      tester,
      readMarketView: () => currentMarket,
      readActiveRunSaveView: () => currentSave,
      onBuyItemOffer: (offer) {
        boughtItemId = offer.contentId;
        final nextItemOffer = RummiMarketItemOfferView.fromItemDefinition(
          offer.item,
          slotIndex: offer.slotIndex,
          currentGold: 9,
          price: offer.price,
        );
        currentMarket = RummiMarketRuntimeFacade(
          gold: 9,
          rerollCost: currentMarket.rerollCost,
          maxOwnedSlots: currentMarket.maxOwnedSlots,
          runtimeSnapshot: currentMarket.runtimeSnapshot,
          ownedEntries: currentMarket.ownedEntries,
          offers: currentMarket.offers,
          itemOfferSlotCount: currentMarket.itemOfferSlotCount,
          quickSlotCapacity: currentMarket.quickSlotCapacity,
          itemOffers: [nextItemOffer],
        );
        currentSave = const RummiActiveRunSaveFacade(
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
        return null;
      },
      onBuyOffer: (offerIndex) {
        expect(offerIndex, 0);
        currentMarket = RummiMarketRuntimeFacade(
          gold: 5,
          rerollCost: 5,
          maxOwnedSlots: RummiRunProgress.maxJesterSlots,
          runtimeSnapshot: const RummiJesterRuntimeSnapshot(),
          ownedEntries: [
            RummiMarketOwnedEntryView(
              slotIndex: 0,
              category: RummiMarketCategory.jester,
              contentId: offerCard.id,
              displayName: offerCard.displayName,
              sellPrice: 2,
              card: offerCard,
            ),
          ],
          offers: const [],
          itemOfferSlotCount: 3,
          quickSlotCapacity: currentMarket.quickSlotCapacity,
          itemOffers: currentMarket.itemOffers,
        );
        currentSave = const RummiActiveRunSaveFacade(
          schemaVersion: 2,
          activeScene: 'shop',
          sceneAlias: RummiSaveSceneAlias.market,
          currentStageIndex: 2,
          currentStationIndex: 2,
          currentRunSeed: 77,
          currentGold: 5,
          checkpoint: RummiStationCheckpointSaveView(
            stageIndex: 2,
            stationIndex: 2,
            runSeed: 77,
            gold: 10,
          ),
        );
        return null;
      },
    );

    expect(find.text('GOLD'), findsOneWidget);
    expect(find.text('12'), findsOneWidget);
    expect(find.text('Tool Slots'), findsOneWidget);
    expect(find.text('Gear Slots'), findsOneWidget);
    expect(find.text('Jester Slots'), findsNothing);
    expect(find.text('구매'), findsOneWidget);

    expect(find.text('리롤 토큰'), findsWidgets);
    expect(find.text('다음 상점 리롤 비용이 1 줄어듭니다.'), findsOneWidget);

    await tester.tap(find.text('구매'));
    await tester.pumpAndSettle();

    expect(boughtItemId, 'reroll_token');
    expect(find.text('9'), findsOneWidget);

    await tester.tap(find.text('Jester / Slots'));
    await tester.pumpAndSettle();

    expect(find.text('Jester Slots'), findsOneWidget);
    expect(find.text('1/5'), findsNothing);

    await tester.tap(find.text('구매'));
    await tester.pumpAndSettle();

    expect(find.text('5'), findsOneWidget);
    expect(find.text('1/5'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.more_horiz_rounded));
    await tester.pumpAndSettle();

    expect(find.text('Run Snapshot'), findsOneWidget);
    expect(
      find.text('현재 Station 2 · Market · Gold 5\n체크포인트 Station 2'),
      findsOneWidget,
    );
  });
}
