import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:rummipoker/app_config.dart';
import 'package:rummipoker/logic/rummi_poker_grid/boss_modifier.dart';
import 'package:rummipoker/logic/rummi_poker_grid/jester_meta.dart';
import 'package:rummipoker/logic/rummi_poker_grid/models/poker_deck.dart';
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
    SharedPreferences.setMockInitialValues(<String, Object>{
      StorageKeys.tutorialBattleIntroSeen: true,
    });
    await StorageHelper.init();
    GameSettings.bgmMuted = true;
    GameSettings.sfxMuted = true;
  });

  testWidgets('보스 인트로 제목은 말줄임 없이 줄바꿈을 허용한다', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final session = RummiPokerGridSession(
      runSeed: 901,
      blind: RummiBlindState(
        targetScore: 285,
        boardDiscardsRemaining: 3,
        handDiscardsRemaining: 1,
        bossModifier: RummiBossModifier.redDampener,
      ),
      deck: PokerDeck.fromSnapshot(const []),
    );
    final runProgress = RummiRunProgress()
      ..stageIndex = 1
      ..currentStationBlindTierIndex = 2;
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
                  child: GameView(runSeed: 901, restoredRun: restoredRun),
                ),
              ),
            );
          },
        ),
      ),
    );

    await tester.pump();
    await tester.pump();

    final titleText = tester.widget<Text>(find.text('빨간 타일 약화'));
    expect(titleText.overflow, isNull);
    expect(titleText.maxLines, isNull);
    expect(titleText.softWrap, isTrue);
    expect(
      find.byKey(const ValueKey('boss-constraint-rule-scroll')),
      findsOneWidget,
    );
    expect(find.text('빨간 타일이 포함된 점수 라인은 35% 감소합니다.'), findsOneWidget);

    await tester.tap(find.text('전투 시작'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('battle-blind-info-chip')));
    await tester.pumpAndSettle();

    expect(find.text('빨간 타일 약화'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('boss-constraint-rule-scroll')),
      findsOneWidget,
    );
    expect(find.text('빨간 타일이 포함된 점수 라인은 35% 감소합니다.'), findsOneWidget);
    expect(find.text('닫기'), findsOneWidget);

    await tester.tap(find.text('닫기'));
    await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });
}
