import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:rummipoker/resources/item_translation_scope.dart';
import 'package:rummipoker/resources/jester_translation_scope.dart';
import 'package:rummipoker/services/debug_run_fixture_service.dart';
import 'package:rummipoker/services/game_settings.dart';
import 'package:rummipoker/utils/storage_helper.dart';
import 'package:rummipoker/views/game_view.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    StorageHelper.resetForTest();
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await StorageHelper.init();
    GameSettings.bgmMuted = true;
    GameSettings.sfxMuted = true;
  });

  testWidgets('debug battle item auto use shows item feedback burst', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final fixture = DebugRunFixtureService.build(
      DebugRunFixtureService.animationEffectsEyeCheck,
    );
    expect(fixture, isNotNull);

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
                      restoredRun: fixture,
                      debugFixtureId:
                          DebugRunFixtureService.animationEffectsEyeCheck,
                      debugAutoUseItemId: 'board_scrap',
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );

    for (var i = 0; i < 30; i++) {
      await tester.pump(const Duration(milliseconds: 100));
      if (find
          .byKey(const ValueKey('item-effect-spark-burst'))
          .evaluate()
          .isNotEmpty) {
        break;
      }
    }

    expect(
      find.byKey(const ValueKey('item-effect-spark-burst')),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('item-effect-source-label')),
        matching: find.text('Q1'),
      ),
      findsOneWidget,
    );

    await tester.pump(const Duration(seconds: 3));
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });
}
