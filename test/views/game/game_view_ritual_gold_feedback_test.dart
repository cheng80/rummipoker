import 'dart:io';

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

  testWidgets('ritual burn requires confirm and shows gold coin flight', (
    tester,
  ) async {
    final fixture = DebugRunFixtureService.build(
      DebugRunFixtureService.ritualPruneBurnBattlePreview,
    );
    expect(fixture, isNotNull);

    await _pumpGameView(
      tester,
      restoredRun: fixture!,
      debugFixtureId: 'test_ritual_gold_feedback',
      debugAutoUseItemId: 'deadwood_burn',
    );

    await _pumpUntilText(tester, '보드에서 적용할 선을 선택하세요.');
    await _pumpUntilKey(tester, const ValueKey('fate-line-selection-overlay'));

    final candidateKey = _lastValueKeyWithPrefix(
      tester,
      'fate-line-selection-candidate-',
    );
    expect(candidateKey, isNotNull);
    expect(find.byKey(candidateKey!), findsOneWidget);
    expect(find.byKey(const ValueKey('ritual-gold-flight')), findsNothing);

    await tester.tap(find.byKey(candidateKey));
    await tester.pump();

    final selectedKey = ValueKey<String>(
      candidateKey.value.replaceFirst(
        'fate-line-selection-candidate-',
        'fate-line-selection-selected-',
      ),
    );
    await _pumpUntilKey(tester, selectedKey);
    expect(find.byKey(selectedKey), findsOneWidget);
    expect(find.byKey(const ValueKey('ritual-gold-flight')), findsNothing);

    await tester.tap(find.byKey(const ValueKey('fate-line-confirm-button')));
    await tester.pump();

    expect(find.byKey(const ValueKey('ritual-gold-flight')), findsOneWidget);
    expect(
      _lastValueKeyWithPrefix(tester, 'ritual-gold-flight-coin-'),
      isNotNull,
    );
    await _pumpUntilKey(tester, const ValueKey('market-gold-gain-badge'));
    expect(find.text('+3G'), findsOneWidget);

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

  tester.view.physicalSize = const Size(1280, 2400);
  tester.view.devicePixelRatio = 1.0;
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

Future<void> _pumpUntilText(WidgetTester tester, String text) async {
  for (var i = 0; i < 30; i++) {
    await tester.pump(const Duration(milliseconds: 100));
    if (find.text(text).evaluate().isNotEmpty) return;
  }
  fail('Expected to find "$text".');
}

Future<void> _pumpUntilKey(WidgetTester tester, Key key) async {
  for (var i = 0; i < 30; i++) {
    await tester.pump(const Duration(milliseconds: 100));
    if (find.byKey(key).evaluate().isNotEmpty) return;
  }
  fail('Expected to find key "$key".');
}

ValueKey<String>? _lastValueKeyWithPrefix(WidgetTester tester, String prefix) {
  ValueKey<String>? result;
  for (final element in find.byWidgetPredicate((_) => true).evaluate()) {
    final key = element.widget.key;
    if (key is ValueKey<String> && key.value.startsWith(prefix)) {
      result = key;
    }
  }
  return result;
}

Future<void> _disposeGameView(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 3));
  await tester.pump(const Duration(seconds: 3));
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pumpAndSettle();
}
