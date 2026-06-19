import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:rummipoker/logic/rummi_poker_grid/jester_meta.dart';
import 'package:rummipoker/logic/rummi_poker_grid/models/poker_deck.dart';
import 'package:rummipoker/logic/rummi_poker_grid/rummi_blind_state.dart';
import 'package:rummipoker/logic/rummi_poker_grid/rummi_poker_grid_session.dart';
import 'package:rummipoker/resources/jester_translation_scope.dart';
import 'package:rummipoker/services/active_run_save_service.dart';
import 'package:rummipoker/services/game_settings.dart';
import 'package:rummipoker/services/new_run_setup.dart';
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

  testWidgets('짧은 inactive는 무시하고 paused 복귀는 옵션창을 연다', (tester) async {
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
                  child: GameView(
                    runSeed: 902,
                    restoredRun: _restoredBattleForLifecycleTest(),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
    await tester.pump();
    await _pumpUntilGameViewBuilt(tester);

    _sendGameLifecycle(tester, AppLifecycleState.inactive);
    await tester.pump(const Duration(milliseconds: 50));
    _sendGameLifecycle(tester, AppLifecycleState.resumed);
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('일시정지'), findsNothing);

    _sendGameLifecycle(tester, AppLifecycleState.inactive);
    await tester.pump();
    _sendGameLifecycle(tester, AppLifecycleState.paused);
    await tester.pump();
    _sendGameLifecycle(tester, AppLifecycleState.resumed);
    await tester.pump();
    for (var i = 0; i < 10 && find.text('옵션').evaluate().isEmpty; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(find.text('옵션'), findsOneWidget);
    expect(find.text('설정 화면을 열고 복귀 후 현재 메뉴를 다시 엽니다.'), findsOneWidget);
    expect(find.text('일시정지'), findsOneWidget);

    await tester.tap(find.byTooltip('취소'));
    await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });
}

ActiveRunRuntimeState _restoredBattleForLifecycleTest() {
  final session = RummiPokerGridSession(
    runSeed: 902,
    blind: RummiBlindState(
      targetScore: 240,
      boardDiscardsRemaining: 4,
      handDiscardsRemaining: 2,
    ),
    deck: PokerDeck.fromSnapshot(const []),
  );
  final runProgress = RummiRunProgress()
    ..stageIndex = 1
    ..currentStationBlindTierIndex = 0
    ..gold = 0;

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

Future<void> _pumpUntilGameViewBuilt(WidgetTester tester) async {
  for (var i = 0; i < 50 && find.byType(GameView).evaluate().isEmpty; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  expect(find.byType(GameView), findsOneWidget);
}

void _sendGameLifecycle(WidgetTester tester, AppLifecycleState state) {
  final observer =
      tester.state(find.byType(GameView)) as WidgetsBindingObserver;
  observer.didChangeAppLifecycleState(state);
}
