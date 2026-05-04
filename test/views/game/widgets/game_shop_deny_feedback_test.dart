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

  testWidgets('GameShopScreen gives deny feedback when buy cannot proceed', (
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

    final itemOffer = RummiMarketItemOfferView.fromItemDefinition(
      ItemDefinition.fromJson(const <String, dynamic>{
        'id': 'too_expensive_item',
        'displayName': 'Too Expensive',
        'type': 'utility',
        'rarity': 'common',
        'basePrice': 9,
        'sellPrice': 1,
        'stackable': true,
        'maxStack': 1,
        'sellable': true,
        'usableInBattle': false,
        'placement': 'inventory',
        'slotHint': 'utility',
        'effectText': 'Test item.',
        'effect': <String, dynamic>{
          'timing': 'market_reroll',
          'op': 'free_next_reroll',
          'amount': 1,
          'consume': true,
        },
        'tags': <String>['market'],
        'sourceNotes': 'Test fixture.',
      }),
      slotIndex: 0,
      currentGold: 0,
    );
    var buyCalled = false;
    final market = RummiMarketRuntimeFacade(
      gold: 0,
      rerollCost: 5,
      maxOwnedSlots: RummiRunProgress.maxJesterSlots,
      runtimeSnapshot: const RummiJesterRuntimeSnapshot(),
      ownedEntries: const [],
      offers: const [],
      itemOfferSlotCount: 3,
      quickSlotCapacity: RunInventoryState.defaultQuickSlotCapacity,
      itemOffers: [itemOffer],
    );
    const save = RummiActiveRunSaveFacade(
      schemaVersion: 2,
      activeScene: 'shop',
      sceneAlias: RummiSaveSceneAlias.market,
      currentStageIndex: 2,
      currentStationIndex: 2,
      currentRunSeed: 77,
      currentGold: 0,
      checkpoint: RummiStationCheckpointSaveView(
        stageIndex: 2,
        stationIndex: 2,
        runSeed: 77,
        gold: 0,
      ),
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
                    readMarketView: () => market,
                    readActiveRunSaveView: () => save,
                    onReroll: () => null,
                    onBuyOffer: (_) {
                      buyCalled = true;
                      return null;
                    },
                    onBuyItemOffer: (_) {
                      buyCalled = true;
                      return null;
                    },
                    onUseMarketItem: (_) => null,
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

    await tester.tap(find.text('구매'));
    await tester.pump(const Duration(milliseconds: 80));

    expect(buyCalled, isFalse);
    expect(find.byKey(const ValueKey('market-deny-feedback')), findsOneWidget);
    expect(find.text('Gold 부족'), findsWidgets);

    await tester.pump(const Duration(milliseconds: 700));
    expect(find.byKey(const ValueKey('market-deny-feedback')), findsNothing);

    await tester.pump(const Duration(seconds: 3));
  });
}
