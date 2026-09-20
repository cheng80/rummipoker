import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'app_config.dart';
import 'logic/rummi_poker_grid/rummi_poker_grid_session.dart';
import 'services/active_run_save_service.dart';
import 'services/blind_selection_setup.dart';
import 'services/debug_run_fixture_service.dart';
import 'services/new_run_setup.dart';
import 'services/run_unlock_state_service.dart';
import 'views/archive_view.dart';
import 'views/game/game_presentation_timings.dart';
import 'views/blind_select_view.dart';
import 'views/game_view.dart';
import 'views/home_placeholder_view.dart';
import 'views/new_run_view.dart';
import 'views/setting_view.dart';
import 'views/title_view.dart';
import 'widgets/fx/motion_policy.dart';

/// 앱 전체 라우팅 설정.
final GoRouter appRouter = GoRouter(
  initialLocation: RoutePaths.title,
  observers: [FirebaseAnalyticsObserver(analytics: FirebaseAnalytics.instance)],
  routes: [
    GoRoute(
      path: RoutePaths.title,
      pageBuilder: (context, state) => appTransitionPage(
        state: state,
        child: TitleView(
          debugScrollPreset: state.uri.queryParameters['debug_scroll'],
        ),
      ),
    ),
    GoRoute(
      path: RoutePaths.blindSelect,
      pageBuilder: (context, state) {
        final restoredRun = state.extra is ActiveRunRuntimeState
            ? state.extra as ActiveRunRuntimeState
            : null;
        final seed =
            restoredRun?.session.runSeed ??
            int.tryParse(state.uri.queryParameters['seed'] ?? '') ??
            RummiPokerGridSession.rollNewRunSeed();
        final difficulty = NewRunSetup.parseDifficulty(
          restoredRun?.difficulty.name ??
              state.uri.queryParameters['difficulty'],
        );
        final runModifier = NewRunModifier.parse(
          state.uri.queryParameters['modifier'],
        );
        return appTransitionPage(
          state: state,
          child: BlindSelectView(
            runSeed: seed,
            difficulty: difficulty,
            runModifier: runModifier,
            restoredRun: restoredRun,
          ),
        );
      },
    ),
    GoRoute(
      path: RoutePaths.game,
      pageBuilder: (context, state) {
        final fixtureId = state.uri.queryParameters['fixture'];
        final restoredRun = state.extra is ActiveRunRuntimeState
            ? state.extra as ActiveRunRuntimeState
            : fixtureId != null
            ? DebugRunFixtureService.build(fixtureId)
            : null;
        final seedStr = state.uri.queryParameters['seed'];
        final autoAdvanceMarketOnLoad =
            state.uri.queryParameters['auto_advance_market'] == '1';
        final autoEnterMarketOnCashOut =
            state.uri.queryParameters['auto_enter_market'] == '1';
        final autoCashOutLoopOnLoad =
            state.uri.queryParameters['auto_cashout_loop'] == '1';
        final debugCompleteRunOnClear =
            state.uri.queryParameters['debug_complete_run_on_clear'] == '1';
        final debugCompleteRunOnLoad =
            state.uri.queryParameters['debug_complete_run_on_load'] == '1';
        final debugAutoUseItemId =
            state.uri.queryParameters['debug_auto_use_item'];
        final debugShopTab = state.uri.queryParameters['debug_shop_tab'];
        final debugShowGameOverOnLoad =
            state.uri.queryParameters['debug_show_game_over_on_load'] == '1' ||
            DebugRunFixtureService.shouldShowGameOverOnLoad(fixtureId);
        final debugOpenRunInfoOnLoad =
            state.uri.queryParameters['debug_open_run_info'] == '1';
        final debugSuppressFixtureNotice =
            state.uri.queryParameters['debug_suppress_fixture_notice'] == '1';
        final difficulty = NewRunSetup.parseDifficulty(
          restoredRun?.difficulty.name ??
              state.uri.queryParameters['difficulty'],
        );
        final challengeCarryover =
            restoredRun == null &&
                fixtureId == null &&
                difficulty == NewRunDifficulty.challenge
            ? RunUnlockStateService.loadSync().challengeCarryover
            : null;
        final runModifier = NewRunModifier.parse(
          state.uri.queryParameters['modifier'],
        );
        final blindTier = BlindSelectionSetup.parseTier(
          state.uri.queryParameters['blind_tier'],
        );
        final runSeed =
            restoredRun?.session.runSeed ??
            int.tryParse(seedStr ?? '') ??
            RummiPokerGridSession.rollNewRunSeed();
        return appTransitionPage(
          state: state,
          child: GameView(
            runSeed: runSeed,
            restoredRun: restoredRun,
            debugFixtureId: fixtureId,
            difficulty: difficulty,
            challengeCarryover: challengeCarryover,
            runModifier: runModifier,
            blindTier: blindTier,
            autoAdvanceMarketOnLoad: autoAdvanceMarketOnLoad,
            autoEnterMarketOnCashOut: autoEnterMarketOnCashOut,
            autoCashOutLoopOnLoad: autoCashOutLoopOnLoad,
            debugCompleteRunOnClear: debugCompleteRunOnClear,
            debugCompleteRunOnLoad: debugCompleteRunOnLoad,
            debugAutoUseItemId: debugAutoUseItemId,
            debugStartItemShop: debugShopTab == 'items',
            debugShowGameOverOnLoad: debugShowGameOverOnLoad,
            debugOpenRunInfoOnLoad: debugOpenRunInfoOnLoad,
            debugSuppressFixtureNotice: debugSuppressFixtureNotice,
          ),
        );
      },
    ),
    GoRoute(
      path: RoutePaths.setting,
      pageBuilder: (context, state) =>
          appTransitionPage(state: state, child: const SettingView()),
    ),
    GoRoute(
      path: RoutePaths.newRun,
      pageBuilder: (context, state) => appTransitionPage(
        state: state,
        child: NewRunView(
          debugScrollPreset: state.uri.queryParameters['debug_scroll'],
        ),
      ),
    ),
    GoRoute(
      path: RoutePaths.trial,
      pageBuilder: (context, state) => appTransitionPage(
        state: state,
        child: HomePlaceholderView(
          title: '특별 모드',
          summary: '추가 규칙을 가진 별도 모드 자리입니다.',
          cardTitle: '안내 카드',
          debugScrollPreset: state.uri.queryParameters['debug_scroll'],
          items: [
            '지금은 진입 구조만 먼저 분리해 둔 상태입니다.',
            '규칙, 보상, 기록 정책은 아직 정해지지 않았습니다.',
            '개발 검증용 진입은 여기 두지 않고 디버그에만 둡니다.',
          ],
        ),
      ),
    ),
    GoRoute(
      path: RoutePaths.archive,
      pageBuilder: (context, state) => appTransitionPage(
        state: state,
        child: ArchiveView(
          debugScrollPreset: state.uri.queryParameters['debug_scroll'],
          debugCollectionPreset: state.uri.queryParameters['debug_collection'],
        ),
      ),
    ),
  ],
);

/// 디버그 픽스처·자동 흐름 경로와 OS 동작 줄이기에서는 전환 애니메이션을 건너뛴다.
bool isInstantRouteTransition(Uri uri) =>
    MotionPolicy.reduceMotion ||
    uri.queryParameters.keys.any(
      (key) =>
          key == 'fixture' ||
          key.startsWith('auto_') ||
          key.startsWith('debug_'),
    );

/// 화면 전환. 짧은 fade와 아래에서 올라오는 slide를 쓴다.
///
/// 디버그 픽스처·`auto_*`·`debug_*` 경로와 OS 동작 줄이기에서는 풀런봇과
/// 자동 흐름을 늦추지 않도록 즉시 전환한다.
CustomTransitionPage<void> appTransitionPage({
  required GoRouterState state,
  required Widget child,
}) {
  final instant = isInstantRouteTransition(state.uri);
  return CustomTransitionPage<void>(
    key: state.pageKey,
    name: state.matchedLocation,
    transitionDuration: instant
        ? Duration.zero
        : GamePresentationTimings.routeTransition,
    reverseTransitionDuration: instant
        ? Duration.zero
        : GamePresentationTimings.routeReverseTransition,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      if (instant) return child;
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.04),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      );
    },
    child: child,
  );
}
