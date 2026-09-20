import 'dart:convert';
import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rummipoker/resources/asset_paths.dart';
import 'package:rummipoker/resources/sound_manager.dart';
import 'package:rummipoker/services/game_settings.dart';
import 'package:rummipoker/utils/app_translation.dart';
import 'package:rummipoker/utils/common_ui.dart';
import 'package:rummipoker/utils/storage_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _NoticeTranslationLoader extends AssetLoader {
  const _NoticeTranslationLoader();
  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) async =>
      jsonDecode(
            File('$path/${locale.toLanguageTag()}.json').readAsStringSync(),
          )
          as Map<String, dynamic>;
}

void main() {
  final sounds = <String>[];
  setUp(() async {
    StorageHelper.resetForTest();
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await StorageHelper.init();
    GameSettings.sfxMuted = false;
    sounds.clear();
    SoundManager.debugSfxSink = (path, _, _) => sounds.add(path);
  });
  tearDown(() => SoundManager.debugSfxSink = null);

  for (final top in [true, false]) {
    testWidgets(
      '${top ? 'top' : 'bottom'} notice localizes without replaying cue or restarting timer',
      (tester) async {
        late BuildContext screen;
        await tester.pumpWidget(
          EasyLocalization(
            supportedLocales: const [Locale('ko'), Locale('en')],
            path: 'assets/translations',
            assetLoader: const _NoticeTranslationLoader(),
            startLocale: const Locale('ko'),
            fallbackLocale: const Locale('ko'),
            saveLocale: false,
            child: Builder(
              builder: (context) => MaterialApp(
                locale: context.locale,
                supportedLocales: context.supportedLocales,
                localizationsDelegates: context.localizationDelegates,
                home: Builder(
                  builder: (context) {
                    screen = context;
                    return const Scaffold(body: SizedBox.shrink());
                  },
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final show = top ? showTopNotice : showBottomNotice;
        final start = tester.binding.clock.now();
        show(
          screen,
          'fallback text',
          duration: const Duration(seconds: 2),
          messageBuilder: (context) => context.translate('runInfoTitle'),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        expect(find.text('런 정보'), findsOneWidget);
        expect(find.text('fallback text'), findsNothing);
        await screen.setLocale(const Locale('en'));
        await tester.pumpAndSettle();
        expect(find.text('Run Info'), findsOneWidget);
        expect(find.text('런 정보'), findsNothing);
        expect(sounds, [AssetPaths.sfxTimeTic]);
        final elapsed = tester.binding.clock.now().difference(start);
        await tester.pump(const Duration(milliseconds: 2261) - elapsed);
        await tester.pump();
        expect(find.text('Run Info'), findsNothing);
        expect(sounds, [AssetPaths.sfxTimeTic]);

        // Legacy/custom strings remain literal even when they resemble a key.
        show(screen, 'runInfoTitle', cue: null);
        await tester.pumpAndSettle();
        await screen.setLocale(const Locale('ko'));
        await tester.pumpAndSettle();
        expect(find.text('runInfoTitle'), findsOneWidget);
        expect(sounds, [AssetPaths.sfxTimeTic]);
        await tester.pump(const Duration(seconds: 3));
        await tester.pump();
        expect(find.text('runInfoTitle'), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
