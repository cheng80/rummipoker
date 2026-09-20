import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:rummipoker/logic/rummi_poker_grid/jester_meta.dart';
import 'package:rummipoker/logic/rummi_poker_grid/models/poker_deck.dart';
import 'package:rummipoker/logic/rummi_poker_grid/rummi_blind_state.dart';
import 'package:rummipoker/logic/rummi_poker_grid/rummi_poker_grid_session.dart';
import 'package:rummipoker/resources/jester_translation_scope.dart';
import 'package:rummipoker/services/active_run_save_service.dart';
import 'package:rummipoker/services/game_analytics_service.dart';
import 'package:rummipoker/services/game_settings.dart';
import 'package:rummipoker/services/new_run_setup.dart';
import 'package:rummipoker/services/tutorial_state_service.dart';
import 'package:rummipoker/utils/storage_helper.dart';
import 'package:rummipoker/views/game_view.dart';
import 'package:rummipoker/widgets/fx/fx_ambient.dart';
import '../../support/test_translations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    StorageHelper.resetForTest();
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await StorageHelper.init();
    await TutorialStateService.markBattleIntroSeen();
    GameSettings.bgmMuted = true;
    GameSettings.sfxMuted = true;
    GameAnalyticsService.debugResetForTest();
    FxAmbient.debugReset();
  });

  tearDown(GameAnalyticsService.debugResetForTest);

  testWidgets('Boss 전투에 진입하면 boss 분위기가 된다', (tester) async {
    tester.view.physicalSize = const Size(1280, 720);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    final session = RummiPokerGridSession(
      runSeed: 901,
      blind: RummiBlindState(
        targetScore: 400,
        boardDiscardsRemaining: 4,
        handDiscardsRemaining: 2,
      ),
      deck: PokerDeck.fromSnapshot(const []),
    );
    final runProgress = RummiRunProgress()
      ..stageIndex = 1
      ..currentStationBlindTierIndex = 2
      ..gold = 10;
    final restoredRun = ActiveRunRuntimeState(
      activeScene: ActiveRunScene.battle,
      difficulty: NewRunDifficulty.standard,
      session: session,
      runProgress: runProgress,
      stageStartSnapshot: ActiveRunStageSnapshot(
        session: session.copySnapshot(),
        runProgress: runProgress.copySnapshot(),
      ),
    );
    await tester.pumpWidget(
      EasyLocalization(
        assetLoader: const TestTranslationAssetLoader(),
        supportedLocales: const [Locale('ko'), Locale('en')],
        path: 'assets/translations',
        fallbackLocale: const Locale('ko'),
        startLocale: const Locale('ko'),
        saveLocale: false,
        child: Builder(
          builder: (context) => ProviderScope(
            child: MaterialApp(
              locale: context.locale,
              supportedLocales: context.supportedLocales,
              localizationsDelegates: context.localizationDelegates,
              home: JesterTranslationScope(
                child: GameView(runSeed: 901, restoredRun: restoredRun),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(FxAmbient.controller.mood, FxAmbientMood.boss);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });
}
