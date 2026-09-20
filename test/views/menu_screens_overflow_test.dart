import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:rummipoker/resources/sound_manager.dart';
import 'package:rummipoker/services/game_settings.dart';
import 'package:rummipoker/utils/storage_helper.dart';
import 'package:rummipoker/views/new_run_view.dart';
import 'package:rummipoker/views/setting_view.dart';
import 'package:rummipoker/views/title_view.dart';
import 'package:rummipoker/widgets/fx/fx_ambient.dart';

/// 작은 화면과 문구가 긴 언어에서 메뉴 세 화면이 넘치지 않는지 본다.
///
/// 폰 프레임은 논리 390x750으로 고정되고 바깥 크기에 맞춰 축소되므로,
/// 여기서 보는 것은 축소 배치와 언어별 문구 길이가 만드는 overflow다.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const smallSurface = Size(320, 568);
  const locales = <Locale>[Locale('ko'), Locale('en'), Locale('ja')];

  setUp(() async {
    StorageHelper.resetForTest();
    SharedPreferences.setMockInitialValues(<String, Object>{});
    PackageInfo.setMockInitialValues(
      appName: 'Rummi Poker',
      packageName: 'rummipoker',
      version: '1.0.0',
      buildNumber: '1',
      buildSignature: '',
    );
    await StorageHelper.init();
    GameSettings.bgmMuted = true;
    GameSettings.sfxMuted = true;
    SoundManager.debugResetForTest();
    FxAmbient.debugReset();
    debugResetTitleEntrance();
  });

  tearDown(() {
    SoundManager.debugResetForTest();
  });

  Future<void> pumpScreen(
    WidgetTester tester, {
    required Locale locale,
    required Widget screen,
  }) async {
    await tester.binding.setSurfaceSize(smallSurface);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: locales,
        path: 'assets/translations',
        fallbackLocale: const Locale('ko'),
        startLocale: locale,
        saveLocale: false,
        child: Builder(
          builder: (context) => ProviderScope(
            child: MaterialApp(
              locale: context.locale,
              supportedLocales: context.supportedLocales,
              localizationsDelegates: context.localizationDelegates,
              home: screen,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  for (final locale in locales) {
    final tag = locale.toLanguageTag();

    testWidgets('타이틀이 320x568 $tag에서 넘치지 않는다', (tester) async {
      await pumpScreen(
        tester,
        locale: locale,
        screen: const TitleView(showDebugEntriesOverride: false),
      );
      expect(tester.takeException(), isNull);

      // 스크롤 없이 한 화면에 들어온다.
      final scrollable = find.byType(Scrollable).first;
      final position = tester.state<ScrollableState>(scrollable).position;
      expect(position.maxScrollExtent, 0);

      // 타이틀은 2초 뒤 리뷰 요청 타이머를 걸어 두므로 지나간 뒤에 정리한다.
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    });

    testWidgets('새 런 화면이 320x568 $tag에서 넘치지 않는다', (tester) async {
      await pumpScreen(tester, locale: locale, screen: const NewRunView());
      expect(tester.takeException(), isNull);
    });

    testWidgets('설정 화면이 320x568 $tag에서 넘치지 않는다', (tester) async {
      await pumpScreen(tester, locale: locale, screen: const SettingView());
      expect(tester.takeException(), isNull);
    });
  }
}
