import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'app_config.dart';
import 'logic/rummi_poker_grid/rummi_poker_grid_session.dart';
import 'services/active_run_save_service.dart';
import 'services/blind_selection_setup.dart';
import 'services/debug_run_fixture_service.dart';
import 'services/new_run_setup.dart';
import 'views/archive_view.dart';
import 'views/blind_select_view.dart';
import 'views/game_view.dart';
import 'views/home_placeholder_view.dart';
import 'views/new_run_view.dart';
import 'views/setting_view.dart';
import 'views/title_view.dart';

/// 앱 전체 라우팅 설정.
final GoRouter appRouter = GoRouter(
  initialLocation: RoutePaths.title,
  routes: [
    GoRoute(
      path: RoutePaths.title,
      pageBuilder: (context, state) => _instantPage(
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
        return _instantPage(
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
            state.uri.queryParameters['debug_show_game_over_on_load'] == '1';
        final difficulty = NewRunSetup.parseDifficulty(
          state.uri.queryParameters['difficulty'],
        );
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
        return _instantPage(
          state: state,
          child: GameView(
            runSeed: runSeed,
            restoredRun: restoredRun,
            debugFixtureId: fixtureId,
            difficulty: difficulty,
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
          ),
        );
      },
    ),
    GoRoute(
      path: RoutePaths.setting,
      pageBuilder: (context, state) =>
          _instantPage(state: state, child: const SettingView()),
    ),
    GoRoute(
      path: RoutePaths.newRun,
      pageBuilder: (context, state) => _instantPage(
        state: state,
        child: NewRunView(
          debugScrollPreset: state.uri.queryParameters['debug_scroll'],
        ),
      ),
    ),
    GoRoute(
      path: RoutePaths.trial,
      pageBuilder: (context, state) => _instantPage(
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
      pageBuilder: (context, state) => _instantPage(
        state: state,
        child: ArchiveView(
          debugScrollPreset: state.uri.queryParameters['debug_scroll'],
          debugCollectionPreset: state.uri.queryParameters['debug_collection'],
        ),
      ),
    ),
  ],
);

CustomTransitionPage<void> _instantPage({
  required GoRouterState state,
  required Widget child,
}) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    transitionDuration: Duration.zero,
    reverseTransitionDuration: Duration.zero,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return child;
    },
    child: child,
  );
}
