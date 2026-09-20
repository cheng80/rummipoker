import 'dart:convert';
import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rummipoker/logic/rummi_poker_grid/jester_meta.dart';
import 'package:rummipoker/logic/rummi_poker_grid/rummi_poker_grid_session.dart';
import 'package:rummipoker/services/active_run_save_service.dart';
import 'package:rummipoker/services/game_settings.dart';
import 'package:rummipoker/services/new_run_setup.dart';
import 'package:rummipoker/utils/storage_helper.dart';
import 'package:rummipoker/views/title_view.dart';
import 'package:rummipoker/widgets/fx/fx_ambient.dart';

class _Loader extends AssetLoader {
  const _Loader();
  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) async =>
      jsonDecode(
            File('$path/${locale.toLanguageTag()}.json').readAsStringSync(),
          )
          as Map<String, dynamic>;
}

void main() {
  testWidgets(
    'Title saved location and open continue dialog follow five locales',
    (tester) async {
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
      final session = RummiPokerGridSession(runSeed: 42);
      final progress = RummiRunProgress()
        ..stageIndex = 3
        ..gold = 27;
      final runtime = ActiveRunRuntimeState(
        activeScene: ActiveRunScene.shop,
        difficulty: NewRunDifficulty.challenge,
        runModifier: NewRunModifier.highStakes,
        session: session,
        runProgress: progress,
        stageStartSnapshot: ActiveRunSaveService.captureStageStartSnapshot(
          session: session,
          runProgress: progress,
        ),
      );
      await ActiveRunSaveService.saveRuntimeState(runtime);
      await ActiveRunSaveService.saveBookmarkSlot(
        slotIndex: 0,
        runtime: runtime,
      );
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      const locales = [
        Locale('ko'),
        Locale('en'),
        Locale('ja'),
        Locale('zh', 'CN'),
        Locale('zh', 'TW'),
      ];
      late BuildContext screen;
      await tester.pumpWidget(
        EasyLocalization(
          supportedLocales: locales,
          path: 'assets/translations',
          assetLoader: const _Loader(),
          fallbackLocale: const Locale('ko'),
          startLocale: const Locale('ko'),
          saveLocale: false,
          child: Builder(
            builder: (context) {
              screen = context;
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
      await tester.pumpAndSettle();
      expect(find.text('현재 Station 3 · Market · Gold 27'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('home-entry-continue')));
      await tester.pumpAndSettle();
      for (final locale in locales) {
        await screen.setLocale(locale);
        await tester.pumpAndSettle();
        final values =
            jsonDecode(
                  File(
                    'assets/translations/${locale.toLanguageTag()}.json',
                  ).readAsStringSync(),
                )
                as Map<String, dynamic>;
        String tr(String key, [Map<String, String> args = const {}]) {
          var value = values[key] as String;
          for (final entry in args.entries) {
            value = value.replaceAll('{${entry.key}}', entry.value);
          }
          return value;
        }

        final location = tr('coreSaveLocation', {
          'station': '3',
          'scene': tr('coreSaveSceneMarket'),
          'gold': '27',
        });
        final checkpoint = tr('coreSaveCheckpoint', {'station': '3'});
        expect(find.text(location, skipOffstage: false), findsOneWidget);
        expect(
          find.text(
            tr('coreSaveContinue', {
              'summary': tr('coreSaveSnapshot', {
                'location': location,
                'checkpoint': checkpoint,
              }),
            }),
          ),
          findsOneWidget,
        );
        expect(find.text(tr('menuDelete')), findsOneWidget);
        expect(find.text(tr('cancel')), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
      await tester.tap(find.text('取消'));
      await tester.pumpAndSettle();
      await screen.setLocale(const Locale('ko'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('home-entry-bookmark')));
      await tester.pumpAndSettle();
      expect(find.text('슬롯 1'), findsOneWidget);
      await tester.tap(find.text('슬롯 1'));
      await tester.pumpAndSettle();
      expect(find.textContaining('S3 · 도전 · 하이 스테이크'), findsOneWidget);
      await screen.setLocale(const Locale('en'));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('S3 · Challenge · High Stakes'),
        findsOneWidget,
      );
      expect(find.textContaining('S3 · 도전 · 하이 스테이크'), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    },
  );
}
