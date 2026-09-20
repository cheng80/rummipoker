import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:rummipoker/views/game/game_feedback_cues.dart';
import 'package:rummipoker/resources/game_haptics.dart';
import 'package:rummipoker/resources/sound_manager.dart';
import 'package:rummipoker/services/game_settings.dart';
import 'package:rummipoker/services/new_run_setup.dart';
import 'package:rummipoker/services/run_unlock_state_service.dart';
import 'package:rummipoker/utils/storage_helper.dart';
import 'package:rummipoker/views/new_run_view.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final sfx = <String>[];
  final haptics = <HapticGrade>[];

  setUp(() async {
    StorageHelper.resetForTest();
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await StorageHelper.init();
    GameSettings.bgmMuted = true;
    GameSettings.sfxMuted = false;
    SoundManager.debugResetForTest();
    sfx.clear();
    haptics.clear();
    SoundManager.debugSfxSink = (path, _, _) => sfx.add(path);
    GameHaptics.debugSink = haptics.add;
  });

  tearDown(() {
    SoundManager.debugSfxSink = null;
    GameHaptics.debugSink = null;
    SoundManager.debugResetForTest();
  });

  Future<void> pumpNewRun(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3.0;
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
          builder: (context) => MaterialApp(
            locale: context.locale,
            supportedLocales: context.supportedLocales,
            localizationsDelegates: context.localizationDelegates,
            home: const NewRunView(),
          ),
        ),
      ),
    );
    for (var i = 0; i < 5; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pumpAndSettle();
    }
  }

  Future<void> tapHighStakes(WidgetTester tester) async {
    final card = find.byKey(const ValueKey('run-modifier-high_stakes'));
    await tester.ensureVisible(card);
    await tester.pumpAndSettle();
    sfx.clear();
    haptics.clear();
    await tester.tap(card);
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pumpAndSettle();
  }

  Future<void> disposeView(WidgetTester tester) async {
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  }

  // EasyLocalization은 파일당 한 번만 안정적으로 로드되어 한 테스트에서 거절→해금을 잇는다.
  testWidgets('locked modifier is denied first, then unlock celebrates', (
    tester,
  ) async {
    await pumpNewRun(tester);
    await tapHighStakes(tester);

    expect(sfx, [gameFeedbackCues[GameCue.deny]!.sfx]);
    expect(haptics, [HapticGrade.error]);
    var state = await tester.runAsync(RunUnlockStateService.load);
    expect(state!.isRunModifierUnlocked(NewRunModifier.highStakes), isFalse);
    expect(state.insight, 0);

    await tester.runAsync(() => RunUnlockStateService.addInsight(20));
    await tapHighStakes(tester);

    expect(sfx, [gameFeedbackCues[GameCue.unlock]!.sfx]);
    expect(haptics, [HapticGrade.impact]);
    state = await tester.runAsync(RunUnlockStateService.load);
    expect(state!.isRunModifierUnlocked(NewRunModifier.highStakes), isTrue);
    expect(state.insight, 0);
    await disposeView(tester);
  });
}
