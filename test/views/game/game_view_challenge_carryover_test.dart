import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:rummipoker/logic/rummi_poker_grid/hand_rank.dart';
import 'package:rummipoker/logic/rummi_poker_grid/jester_meta.dart';
import 'package:rummipoker/logic/rummi_poker_grid/models/poker_deck.dart';
import 'package:rummipoker/logic/rummi_poker_grid/models/tile.dart';
import 'package:rummipoker/logic/rummi_poker_grid/rummi_blind_state.dart';
import 'package:rummipoker/logic/rummi_poker_grid/rummi_hand_growth.dart';
import 'package:rummipoker/logic/rummi_poker_grid/rummi_poker_grid_session.dart';
import 'package:rummipoker/providers/features/rummi_poker_grid/game_session_notifier.dart';
import 'package:rummipoker/resources/jester_translation_scope.dart';
import 'package:rummipoker/services/active_run_save_service.dart';
import 'package:rummipoker/services/game_settings.dart';
import 'package:rummipoker/services/new_run_setup.dart';
import 'package:rummipoker/services/run_unlock_state_service.dart';
import 'package:rummipoker/services/tutorial_state_service.dart';
import 'package:rummipoker/utils/storage_helper.dart';
import 'package:rummipoker/views/game_view.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    StorageHelper.resetForTest();
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await StorageHelper.init();
    await TutorialStateService.markBattleIntroSeen();
    GameSettings.bgmMuted = true;
    GameSettings.sfxMuted = true;
  });

  testWidgets('표준 완료 계승 데이터가 다음 challenge 새 런에 반영된다', (tester) async {
    final runProgress = RummiRunProgress()
      ..stageIndex = 8
      ..runClaimId = 'challenge-carryover-integration'
      ..applyChallengeCarryover(
        playedHandCounts: const {RummiHandRank.flush: 6},
        handGrowthStates: const {
          RummiHandRank.flush: RummiHandGrowthState(
            level: 4,
            progress: 2,
            requiredProgress: 5,
          ),
        },
        addedDeckTiles: const [Tile(id: 901, color: TileColor.red, number: 7)],
      );
    final session = RummiPokerGridSession(
      runSeed: 901,
      blind: RummiBlindState(
        targetScore: 100,
        boardDiscardsRemaining: 4,
        handDiscardsRemaining: 2,
      ),
      deck: PokerDeck.fromSnapshot(const []),
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
    final router = GoRouter(
      initialLocation: '/game',
      routes: [
        GoRoute(
          path: '/game',
          builder: (context, state) => JesterTranslationScope(
            child: GameView(
              runSeed: 901,
              restoredRun: restoredRun,
              debugCompleteRunOnLoad: true,
            ),
          ),
        ),
        GoRoute(path: '/', builder: (context, state) => const SizedBox()),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: const [Locale('ko'), Locale('en')],
        path: 'assets/translations',
        fallbackLocale: const Locale('ko'),
        startLocale: const Locale('ko'),
        saveLocale: false,
        child: ProviderScope(
          child: Builder(
            builder: (context) => MaterialApp.router(
              routerConfig: router,
              locale: context.locale,
              supportedLocales: context.supportedLocales,
              localizationsDelegates: context.localizationDelegates,
            ),
          ),
        ),
      ),
    );
    for (var i = 0; i < 50 && find.byType(GameView).evaluate().isEmpty; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.byType(GameView), findsOneWidget);
    for (
      var i = 0;
      i < 100 && RunUnlockStateService.loadSync().challengeCarryover == null;
      i++
    ) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    final carryover = (await RunUnlockStateService.load()).challengeCarryover;
    final challengeRuntime = buildInitialRunRuntime(
      GameSessionArgs(
        runSeed: 902,
        difficulty: NewRunDifficulty.challenge,
        challengeCarryover: carryover,
      ),
    );

    expect(
      challengeRuntime.runProgress
          .snapshotHandGrowthStates()[RummiHandRank.flush]
          ?.level,
      4,
    );
    expect(
      challengeRuntime.runProgress
          .snapshotPlayedHandCounts()[RummiHandRank.flush],
      6,
    );
    expect(challengeRuntime.runProgress.addedDeckTiles.single.number, 7);
    expect(challengeRuntime.session.deck.remaining, kBasePokerTileCount + 1);
  });
}
