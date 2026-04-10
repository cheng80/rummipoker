import 'package:go_router/go_router.dart';

import 'app_config.dart';
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
        /// query parameter로 게임 모드를 전달받는다.
        /// 0 = 숫자, 1 = 알파벳
        final mode = int.tryParse(
              state.uri.queryParameters['mode'] ?? '0',
            ) ??
            0;
        return GameView(gameMode: mode);
      },
    ),
    GoRoute(
      path: RoutePaths.setting,
      builder: (context, state) => const SettingView(),
    ),
  ],
);
