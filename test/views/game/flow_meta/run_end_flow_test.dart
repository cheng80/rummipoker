import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:rummipoker/app_config.dart';
import 'package:rummipoker/logic/rummi_poker_grid/jester_meta.dart';
import 'package:rummipoker/logic/rummi_poker_grid/models/poker_deck.dart';
import 'package:rummipoker/logic/rummi_poker_grid/models/tile.dart';
import 'package:rummipoker/logic/rummi_poker_grid/rummi_blind_state.dart';
import 'package:rummipoker/logic/rummi_poker_grid/rummi_poker_grid_session.dart';
import 'package:rummipoker/resources/asset_paths.dart';
import 'package:rummipoker/resources/jester_translation_scope.dart';
import 'package:rummipoker/resources/sound_manager.dart';
import 'package:rummipoker/services/active_run_save_service.dart';
import 'package:rummipoker/services/game_settings.dart';
import 'package:rummipoker/services/new_run_setup.dart';
import 'package:rummipoker/utils/storage_helper.dart';
import 'package:rummipoker/views/game_view.dart';
import 'package:rummipoker/widgets/fx/motion_policy.dart';
import '../../../support/test_translations.dart';

ActiveRunRuntimeState _expiringRun() {
  final session = RummiPokerGridSession(
    runSeed: 903,
    blind: RummiBlindState(
      targetScore: 240,
      boardDiscardsRemaining: 4,
      handDiscardsRemaining: 1,
    ),
    deck: PokerDeck.fromSnapshot(const []),
  );
  session.hand.add(const Tile(id: 903, color: TileColor.red, number: 7));
  final runProgress = RummiRunProgress()
    ..stageIndex = 1
    ..currentStationBlindTierIndex = 0
    ..gold = 0;
  return ActiveRunRuntimeState(
    activeScene: ActiveRunScene.battle,
    difficulty: NewRunDifficulty.standard,
    session: session,
    runProgress: runProgress,
    stageStartSnapshot: ActiveRunStageSnapshot(
      session: session.copySnapshot(),
      runProgress: runProgress.copySnapshot(),
    ),
  );
}

Widget _routerApp(GoRouter router) {
  return EasyLocalization(
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
  );
}

GoRouter _router(Widget game) => GoRouter(
  initialLocation: RoutePaths.game,
  routes: [
    GoRoute(
      path: RoutePaths.game,
      builder: (context, state) => JesterTranslationScope(child: game),
    ),
    GoRoute(
      path: RoutePaths.title,
      builder: (context, state) => const SizedBox(key: ValueKey('title-stub')),
    ),
    GoRoute(
      path: RoutePaths.newRun,
      builder: (context, state) =>
          const SizedBox(key: ValueKey('new-run-stub')),
    ),
  ],
);

Future<void> _resetStorage() async {
  StorageHelper.resetForTest();
  SharedPreferences.setMockInitialValues(<String, Object>{
    StorageKeys.tutorialBattleIntroSeen: true,
  });
  await StorageHelper.init();
  GameSettings.bgmMuted = true;
  GameSettings.sfxMuted = false;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final sfx = <String>[];

  setUp(() async {
    await _resetStorage();
    sfx.clear();
    SoundManager.debugSfxSink = (path, _, _) => sfx.add(path);
  });

  tearDown(() {
    SoundManager.debugSfxSink = null;
    MotionPolicy.debugReduceMotionOverride = null;
    SoundManager.rampGlobalPitch(1, Duration.zero);
  });

  testWidgets('게임오버 뒤 어느 출구로 나가도 전역 pitch가 1로 돌아온다', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    for (final exitKey in const [
      'game-over-retry-stake',
      'game-over-retry-station',
      'game-over-new-run',
      'game-over-exit',
    ]) {
      final router = _router(
        GameView(runSeed: 903, restoredRun: _expiringRun()),
      );
      await tester.pumpWidget(_routerApp(router));
      await tester.pumpAndSettle();
      sfx.clear();

      await tester.tap(find.byKey(const ValueKey('settled-R7#903')));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(find.byTooltip('손패 버림'));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byKey(const ValueKey('game-over-fade-veil')), findsOneWidget);
      expect(sfx, contains(AssetPaths.sfxTimeUp), reason: 'gameOver cue');
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();
      expect(
        SoundManager.globalPitch,
        closeTo(0.5, 0.01),
        reason: '위험 fade 동안 소리가 내려간다',
      );
      expect(find.byKey(const ValueKey('game-over-reward-reveal')), findsOne);

      await tester.ensureVisible(find.byKey(ValueKey(exitKey)));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(ValueKey(exitKey)));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();
      expect(SoundManager.globalPitch, 1, reason: exitKey);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      router.dispose();
      await _resetStorage();
    }
  });
}
