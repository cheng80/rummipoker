import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:rummipoker/app_config.dart';
import 'package:rummipoker/logic/rummi_poker_grid/jester_meta.dart';
import 'package:rummipoker/logic/rummi_poker_grid/models/poker_deck.dart';
import 'package:rummipoker/logic/rummi_poker_grid/rummi_blind_state.dart';
import 'package:rummipoker/logic/rummi_poker_grid/rummi_poker_grid_session.dart';
import 'package:rummipoker/resources/jester_translation_scope.dart';
import 'package:rummipoker/resources/sound_manager.dart';
import 'package:rummipoker/services/active_run_save_service.dart';
import 'package:rummipoker/services/game_settings.dart';
import 'package:rummipoker/services/in_app_review_service.dart';
import 'package:rummipoker/services/new_run_setup.dart';
import 'package:rummipoker/utils/storage_helper.dart';
import 'package:rummipoker/views/game_view.dart';
import 'package:rummipoker/widgets/fx/motion_policy.dart';

ActiveRunRuntimeState _finalRun() {
  final runProgress = RummiRunProgress()
    ..stageIndex = 8
    ..currentStationBlindTierIndex = 2
    ..runClaimId = 'first-clear-review';
  final session = RummiPokerGridSession(
    runSeed: 905,
    blind: RummiBlindState(
      targetScore: 100,
      boardDiscardsRemaining: 4,
      handDiscardsRemaining: 2,
    ),
    deck: PokerDeck.fromSnapshot(const []),
  );
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  var requests = 0;

  setUp(() async {
    StorageHelper.resetForTest();
    SharedPreferences.setMockInitialValues(<String, Object>{
      StorageKeys.tutorialBattleIntroSeen: true,
    });
    await StorageHelper.init();
    GameSettings.bgmMuted = true;
    GameSettings.sfxMuted = true;
    MotionPolicy.debugReduceMotionOverride = false;
    requests = 0;
    InAppReviewService.debugRequestSink = () async => requests++;
  });

  tearDown(() {
    InAppReviewService.debugRequestSink = null;
    MotionPolicy.debugReduceMotionOverride = null;
    SoundManager.rampGlobalPitch(1, Duration.zero);
  });

  Future<void> clearRun(WidgetTester tester) async {
    final router = _router(
      GameView(
        runSeed: 905,
        restoredRun: _finalRun(),
        debugCompleteRunOnLoad: true,
      ),
    );
    await tester.pumpWidget(_routerApp(router));
    for (var i = 0; i < 100; i++) {
      await tester.pump(const Duration(milliseconds: 100));
      if (find
          .byKey(const ValueKey('run-victory-overlay'))
          .evaluate()
          .isNotEmpty) {
        break;
      }
    }
    expect(find.byKey(const ValueKey('run-victory-overlay')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('run-victory-overlay')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));
    router.dispose();
  }

  testWidgets('첫 클리어 승리 장면이 끝나면 인앱 리뷰를 1회만 요청한다', (tester) async {
    await clearRun(tester);

    expect(requests, 1);
    expect(
      StorageHelper.readBool(StorageKeys.reviewRequestedAfterFirstClear),
      isTrue,
    );

    // 두 번째 클리어에서도 다시 뜨지 않는다.
    await InAppReviewService.maybeRequestReviewAfterFirstClear();
    expect(requests, 1);
  });
}
