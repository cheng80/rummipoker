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

  testWidgets('Fate selection follows all five locales without losing its target', (
    tester,
  ) async {
    final fixture = DebugRunFixtureService.build(
      'fate_two_pair_high_battle_preview',
    )!;
    await _pumpGameView(
      tester,
      restoredRun: fixture,
      debugFixtureId: 'test_fate_localization',
      debugAutoUseItemId: 'trim_rank',
    );
    await _pumpUntilKey(
      tester,
      const ValueKey('fate-line-selection-candidate-row-2'),
    );
    await tester.tap(
      find.byKey(const ValueKey('fate-line-selection-candidate-row-2')),
    );
    await tester.pump();
    final gameContext = tester.element(find.byType(GameView));
    final locales = [
      const Locale('ko'),
      const Locale('en'),
      const Locale('ja'),
      const Locale('zh', 'CN'),
      const Locale('zh', 'TW'),
    ];
    for (final locale in locales) {
      await gameContext.setLocale(locale);
      await tester.pumpAndSettle();
      final messages =
          jsonDecode(
                File(
                  'assets/translations/${locale.toString().replaceAll('_', '-')}.json',
                ).readAsStringSync(),
              )
              as Map<String, dynamic>;
      expect(
        find.text(messages['battleTwoPairPreview'] as String),
        findsOneWidget,
      );
      expect(find.text(messages['battleTransform'] as String), findsOneWidget);
      expect(
        find.byKey(const ValueKey('fate-line-selection-selected-row-2')),
        findsOneWidget,
      );
      if (locale.languageCode == 'en') {
        expect(
          find.text('Row 3 · Incomplete / no score · Tiles 5'),
          findsOneWidget,
        );
      }
      final itemMessages =
          jsonDecode(
                File(
                  'assets/translations/data/${locale.toString().replaceAll('_', '-')}/items.json',
                ).readAsStringSync(),
              )
              as Map<String, dynamic>;
      final itemName =
          itemMessages['data']['items']['trim_rank']['displayName'] as String;
      expect(find.text(itemName), findsWidgets);

      final raw = find.byWidgetPredicate(
        (w) =>
            w is Text &&
            RegExp(r'\{(?:count|rank|tile|line)\}').hasMatch(w.data ?? ''),
      );
      expect(raw, findsNothing);
      expect(tester.takeException(), isNull, reason: '$locale');
    }
    await tester.tap(find.byKey(const ValueKey('fate-line-confirm-button')));
    await tester.pump();
    await _pumpUntilKey(
      tester,
      const ValueKey('fate-line-transform-result-feedback'),
    );
    await _disposeGameView(tester);
  });
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
