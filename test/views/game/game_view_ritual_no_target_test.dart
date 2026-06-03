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

  testWidgets('ritual with no valid target consumes nothing and shows notice', (
    tester,
  ) async {
    final fixture = DebugRunFixtureService.build(
      DebugRunFixtureService.ritualGrowthCopyBattlePreview,
    );
    expect(fixture, isNotNull);

    await _pumpGameView(
      tester,
      restoredRun: _withSingleQuickItem(fixture!, 'sealed_copy'),
      debugFixtureId: 'test_ritual_no_target_feedback',
      debugAutoUseItemId: 'sealed_copy',
    );

    await _pumpUntilText(tester, '선택할 보드 선이 없습니다.');

    expect(
      find.byKey(const ValueKey('battle-item-card-sealed_copy')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('fate-tile-selection-overlay')),
      findsNothing,
    );
    expect(find.byKey(const ValueKey('ritual-deck-flight')), findsNothing);

    await _disposeGameView(tester);
  });
}

ActiveRunRuntimeState _withSingleQuickItem(
  ActiveRunRuntimeState base,
  String itemId,
) {
  final runProgress = base.runProgress.copySnapshot()
    ..itemInventory = RunInventoryState(
      ownedItems: [
        OwnedItemEntry(
          itemId: itemId,
          count: 1,
          placement: ItemPlacement.quickSlot,
        ),
      ],
      quickSlotItemIds: [itemId],
    );
  return ActiveRunRuntimeState(
    activeScene: base.activeScene,
    difficulty: base.difficulty,
    runModifier: base.runModifier,
    session: base.session.copySnapshot(),
    runProgress: runProgress,
    stageStartSnapshot: ActiveRunStageSnapshot(
      session: base.stageStartSnapshot.session.copySnapshot(),
      runProgress: runProgress.copySnapshot(),
    ),
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

Future<void> _disposeGameView(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 3));
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pumpAndSettle();
}
