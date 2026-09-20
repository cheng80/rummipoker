import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:rummipoker/services/game_settings.dart';
import 'package:rummipoker/utils/storage_helper.dart';
import 'package:rummipoker/views/setting_view.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    StorageHelper.resetForTest();
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await StorageHelper.init();
    GameSettings.bgmMuted = true;
    GameSettings.sfxMuted = true;
  });

  testWidgets('effect settings section saves intensity and speed choices', (
    tester,
  ) async {
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
                home: const SettingView(),
              ),
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    final strong = find.byKey(
      ValueKey('setting-fx-intensity-${FxIntensity.strong.name}'),
    );
    await tester.scrollUntilVisible(strong, 200);
    await tester.tap(strong);
    await tester.pumpAndSettle();
    expect(GameSettings.fxIntensity, FxIntensity.strong);

    final instant = find.byKey(
      ValueKey('setting-settlement-speed-${SettlementSpeed.instant.name}'),
    );
    await tester.scrollUntilVisible(instant, 200);
    await tester.tap(instant);
    await tester.pumpAndSettle();
    expect(GameSettings.settlementSpeed, SettlementSpeed.instant);

    final shake = find.byKey(const ValueKey('setting-screen-shake'));
    await tester.scrollUntilVisible(shake, 200);
    await tester.tap(shake);
    await tester.pumpAndSettle();
    expect(GameSettings.screenShakeEnabled, isFalse);
  });
}
