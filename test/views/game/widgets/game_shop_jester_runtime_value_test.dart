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

  testWidgets('GameShopScreen keeps owned jester runtime value readable', (
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

    final greenJester = RummiJesterCard(
      id: 'green_jester',
      displayName: 'Green Jester',
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
    final market = RummiMarketRuntimeFacade(
      gold: 12,
      rerollCost: 5,
      maxOwnedSlots: RummiRunProgress.maxJesterSlots,
      runtimeSnapshot: const RummiJesterRuntimeSnapshot(
        slotStateValues: {0: 7},
      ),
      ownedEntries: [
        RummiMarketOwnedEntryView(
          slotIndex: 0,
          category: RummiMarketCategory.jester,
          contentId: greenJester.id,
          displayName: greenJester.displayName,
          sellPrice: 2,
          card: greenJester,
        ),
      ],
      offers: const [],
      itemOfferSlotCount: 3,
      quickSlotCapacity: RunInventoryState.defaultQuickSlotCapacity,
      itemOffers: const [],
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
                    onReroll: () => null,
                    onBuyOffer: (_) => null,
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

    final runtimeText = tester.widget<Text>(
      find.byWidgetPredicate(
        (widget) => widget is Text && widget.data == '현재 점수 +35%',
      ),
    );
    expect(runtimeText.overflow, isNot(TextOverflow.ellipsis));
  });
}
