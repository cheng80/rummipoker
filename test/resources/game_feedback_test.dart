import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:rummipoker/resources/asset_paths.dart';
import 'package:rummipoker/resources/game_haptics.dart';
import 'package:rummipoker/resources/sound_manager.dart';
import 'package:rummipoker/services/game_settings.dart';
import 'package:rummipoker/utils/storage_helper.dart';
import 'package:rummipoker/views/game/game_feedback_cues.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final sfx = <(String, double, double)>[];
  final haptics = <HapticGrade>[];

  setUp(() async {
    StorageHelper.resetForTest();
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await StorageHelper.init();
    SoundManager.debugResetForTest();
    sfx.clear();
    haptics.clear();
    SoundManager.debugSfxSink = (path, volume, rate) =>
        sfx.add((path, volume, rate));
    GameHaptics.debugSink = haptics.add;
  });

  tearDown(() {
    SoundManager.debugResetForTest();
    GameHaptics.debugSink = null;
  });

  test('playSfx passes pitch and the global pitch to the output', () {
    SoundManager.playSfx(AssetPaths.sfxCollect, pitch: 1.2);
    expect(sfx.single.$1, AssetPaths.sfxCollect);
    expect(sfx.single.$3, closeTo(1.2, 1e-9));

    SoundManager.rampGlobalPitch(0.5, Duration.zero);
    SoundManager.playSfx(AssetPaths.sfxCollect, pitch: 1.2);
    expect(sfx.last.$3, closeTo(0.6, 1e-9));
  });

  test('pitch variance stays inside the requested range and clamps', () {
    double rate(double random) => SoundManager.resolveSfxRate(
      pitch: 1,
      pitchVariance: 0.1,
      globalPitch: 1,
      random: random,
    );
    expect(rate(0), closeTo(0.9, 1e-9));
    expect(rate(1), closeTo(1.1, 1e-9));
    expect(
      SoundManager.resolveSfxRate(
        pitch: 9,
        pitchVariance: 0,
        globalPitch: 1,
        random: 0.5,
      ),
      4,
    );
  });

  test('muted SFX produces no output', () {
    GameSettings.sfxMuted = true;
    SoundManager.playSfx(AssetPaths.sfxBtnSnd, pitch: 1.5);
    expect(sfx, isEmpty);
  });

  test('cue plays sound and haptic together with its pitch', () {
    GameFeedback.play(GameCue.deny);
    expect(sfx.single.$1, gameFeedbackCues[GameCue.deny]!.sfx);
    expect(
      sfx.single.$3,
      closeTo(gameFeedbackCues[GameCue.deny]!.pitch, 1e-9),
    );
    expect(haptics, [HapticGrade.error]);

    GameSettings.hapticsEnabled = false;
    GameFeedback.play(GameCue.scoreTick, pitch: 1.1);
    expect(sfx.last.$3, closeTo(1.1, 1e-9));
    expect(haptics, [HapticGrade.error]);
  });

  test('every cue has a spec', () {
    for (final cue in GameCue.values) {
      expect(gameFeedbackCues[cue], isNotNull, reason: cue.name);
    }
  });
}
