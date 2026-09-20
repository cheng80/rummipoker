import 'dart:convert';
import 'dart:io';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rummipoker/logic/rummi_poker_grid/boss_modifier.dart';
import 'package:rummipoker/logic/rummi_poker_grid/jester_meta.dart';
import 'package:rummipoker/logic/rummi_poker_grid/rummi_poker_grid_session.dart';
import 'package:rummipoker/services/active_run_save_service.dart';
import 'package:rummipoker/services/game_settings.dart';
import 'package:rummipoker/services/new_run_setup.dart';
import 'package:rummipoker/utils/storage_helper.dart';
import 'package:rummipoker/views/blind_select_view.dart';
import '../support/test_translations.dart';

ActiveRunRuntimeState _runtime(RummiBossModifier modifier) {
  final session = RummiPokerGridSession(runSeed: 1);
  final progress = RummiRunProgress()..currentStationBlindTierIndex = -1;
  return ActiveRunRuntimeState(
    activeScene: ActiveRunScene.blindSelect,
    difficulty: NewRunDifficulty.standard,
    blindSelectBossModifier: modifier,
    session: session,
    runProgress: progress,
    stageStartSnapshot: ActiveRunSaveService.captureStageStartSnapshot(
      session: session,
      runProgress: progress,
    ),
  );
}

void main() {
  testWidgets(
    'Boss badge follows locale while custom saved text stays intact',
    (tester) async {
      StorageHelper.resetForTest();
      SharedPreferences.setMockInitialValues(<String, Object>{});
      await StorageHelper.init();
      GameSettings.bgmMuted = true;
      GameSettings.sfxMuted = true;
      final selected = ValueNotifier(RummiBossModifier.redDampener);
      addTearDown(selected.dispose);
      await tester.binding.setSurfaceSize(const Size(320, 568));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      late BuildContext localeContext;
      await tester.pumpWidget(
        EasyLocalization(
          assetLoader: const TestTranslationAssetLoader(),
          supportedLocales: const [Locale('ko'), Locale('en')],
          path: 'assets/translations',
          startLocale: const Locale('ko'),
          fallbackLocale: const Locale('ko'),
          saveLocale: false,
          child: Builder(
            builder: (context) {
              localeContext = context;
              return MaterialApp(
                locale: context.locale,
                supportedLocales: context.supportedLocales,
                localizationsDelegates: context.localizationDelegates,
                home: ValueListenableBuilder(
                  valueListenable: selected,
                  builder: (context, modifier, child) => BlindSelectView(
                    key: ValueKey(modifier.id),
                    runSeed: 1,
                    difficulty: NewRunDifficulty.standard,
                    restoredRun: _runtime(modifier),
                  ),
                ),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text(RummiBossModifier.redDampener.title), findsOneWidget);
      await localeContext.setLocale(const Locale('en'));
      await tester.pumpAndSettle();
      final translations =
          jsonDecode(
                File('assets/translations/src/core/en.json').readAsStringSync(),
              )
              as Map<String, dynamic>;
      final keys = RummiBossModifier.redDampener.displayKeys!;
      expect(find.text(translations[keys.titleKey] as String), findsOneWidget);
      expect(
        find.text(translations[keys.markerTextKey] as String),
        findsOneWidget,
      );
      expect(find.text(RummiBossModifier.redDampener.title), findsNothing);
      expect(tester.takeException(), isNull);

      selected.value = const RummiBossModifier(
        id: 'custom_saved_boss',
        category: RummiBossModifierCategory.allScoreWeaken,
        title: 'Saved custom title',
        ruleText: 'Saved custom rule',
        markerText: 'Custom marker',
        scoreMultiplier: 0.9,
      );
      await tester.pumpAndSettle();
      expect(find.text('Saved custom title'), findsOneWidget);
      expect(find.text('Custom marker'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
