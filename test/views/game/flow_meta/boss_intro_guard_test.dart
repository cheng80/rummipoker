import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:rummipoker/logic/rummi_poker_grid/boss_modifier.dart';
import 'package:rummipoker/logic/rummi_poker_grid/jester_meta.dart';
import 'package:rummipoker/logic/rummi_poker_grid/models/poker_deck.dart';
import 'package:rummipoker/logic/rummi_poker_grid/models/tile.dart';
import 'package:rummipoker/logic/rummi_poker_grid/rummi_blind_state.dart';
import 'package:rummipoker/logic/rummi_poker_grid/rummi_poker_grid_session.dart';
import 'package:rummipoker/resources/jester_translation_scope.dart';
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

ActiveRunRuntimeState _bossRun({bool marks = true}) {
  final session = RummiPokerGridSession(
    runSeed: 911,
    blind: RummiBlindState(
      targetScore: 285,
      boardDiscardsRemaining: 3,
      handDiscardsRemaining: 1,
      bossModifier: marks
          ? RummiBossModifier.blockRightColumn
          : RummiBossModifier.allScoreDampener,
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

bool _veilHiddenOf(WidgetTester tester) =>
    tester.widget<GameBossMarkVeil>(find.byType(GameBossMarkVeil)).hidden;

/// 비행이 끝까지 가지 못하는 상황(앱이 멈춰 티커가 죽은 상태)을 만든다.
Widget _frozen(Widget child) => TickerMode(enabled: false, child: child);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final events = <String>[];

  setUp(() async {
    StorageHelper.resetForTest();
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await StorageHelper.init();
    GameSettings.bgmMuted = true;
    GameSettings.sfxMuted = true;
    events.clear();
    GameAnalyticsService.debugSetInstanceForTest(
      GameAnalyticsService(sink: (name, _) async => events.add(name)),
    );
  });

  tearDown(() {
    MotionPolicy.debugReduceMotionOverride = null;
    GameAnalyticsService.debugResetForTest();
  });

  testWidgets('비행이 끝까지 가지 못해도 상한 안에 제약 표시가 드러나고 튜토리얼이 시작한다', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final bound =
        GameBossMarkFlightLayer.totalDuration(5) +
        GamePresentationTimings.bossMarkFlightGuard;

    // --- 1) 보드에 금지 칸이 있는 Boss. 비행이 멈춰도 상한 뒤 표시가 드러난다.
    await tester.pumpWidget(
      _frozen(_app(GameView(runSeed: 921, restoredRun: _bossRun()))),
    );
    await tester.pump();
    await tester.pump();
    expect(find.byType(GameBossIntroCard), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('boss-intro-confirm')));
    await tester.pump();
    await tester.pump();
    expect(_veilHiddenOf(tester), isTrue, reason: '비행을 시작했다');
    expect(events.contains('tutorial_start'), isFalse);

    await tester.pump(bound);
    await tester.pump();
    expect(_veilHiddenOf(tester), isFalse, reason: '상한이 지나면 표시를 드러낸다');
    expect(find.byKey(const ValueKey('boss-mark-flight-layer')), findsNothing);

    await tester.pumpWidget(
      _app(GameView(runSeed: 921, restoredRun: _bossRun())),
    );
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));

    // --- 2) 보드·손패에 표시가 하나도 없는 Boss도 상한 안에 끝난다.
    events.clear();
    await tester.pumpWidget(
      _frozen(
        _app(GameView(runSeed: 922, restoredRun: _bossRun(marks: false))),
      ),
    );
    await tester.pump();
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('boss-intro-confirm')));
    await tester.pump();
    await tester.pump();
    await tester.pump(bound);
    await tester.pump();
    expect(_veilHiddenOf(tester), isFalse);
    expect(find.byKey(const ValueKey('boss-mark-flight-layer')), findsNothing);

    // 티커가 살아나면 자동 튜토리얼이 이어서 시작한다.
    await tester.pumpWidget(
      _app(GameView(runSeed: 922, restoredRun: _bossRun(marks: false))),
    );
    for (var i = 0; i < 15; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));
  });
}
