import 'dart:io';
import 'dart:convert';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:rummipoker/logic/rummi_poker_grid/item_definition.dart';
import 'package:rummipoker/resources/item_translation_scope.dart';
import 'package:rummipoker/resources/jester_translation_scope.dart';
import 'package:rummipoker/services/active_run_save_service.dart';
import 'package:rummipoker/services/debug_run_fixture_service.dart';
import 'package:rummipoker/services/game_settings.dart';
import 'package:rummipoker/utils/storage_helper.dart';
import 'package:rummipoker/views/game_view.dart';
import '../../support/test_translations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    StorageHelper.resetForTest();
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await EasyLocalization.ensureInitialized();
    await StorageHelper.init();
    GameSettings.bgmMuted = true;
    GameSettings.sfxMuted = true;
  });

  testWidgets(
    'open successful Item feedback changes name and detail with locale',
    (tester) async {
      final fixture = DebugRunFixtureService.build(
        'line_memory_battle_preview',
      )!;
      await _pumpGameView(
        tester,
        restoredRun: fixture,
        debugFixtureId: 'test_item_feedback_locale',
        debugAutoUseItemId: 'line_memory',
      );
      await _pumpUntilKey(
        tester,
        const ValueKey('fate-line-selection-candidate-row-1'),
      );
      await tester.tap(
        find.byKey(const ValueKey('fate-line-selection-candidate-row-1')),
      );
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('fate-line-confirm-button')));
      await tester.pump();
      await _pumpUntilKey(tester, const ValueKey('item-effect-feedback-toast'));
      final gameContext = tester.element(find.byType(GameView));
      final toast = find.byKey(const ValueKey('item-effect-feedback-toast'));
      for (final locale in const [
        Locale('en'),
        Locale('ja'),
        Locale('zh', 'CN'),
        Locale('zh', 'TW'),
      ]) {
        await gameContext.setLocale(locale);
        await tester.pump();
        await tester.runAsync(() async {
          await Future<void>.delayed(const Duration(milliseconds: 40));
        });
        await tester.pump(const Duration(milliseconds: 40));
        final code = locale.toLanguageTag();
        final items =
            jsonDecode(
                  File(
                    'assets/translations/data/$code/items.json',
                  ).readAsStringSync(),
                )
                as Map<String, dynamic>;
        final name =
            items['data']['items']['line_memory']['displayName'] as String;
        expect(
          find.descendant(of: toast, matching: find.text(name)),
          findsOneWidget,
        );
        final strings =
            jsonDecode(
                  File('assets/translations/$code.json').readAsStringSync(),
                )
                as Map<String, dynamic>;
        final detail = tester
            .widget<Text>(
              find.byKey(const ValueKey('item-effect-result-label')),
            )
            .data!;
        expect(
          detail,
          contains(
            (strings['battleTargetGrowth'] as String)
                .split('{target}')
                .last
                .replaceAll('{amount}', '1')
                .trim(),
          ),
        );
        expect(tester.takeException(), isNull);
      }
      await _disposeGameView(tester);
    },
  );
}

Future<void> _pumpGameView(
  WidgetTester tester, {
  required ActiveRunRuntimeState restoredRun,
  required String debugFixtureId,
  String? debugAutoUseItemId,
}) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump();

  tester.view.physicalSize = const Size(390, 750);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  await tester.pumpWidget(
    EasyLocalization(
      assetLoader: const TestTranslationAssetLoader(),
      supportedLocales: const [
        Locale('ko'),
        Locale('en'),
        Locale('ja'),
        Locale('zh', 'CN'),
        Locale('zh', 'TW'),
      ],
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
              home: JesterTranslationScope(
                child: ItemTranslationScope(
                  child: GameView(
                    runSeed: 901,
                    restoredRun: restoredRun,
                    debugFixtureId: debugFixtureId,
                    debugAutoUseItemId: debugAutoUseItemId,
                    debugItemCatalogOverride: ItemCatalog.fromJsonString(
                      File(
                        'data/common/items_common_v1.json',
                      ).readAsStringSync(),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    ),
  );
  await tester.pump();
}

Future<void> _pumpUntilKey(WidgetTester tester, Key key) async {
  for (var i = 0; i < 30; i++) {
    await tester.pump(const Duration(milliseconds: 100));
    if (find.byKey(key).evaluate().isNotEmpty) return;
  }
  fail('Expected to find key "$key".');
}

Future<void> _disposeGameView(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 3));
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pumpAndSettle();
}
