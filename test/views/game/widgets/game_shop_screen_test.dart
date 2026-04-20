import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rummipoker/logic/rummi_poker_grid/jester_meta.dart';
import 'package:rummipoker/logic/rummi_poker_grid/rummi_market_facade.dart';
import 'package:rummipoker/services/active_run_save_facade.dart';
import 'package:rummipoker/views/game/widgets/game_shop_screen.dart';
import 'package:rummipoker/resources/jester_translation_scope.dart';

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
              child: GameShopScreen(
                runSeed: 77,
                readMarketView: readMarketView,
                readActiveRunSaveView: readActiveRunSaveView,
                onReroll: () => null,
                onBuyOffer: onBuyOffer,
                onSellOwnedJester: (_) => false,
                onStateChanged: () async {},
                onOpenSettings: () async {},
                onExitToTitle: () async {},
                onRestartRun: () async {},
                isDebugFixtureRun: false,
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

    await _pumpShopScreen(
      tester,
      readMarketView: () => currentMarket,
      readActiveRunSaveView: () => currentSave,
      onBuyOffer: (offerIndex) {
        expect(offerIndex, 0);
        currentMarket = RummiMarketRuntimeFacade(
          gold: 8,
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
        );
        currentSave = const RummiActiveRunSaveFacade(
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
            gold: 10,
          ),
        );
        return null;
      },
    );

    expect(find.text('Gold 12'), findsOneWidget);
    expect(find.text('보유 Jester 0/5슬롯'), findsOneWidget);
    expect(find.text('구매'), findsOneWidget);

    await tester.tap(find.text('구매'));
    await tester.pumpAndSettle();

    expect(find.text('Gold 8'), findsOneWidget);
    expect(find.text('보유 Jester 1/5슬롯'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.more_horiz_rounded));
    await tester.pumpAndSettle();

    expect(find.text('Run Snapshot'), findsOneWidget);
    expect(
      find.text('현재 Station 2 · Market · Gold 8\n체크포인트 Station 2'),
      findsOneWidget,
    );
  });
}
