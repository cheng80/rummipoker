import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:rummipoker/app_config.dart';
import 'package:rummipoker/resources/asset_paths.dart';
import 'package:rummipoker/providers/features/rummi_poker_grid/game_session_notifier.dart';
import 'package:rummipoker/resources/jester_translation_scope.dart';
import 'package:rummipoker/resources/item_translation_scope.dart';
import 'package:rummipoker/views/blind_select_view.dart';
import '../../support/test_translations.dart';
import 'package:rummipoker/services/active_run_save_service.dart';
import 'package:rummipoker/services/blind_selection_setup.dart';
import 'package:rummipoker/services/game_settings.dart';
import 'package:rummipoker/utils/storage_helper.dart';
import 'package:rummipoker/views/game_view.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    rootBundle.evict(AssetPaths.jestersCommon);
    rootBundle.evict(AssetPaths.itemsCommon);
    StorageHelper.resetForTest();
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await StorageHelper.init();
    await StorageHelper.write(StorageKeys.tutorialBattleIntroSeen, true);
    GameSettings.bgmMuted = true;
    GameSettings.sfxMuted = true;
  });

  for (final station in [1, 2]) {
    testWidgets('S$station 재시작은 시작 상태를 저장하고 Scout 선택으로 이동한다', (tester) async {
      final stationStart = buildInitialRunRuntime(
        const GameSessionArgs(runSeed: 904),
      );
      var battleRuntime =
          BlindSelectionSetup.prepareContinuedRunForSelectedBlind(
            runtime: stationStart,
            tier: BlindTier.small,
          );
      if (station == 2) {
        final bossRuntime =
            BlindSelectionSetup.prepareContinuedRunForSelectedBlind(
              runtime: battleRuntime,
              tier: BlindTier.boss,
            );
        final nextStation = BlindSelectionSetup.prepareRuntimeForBlindSelect(
          runtime: bossRuntime,
        );
        battleRuntime = BlindSelectionSetup.prepareContinuedRunForSelectedBlind(
          runtime: nextStation,
          tier: BlindTier.small,
        );
      }
      final startingGold = battleRuntime.stageStartSnapshot.runProgress.gold;
      battleRuntime.runProgress.gold += 9;
      final router = GoRouter(
        initialLocation: RoutePaths.game,
        routes: [
          GoRoute(
            path: RoutePaths.game,
            builder: (context, state) => JesterTranslationScope(
              child: ItemTranslationScope(
                child: GameView(runSeed: 904, restoredRun: battleRuntime),
              ),
            ),
          ),
          GoRoute(
            path: RoutePaths.blindSelect,
            builder: (context, state) {
              final runtime = state.extra! as ActiveRunRuntimeState;
              return BlindSelectView(
                runSeed: 904,
                difficulty: runtime.difficulty,
                restoredRun: runtime,
              );
            },
          ),
        ],
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(
        EasyLocalization(
          assetLoader: const TestTranslationAssetLoader(),
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

      await tester.tap(find.byKey(const ValueKey('battle-options-button')));
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
      expect(savedRuntime?.runProgress.gold, startingGold);
      expect(savedRuntime?.runProgress.stageIndex, station);
      await tester.pumpAndSettle();
      final options = BlindSelectionSetup.buildForStation(
        stationIndex: savedRuntime!.runProgress.stageIndex,
        clearedBlindTierIndex:
            savedRuntime.runProgress.currentStationBlindTierIndex,
        difficulty: savedRuntime.difficulty,
        ruleset: savedRuntime.session.ruleset,
      );
      expect(options.first.isSelectable, isTrue);
      expect(options[1].isLocked, isTrue);
      expect(find.byKey(const ValueKey('blind-card-small')), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    });
  }
}
