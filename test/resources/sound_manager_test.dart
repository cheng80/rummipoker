import 'package:flutter_test/flutter_test.dart';
import 'package:rummipoker/resources/asset_paths.dart';
import 'package:rummipoker/resources/sound_manager.dart';

void main() {
  group('SoundManager web BGM recovery policy', () {
    test('replays pending BGM even when the web player reports playing', () {
      expect(
        SoundManager.debugShouldReplayWebBgm(
          requestedBgm: AssetPaths.bgmMain,
          currentBgm: AssetPaths.bgmMain,
          pendingBgm: AssetPaths.bgmMain,
          audioPlayerReportsPlaying: true,
        ),
        isTrue,
      );
    });

    test('trusts playing state when there is no pending web recovery', () {
      expect(
        SoundManager.debugShouldReplayWebBgm(
          requestedBgm: AssetPaths.bgmMain,
          currentBgm: AssetPaths.bgmMain,
          pendingBgm: null,
          audioPlayerReportsPlaying: true,
        ),
        isFalse,
      );
    });

    test('marks pending BGM only for lifecycle web recovery pauses', () {
      expect(
        SoundManager.debugPendingBgmAfterPause(
          recoverOnNextWebGesture: true,
          currentBgm: AssetPaths.bgmMain,
        ),
        AssetPaths.bgmMain,
      );
      expect(
        SoundManager.debugPendingBgmAfterPause(
          recoverOnNextWebGesture: false,
          currentBgm: AssetPaths.bgmMain,
        ),
        isNull,
      );
    });

    test('waits for a web gesture when pending BGM needs recovery', () {
      expect(
        SoundManager.debugShouldResumeBgmImmediately(
          isWeb: true,
          target: AssetPaths.bgmMain,
          pendingBgm: AssetPaths.bgmMain,
        ),
        isFalse,
      );
      expect(
        SoundManager.debugShouldResumeBgmImmediately(
          isWeb: false,
          target: AssetPaths.bgmMain,
          pendingBgm: AssetPaths.bgmMain,
        ),
        isTrue,
      );
    });

    test(
      'does not start duplicate web replay while the same BGM is in flight',
      () {
        expect(
          SoundManager.debugShouldStartWebBgmReplay(
            replayInFlight: true,
            requestedBgm: AssetPaths.bgmMain,
            pendingBgm: AssetPaths.bgmMain,
          ),
          isFalse,
        );
        expect(
          SoundManager.debugShouldStartWebBgmReplay(
            replayInFlight: true,
            requestedBgm: AssetPaths.bgmMenu,
            pendingBgm: AssetPaths.bgmMain,
          ),
          isTrue,
        );
      },
    );

    test('tries resume before web replay fallback for pending recovery', () {
      expect(
        SoundManager.debugShouldResumePendingWebBgm(
          requestedBgm: AssetPaths.bgmMain,
          pendingBgm: AssetPaths.bgmMain,
          resumeInFlight: false,
          resumeAlreadyTried: false,
        ),
        isTrue,
      );
      expect(
        SoundManager.debugShouldResumePendingWebBgm(
          requestedBgm: AssetPaths.bgmMain,
          pendingBgm: AssetPaths.bgmMain,
          resumeInFlight: false,
          resumeAlreadyTried: true,
        ),
        isFalse,
      );
    });

    test('skips audio cache preload on web', () {
      expect(SoundManager.debugShouldPreloadAudioCache(isWeb: true), isFalse);
      expect(SoundManager.debugShouldPreloadAudioCache(isWeb: false), isTrue);
    });

    test('uses a direct Flutter web asset URL for web SFX', () {
      expect(
        SoundManager.debugWebSfxAssetUrl(AssetPaths.sfxBtnSnd),
        'assets/assets/audio/sfx/BtnSnd.mp3',
      );
    });

    test('uses a direct Flutter web asset URL for web BGM', () {
      expect(
        SoundManager.debugWebBgmAssetUrl(AssetPaths.bgmMenu),
        'assets/assets/audio/music/Menu_BGM.mp3',
      );
    });

    test('uses pools for repeated SFX but keeps BGM out of the pool', () {
      expect(SoundManager.debugShouldUseSfxPool(AssetPaths.sfxBtnSnd), isTrue);
      expect(SoundManager.debugShouldUseSfxPool(AssetPaths.sfxClear), isTrue);
      expect(SoundManager.debugShouldUseSfxPool(AssetPaths.bgmMain), isFalse);
    });
  });
}
