import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_config.dart';
import 'providers/features/settings/settings_notifier.dart';
import 'resources/asset_paths.dart';
import 'resources/item_translation_scope.dart';
import 'resources/jester_translation_scope.dart';
import 'resources/sound_manager.dart';
import 'router.dart';
import 'services/frame_timing_metrics.dart';
import 'views/game/widgets/game_ui_palette.dart';
import 'widgets/fx/fx_layer.dart';
import 'widgets/starry_background.dart';

/// 기본 폰트(NEXON Lv2 Gothic)에 글리프가 없는 글자를 그릴 폰트 순서.
/// 이 fallback이 없으면 웹(CanvasKit)이 빠진 글자를 Google 서버의 Noto 폰트로 그때그때 내려받아
/// 받기 전까지 빈 네모가 보이고, 오프라인·차단 환경에서는 계속 네모로 남는다.
/// 텍스트 스타일마다 덧대지 않도록 테마 한 곳에서만 지정한다.
const List<String> appFontFamilyFallback = <String>[
  AssetPaths.fontNotoSansCjkLangNames,
];

/// 앱 전체 테마. 글꼴과 fallback을 여기 한 곳에서만 정한다.
ThemeData buildAppTheme() {
  final baseTheme = ThemeData.dark();
  return baseTheme.copyWith(
    textTheme: baseTheme.textTheme.apply(
      fontFamily: AssetPaths.fontNexonLv2Gothic,
      fontFamilyFallback: appFontFamilyFallback,
    ),
    primaryTextTheme: baseTheme.primaryTextTheme.apply(
      fontFamily: AssetPaths.fontNexonLv2Gothic,
      fontFamilyFallback: appFontFamilyFallback,
    ),
    colorScheme: ColorScheme.dark(
      primary: GameUiPalette.appPrimaryBlue,
      secondary: GameUiPalette.appSecondaryBlue,
    ),
  );
}

/// 앱의 루트 위젯. 테마, 라우팅 등 앱 전체 설정을 담당한다.
/// main.dart와 분리한 이유:
///   - main()에 초기화 코드가 늘어나도(Firebase, 환경변수 등) 이 파일은 변경 없이 유지된다.
///   - ProviderScope는 main()에서 EasyLocalization 바깥으로 감싼다.
///
/// [StarryBackground]는 앱 전체에서 단 하나만 존재한다.
/// [MaterialApp.router]의 [builder]를 통해 Router 바깥에 배치하여,
/// 페이지 전환 시에도 배경이 파괴/재생성되지 않는다.
class App extends ConsumerStatefulWidget {
  const App({super.key});

  @override
  ConsumerState<App> createState() => _AppState();
}

class _AppState extends ConsumerState<App> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    ref.read(settingsNotifierProvider.notifier).applyInitialWakelock();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
      case AppLifecycleState.detached:
        FrameTimingMetrics.instance.reportAndReset();
        SoundManager.pauseBgm(recoverOnNextWebGesture: true);
        break;
      case AppLifecycleState.resumed:
        SoundManager.resumeBgm();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = JesterTranslationScope(
      child: ItemTranslationScope(
        child: MaterialApp.router(
          title: AppConfig.appTitle,
          debugShowCheckedModeBanner: false,
          localizationsDelegates: context.localizationDelegates,
          supportedLocales: context.supportedLocales,
          locale: context.locale,
          theme: buildAppTheme(),
          scrollBehavior: const AppScrollBehavior(),
          routerConfig: appRouter,
          builder: (context, child) {
            return Stack(
              children: [
                const Positioned.fill(
                  child: ColoredBox(color: GameUiPalette.ink),
                ),
                const Positioned.fill(child: StarryBackground()),
                if (child != null)
                  Positioned.fill(child: RepaintBoundary(child: child)),
                const Positioned.fill(child: FxLayer()),
              ],
            );
          },
        ),
      ),
    );
    if (kIsWeb) {
      return Listener(
        onPointerDown: (_) => SoundManager.unlockForWeb(),
        onPointerUp: (_) => SoundManager.unlockForWeb(),
        behavior: HitTestBehavior.translucent,
        child: app,
      );
    }
    return app;
  }
}

class AppScrollBehavior extends MaterialScrollBehavior {
  const AppScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.stylus,
    PointerDeviceKind.invertedStylus,
    PointerDeviceKind.unknown,
  };

  @override
  Widget buildScrollbar(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    if (kIsWeb) return child;
    return super.buildScrollbar(context, child, details);
  }
}
