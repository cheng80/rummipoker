import 'dart:convert';
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
import 'package:rummipoker/utils/common_ui.dart';
import 'package:rummipoker/views/game_view.dart';
import '../../support/test_translations.dart';
import 'package:rummipoker/utils/active_run_translation.dart';

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

  testWidgets('run restart and exit confirmations use the selected locale', (
    tester,
  ) async {
    final fixture = DebugRunFixtureService.build(
      'fate_two_pair_high_battle_preview',
    )!;
    await ActiveRunSaveService.saveBookmarkSlot(slotIndex: 0, runtime: fixture);
    await _pumpGameView(
      tester,
      restoredRun: fixture,
      debugFixtureId: 'test_run_end_localization',
    );
    for (
      var i = 0;
      i < 40 && find.byIcon(Icons.more_vert_rounded).evaluate().isEmpty;
      i++
    ) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    final gameContext = tester.element(find.byType(GameView));
    await tester.tap(find.byIcon(Icons.more_vert_rounded));
    await tester.pumpAndSettle();
    for (final locale in [
      const Locale('ko'),
      const Locale('en'),
      const Locale('ja'),
      const Locale('zh', 'CN'),
      const Locale('zh', 'TW'),
    ]) {
      await gameContext.setLocale(locale);
      await tester.pumpAndSettle();
      final code = locale.toString().replaceAll('_', '-');
      final messages =
          jsonDecode(File('assets/translations/$code.json').readAsStringSync())
              as Map<String, dynamic>;
      for (final entry in {
        Icons.replay_rounded: 'battleRestartBattlePrompt',
        Icons.logout_rounded: 'battleExitTitlePrompt',
      }.entries) {
        final action = tester.widget<GameMenuActionTile>(
          find.byWidgetPredicate(
            (w) => w is GameMenuActionTile && w.icon == entry.key,
          ),
        );
        action.onTap!();
        await tester.pumpAndSettle();
        expect(
          find.text(messages[entry.value] as String),
          findsOneWidget,
          reason: code,
        );
        expect(tester.takeException(), isNull, reason: code);
        final changedLocale = locale.languageCode == 'en'
            ? const Locale('ja')
            : const Locale('en');
        await gameContext.setLocale(changedLocale);
        await tester.pumpAndSettle();
        final changedMessages =
            jsonDecode(
                  File(
                    'assets/translations/${changedLocale.languageCode}.json',
                  ).readAsStringSync(),
                )
                as Map<String, dynamic>;
        expect(
          find.text(changedMessages[entry.value] as String),
          findsOneWidget,
          reason: 'An already open confirmation must follow the locale',
        );

        Navigator.of(tester.element(find.byType(Dialog).last)).pop(false);
        await tester.pumpAndSettle();
        await gameContext.setLocale(locale);
        await tester.pumpAndSettle();
      }
    }
    expect(find.textContaining('표준'), findsNothing);
    final bookmarkAction = tester.widget<GameMenuActionTile>(
      find.byWidgetPredicate(
        (w) => w is GameMenuActionTile && w.icon == Icons.bookmark_add_rounded,
      ),
    );
    bookmarkAction.onTap!();
    await tester.pumpAndSettle();
    await gameContext.setLocale(const Locale('en'));
    await tester.pumpAndSettle();
    expect(find.text('Save bookmark'), findsOneWidget);
    final slotOptions = find.descendant(
      of: find.byType(Dialog).last,
      matching: find.byWidgetPredicate(
        (w) => w is Semantics && w.properties.button == true,
      ),
    );
    await tester.tap(slotOptions.first);
    await tester.pumpAndSettle();
    final savedSlots = await ActiveRunSaveService.loadBookmarkSlots();
    expect(
      find.text(
        '${gameContext.activeRunSlotLabel(savedSlots.first)}\n\nOverwrite this slot with your current progress?',
      ),
      findsOneWidget,
    );
    expect(find.textContaining('Standard'), findsWidgets);
    expect(find.textContaining('표준'), findsNothing);
    await gameContext.setLocale(const Locale('ja'));
    await tester.pumpAndSettle();
    final japanese =
        jsonDecode(File('assets/translations/ja.json').readAsStringSync())
            as Map<String, dynamic>;
    expect(
      find.text(
        (japanese['battleBookmarkOverwritePrompt'] as String).replaceAll(
          '{label}',
          gameContext.activeRunSlotLabel(savedSlots.first),
        ),
      ),
      findsOneWidget,
    );
    expect(find.textContaining('Standard'), findsNothing);
    Navigator.of(tester.element(find.byType(Dialog).last)).pop(false);
    await tester.pumpAndSettle();
    Navigator.of(tester.element(find.byType(Dialog).last)).pop();
    await tester.pumpAndSettle();
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

Future<void> _disposeGameView(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 3));
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pumpAndSettle();
}
