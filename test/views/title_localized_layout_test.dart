import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rummipoker/resources/asset_paths.dart';
import 'package:rummipoker/resources/sound_manager.dart';
import 'package:rummipoker/services/game_settings.dart';
import 'package:rummipoker/utils/storage_helper.dart';
import 'package:rummipoker/views/title_view.dart';
import 'package:rummipoker/widgets/fx/fx_ambient.dart';
import 'package:rummipoker/widgets/fx/motion_policy.dart';
import '../support/test_translations.dart';

void main() {
  testWidgets('decoded Title logo and all five locales fit without scrolling', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    StorageHelper.resetForTest();
    SharedPreferences.setMockInitialValues({});
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
    MotionPolicy.debugReduceMotionOverride = true;
    addTearDown(() {
      MotionPolicy.debugReduceMotionOverride = null;
      SoundManager.debugResetForTest();
    });
    const locales = [
      Locale('ko'),
      Locale('en'),
      Locale('ja'),
      Locale('zh', 'CN'),
      Locale('zh', 'TW'),
    ];
    late BuildContext localeContext;
    late BuildContext screenContext;
    await tester.pumpWidget(
      ProviderScope(
        child: EasyLocalization(
          supportedLocales: locales,
          path: 'assets/translations',
          assetLoader: const TestTranslationAssetLoader(),
          startLocale: locales.first,
          fallbackLocale: locales.first,
          saveLocale: false,
          child: Builder(
            builder: (context) {
              localeContext = context;
              return MaterialApp(
                locale: context.locale,
                supportedLocales: context.supportedLocales,
                localizationsDelegates: context.localizationDelegates,
                home: Builder(
                  builder: (context) {
                    screenContext = context;
                    return const TitleView(showDebugEntriesOverride: false);
                  },
                ),
              );
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    // A cold image has zero height until decoding completes; that can hide
    // overflow in an isolated locale test. Await the actual image, not time.
    await tester.runAsync(
      () => precacheImage(
        const AssetImage(AssetPaths.uiRummiPokerLogo),
        screenContext,
      ),
    );
    await tester.pumpAndSettle();
    for (final locale in locales) {
      await tester.runAsync(() => localeContext.setLocale(locale));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: '$locale');
      expect(tester.getSize(find.byType(Image).first).height, greaterThan(160));
      final position = tester
          .state<ScrollableState>(find.byType(Scrollable).first)
          .position;
      expect(position.maxScrollExtent, 0, reason: 'decoded logo / $locale');
    }
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });
}
