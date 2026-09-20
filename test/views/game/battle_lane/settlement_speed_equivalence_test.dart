import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:rummipoker/logic/rummi_poker_grid/jester_meta.dart';
import 'package:rummipoker/logic/rummi_poker_grid/models/board.dart';
import 'package:rummipoker/logic/rummi_poker_grid/models/poker_deck.dart';
import 'package:rummipoker/logic/rummi_poker_grid/models/tile.dart';
import 'package:rummipoker/logic/rummi_poker_grid/rummi_blind_state.dart';
import 'package:rummipoker/logic/rummi_poker_grid/rummi_poker_grid_session.dart';
import 'package:rummipoker/resources/jester_translation_scope.dart';
import 'package:rummipoker/resources/asset_paths.dart';
import 'package:rummipoker/resources/sound_manager.dart';
import 'package:rummipoker/services/active_run_save_service.dart';
import 'package:rummipoker/services/game_analytics_service.dart';
import 'package:rummipoker/services/game_settings.dart';
import 'package:rummipoker/services/new_run_setup.dart';
import 'package:rummipoker/services/tutorial_state_service.dart';
import 'package:rummipoker/utils/storage_helper.dart';
import 'package:rummipoker/views/game_view.dart';
import 'package:rummipoker/widgets/fx/motion_policy.dart';
import '../../../support/test_translations.dart';

/// 정산을 1x, 즉시, 중간 탭 스킵, 동작 줄이기로 돌려도 저장되는 최종 상태가 같아야 한다.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() {
    SoundManager.debugResetForTest();
    MotionPolicy.debugReduceMotionOverride = null;
    GameAnalyticsService.debugResetForTest();
  });

  Future<String> runConfirm(
    WidgetTester tester, {
    required SettlementSpeed speed,
    bool skipMidway = false,
    bool reduceMotion = false,
    List<Map<String, Object?>>? scoreEvents,
  }) async {
    StorageHelper.resetForTest();
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await StorageHelper.init();
    await TutorialStateService.markBattleIntroSeen();
    GameSettings.bgmMuted = true;
    GameSettings.sfxMuted = false;
    final sounds = <String>[];
    SoundManager.debugSfxSink = (path, _, _) => sounds.add(path);
    GameSettings.settlementSpeed = speed;
    MotionPolicy.debugReduceMotionOverride = reduceMotion;
    GameAnalyticsService.debugSetInstanceForTest(
      GameAnalyticsService(
        sink: (name, parameters) async {
          if (name == 'score_confirm') scoreEvents?.add(parameters);
        },
      ),
    );
    tester.view.physicalSize = const Size(1280, 720);
    tester.view.devicePixelRatio = 1.0;

    await tester.pumpWidget(_app(_crossingLinesRun()));
    await tester.pump();
    for (var i = 0; i < 10 && find.byTooltip('확정').evaluate().isEmpty; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await tester.tap(find.byTooltip('확정'));
    await tester.pump(const Duration(milliseconds: 60));
    if (skipMidway) {
      await tester.pump(const Duration(milliseconds: 300));
      expect(
        find.byKey(const ValueKey('settlement-skip-area')),
        findsOneWidget,
      );
      final beforeClicks = sounds
          .where((s) => s == AssetPaths.sfxBtnSnd)
          .length;
      await tester.tap(find.byKey(const ValueKey('settlement-skip-area')));
      expect(
        sounds.where((s) => s == AssetPaths.sfxBtnSnd).length,
        beforeClicks + 1,
      );
    }
    for (
      var i = 0;
      i < 300 &&
          find
              .byKey(const ValueKey('settlement-skip-area'))
              .evaluate()
              .isNotEmpty;
      i++
    ) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.byKey(const ValueKey('settlement-skip-area')), findsNothing);
    await tester.pump(const Duration(seconds: 2));

    expect(sounds, isNot(contains(AssetPaths.sfxClear)));
    final saved = await ActiveRunSaveService.loadActiveRun();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
    expect(saved, isNotNull);
    final session = saved!.session;
    final cells = [
      for (var r = 0; r < kBoardSize; r++)
        for (var c = 0; c < kBoardSize; c++)
          session.board.cellAt(r, c)?.id ?? '-',
    ].join(',');
    return [
      'score=${session.blind.scoreTowardBlind}',
      'board=$cells',
      'gold=${saved.runProgress.gold}',
      'deck=${session.deck.remaining}',
      'hand=${session.hand.map((t) => t.id).join(',')}',
      'discards=${session.blind.boardDiscardsRemaining}/${session.blind.handDiscardsRemaining}',
    ].join(' | ');
  }

  testWidgets('정산 속도·스킵·동작 줄이기와 무관하게 최종 상태가 같다', (tester) async {
    final events = <Map<String, Object?>>[];
    final normal = await runConfirm(
      tester,
      speed: SettlementSpeed.x1,
      scoreEvents: events,
    );
    expect(events.single['line_count'], 2, reason: '교차 두 줄 확정');
    expect(normal, contains('score='));
    expect(normal, isNot(contains('score=0 ')));

    final instant = await runConfirm(tester, speed: SettlementSpeed.instant);
    final skipped = await runConfirm(
      tester,
      speed: SettlementSpeed.x1,
      skipMidway: true,
    );
    final reduced = await runConfirm(
      tester,
      speed: SettlementSpeed.x4,
      reduceMotion: true,
    );
    expect(instant, normal);
    expect(skipped, normal);
    expect(reduced, normal);
  });
}

Widget _app(ActiveRunRuntimeState restoredRun) {
  return EasyLocalization(
    assetLoader: const TestTranslationAssetLoader(),
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
              child: GameView(runSeed: 903, restoredRun: restoredRun),
            ),
          ),
        );
      },
    ),
  );
}

/// 0행 스트레이트와 0열 같은 색 줄이 (0,0)에서 교차한다. 목표가 커서 클리어하지 않는다.
ActiveRunRuntimeState _crossingLinesRun() {
  final session = RummiPokerGridSession(
    runSeed: 903,
    blind: RummiBlindState(
      targetScore: 100000,
      boardDiscardsRemaining: 4,
      handDiscardsRemaining: 2,
    ),
    deck: PokerDeck.fromSnapshot(const [
      Tile(id: 90, color: TileColor.blue, number: 9),
      Tile(id: 91, color: TileColor.black, number: 11),
    ]),
  );
  final runProgress = RummiRunProgress()
    ..stageIndex = 1
    ..currentStationBlindTierIndex = 0
    ..gold = 12;
  const row = [
    Tile(id: 1, color: TileColor.red, number: 1),
    Tile(id: 2, color: TileColor.blue, number: 2),
    Tile(id: 3, color: TileColor.yellow, number: 3),
    Tile(id: 4, color: TileColor.black, number: 4),
    Tile(id: 5, color: TileColor.red, number: 5),
  ];
  for (var c = 0; c < 5; c++) {
    session.board.setCell(0, c, row[c]);
  }
  const column = [
    Tile(id: 11, color: TileColor.red, number: 8),
    Tile(id: 12, color: TileColor.red, number: 10),
    Tile(id: 13, color: TileColor.red, number: 12),
    Tile(id: 14, color: TileColor.red, number: 13),
  ];
  for (var r = 1; r < 5; r++) {
    session.board.setCell(r, 0, column[r - 1]);
  }
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
