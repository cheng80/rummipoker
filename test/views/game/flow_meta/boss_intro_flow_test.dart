import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:rummipoker/app_config.dart';
import 'package:rummipoker/logic/rummi_poker_grid/boss_modifier.dart';
import 'package:rummipoker/logic/rummi_poker_grid/jester_meta.dart';
import 'package:rummipoker/logic/rummi_poker_grid/models/poker_deck.dart';
import 'package:rummipoker/logic/rummi_poker_grid/models/tile.dart';
import 'package:rummipoker/logic/rummi_poker_grid/rummi_blind_state.dart';
import 'package:rummipoker/logic/rummi_poker_grid/rummi_poker_grid_session.dart';
import 'package:rummipoker/resources/asset_paths.dart';
import 'package:rummipoker/resources/jester_translation_scope.dart';
import 'package:rummipoker/resources/sound_manager.dart';
import 'package:rummipoker/services/active_run_save_service.dart';
import 'package:rummipoker/services/game_analytics_service.dart';
import 'package:rummipoker/services/game_settings.dart';
import 'package:rummipoker/services/new_run_setup.dart';
import 'package:rummipoker/utils/storage_helper.dart';
import 'package:rummipoker/views/game/game_presentation_timings.dart';
import 'package:rummipoker/views/game/widgets/game_boss_intro_widgets.dart';
import 'package:rummipoker/views/game_view.dart';
import 'package:rummipoker/widgets/fx/motion_policy.dart';
import '../../../support/test_translations.dart';

ActiveRunRuntimeState _bossRun() {
  final session = RummiPokerGridSession(
    runSeed: 911,
    blind: RummiBlindState(
      targetScore: 285,
      boardDiscardsRemaining: 3,
      handDiscardsRemaining: 1,
      bossModifier: RummiBossModifier.blockRightColumn,
    ),
    deck: PokerDeck.fromSnapshot(const []),
  );
  session.hand.add(const Tile(id: 911, color: TileColor.red, number: 7));
  final runProgress = RummiRunProgress()
    ..stageIndex = 1
    ..currentStationBlindTierIndex = 1;
  return ActiveRunRuntimeState(
    activeScene: ActiveRunScene.battle,
    difficulty: NewRunDifficulty.standard,
    session: session,
    runProgress: runProgress,
    stageStartSnapshot: ActiveRunStageSnapshot(
      session: session.copySnapshot(),
      runProgress: runProgress.copySnapshot(),
    ),
  );
}

Widget _app(Widget home) {
  return EasyLocalization(
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
          home: JesterTranslationScope(child: home),
        ),
      ),
    ),
  );
}

bool _veilHidden(WidgetTester tester) =>
    tester.widget<GameBossMarkVeil>(find.byType(GameBossMarkVeil)).hidden;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final sfx = <(String, double)>[];
  final events = <String>[];
  bool tutorialStarted() => events.contains('tutorial_start');

  setUp(() async {
    StorageHelper.resetForTest();
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await StorageHelper.init();
    GameSettings.bgmMuted = true;
    GameSettings.sfxMuted = false;
    sfx.clear();
    SoundManager.debugSfxSink = (path, _, rate) => sfx.add((path, rate));
    events.clear();
    GameAnalyticsService.debugSetInstanceForTest(
      GameAnalyticsService(sink: (name, _) async => events.add(name)),
    );
  });

  tearDown(() {
    SoundManager.debugSfxSink = null;
    MotionPolicy.debugReduceMotionOverride = null;
    GameAnalyticsService.debugResetForTest();
  });

  testWidgets('Boss 인트로는 탭해야 닫히고, 제약 표시가 보드로 날아간 뒤 튜토리얼이 시작한다', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    // --- 1) 일반 연출: 탭 전에는 닫히지 않고, 튜토리얼도 기다린다.
    await tester.pumpWidget(
      _app(GameView(runSeed: 911, restoredRun: _bossRun())),
    );
    await tester.pump();
    await tester.pump();

    expect(sfx.where((e) => e.$1 == AssetPaths.sfxStart), isEmpty);
    expect(find.byType(GameBossIntroCard), findsOneWidget);
    expect(_veilHidden(tester), isTrue);
    expect(sfx, isEmpty, reason: 'boss intro is silent');

    for (var i = 0; i < 15; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
    expect(
      find.byType(GameBossIntroCard),
      findsOneWidget,
      reason: '자동으로 닫지 않는다',
    );
    expect(tutorialStarted(), isFalse);

    await tester.tap(find.byKey(const ValueKey('boss-intro-confirm')));
    await tester.pump();
    await tester.pump();

    expect(
      find.byKey(const ValueKey('boss-mark-flight-layer')),
      findsOneWidget,
    );
    expect(_veilHidden(tester), isTrue, reason: '비행 중에는 아직 숨긴다');
    expect(tutorialStarted(), isFalse);

    await tester.pump(
      GamePresentationTimings.bossMarkFlight +
          const Duration(milliseconds: 400),
    );
    expect(find.byKey(const ValueKey('boss-mark-flight-layer')), findsNothing);
    expect(_veilHidden(tester), isFalse, reason: '착지하면 보드 도장이 찍힌다');
    expect(
      sfx.where((e) => e.$1 == AssetPaths.sfxFail),
      isNotEmpty,
      reason: '착지 penalty cue',
    );

    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
    expect(tutorialStarted(), isTrue, reason: '배너 뒤 튜토리얼');

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));

    // --- 2) 동작 줄이기: 같은 탭으로 닫히고 비행 없이 바로 안정된다.
    MotionPolicy.debugReduceMotionOverride = true;
    await StorageHelper.write(StorageKeys.tutorialBattleIntroSeen, true);
    await tester.pumpWidget(
      _app(GameView(runSeed: 912, restoredRun: _bossRun())),
    );
    await tester.pump();
    await tester.pump();

    expect(find.byType(GameBossIntroCard), findsOneWidget);
    expect(_veilHidden(tester), isFalse, reason: '동작 줄이기에서는 숨기지 않는다');
    await tester.tap(find.byKey(const ValueKey('boss-intro-confirm')));
    await tester.pump();
    await tester.pump();
    expect(find.byType(GameBossIntroCard), findsNothing);
    expect(find.byKey(const ValueKey('boss-mark-flight-layer')), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));
    MotionPolicy.debugReduceMotionOverride = null;

    // --- 3) 자동 흐름(auto_*): 봇이 쓰는 '전투 시작' 버튼으로 넘어가고 비행이 없다.
    await tester.pumpWidget(
      _app(
        GameView(
          runSeed: 913,
          restoredRun: _bossRun(),
          autoAdvanceMarketOnLoad: true,
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    expect(_veilHidden(tester), isFalse);
    await tester.tap(find.text('전투 시작'));
    await tester.pump();
    await tester.pump();
    expect(find.byType(GameBossIntroCard), findsNothing);
    expect(find.byKey(const ValueKey('boss-mark-flight-layer')), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));
  });
}
