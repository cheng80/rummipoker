import 'dart:convert';
import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rummipoker/resources/asset_paths.dart';
import 'package:rummipoker/resources/sound_manager.dart';
import 'package:rummipoker/services/game_settings.dart';
import 'package:rummipoker/utils/action_failure_translation.dart';
import 'package:rummipoker/utils/app_translation.dart';
import 'package:rummipoker/logic/rummi_poker_grid/action_failure.dart';
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

  test('all reasons have matching keys and placeholders in five locales', () {
    final maps = [
      for (final locale in ['ko', 'en', 'ja', 'zh-CN', 'zh-TW'])
        jsonDecode(
              File(
                'assets/translations/src/core_action_errors/$locale.json',
              ).readAsStringSync(),
            )
            as Map<String, dynamic>,
    ];
    for (final map in maps) {
      expect(map.keys.toSet(), maps.first.keys.toSet());
      for (final key in maps.first.keys) {
        Set<String> placeholders(String text) =>
            RegExp(r'\{[^}]+\}').allMatches(text).map((m) => m[0]!).toSet();
        expect(
          placeholders(map[key] as String),
          placeholders(maps.first[key] as String),
        );
      }
    }
    expect(maps.first.length, ActionFailureReason.values.length + 8);
  });
  for (final top in [true, false]) {
    testWidgets(
      '${top ? 'top' : 'bottom'} notice localizes without replaying cue or restarting timer',
      (tester) async {
        late BuildContext screen;
        await tester.pumpWidget(
          EasyLocalization(
            supportedLocales: const [
              Locale('ko'),
              Locale('en'),
              Locale('ja'),
              Locale('zh', 'CN'),
              Locale('zh', 'TW'),
            ],
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
          messageBuilder: (context) => actionFailureLabel(
            context,
            const ActionFailure(
              ActionFailureReason.handFull,
              'legacy',
              args: {'count': '5'},
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        expect(find.text('손패는 최대 5장입니다.'), findsOneWidget);
        expect(find.text('fallback text'), findsNothing);
        await screen.setLocale(const Locale('en'));
        await tester.pumpAndSettle();
        expect(find.text('Hand limit: 5 tiles.'), findsOneWidget);
        expect(find.text('손패는 최대 5장입니다.'), findsNothing);
        expect(sounds, [AssetPaths.sfxTimeTic]);
        final elapsed = tester.binding.clock.now().difference(start);
        await tester.pump(const Duration(milliseconds: 2261) - elapsed);
        await tester.pump();
        expect(find.text('Hand limit: 5 tiles.'), findsNothing);
        expect(sounds, [AssetPaths.sfxTimeTic]);

        for (final locale in [
          const Locale('ja'),
          const Locale('zh', 'CN'),
          const Locale('zh', 'TW'),
        ]) {
          await screen.setLocale(locale);
          await tester.pumpAndSettle();
          show(
            screen,
            '',
            cue: null,
            messageBuilder: (context) => actionFailureLabel(
              context,
              const ActionFailure(
                ActionFailureReason.handFull,
                'legacy',
                args: {'count': '5'},
              ),
            ),
          );
          await tester.pumpAndSettle();
          final messages =
              jsonDecode(
                    File(
                      'assets/translations/src/core_action_errors/${locale.toLanguageTag()}.json',
                    ).readAsStringSync(),
                  )
                  as Map<String, dynamic>;
          expect(
            find.text(
              (messages['coreActionHandFull'] as String).replaceAll(
                '{count}',
                '5',
              ),
            ),
            findsOneWidget,
          );
          await tester.pump(const Duration(seconds: 3));
        }
        // Legacy/custom strings remain literal even when they resemble a key.
        show(
          screen,
          'runInfoTitle',
          cue: null,
          messageBuilder: (context) => actionFailureLabel(
            context,
            const ActionFailure(null, 'runInfoTitle'),
          ),
        );
        await tester.pumpAndSettle();
        await screen.setLocale(const Locale('ko'));
        await tester.pumpAndSettle();
        expect(find.text('runInfoTitle'), findsOneWidget);
        expect(sounds, [AssetPaths.sfxTimeTic]);
        await tester.pump(const Duration(seconds: 3));
        await tester.pump();
        expect(find.text('runInfoTitle'), findsNothing);
        for (final key in [
          'marketJesterSold',
          'marketItemSold',
          'marketTileAdded',
        ]) {
          await screen.setLocale(const Locale('ko'));
          await tester.pumpAndSettle();
          show(
            screen,
            'old sale notice',
            cue: null,
            messageBuilder: (context) =>
                context.translate(key, namedArgs: const {'tile': 'R7'}),
          );
          await tester.pump();
          await screen.setLocale(const Locale('en'));
          await tester.pumpAndSettle();
          final english =
              jsonDecode(File('assets/translations/en.json').readAsStringSync())
                  as Map<String, dynamic>;
          expect(
            find.text((english[key] as String).replaceAll('{tile}', 'R7')),
            findsOneWidget,
          );
          expect(find.text('old sale notice'), findsNothing);
          await tester.pump(const Duration(seconds: 3));
        }
        expect(tester.takeException(), isNull);
      },
    );
  }
}
