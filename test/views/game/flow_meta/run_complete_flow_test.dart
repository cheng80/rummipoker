import 'dart:convert';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:rummipoker/app_config.dart';
import 'package:rummipoker/logic/rummi_poker_grid/hand_rank.dart';
import 'package:rummipoker/logic/rummi_poker_grid/jester_meta.dart';
import 'package:rummipoker/logic/rummi_poker_grid/models/poker_deck.dart';
import 'package:rummipoker/logic/rummi_poker_grid/rummi_blind_state.dart';
import 'package:rummipoker/logic/rummi_poker_grid/rummi_poker_grid_session.dart';
import 'package:rummipoker/resources/asset_paths.dart';
import 'package:rummipoker/resources/jester_translation_scope.dart';
import 'package:rummipoker/resources/sound_manager.dart';
import 'package:rummipoker/services/active_run_save_service.dart';
import 'package:rummipoker/services/game_settings.dart';
import 'package:rummipoker/services/new_run_setup.dart';
import 'package:rummipoker/services/run_unlock_state_service.dart';
import 'package:rummipoker/utils/storage_helper.dart';
import 'package:rummipoker/views/game_view.dart';
import 'package:rummipoker/widgets/fx/motion_policy.dart';
import '../../../support/test_translations.dart';

ActiveRunRuntimeState _finalRun() {
  final runProgress = RummiRunProgress()
    ..stageIndex = 8
    ..currentStationBlindTierIndex = 2
    ..runClaimId = 'flow-meta-victory'
    ..boughtJesterIds.addAll(const ['egg', 'popcorn'])
    ..recordHandRankCompletion(RummiHandRank.flush)
    ..recordHandRankCompletion(RummiHandRank.onePair);
  final session = RummiPokerGridSession(
    runSeed: 904,
    blind: RummiBlindState(
      targetScore: 100,
      boardDiscardsRemaining: 4,
      handDiscardsRemaining: 2,
    ),
    deck: PokerDeck.fromSnapshot(const []),
  );
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

Widget _routerApp(GoRouter router) {
  return EasyLocalization(
    assetLoader: const TestTranslationAssetLoader(),
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
  );
}

GoRouter _router(Widget game) => GoRouter(
  initialLocation: RoutePaths.game,
  routes: [
    GoRoute(
      path: RoutePaths.game,
      builder: (context, state) => JesterTranslationScope(child: game),
    ),
    GoRoute(
      path: RoutePaths.title,
      builder: (context, state) => const SizedBox(key: ValueKey('title-stub')),
    ),
    GoRoute(
      path: RoutePaths.newRun,
      builder: (context, state) =>
          const SizedBox(key: ValueKey('new-run-stub')),
    ),
  ],
);

Future<void> _resetStorage() async {
  StorageHelper.resetForTest();
  SharedPreferences.setMockInitialValues(<String, Object>{
    StorageKeys.tutorialBattleIntroSeen: true,
  });
  await StorageHelper.init();
  GameSettings.bgmMuted = true;
  GameSettings.sfxMuted = false;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final sfx = <String>[];

  setUp(() async {
    await _resetStorage();
    sfx.clear();
    SoundManager.debugSfxSink = (path, _, _) => sfx.add(path);
  });

  tearDown(() {
    SoundManager.debugSfxSink = null;
    MotionPolicy.debugReduceMotionOverride = null;
    SoundManager.rampGlobalPitch(1, Duration.zero);
  });

  testWidgets('런 완료는 기록·save 정리 뒤 승리 장면을 보여 주고, 결과는 연출을 건너뛸 때와 같다', (
    tester,
  ) async {
    Future<(String, bool)> completeRun({required bool reduceMotion}) async {
      MotionPolicy.debugReduceMotionOverride = reduceMotion;
      final router = _router(
        GameView(
          runSeed: 904,
          restoredRun: _finalRun(),
          debugCompleteRunOnLoad: true,
        ),
      );
      await tester.pumpWidget(_routerApp(router));
      for (var i = 0; i < 100; i++) {
        await tester.pump(const Duration(milliseconds: 100));
        if (find
                .byKey(const ValueKey('run-victory-overlay'))
                .evaluate()
                .isNotEmpty ||
            find.byKey(const ValueKey('title-stub')).evaluate().isNotEmpty) {
          break;
        }
      }
      final state = jsonEncode(RunUnlockStateService.loadSync().toJson());
      final activeRunCleared = !StorageHelper.hasData(
        StorageKeys.activeRunPayloadV1,
      );
      if (!reduceMotion) {
        expect(
          find.byKey(const ValueKey('run-victory-overlay')),
          findsOneWidget,
        );
        expect(sfx, contains(AssetPaths.sfxReward), reason: 'victory cue');
        // 장면이 떠 있는 동안 이미 기록과 save 정리가 끝나 있다.
        expect(activeRunCleared, isTrue);
        await tester.pump(const Duration(milliseconds: 1000));
        await tester.pump(const Duration(milliseconds: 800));
        expect(find.text('2'), findsWidgets, reason: '구매한 Jester tally');
        // 탭 건너뛰기와 자동 종료는 overlay 단위 테스트에서 확인한다.
        // BGM 정지가 테스트 환경의 플랫폼 채널을 기다리므로 여기서는 라우팅까지 가지 않는다.
      } else {
        expect(find.byKey(const ValueKey('run-victory-overlay')), findsNothing);
      }
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 1));
      router.dispose();
      return (state, activeRunCleared);
    }

    final withVictory = await completeRun(reduceMotion: false);
    await _resetStorage();
    final skipped = await completeRun(reduceMotion: true);

    expect(withVictory.$2, isTrue);
    expect(skipped.$2, isTrue);
    expect(withVictory.$1, skipped.$1, reason: '기록 결과가 같다');
    expect(withVictory.$1, contains('flow-meta-victory'));
  });
}
