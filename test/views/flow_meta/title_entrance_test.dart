import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:rummipoker/services/game_settings.dart';
import 'package:rummipoker/utils/storage_helper.dart';
import 'package:rummipoker/views/title_view.dart';
import 'package:rummipoker/widgets/fx/entrance_in.dart';
import '../../support/test_translations.dart';

/// 로고 등장 위젯이 움직이는 중이면 안쪽에 FadeTransition을 둔다.
Finder _logoEntranceMotion() => find.descendant(
  of: find.byType(EntranceIn).first,
  matching: find.byType(FadeTransition),
);

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
    debugResetTitleEntrance();
  });

  testWidgets('타이틀 등장은 처음 한 번만 움직이고, 기본 강도에서는 멈춘다', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    Widget app() => EasyLocalization(
      assetLoader: const TestTranslationAssetLoader(),
      supportedLocales: const [Locale('ko')],
      path: 'assets/translations',
      fallbackLocale: const Locale('ko'),
      startLocale: const Locale('ko'),
      saveLocale: false,
      child: Builder(
        builder: (context) => ProviderScope(
          child: MaterialApp(
            locale: context.locale,
            supportedLocales: context.supportedLocales,
            localizationsDelegates: context.localizationDelegates,
            home: const TitleView(showDebugEntriesOverride: false),
          ),
        ),
      ),
    );

    await tester.pumpWidget(app());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 60));
    expect(_logoEntranceMotion(), findsWidgets, reason: '첫 진입 등장 연출');
    // 기본 강도에서는 등장 뒤 멈춘다(상시 idle 루프 없음).
    await tester.pumpAndSettle();
    expect(tester.hasRunningAnimations, isFalse);

    // 두 번째 방문은 처음부터 제자리다.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(app());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 60));
    expect(_logoEntranceMotion(), findsNothing, reason: '두 번째 방문은 정지');

    // 강도 '강'에서만 idle 루프가 돈다.
    GameSettings.fxIntensity = FxIntensity.strong;
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(app());
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(tester.hasRunningAnimations, isTrue, reason: "'강' idle 루프");
    GameSettings.fxIntensity = FxIntensity.normal;
    await tester.pumpWidget(const SizedBox.shrink());
    // 타이틀의 리뷰 요청 지연(2초) 타이머를 흘려 보낸다.
    await tester.pump(const Duration(seconds: 3));
  });
}
