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

Future<void> _pumpSlotUnlockShop(
  WidgetTester tester, {
  required RummiMarketRuntimeFacade market,
  required Future<void> Function() onSlotUnlockPresentationShown,
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
                      gold: 12,
                    ),
                  ),
                  onReroll: () => null,
                  onRerollItemOffers: (_) => null,
                  onBuyOffer: (_) => null,
                  onBuyItemOffer: (_) => null,
                  onBuyTileOffer: (_) => null,
                  onUseMarketItem: (_) => null,
                  onSellOwnedJester: (_) => false,
                  onSellMarketItem: (_) => false,
                  onSlotUnlockPresentationShown: onSlotUnlockPresentationShown,
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
  await tester.pump();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('GameShopScreen shows pending slot unlock presentation once', (
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

    final market = RummiMarketRuntimeFacade(
      gold: 12,
      rerollCost: 5,
      maxOwnedSlots: RummiRunProgress.maxJesterSlots,
      jesterSlotCapacity: 5,
      pendingSlotUnlockPresentations: const <RummiSlotUnlockKind>{
        RummiSlotUnlockKind.jester,
      },
      runtimeSnapshot: const RummiJesterRuntimeSnapshot(),
      ownedEntries: const [],
      offers: const [],
      itemOfferSlotCount: 3,
      quickSlotCapacity: RunInventoryState.defaultQuickSlotCapacity,
    );
    var presentationSeenCount = 0;

    await _pumpSlotUnlockShop(
      tester,
      market: market,
      onSlotUnlockPresentationShown: () async {
        presentationSeenCount += 1;
      },
    );

    final bannerFinder = find.byKey(
      const ValueKey('market-slot-unlock-banner'),
    );
    for (var frame = 0; frame < 40; frame += 1) {
      await tester.pump(const Duration(milliseconds: 16));
      if (bannerFinder.evaluate().isNotEmpty) {
        break;
      }
    }

    expect(bannerFinder, findsOneWidget);
    expect(find.text('Jester 슬롯 +1'), findsOneWidget);

    for (var frame = 0; frame < 80; frame += 1) {
      await tester.pump(const Duration(milliseconds: 16));
      if (presentationSeenCount > 0) {
        break;
      }
    }

    expect(presentationSeenCount, 1);
    await tester.pump(const Duration(milliseconds: 1300));
    await tester.pumpAndSettle();
  });
}
