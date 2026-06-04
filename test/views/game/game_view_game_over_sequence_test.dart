import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:rummipoker/app_config.dart';
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
    await StorageHelper.write(StorageKeys.tutorialBattleIntroSeen, true);
    GameSettings.bgmMuted = true;
    GameSettings.sfxMuted = true;
  });

  testWidgets('game over는 빨간 fade 후 dialog를 연다', (tester) async {
    tester.view.physicalSize = const Size(1280, 720);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final session = RummiPokerGridSession(
      runSeed: 903,
      blind: RummiBlindState(
        targetScore: 240,
        boardDiscardsRemaining: 4,
        handDiscardsRemaining: 1,
      ),
      deck: PokerDeck.fromSnapshot(const []),
    );
    session.hand.add(const Tile(id: 903, color: TileColor.red, number: 7));
    final runProgress = RummiRunProgress()
      ..stageIndex = 1
      ..currentStationBlindTierIndex = 0
      ..gold = 0;
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
                  child: GameView(runSeed: 903, restoredRun: restoredRun),
                ),
              ),
            );
          },
        ),
      ),
    );

    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('settled-R7#903')));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.byTooltip('손패 버림'));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byKey(const ValueKey('game-over-fade-veil')), findsOneWidget);
    expect(find.text('이번 런 정산'), findsNothing);

    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('game-over-fade-veil')), findsOneWidget);
    expect(find.text('이번 런 정산'), findsOneWidget);
    expect(find.text('현재 전투 재시작'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });
}
