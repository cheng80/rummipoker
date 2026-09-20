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
    expect(sfx.single.$1, AssetPaths.sfxDeny);
    expect(sfx.single.$3, closeTo(1, 1e-9));
    expect(haptics, [HapticGrade.error]);

    GameSettings.hapticsEnabled = false;
    GameFeedback.play(GameCue.scoreTick, pitch: 1.1);
    expect(sfx.last.$3, closeTo(1.1, 1e-9));
    expect(haptics, [HapticGrade.error]);
  });

  test('run navigation preserves the original button sound and pitch', () {
    for (final cue in [
      GameCue.runStart,
      GameCue.battleStart,
      GameCue.runRestore,
    ]) {
      GameFeedback.play(cue);
      expect(sfx.last.$1, AssetPaths.sfxBtnSnd, reason: cue.name);
      expect(sfx.last.$3, 1, reason: cue.name);
    }
  });

  test('line scores and progression never announce cash-out Clear', () {
    for (final cue in [
      GameCue.bigScore1,
      GameCue.bigScore2,
      GameCue.bigScore3,
      GameCue.bigScore4,
      GameCue.unlock,
      GameCue.stationAdvance,
      GameCue.victory,
    ]) {
      GameFeedback.play(cue);
      expect(sfx.last.$1, isNot(AssetPaths.sfxClear), reason: cue.name);
    }
  });

  test(
    'UI clicks always use the original button sound without pitch variation',
    () {
      for (final cue in [
        GameCue.buttonTap,
        GameCue.choiceSelect,
        GameCue.marketTab,
        GameCue.marketPage,
        GameCue.menuNavigate,
        GameCue.panelOpen,
      ]) {
        for (var i = 0; i < 5; i++) {
          GameFeedback.play(cue);
          expect(sfx.last.$1, AssetPaths.sfxBtnSnd, reason: cue.name);
          expect(sfx.last.$3, 1, reason: cue.name);
        }
      }
    },
  );

  test('word announcements are not reused for generic effects', () {
    for (final entry in gameFeedbackCues.entries) {
      expect(
        entry.value.sfx,
        isNot(AssetPaths.sfxStart),
        reason: entry.key.name,
      );
      if (entry.value.sfx == AssetPaths.sfxClear) {
        expect(entry.key, GameCue.cashOutOpen);
        expect(entry.value.pitch, 1);
        expect(entry.value.pitchVariance, 0);
      }
    }
    expect(gameFeedbackCues[GameCue.cashOutOpen]!.sfx, AssetPaths.sfxClear);
  });

  test(
    'spoken announcements retain rate one under global pitch and variation',
    () {
      SoundManager.rampGlobalPitch(0.5, Duration.zero);
      GameFeedback.play(GameCue.cashOutOpen, pitch: 1.5);
      expect(sfx.single.$1, AssetPaths.sfxClear);
      expect(sfx.single.$3, 1);
      for (final path in [AssetPaths.sfxStart, AssetPaths.sfxClear]) {
        SoundManager.playSfx(path, pitch: 1.7, pitchVariance: 0.2);
        expect(sfx.last.$3, 1);
      }
    },
  );

  test('visual only cues preserve haptics without additional sound', () {
    GameFeedback.play(GameCue.newReveal);
    GameFeedback.play(GameCue.marketEntry);
    expect(sfx, isEmpty);
    expect(haptics, [HapticGrade.impact, HapticGrade.impact]);
    for (final cue in [GameCue.deny, GameCue.penalty]) {
      GameFeedback.play(cue);
      expect(
        sfx.last.$1,
        cue == GameCue.deny ? AssetPaths.sfxDeny : AssetPaths.sfxFail,
      );
      expect(sfx.last.$3, 1);
    }
  });

  test(
    'UI button cues ignore global pitch but gameplay pitch remains active',
    () {
      SoundManager.rampGlobalPitch(0.5, Duration.zero);
      for (final cue in [
        GameCue.buttonTap,
        GameCue.choiceSelect,
        GameCue.marketTab,
        GameCue.marketPage,
        GameCue.menuNavigate,
        GameCue.panelOpen,
        GameCue.runStart,
        GameCue.battleStart,
        GameCue.runRestore,
      ]) {
        GameFeedback.play(cue, pitch: 1.8);
        expect(sfx.last.$1, AssetPaths.sfxBtnSnd);
        expect(sfx.last.$3, 1, reason: cue.name);
      }
      GameFeedback.play(GameCue.tilePlace);
      expect(sfx.last.$3, 1);
      GameFeedback.play(GameCue.countTick, pitch: 1.4);
      expect(sfx.last.$3, closeTo(1.35 * 1.4 * 0.5, 1e-9));
    },
  );

  test(
    'approved original cues stay rate one and silent cues remain silent',
    () {
      SoundManager.rampGlobalPitch(0.5, Duration.zero);
      for (final entry in gameFeedbackCues.entries.where(
        (e) => e.value.preserveOriginalPitch,
      )) {
        sfx.clear();
        GameFeedback.play(entry.key, pitch: 1.8);
        if (entry.value.sfx == null) {
          expect(sfx, isEmpty, reason: entry.key.name);
        } else {
          expect(sfx, hasLength(1), reason: entry.key.name);
          expect(sfx.single.$1, entry.value.sfx);
          expect(sfx.single.$3, 1, reason: entry.key.name);
        }
      }
    },
  );

  test('every cue has a spec', () {
    for (final cue in GameCue.values) {
      expect(gameFeedbackCues[cue], isNotNull, reason: cue.name);
    }
  });
}
