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
      builder: (context, state) => TitleView(
        debugScrollPreset: state.uri.queryParameters['debug_scroll'],
      ),
    ),
    GoRoute(
      path: RoutePaths.blindSelect,
      builder: (context, state) {
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
        return BlindSelectView(
          runSeed: seed,
          difficulty: difficulty,
          restoredRun: restoredRun,
        );
      },
    ),
    GoRoute(
      path: RoutePaths.game,
      builder: (context, state) {
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
        final difficulty = NewRunSetup.parseDifficulty(
          state.uri.queryParameters['difficulty'],
        );
        final blindTier = BlindSelectionSetup.parseTier(
          state.uri.queryParameters['blind_tier'],
        );
        final runSeed =
            restoredRun?.session.runSeed ??
            int.tryParse(seedStr ?? '') ??
            RummiPokerGridSession.rollNewRunSeed();
        return GameView(
          runSeed: runSeed,
          restoredRun: restoredRun,
          debugFixtureId: fixtureId,
          difficulty: difficulty,
          blindTier: blindTier,
          autoAdvanceMarketOnLoad: autoAdvanceMarketOnLoad,
          autoEnterMarketOnCashOut: autoEnterMarketOnCashOut,
          autoCashOutLoopOnLoad: autoCashOutLoopOnLoad,
          debugCompleteRunOnClear: debugCompleteRunOnClear,
          debugCompleteRunOnLoad: debugCompleteRunOnLoad,
          debugAutoUseItemId: debugAutoUseItemId,
        );
      },
    ),
    GoRoute(
      path: RoutePaths.setting,
      builder: (context, state) => const SettingView(),
    ),
    GoRoute(
      path: RoutePaths.newRun,
      builder: (context, state) => NewRunView(
        debugScrollPreset: state.uri.queryParameters['debug_scroll'],
      ),
    ),
    GoRoute(
      path: RoutePaths.trial,
      builder: (context, state) => HomePlaceholderView(
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
    GoRoute(
      path: RoutePaths.archive,
      builder: (context, state) => ArchiveView(
        debugScrollPreset: state.uri.queryParameters['debug_scroll'],
      ),
    ),
  ],
);
