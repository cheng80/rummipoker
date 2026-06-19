import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:rummipoker/logic/rummi_poker_grid/jester_meta.dart';
import 'package:rummipoker/logic/rummi_poker_grid/rummi_market_facade.dart';
import 'package:rummipoker/resources/item_translation_scope.dart';
import 'package:rummipoker/resources/jester_translation_scope.dart';
import 'package:rummipoker/services/active_run_save_facade.dart';
import 'package:rummipoker/services/game_settings.dart';
import 'package:rummipoker/services/tutorial_state_service.dart';
import 'package:rummipoker/utils/storage_helper.dart';
import 'package:rummipoker/views/game/widgets/game_shop_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    StorageHelper.resetForTest();
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await StorageHelper.init();
    await TutorialStateService.markMarketIntroSeen();
    GameSettings.bgmMuted = true;
    GameSettings.sfxMuted = true;
  });

  testWidgets('짧은 inactive는 무시하고 paused 복귀는 Market 옵션창을 연다', (tester) async {
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
                    readMarketView: _market,
                    readActiveRunSaveView: _activeRunSave,
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
                    autoStartTutorials: false,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
    await tester.pump();
    await _pumpUntilShopBuilt(tester);

    _sendShopLifecycle(tester, AppLifecycleState.inactive);
    await tester.pump(const Duration(milliseconds: 50));
    _sendShopLifecycle(tester, AppLifecycleState.resumed);
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Market 옵션'), findsNothing);

    _sendShopLifecycle(tester, AppLifecycleState.inactive);
    await tester.pump();
    _sendShopLifecycle(tester, AppLifecycleState.paused);
    await tester.pump();
    _sendShopLifecycle(tester, AppLifecycleState.resumed);
    await tester.pump();
    for (var i = 0; i < 10 && find.text('Market 옵션').evaluate().isEmpty; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(find.text('Market 옵션'), findsOneWidget);
    expect(find.text('설정 화면을 열고, Market으로 다시 돌아옵니다.'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close_rounded).last);
    await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });
}

RummiMarketRuntimeFacade _market() {
  return const RummiMarketRuntimeFacade(
    gold: 12,
    rerollCost: 5,
    maxOwnedSlots: RummiRunProgress.baseUnlockedJesterSlots,
    runtimeSnapshot: RummiJesterRuntimeSnapshot(),
    ownedEntries: [],
    offers: [],
    itemOfferSlotCount: 3,
    quickSlotCapacity: 2,
  );
}

RummiActiveRunSaveFacade _activeRunSave() {
  return const RummiActiveRunSaveFacade(
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
  );
}

Future<void> _pumpUntilShopBuilt(WidgetTester tester) async {
  for (
    var i = 0;
    i < 50 && find.byType(GameShopScreen).evaluate().isEmpty;
    i++
  ) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  expect(find.byType(GameShopScreen), findsOneWidget);
}

void _sendShopLifecycle(WidgetTester tester, AppLifecycleState state) {
  final observer =
      tester.state(find.byType(GameShopScreen)) as WidgetsBindingObserver;
  observer.didChangeAppLifecycleState(state);
}
