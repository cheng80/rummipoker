import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:rummipoker/services/game_settings.dart';
import 'package:rummipoker/utils/storage_helper.dart';
import 'package:rummipoker/views/title_view.dart';
import 'package:rummipoker/widgets/fx/fx_ambient.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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
    FxAmbient.debugReset();
  });

  testWidgets('title run info entry opens an empty-run explanation', (
    tester,
  ) async {
    FxAmbient.setMood(FxAmbientMood.battle);
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: const [Locale('ko'), Locale('en')],
        path: 'assets/translations',
        fallbackLocale: const Locale('ko'),
        startLocale: const Locale('ko'),
        saveLocale: false,
        child: Builder(
          builder: (context) {
            return ProviderScope(
              child: MaterialApp(
                locale: context.locale,
                supportedLocales: context.supportedLocales,
                localizationsDelegates: context.localizationDelegates,
                home: const TitleView(showDebugEntriesOverride: false),
              ),
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(FxAmbient.controller.mood, FxAmbientMood.menu);
    expect(find.text('버전 1.0.0+1'), findsOneWidget);
    expect(find.byKey(const ValueKey('home-entry-archive')), findsOneWidget);
    expect(find.byKey(const ValueKey('home-entry-bookmark')), findsOneWidget);
    expect(find.byKey(const ValueKey('home-entry-run-info')), findsOneWidget);
    expect(find.byKey(const ValueKey('home-entry-new-run')), findsOneWidget);
    expect(find.byKey(const ValueKey('home-entry-setting')), findsOneWidget);
    expect(find.text('도감'), findsWidgets);
    expect(find.text('북마크 불러오기'), findsOneWidget);
    expect(find.byKey(const ValueKey('home-entry-special-mode')), findsNothing);
    expect(
      find.byKey(const ValueKey('home-entry-debug-fixture')),
      findsNothing,
    );

    await tester.tap(find.byKey(const ValueKey('home-entry-run-info')));
    await tester.pumpAndSettle();

    expect(find.text('런 정보'), findsWidgets);
    expect(find.textContaining('진행 중인 런이 없습니다.'), findsOneWidget);
    expect(find.textContaining('족보 성장과 추가 덱 정보'), findsOneWidget);

    await tester.pump(const Duration(seconds: 3));
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });
}
