import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:rummipoker/app_config.dart';
import 'package:rummipoker/logic/rummi_poker_grid/jester_meta.dart';
import 'package:rummipoker/logic/rummi_poker_grid/rummi_poker_grid_session.dart';
import 'package:rummipoker/resources/sound_manager.dart';
import 'package:rummipoker/services/active_run_save_service.dart';
import 'package:rummipoker/services/game_settings.dart';
import 'package:rummipoker/services/new_run_setup.dart';
import 'package:rummipoker/utils/storage_helper.dart';
import 'package:rummipoker/views/blind_select_view.dart';
import 'package:rummipoker/views/game/game_presentation_timings.dart';
import 'package:rummipoker/widgets/fx/motion_policy.dart';

ActiveRunRuntimeState _runtime({required int station, required int cleared}) {
  final session = RummiPokerGridSession(runSeed: 77);
  final runProgress = RummiRunProgress()
    ..stageIndex = station
    ..currentStationBlindTierIndex = cleared;
  return ActiveRunRuntimeState(
    activeScene: ActiveRunScene.blindSelect,
    difficulty: NewRunDifficulty.standard,
    session: session,
    runProgress: runProgress,
    stageStartSnapshot: ActiveRunStageSnapshot(
      session: session.copySnapshot(),
      runProgress: runProgress.copySnapshot(),
    ),
  );
}

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
    MotionPolicy.debugReduceMotionOverride = null;
    SoundManager.debugResetForTest();
  });

  Future<void> pumpView(WidgetTester tester, Widget view) async {
    tester.view.physicalSize = const Size(360, 740);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(MaterialApp(home: view));
  }

  testWidgets('런 진행 띠는 Station 수와 현재 위치를 그리고, 새 Station이면 한 칸 나아간다', (
    tester,
  ) async {
    await pumpView(
      tester,
      BlindSelectView(
        runSeed: 77,
        difficulty: NewRunDifficulty.standard,
        restoredRun: _runtime(station: 3, cleared: -1),
      ),
    );
    await tester.pump();

    for (var s = 1; s <= 8; s++) {
      expect(find.byKey(ValueKey('run-progress-s$s')), findsOneWidget);
    }
    expect(find.byKey(const ValueKey('run-progress-s9')), findsNothing);
    expect(
      find.byIcon(Icons.check_rounded),
      findsNWidgets(2),
      reason: 'S1·S2 완료',
    );

    double markerX() =>
        tester.getCenter(find.byKey(const ValueKey('run-progress-marker'))).dx;
    final s2 = tester
        .getCenter(find.byKey(const ValueKey('run-progress-s2')))
        .dx;
    final s3 = tester
        .getCenter(find.byKey(const ValueKey('run-progress-s3')))
        .dx;
    expect((markerX() - s2).abs(), lessThan(4), reason: '이전 칸에서 출발');
    await tester.pumpAndSettle();
    expect((markerX() - s3).abs(), lessThan(1), reason: '현재 칸에 도착');
    expect(tester.takeException(), isNull);
  });

  testWidgets('무한 구간은 모든 칸 완료와 무한 표시를 보이고 글자가 넘치지 않는다', (tester) async {
    await pumpView(
      tester,
      BlindSelectView(
        runSeed: 77,
        difficulty: NewRunDifficulty.standard,
        restoredRun: _runtime(station: 9, cleared: -1),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.check_rounded), findsNWidgets(8));
    expect(find.byKey(const ValueKey('run-progress-endless')), findsOneWidget);
    expect(find.byKey(const ValueKey('run-progress-marker')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('방금 깬 tier는 OPEN에서 CLEAR로, 다음 tier는 LOCKED에서 OPEN으로 바뀐다', (
    tester,
  ) async {
    await pumpView(
      tester,
      BlindSelectView(
        runSeed: 77,
        difficulty: NewRunDifficulty.standard,
        restoredRun: _runtime(station: 2, cleared: 0),
      ),
    );
    await tester.pump();
    expect(find.byKey(const ValueKey('blind-badge-CLEAR')), findsNothing);
    expect(find.byKey(const ValueKey('blind-badge-OPEN')), findsOneWidget);
    expect(find.byKey(const ValueKey('blind-badge-LOCKED')), findsNWidgets(2));

    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('blind-badge-CLEAR')), findsOneWidget);
    expect(find.byKey(const ValueKey('blind-badge-OPEN')), findsOneWidget);
    expect(find.byKey(const ValueKey('blind-badge-LOCKED')), findsOneWidget);
  });

  testWidgets('play는 선택 강조 뒤 300ms 안에 넘어가고, 동작 줄이기에서는 바로 넘어간다', (tester) async {
    expect(
      GamePresentationTimings.blindPlayCommit,
      lessThanOrEqualTo(const Duration(milliseconds: 300)),
    );
    for (final reduce in [false, true]) {
      MotionPolicy.debugReduceMotionOverride = reduce;
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
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.play_arrow_rounded).first);
      await tester.pump();
      if (!reduce) {
        expect(
          find.byKey(const ValueKey('game')),
          findsNothing,
          reason: '강조 중',
        );
        await tester.pump(GamePresentationTimings.blindPlayCommit);
      }
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('game')),
        findsOneWidget,
        reason: 'reduce=$reduce',
      );
      await tester.pumpWidget(const SizedBox.shrink());
      router.dispose();
    }
  });
}
