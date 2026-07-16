import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rummipoker/app_config.dart';
import 'package:rummipoker/logic/rummi_poker_grid/jester_meta.dart';
import 'package:rummipoker/logic/rummi_poker_grid/rummi_ruleset.dart';
import 'package:rummipoker/logic/rummi_poker_grid/rummi_poker_grid_session.dart';
import 'package:rummipoker/resources/asset_paths.dart';
import 'package:rummipoker/resources/sound_manager.dart';
import 'package:rummipoker/services/active_run_save_service.dart';
import 'package:rummipoker/services/blind_selection_setup.dart';
import 'package:rummipoker/services/game_analytics_service.dart';
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
    GameAnalyticsService.debugResetForTest();
  });

  tearDown(() {
    SoundManager.debugResetForTest();
    GameAnalyticsService.debugResetForTest();
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

    final modifier = BlindSelectionSetup.resolveSpec(
      tier: BlindTier.boss,
      stationIndex: 1,
      difficulty: NewRunDifficulty.standard,
      runSeed: 77,
      ruleset: RummiRuleset.currentDefaults,
    ).bossModifier!;
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

  testWidgets('selectable blind logs station select analytics event', (
    tester,
  ) async {
    final analyticsEvents = <_CapturedEvent>[];
    GameAnalyticsService.debugSetInstanceForTest(
      GameAnalyticsService(
        sink: (name, parameters) async {
          analyticsEvents.add(_CapturedEvent(name, parameters));
        },
      ),
    );
    final router = GoRouter(
      initialLocation: RoutePaths.blindSelect,
      routes: [
        GoRoute(
          path: RoutePaths.blindSelect,
          builder: (context, state) => const BlindSelectView(
            runSeed: 77,
            difficulty: NewRunDifficulty.standard,
          ),
        ),
        GoRoute(
          path: RoutePaths.game,
          builder: (context, state) => const SizedBox(key: ValueKey('game')),
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pump();

    await tester.tap(find.byIcon(Icons.play_arrow_rounded).first);
    await tester.pumpAndSettle();

    final stationSelectEvents = analyticsEvents
        .where((event) => event.name == 'station_select')
        .toList();
    expect(stationSelectEvents, hasLength(1));
    expect(stationSelectEvents.single.parameters['seed_mode'], 'new');
    expect(stationSelectEvents.single.parameters['seed_bucket'], 77);
    expect(stationSelectEvents.single.parameters['difficulty'], 'standard');
    expect(stationSelectEvents.single.parameters['modifier'], 'basic');
    expect(stationSelectEvents.single.parameters['station_index'], 1);
    expect(stationSelectEvents.single.parameters['blind_tier'], 'small');
    expect(stationSelectEvents.single.parameters['target_score'], isA<int>());
    expect(find.byKey(const ValueKey('game')), findsOneWidget);
  });

  testWidgets('locked blind does not log station select analytics event', (
    tester,
  ) async {
    final analyticsEvents = <_CapturedEvent>[];
    GameAnalyticsService.debugSetInstanceForTest(
      GameAnalyticsService(
        sink: (name, parameters) async {
          analyticsEvents.add(_CapturedEvent(name, parameters));
        },
      ),
    );
    final router = GoRouter(
      initialLocation: RoutePaths.blindSelect,
      routes: [
        GoRoute(
          path: RoutePaths.blindSelect,
          builder: (context, state) => const BlindSelectView(
            runSeed: 77,
            difficulty: NewRunDifficulty.standard,
          ),
        ),
        GoRoute(
          path: RoutePaths.game,
          builder: (context, state) => const SizedBox(key: ValueKey('game')),
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pump();

    await tester.tap(find.byIcon(Icons.lock_rounded).first);
    await tester.pumpAndSettle();

    expect(
      analyticsEvents.where((event) => event.name == 'station_select'),
      isEmpty,
    );
    expect(
      router.routerDelegate.currentConfiguration.uri.path,
      RoutePaths.blindSelect,
    );
  });
}

class _CapturedEvent {
  const _CapturedEvent(this.name, this.parameters);

  final String name;
  final Map<String, Object> parameters;
}
