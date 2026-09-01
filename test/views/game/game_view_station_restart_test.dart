import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:rummipoker/app_config.dart';
import 'package:rummipoker/logic/rummi_poker_grid/jester_meta.dart';
import 'package:rummipoker/providers/features/rummi_poker_grid/game_session_notifier.dart';
import 'package:rummipoker/resources/jester_translation_scope.dart';
import 'package:rummipoker/services/active_run_save_service.dart';
import 'package:rummipoker/services/blind_selection_setup.dart';
import 'package:rummipoker/services/game_settings.dart';
import 'package:rummipoker/utils/storage_helper.dart';
import 'package:rummipoker/views/game_view.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    StorageHelper.resetForTest();
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await StorageHelper.init();
    await StorageHelper.write(StorageKeys.tutorialBattleIntroSeen, true);
    GameSettings.bgmMuted = true;
    GameSettings.sfxMuted = true;
  });

  testWidgets('옵션의 Station 재시작은 시작 상태를 저장하고 Blind Select로 이동한다', (
    tester,
  ) async {
    final stationStart = buildInitialRunRuntime(
      const GameSessionArgs(runSeed: 904),
    );
    final battleRuntime =
        BlindSelectionSetup.prepareContinuedRunForSelectedBlind(
          runtime: stationStart,
          tier: BlindTier.small,
        );
    battleRuntime.runProgress.gold += 9;
    final router = GoRouter(
      initialLocation: RoutePaths.game,
      routes: [
        GoRoute(
          path: RoutePaths.game,
          builder: (context, state) => JesterTranslationScope(
            child: GameView(runSeed: 904, restoredRun: battleRuntime),
          ),
        ),
        GoRoute(
          path: RoutePaths.blindSelect,
          builder: (context, state) => const SizedBox(),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: const [Locale('ko'), Locale('en')],
        path: 'assets/translations',
        fallbackLocale: const Locale('ko'),
        startLocale: const Locale('ko'),
        saveLocale: false,
        child: ProviderScope(
          child: Builder(
            builder: (context) => MaterialApp.router(
              routerConfig: router,
              locale: context.locale,
              supportedLocales: context.supportedLocales,
              localizationsDelegates: context.localizationDelegates,
            ),
          ),
        ),
      ),
    );
    for (var i = 0; i < 50 && find.byType(GameView).evaluate().isEmpty; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    await tester.tap(find.byIcon(Icons.more_vert_rounded));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('현재 Station 재시작').first);
    await tester.tap(find.text('현재 Station 재시작').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('현재 Station 재시작').last);
    for (
      var i = 0;
      i < 30 &&
          router.routerDelegate.currentConfiguration.uri.path !=
              RoutePaths.blindSelect;
      i++
    ) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(
      router.routerDelegate.currentConfiguration.uri.path,
      RoutePaths.blindSelect,
    );
    final savedRuntime = await ActiveRunSaveService.loadActiveRun();
    expect(savedRuntime?.activeScene, ActiveRunScene.blindSelect);
    expect(savedRuntime?.runProgress.currentStationBlindTierIndex, -1);
    expect(savedRuntime?.runProgress.gold, RummiEconomyConfig.startingGold);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });
}
