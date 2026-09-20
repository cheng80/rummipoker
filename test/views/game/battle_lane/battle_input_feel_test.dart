import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:rummipoker/logic/rummi_poker_grid/jester_meta.dart';
import 'package:rummipoker/logic/rummi_poker_grid/models/poker_deck.dart';
import 'package:rummipoker/logic/rummi_poker_grid/models/tile.dart';
import 'package:rummipoker/logic/rummi_poker_grid/rummi_blind_state.dart';
import 'package:rummipoker/logic/rummi_poker_grid/rummi_poker_grid_session.dart';
import 'package:rummipoker/resources/asset_paths.dart';
import 'package:rummipoker/resources/game_haptics.dart';
import 'package:rummipoker/resources/jester_translation_scope.dart';
import 'package:rummipoker/resources/sound_manager.dart';
import 'package:rummipoker/services/active_run_save_service.dart';
import 'package:rummipoker/services/game_settings.dart';
import 'package:rummipoker/services/new_run_setup.dart';
import 'package:rummipoker/services/tutorial_state_service.dart';
import 'package:rummipoker/utils/storage_helper.dart';
import 'package:rummipoker/views/game_view.dart';
import 'package:rummipoker/widgets/fx/motion_policy.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final haptics = <HapticGrade>[];

  Future<void> reset({bool reduceMotion = false}) async {
    StorageHelper.resetForTest();
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await StorageHelper.init();
    await TutorialStateService.markBattleIntroSeen();
    GameSettings.bgmMuted = true;
    SoundManager.debugResetForTest();
    sfx.clear();
    haptics.clear();
    SoundManager.debugSfxSink = (path, volume, rate) => sfx.add(path);
    GameHaptics.debugSink = haptics.add;
    MotionPolicy.debugReduceMotionOverride = reduceMotion;
  }

  setUpAll(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await EasyLocalization.ensureInitialized();
  });

  tearDown(() {
    SoundManager.debugResetForTest();
    GameHaptics.debugSink = null;
    MotionPolicy.debugReduceMotionOverride = null;
  });

  testWidgets('전투 입력: 거절 통일·잠긴 슬롯·막힌 드로우·장전·줄 예고·자원 경고·동작 줄이기', (tester) async {
    // 점수 줄 없는 확정: 알림 문구는 그대로, 흔들림·오류음·error 햅틱.
    await reset();
    await _pumpBattle(tester, _run());
    await tester.tap(find.byTooltip('확정'));
    await tester.pump();
    expect(find.text('확정할 족보 줄이 없습니다.'), findsOneWidget);
    expect(sfx, contains(AssetPaths.sfxFail));
    expect(
      sfx,
      isNot(contains(AssetPaths.sfxTimeTic)),
      reason: '거절 때 notice 소리가 겹치면 안 된다',
    );
    expect(haptics, contains(HapticGrade.error));
    expect(find.byKey(const ValueKey('game-deny-shake-1')), findsOneWidget);
    expect(find.byKey(const ValueKey('battle-confirm-armed')), findsNothing);

    // 잠긴 Jester 슬롯 탭.
    sfx.clear();
    await tester.pump(const Duration(seconds: 3));
    await tester.tap(
      find.byKey(const ValueKey('battle-jester-slot-locked')).first,
    );
    await tester.pump();
    expect(find.text('잠긴 슬롯입니다.'), findsOneWidget);
    expect(sfx, contains(AssetPaths.sfxFail));
    await _dispose(tester);

    // 가득 찬 손패의 드로우: 막힌 버튼이어도 거절 피드백.
    await reset();
    await _pumpBattle(tester, _run(handSize: 1, handTiles: 1));
    await tester.tap(find.text('드로우'));
    await tester.pump();
    expect(find.textContaining('손패는 최대'), findsOneWidget);
    expect(sfx, contains(AssetPaths.sfxFail));
    await _dispose(tester);

    // 점수 줄이 있으면 확정 장전 + 줄 예고.
    await reset();
    await _pumpBattle(tester, _run(scoringRow: true));
    expect(find.byKey(const ValueKey('battle-confirm-armed')), findsOneWidget);
    expect(find.byKey(const ValueKey('board-line-hint')), findsOneWidget);
    await _dispose(tester);

    // 마지막 손패 버림과 덱 0은 경고 상태.
    await reset();
    await _pumpBattle(tester, _run(handDiscards: 1, deckTiles: 0));
    expect(
      find.byKey(const ValueKey('bottom-resource-warning-hand')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('bottom-resource-warning-deck')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('bottom-resource-warning-board-move')),
      findsNothing,
    );
    await _dispose(tester);

    // 동작 줄이기: 흔들림 없이 소리·문구만.
    await reset(reduceMotion: true);
    await _pumpBattle(tester, _run());
    await tester.tap(find.byTooltip('확정'));
    await tester.pump();
    expect(find.text('확정할 족보 줄이 없습니다.'), findsOneWidget);
    expect(sfx, contains(AssetPaths.sfxFail));
    expect(find.byKey(const ValueKey('game-deny-shake-1')), findsNothing);
    await _dispose(tester);
  });
}

Future<void> _pumpBattle(WidgetTester tester, ActiveRunRuntimeState run) async {
  tester.view.physicalSize = const Size(1280, 720);
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
        builder: (context) => ProviderScope(
          child: MaterialApp(
            locale: context.locale,
            supportedLocales: context.supportedLocales,
            localizationsDelegates: context.localizationDelegates,
            home: JesterTranslationScope(
              child: GameView(runSeed: 904, restoredRun: run),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  // EasyLocalization 번역 로드는 실제 비동기라 두 번째 테스트부터는 runAsync가 필요하다.
  for (var i = 0; i < 40 && find.byTooltip('확정').evaluate().isEmpty; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump(const Duration(milliseconds: 100));
  }
  expect(find.byTooltip('확정'), findsOneWidget);
  // 진입 deal이 끝나도록 기다린다.
  await tester.pump(const Duration(seconds: 2));
  sfx.clear();
}

Future<void> _dispose(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 5));
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pumpAndSettle();
}

final _sfxList = <String>[];
List<String> get sfx => _sfxList;

ActiveRunRuntimeState _run({
  bool scoringRow = false,
  int handDiscards = 2,
  int handSize = 5,
  int handTiles = 1,
  int deckTiles = 5,
}) {
  final session = RummiPokerGridSession(
    runSeed: 904,
    blind: RummiBlindState(
      targetScore: 100000,
      boardDiscardsRemaining: 4,
      handDiscardsRemaining: handDiscards,
    ),
    deck: PokerDeck.fromSnapshot([
      for (var i = 0; i < deckTiles; i++)
        Tile(id: 80 + i, color: TileColor.yellow, number: 6 + i),
    ]),
  );
  session.maxHandSize = handSize;
  for (var i = 0; i < handTiles; i++) {
    session.hand.add(Tile(id: 60 + i, color: TileColor.blue, number: 3 + i));
  }
  if (scoringRow) {
    const row = [
      Tile(id: 1, color: TileColor.red, number: 1),
      Tile(id: 2, color: TileColor.blue, number: 2),
      Tile(id: 3, color: TileColor.yellow, number: 3),
      Tile(id: 4, color: TileColor.black, number: 4),
      Tile(id: 5, color: TileColor.red, number: 5),
    ];
    for (var c = 0; c < 5; c++) {
      session.board.setCell(2, c, row[c]);
    }
  }
  final runProgress = RummiRunProgress()
    ..stageIndex = 1
    ..currentStationBlindTierIndex = 0
    ..gold = 5;
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
