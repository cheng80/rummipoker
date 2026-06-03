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

  testWidgets('fate line transform requires selection confirm feedback', (
    tester,
  ) async {
    final fixture = DebugRunFixtureService.build(
      'fate_two_pair_high_battle_preview',
    );
    expect(fixture, isNotNull);

    await _pumpGameView(
      tester,
      restoredRun: fixture!,
      debugFixtureId: 'test_fate_confirm_feedback',
      debugAutoUseItemId: 'trim_rank',
    );

    await _pumpUntilText(tester, '보드에서 적용할 선을 선택하세요.');
    await _pumpUntilKey(tester, const ValueKey('fate-line-selection-overlay'));

    expect(
      find.byKey(const ValueKey('fate-line-selection-overlay')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('fate-line-selection-candidate-row-2')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('fate-line-transform-result-feedback')),
      findsNothing,
    );

    await tester.tap(
      find.byKey(const ValueKey('fate-line-selection-candidate-row-2')),
    );
    await tester.pump();
    await _pumpUntilKey(
      tester,
      const ValueKey('fate-line-selection-selected-row-2'),
    );

    expect(
      find.byKey(const ValueKey('fate-line-selection-selected-row-2')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('fate-line-transform-result-feedback')),
      findsNothing,
    );

    await tester.tap(find.byKey(const ValueKey('fate-line-confirm-button')));
    await tester.pump();

    expect(
      find.byKey(const ValueKey('fate-line-transform-flash-row-2')),
      findsOneWidget,
    );
    await _pumpUntilText(tester, '투페어 운명');

    expect(
      find.byKey(const ValueKey('fate-line-transform-result-feedback')),
      findsOneWidget,
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
  final visibleTexts = find
      .byType(Text)
      .evaluate()
      .map((element) {
        final widget = element.widget as Text;
        return widget.data ?? widget.textSpan?.toPlainText() ?? '';
      })
      .where((value) => value.isNotEmpty)
      .join(' | ');
  fail('Expected to find "$text". Visible text: $visibleTexts');
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
