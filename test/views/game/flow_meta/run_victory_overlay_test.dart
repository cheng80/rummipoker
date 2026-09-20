import 'package:rummipoker/resources/asset_paths.dart';
import 'package:rummipoker/resources/sound_manager.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:rummipoker/services/game_settings.dart';
import 'package:rummipoker/utils/storage_helper.dart';
import 'package:rummipoker/views/game/game_presentation_timings.dart';
import 'package:rummipoker/views/game/widgets/game_run_victory_widgets.dart';
import '../../../support/test_translations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    StorageHelper.resetForTest();
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await StorageHelper.init();
    GameSettings.sfxMuted = true;
  });

  testWidgets('승리 장면은 탭으로 건너뛰고, 탭이 없으면 제한 시간 안에 한 번만 끝난다', (tester) async {
    tester.view.physicalSize = const Size(390, 750);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    GameSettings.sfxMuted = false;
    final sounds = <(String, double)>[];
    SoundManager.debugSfxSink = (path, _, rate) => sounds.add((path, rate));
    addTearDown(SoundManager.debugResetForTest);
    var done = 0;
    Widget overlay() => EasyLocalization(
      assetLoader: const TestTranslationAssetLoader(),
      supportedLocales: const [Locale('ko')],
      path: 'assets/translations',
      fallbackLocale: const Locale('ko'),
      startLocale: const Locale('ko'),
      saveLocale: false,
      child: Builder(
        builder: (context) => MaterialApp(
          locale: context.locale,
          supportedLocales: context.supportedLocales,
          localizationsDelegates: context.localizationDelegates,
          home: GameRunVictoryOverlay(
            stats: const [
              GameRunVictoryStat(labelKey: 'flowVictoryStations', value: 8),
              GameRunVictoryStat(labelKey: 'flowVictoryBosses', value: 8),
            ],
            onDone: () => done++,
          ),
        ),
      ),
    );

    await tester.pumpWidget(overlay());
    await tester.pumpAndSettle(const Duration(milliseconds: 50));
    expect(done, 1, reason: '탭 없이도 제한 시간 안에 끝난다');
    expect(sounds.where((e) => e.$1 == AssetPaths.sfxBtnSnd), isEmpty);
    expect(
      GamePresentationTimings.runVictoryHold,
      lessThanOrEqualTo(const Duration(milliseconds: 2500)),
    );
    expect(find.text('8'), findsNWidgets(2), reason: '수치 tally가 끝값에 닿는다');
    for (final value in tester.widgetList<Text>(find.text('8'))) {
      final rect = tester.getRect(find.byWidget(value));
      expect(rect.right, lessThanOrEqualTo(390), reason: '폰 프레임 안에 남는다');
      expect(rect.left, greaterThanOrEqualTo(0));
    }

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(overlay());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    sounds.clear();
    SoundManager.rampGlobalPitch(0.5, Duration.zero);
    await tester.tap(find.byKey(const ValueKey('run-victory-overlay')));
    expect(sounds, [(AssetPaths.sfxBtnSnd, 1.0)]);
    await tester.tap(find.byKey(const ValueKey('run-victory-overlay')));
    expect(sounds, [(AssetPaths.sfxBtnSnd, 1.0)]);
    await tester.pump();
    expect(done, 2, reason: '탭하면 바로 끝난다');
    await tester.pump(GamePresentationTimings.runVictoryHold);
    expect(done, 2, reason: '끝 알림은 한 번만');
  });
}
