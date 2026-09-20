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
import 'package:rummipoker/resources/jester_translation_scope.dart';
import 'package:rummipoker/services/active_run_save_service.dart';
import 'package:rummipoker/services/game_settings.dart';
import 'package:rummipoker/services/new_run_setup.dart';
import 'package:rummipoker/services/tutorial_state_service.dart';
import 'package:rummipoker/utils/storage_helper.dart';
import 'package:rummipoker/views/game_view.dart';

/// 정산 내내 `+점수` 표시가 방금 채점된 0행 칸과 겹치지 않아야 한다(finalScore 포함).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('정산 점수 표시는 채점 중인 줄과 겹치지 않는다', (tester) async {
    StorageHelper.resetForTest();
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await StorageHelper.init();
    await TutorialStateService.markBattleIntroSeen();
    GameSettings.bgmMuted = true;
    GameSettings.sfxMuted = true;
    tester.view.physicalSize = const Size(468, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(_app(_rowZeroRun()));
    await tester.pump();
    for (var i = 0; i < 20 && find.byTooltip('확정').evaluate().isEmpty; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await tester.pump(const Duration(seconds: 2));

    Rect rowZero() => [
      for (var c = 0; c < 5; c++)
        tester.getRect(find.byKey(ValueKey('board-cell-0-$c'))),
    ].reduce((a, b) => a.expandToInclude(b));
    final row = rowZero();

    await tester.tap(find.byTooltip('확정'));
    var sawGrade = false;
    var checkedFrames = 0;
    for (
      var i = 0;
      i < 120 &&
          (i < 3 ||
              find
                  .byKey(const ValueKey('settlement-skip-area'))
                  .evaluate()
                  .isNotEmpty);
      i++
    ) {
      await tester.pump(const Duration(milliseconds: 50));
      if (find
          .byWidgetPredicate(
            (w) =>
                w.key is ValueKey<String> &&
                (w.key! as ValueKey<String>).value.startsWith(
                  'board-score-grade-',
                ),
          )
          .evaluate()
          .isNotEmpty) {
        sawGrade = true;
      }
      for (final element
          in find
              .byWidgetPredicate(
                (w) => w is Text && (w.data?.startsWith('+') ?? false),
              )
              .evaluate()) {
        final rect = tester.getRect(find.byWidget(element.widget).first);
        checkedFrames++;
        expect(
          rect.overlaps(row.deflate(2)),
          isFalse,
          reason:
              '"${(element.widget as Text).data}" $rect overlaps row 0 $row',
        );
      }
    }
    expect(sawGrade, isTrue, reason: 'finalScore 등급 callout을 거쳐야 한다');
    expect(checkedFrames, greaterThan(0));

    await tester.pump(const Duration(seconds: 5));
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });
}

Widget _app(ActiveRunRuntimeState restoredRun) {
  return EasyLocalization(
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
            child: GameView(runSeed: 905, restoredRun: restoredRun),
          ),
        ),
      ),
    ),
  );
}

ActiveRunRuntimeState _rowZeroRun() {
  final session = RummiPokerGridSession(
    runSeed: 905,
    blind: RummiBlindState(
      targetScore: 300,
      boardDiscardsRemaining: 4,
      handDiscardsRemaining: 2,
    ),
    deck: PokerDeck.fromSnapshot(const [
      Tile(id: 90, color: TileColor.blue, number: 9),
    ]),
  );
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
  final runProgress = RummiRunProgress()
    ..stageIndex = 2
    ..currentStationBlindTierIndex = 0
    ..gold = 10;
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
