import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rummipoker/logic/rummi_poker_grid/boss_modifier.dart';
import 'package:rummipoker/logic/rummi_poker_grid/jester_meta.dart';
import 'package:rummipoker/logic/rummi_poker_grid/rummi_poker_grid_session.dart';
import 'package:rummipoker/resources/asset_paths.dart';
import 'package:rummipoker/resources/sound_manager.dart';
import 'package:rummipoker/services/active_run_save_service.dart';
import 'package:rummipoker/services/game_settings.dart';
import 'package:rummipoker/services/new_run_setup.dart';
import 'package:rummipoker/utils/storage_helper.dart';
import 'package:rummipoker/views/blind_select_view.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    StorageHelper.resetForTest();
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await StorageHelper.init();
    GameSettings.bgmMuted = true;
    GameSettings.sfxMuted = true;
    SoundManager.debugResetForTest();
  });

  tearDown(() {
    SoundManager.debugResetForTest();
  });

  testWidgets('blind select requests menu BGM on entry', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: BlindSelectView(
          runSeed: 77,
          difficulty: NewRunDifficulty.standard,
        ),
      ),
    );
    await tester.pump();
    await tester.runAsync(() async {
      await Future<void>.delayed(Duration.zero);
    });
    await tester.pump();

    expect(SoundManager.debugCurrentBgm, AssetPaths.bgmMenu);
  });

  testWidgets('boss constraint chip keeps long rule text out of card', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      const MaterialApp(
        home: BlindSelectView(
          runSeed: 77,
          difficulty: NewRunDifficulty.standard,
        ),
      ),
    );
    await tester.pump();

    const modifier = RummiBossModifier.redDampener;
    final finder = find.text(modifier.title);

    expect(finder, findsOneWidget);
    expect(find.text(modifier.ruleText), findsNothing);
    expect(find.text(modifier.markerText), findsOneWidget);

    final text = tester.widget<Text>(finder);
    expect(text.overflow, isNull);
    expect(text.softWrap, isTrue);
  });

  testWidgets('S9 이후 blind select는 무한 도전으로 표시한다', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final session = RummiPokerGridSession(runSeed: 77);
    final runProgress = RummiRunProgress()
      ..stageIndex = 9
      ..currentStationBlindTierIndex = -1;
    final runtime = ActiveRunRuntimeState(
      activeScene: ActiveRunScene.blindSelect,
      difficulty: NewRunDifficulty.challenge,
      session: session,
      runProgress: runProgress,
      stageStartSnapshot: ActiveRunStageSnapshot(
        session: session.copySnapshot(),
        runProgress: runProgress.copySnapshot(),
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: BlindSelectView(
          runSeed: 77,
          difficulty: NewRunDifficulty.challenge,
          restoredRun: runtime,
        ),
      ),
    );
    await tester.pump();

    expect(find.text('무한 도전 S9'), findsOneWidget);
    expect(find.text('무한 도전'), findsWidgets);
    expect(find.textContaining('점수가 계속 상승합니다'), findsWidgets);
    expect(find.text('DANGER'), findsWidgets);
  });
}
