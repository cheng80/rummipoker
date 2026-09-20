import 'package:rummipoker/resources/asset_paths.dart';
import 'package:rummipoker/resources/sound_manager.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:rummipoker/services/game_settings.dart';
import 'package:rummipoker/utils/storage_helper.dart';
import 'package:rummipoker/views/setting_view.dart';
import '../support/test_translations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    StorageHelper.resetForTest();
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await StorageHelper.init();
    GameSettings.bgmMuted = true;
    GameSettings.sfxMuted = true;
  });

  testWidgets('hides rate app entry when store listing id is empty', (
    tester,
  ) async {
    await tester.pumpWidget(
      EasyLocalization(
        assetLoader: const TestTranslationAssetLoader(),
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

    expect(find.text('평점 남기기'), findsNothing);
    final sounds = <String>[];
    final rates = <double>[];
    SoundManager.debugSfxSink = (path, _, rate) {
      sounds.add(path);
      rates.add(rate);
    };
    addTearDown(() => SoundManager.debugSfxSink = null);
    final sfxToggle = find.byWidgetPredicate(
      (widget) =>
          widget is Semantics &&
          widget.properties.toggled != null &&
          widget.properties.label == '효과음',
    );
    await tester.ensureVisible(sfxToggle);
    await tester.tap(sfxToggle);
    await tester.pumpAndSettle();
    expect(GameSettings.sfxMuted, isFalse);
    expect(sounds, [AssetPaths.sfxBtnSnd]);
    expect(rates, [1]);
    sounds.clear();
    await tester.tap(sfxToggle);
    await tester.pumpAndSettle();
    expect(GameSettings.sfxMuted, isTrue);
    expect(sounds, isEmpty);
  });
}
