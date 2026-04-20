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
import 'package:rummipoker/utils/storage_helper.dart';
import 'package:rummipoker/views/game_view.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    StorageHelper.resetForTest();
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await StorageHelper.init();
    GameSettings.bgmMuted = true;
    GameSettings.sfxMuted = true;
  });

  testWidgets('stage clear settlement sheet와 game over dialog가 함께 뜨지 않는다', (
    tester,
  ) async {
    final previousOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      final exceptionText = details.exceptionAsString();
      if (exceptionText.contains('A RenderFlex overflowed by 16 pixels')) {
        return;
      }
      previousOnError?.call(details);
    };
    tester.view.physicalSize = const Size(1280, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      FlutterError.onError = previousOnError;
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final session = RummiPokerGridSession(
      runSeed: 900,
      blind: RummiBlindState(
        targetScore: 40,
        boardDiscardsRemaining: 4,
        handDiscardsRemaining: 2,
      ),
      deck: PokerDeck.fromSnapshot(const []),
    );
    final runProgress = RummiRunProgress()
      ..stageIndex = 4
      ..currentStationBlindTierIndex = 0
      ..gold = 159;

    session.board.setCell(
      0,
      0,
      const Tile(id: 1, color: TileColor.red, number: 1),
    );
    session.board.setCell(
      0,
      1,
      const Tile(id: 2, color: TileColor.blue, number: 2),
    );
    session.board.setCell(
      0,
      2,
      const Tile(id: 3, color: TileColor.yellow, number: 3),
    );
    session.board.setCell(
      0,
      3,
      const Tile(id: 4, color: TileColor.black, number: 4),
    );
    session.board.setCell(
      0,
      4,
      const Tile(id: 5, color: TileColor.red, number: 5),
    );

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
                  child: GameView(runSeed: 900, restoredRun: restoredRun),
                ),
              ),
            );
          },
        ),
      ),
    );

    await tester.pump();
    await tester.tap(find.text('확정'));
    await tester.pump();
    for (var i = 0; i < 30; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }
    await tester.pumpAndSettle();

    expect(find.text('정산 완료'), findsOneWidget);
    expect(find.text('게임결과'), findsNothing);
    expect(find.text('Market으로'), findsOneWidget);
  });
}
