import 'package:go_router/go_router.dart';

import 'app_config.dart';
import 'logic/rummi_poker_grid/rummi_poker_grid_session.dart';
import 'services/active_run_save_service.dart';
import 'services/debug_run_fixture_service.dart';
import 'views/game_view.dart';
import 'views/setting_view.dart';
import 'views/title_view.dart';

/// 앱 전체 라우팅 설정.
final GoRouter appRouter = GoRouter(
  initialLocation: RoutePaths.title,
  routes: [
    GoRoute(
      path: RoutePaths.title,
      builder: (context, state) => const TitleView(),
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
        final runSeed =
            restoredRun?.session.runSeed ??
            int.tryParse(seedStr ?? '') ??
            RummiPokerGridSession.rollNewRunSeed();
        return GameView(runSeed: runSeed, restoredRun: restoredRun);
      },
    ),
    GoRoute(
      path: RoutePaths.setting,
      builder: (context, state) => const SettingView(),
    ),
  ],
);
