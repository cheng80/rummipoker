import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_config.dart';
import 'providers/features/settings/settings_notifier.dart';
import 'resources/jester_translation_scope.dart';
import 'resources/sound_manager.dart';
import 'router.dart';
import 'widgets/starry_background.dart';

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

class _AppState extends ConsumerState<App> {
  @override
  void initState() {
    super.initState();
    ref.read(settingsNotifierProvider.notifier).applyInitialWakelock();
  }

  @override
  Widget build(BuildContext context) {
    final app = JesterTranslationScope(
      child: MaterialApp.router(
        title: AppConfig.appTitle,
        debugShowCheckedModeBanner: false,
        localizationsDelegates: context.localizationDelegates,
        supportedLocales: context.supportedLocales,
        locale: context.locale,
        theme: ThemeData.dark().copyWith(
          colorScheme: ColorScheme.dark(
            primary: const Color(0xFF42A5F5),
            secondary: const Color(0xFF64B5F6),
          ),
        ),
        scrollBehavior: const MaterialScrollBehavior().copyWith(
          dragDevices: {
            PointerDeviceKind.touch,
            PointerDeviceKind.mouse,
            PointerDeviceKind.stylus,
            PointerDeviceKind.invertedStylus,
            PointerDeviceKind.unknown,
          },
        ),
        routerConfig: appRouter,
        builder: (context, child) {
          return Stack(
            children: [
              const Positioned.fill(child: ColoredBox(color: Colors.black)),
              const Positioned.fill(child: StarryBackground()),
              if (child != null) Positioned.fill(child: child),
            ],
          );
        },
      ),
    );
    if (kIsWeb) {
      return Listener(
        onPointerDown: (_) => SoundManager.unlockForWeb(),
        behavior: HitTestBehavior.translucent,
        child: app,
      );
    }
    return app;
  }
}
