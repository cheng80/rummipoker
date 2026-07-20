import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flame_audio/flame_audio.dart';

import '../services/game_settings.dart';
import 'asset_paths.dart';

/// 앱 전역 사운드 관리. BGM·효과음 재생, 볼륨·음소거 적용.
/// 웹: 사용자 상호작용 전까지 자동재생 차단. 첫 탭 시 unlock.
class SoundManager {
  SoundManager._();

  static const Duration _resumeStateSettleDelay = Duration(milliseconds: 120);
  static const int _sfxPoolMaxPlayers = 3;
  static const Set<String> _pooledSfxPaths = <String>{
    AssetPaths.sfxBtnSnd,
    AssetPaths.sfxCollect,
    AssetPaths.sfxClear,
    AssetPaths.sfxTimeUp,
  };

  static String? _currentBgm;
  static bool _webUnlocked = false;
  static String? _pendingBgm;
  static Future<void> _bgmOp = Future<void>.value();
  static int _bgmRequestSerial = 0;
  static int _bgmAutoResumeBlockDepth = 0;
  static bool _webBgmReplayInFlight = false;
  static bool _webBgmResumeInFlight = false;
  static bool _webPendingResumeTried = false;
  static AudioPlayer? _webBgmPlayer;
  static final Set<AudioPlayer> _webSfxPlayers = <AudioPlayer>{};
  static final Map<String, Future<AudioPool>> _sfxPools =
      <String, Future<AudioPool>>{};

  @visibleForTesting
  static String? get debugCurrentBgm => _currentBgm;

  @visibleForTesting
  static void debugResetForTest() {
    _currentBgm = null;
    _webUnlocked = false;
    _pendingBgm = null;
    _bgmOp = Future<void>.value();
    _bgmRequestSerial = 0;
    _bgmAutoResumeBlockDepth = 0;
    _webBgmReplayInFlight = false;
    _webBgmResumeInFlight = false;
    _webPendingResumeTried = false;
    _webBgmPlayer = null;
    _sfxPools.clear();
  }

  @visibleForTesting
  static bool debugShouldUseSfxPool(String path) {
    return _shouldUseSfxPool(path);
  }

  static bool _shouldUseSfxPool(String path) => _pooledSfxPaths.contains(path);

  @visibleForTesting
  static bool debugShouldReplayWebBgm({
    required String requestedBgm,
    required String? currentBgm,
    required String? pendingBgm,
    required bool audioPlayerReportsPlaying,
  }) {
    return _shouldReplayWebBgm(
      requestedBgm: requestedBgm,
      currentBgm: currentBgm,
      pendingBgm: pendingBgm,
      audioPlayerReportsPlaying: audioPlayerReportsPlaying,
    );
  }

  static bool _shouldReplayWebBgm({
    required String requestedBgm,
    required String? currentBgm,
    required String? pendingBgm,
    required bool audioPlayerReportsPlaying,
  }) {
    if (pendingBgm == requestedBgm) return true;
    if (currentBgm == requestedBgm && audioPlayerReportsPlaying) return false;
    return true;
  }

  @visibleForTesting
  static String? debugPendingBgmAfterPause({
    required bool recoverOnNextWebGesture,
    required String? currentBgm,
  }) {
    return _pendingBgmAfterPause(
      recoverOnNextWebGesture: recoverOnNextWebGesture,
      currentBgm: currentBgm,
    );
  }

  static String? _pendingBgmAfterPause({
    required bool recoverOnNextWebGesture,
    required String? currentBgm,
  }) {
    if (!recoverOnNextWebGesture) return null;
    return currentBgm;
  }

  @visibleForTesting
  static bool debugShouldResumeBgmImmediately({
    required bool isWeb,
    required String target,
    required String? pendingBgm,
  }) {
    return _shouldResumeBgmImmediately(
      isWeb: isWeb,
      target: target,
      pendingBgm: pendingBgm,
    );
  }

  static bool _shouldResumeBgmImmediately({
    required bool isWeb,
    required String target,
    required String? pendingBgm,
  }) {
    return !(isWeb && pendingBgm == target);
  }

  @visibleForTesting
  static bool debugShouldStartWebBgmReplay({
    required bool replayInFlight,
    required String requestedBgm,
    required String? pendingBgm,
  }) {
    return _shouldStartWebBgmReplay(
      replayInFlight: replayInFlight,
      requestedBgm: requestedBgm,
      pendingBgm: pendingBgm,
    );
  }

  static bool _shouldStartWebBgmReplay({
    required bool replayInFlight,
    required String requestedBgm,
    required String? pendingBgm,
  }) {
    return !(replayInFlight && pendingBgm == requestedBgm);
  }

  @visibleForTesting
  static bool debugShouldResumePendingWebBgm({
    required String requestedBgm,
    required String? pendingBgm,
    required bool resumeInFlight,
    required bool resumeAlreadyTried,
  }) {
    return _shouldResumePendingWebBgm(
      requestedBgm: requestedBgm,
      pendingBgm: pendingBgm,
      resumeInFlight: resumeInFlight,
      resumeAlreadyTried: resumeAlreadyTried,
    );
  }

  static bool _shouldResumePendingWebBgm({
    required String requestedBgm,
    required String? pendingBgm,
    required bool resumeInFlight,
    required bool resumeAlreadyTried,
  }) {
    return pendingBgm == requestedBgm && !resumeInFlight && !resumeAlreadyTried;
  }

  @visibleForTesting
  static bool debugShouldPreloadAudioCache({required bool isWeb}) {
    return _shouldPreloadAudioCache(isWeb: isWeb);
  }

  static bool _shouldPreloadAudioCache({required bool isWeb}) {
    return !isWeb;
  }

  @visibleForTesting
  static String debugWebSfxAssetUrl(String path) {
    return _webAudioAssetUrl(path);
  }

  @visibleForTesting
  static String debugWebBgmAssetUrl(String path) {
    return _webAudioAssetUrl(path);
  }

  static String _webAudioAssetUrl(String path) {
    final encodedPath = path.split('/').map(Uri.encodeComponent).join('/');
    return 'assets/assets/audio/$encodedPath';
  }

  static bool get _bgmReportsPlaying {
    if (kIsWeb) {
      return _webBgmPlayer?.state == PlayerState.playing;
    }
    return FlameAudio.bgm.audioPlayer.state == PlayerState.playing;
  }

  /// Pause 메뉴에서 설정을 여는 동안 mute 해제가 BGM을 자동 재개하지 못하게 막는다.
  static void beginBgmAutoResumeBlock() {
    _bgmAutoResumeBlockDepth++;
  }

  static void endBgmAutoResumeBlock() {
    if (_bgmAutoResumeBlockDepth == 0) return;
    _bgmAutoResumeBlockDepth--;
  }

  /// 웹: 사용자 상호작용 시 호출. 대기 중인 BGM을 제스처 안에서 바로 재생한다.
  static void unlockForWeb() {
    if (!kIsWeb) return;
    _webUnlocked = true;
    if (GameSettings.bgmMuted) return;
    final target = _pendingBgm ?? _currentBgm;
    if (target == null) return;
    if (!_shouldReplayWebBgm(
      requestedBgm: target,
      currentBgm: _currentBgm,
      pendingBgm: _pendingBgm,
      audioPlayerReportsPlaying: _bgmReportsPlaying,
    )) {
      return;
    }
    if (_shouldResumePendingWebBgm(
      requestedBgm: target,
      pendingBgm: _pendingBgm,
      resumeInFlight: _webBgmResumeInFlight,
      resumeAlreadyTried: _webPendingResumeTried,
    )) {
      _resumePendingBgmForWebGesture(target);
      return;
    }
    _playBgmImmediatelyForWeb(target);
  }

  static void playBgmFromUserGesture(String path) {
    if (GameSettings.bgmMuted) return;
    if (!kIsWeb) {
      unawaited(playBgm(path));
      return;
    }
    _webUnlocked = true;
    _playBgmImmediatelyForWeb(path);
  }

  static void _resumePendingBgmForWebGesture(String path) {
    _webBgmResumeInFlight = true;
    _webPendingResumeTried = true;
    unawaited(
      _resumeBgm(path).whenComplete(() {
        _webBgmResumeInFlight = false;
      }),
    );
  }

  static void _playBgmImmediatelyForWeb(String path) {
    final pendingBeforeReplay = _pendingBgm;
    final previousBgm = _currentBgm;
    _currentBgm = path;
    if (!_shouldStartWebBgmReplay(
      replayInFlight: _webBgmReplayInFlight,
      requestedBgm: path,
      pendingBgm: pendingBeforeReplay,
    )) {
      return;
    }
    if (!_shouldReplayWebBgm(
      requestedBgm: path,
      currentBgm: previousBgm,
      pendingBgm: pendingBeforeReplay,
      audioPlayerReportsPlaying: _bgmReportsPlaying,
    )) {
      return;
    }
    final requestId = ++_bgmRequestSerial;
    _webBgmReplayInFlight = true;
    try {
      unawaited(
        _playBgmDirectlyForWeb(path, requestId).whenComplete(() {
          _webBgmReplayInFlight = false;
        }),
      );
    } catch (_) {
      _pendingBgm = path;
      _webBgmReplayInFlight = false;
    }
  }

  static Future<void> _playBgmDirectlyForWeb(String path, int requestId) async {
    AudioPlayer? player;
    try {
      await _disposeWebBgmPlayer();
      if (_currentBgm != path || requestId != _bgmRequestSerial) return;
      player = AudioPlayer();
      _webBgmPlayer = player;
      await player.setReleaseMode(ReleaseMode.loop);
      await player.play(
        UrlSource(_webAudioAssetUrl(path)),
        volume: GameSettings.bgmVolume,
        mode: PlayerMode.mediaPlayer,
      );
      if (_currentBgm == path && requestId == _bgmRequestSerial) {
        _pendingBgm = null;
        _webPendingResumeTried = false;
      }
    } catch (_) {
      if (_currentBgm == path && requestId == _bgmRequestSerial) {
        _pendingBgm = path;
      }
      if (identical(_webBgmPlayer, player)) {
        _webBgmPlayer = null;
      }
      try {
        await player?.dispose();
      } catch (_) {}
    }
  }

  static Future<void> _disposeWebBgmPlayer() async {
    final player = _webBgmPlayer;
    _webBgmPlayer = null;
    if (player == null) return;
    try {
      await player.stop();
    } catch (_) {}
    try {
      await player.dispose();
    } catch (_) {}
  }

  /// 게임·메뉴 BGM과 효과음을 미리 로드한다. 앱 시작 시 호출.
  static Future<void> preload() async {
    if (!_shouldPreloadAudioCache(isWeb: kIsWeb)) return;
    await Future.wait([
      FlameAudio.audioCache.load(AssetPaths.bgmMenu),
      FlameAudio.audioCache.load(AssetPaths.bgmMain),
      FlameAudio.audioCache.load(AssetPaths.sfxTimeTic),
      FlameAudio.audioCache.load(AssetPaths.sfxStart),
      FlameAudio.audioCache.load(AssetPaths.sfxCollect),
      FlameAudio.audioCache.load(AssetPaths.sfxFail),
      FlameAudio.audioCache.load(AssetPaths.sfxBtnSnd),
      FlameAudio.audioCache.load(AssetPaths.sfxClear),
      FlameAudio.audioCache.load(AssetPaths.sfxTimeUp),
    ]);
  }

  /// BGM 재생. 음소거 시에는 _currentBgm만 갱신하고 재생하지 않음.
  /// 웹: unlock 전이면 대기 후 첫 탭 시 재생.
  static Future<void> playBgm(String path) async {
    final requestId = ++_bgmRequestSerial;
    _bgmOp = _bgmOp.then((_) async {
      if (GameSettings.bgmMuted) {
        _pendingBgm = null;
        _currentBgm = path;
        return;
      }
      if (!_shouldReplayWebBgm(
        requestedBgm: path,
        currentBgm: _currentBgm,
        pendingBgm: _pendingBgm,
        audioPlayerReportsPlaying: _bgmReportsPlaying,
      )) {
        return;
      }
      _currentBgm = path;
      if (kIsWeb && !_webUnlocked) {
        _pendingBgm = path;
        return;
      }
      if (requestId != _bgmRequestSerial) return;
      if (kIsWeb) {
        await _playBgmDirectlyForWeb(path, requestId);
        return;
      }
      try {
        await FlameAudio.bgm.stop();
        if (requestId != _bgmRequestSerial) return;
        await FlameAudio.bgm.play(path, volume: GameSettings.bgmVolume);
        _pendingBgm = null;
      } catch (_) {
        _pendingBgm = path;
      }
    });
    await _bgmOp;
  }

  /// BGM 중지.
  static Future<void> stopBgm() async {
    _bgmRequestSerial++;
    _pendingBgm = null;
    _webPendingResumeTried = false;
    _currentBgm = null;
    if (kIsWeb) {
      await _disposeWebBgmPlayer();
      return;
    }
    try {
      await FlameAudio.bgm.stop();
    } catch (_) {}
  }

  /// BGM 일시정지. [onlyIfCurrent]가 지정되면 현재 BGM과 일치할 때만 적용.
  static void pauseBgm({
    String? onlyIfCurrent,
    bool recoverOnNextWebGesture = false,
  }) {
    if (onlyIfCurrent != null && _currentBgm != onlyIfCurrent) return;
    final pendingAfterPause = _pendingBgmAfterPause(
      recoverOnNextWebGesture: recoverOnNextWebGesture,
      currentBgm: _currentBgm,
    );
    if (kIsWeb && pendingAfterPause != null) {
      // 웹 복귀 후 브라우저가 playing 상태를 잘못 유지해도 다음 제스처에서 재시도한다.
      _pendingBgm = pendingAfterPause;
      _webPendingResumeTried = false;
    }
    if (kIsWeb) {
      unawaited(_webBgmPlayer?.pause().catchError((Object _) {}));
      return;
    }
    unawaited(FlameAudio.bgm.pause().catchError((Object _) {}));
  }

  /// BGM 재개. [onlyIfCurrent]가 지정되면 현재 BGM과 일치할 때만 적용.
  static void resumeBgm({String? onlyIfCurrent}) {
    if (onlyIfCurrent != null && _currentBgm != onlyIfCurrent) return;
    if (GameSettings.bgmMuted) return;
    final target = _currentBgm;
    if (target == null) return;
    if (!_shouldResumeBgmImmediately(
      isWeb: kIsWeb,
      target: target,
      pendingBgm: _pendingBgm,
    )) {
      return;
    }
    if (_bgmReportsPlaying && (!kIsWeb || _pendingBgm != target)) {
      return;
    }
    if (kIsWeb && !_webUnlocked) return;
    unawaited(_resumeBgm(target));
  }

  static Future<void> _resumeBgm(
    String target, {
    bool replayFallback = true,
  }) async {
    final resumeRequestSerial = _bgmRequestSerial;
    try {
      if (kIsWeb) {
        await _webBgmPlayer?.resume();
      } else {
        await FlameAudio.bgm.resume();
      }
    } catch (_) {}
    await Future<void>.delayed(_resumeStateSettleDelay);
    if (_currentBgm != target ||
        resumeRequestSerial != _bgmRequestSerial ||
        GameSettings.bgmMuted) {
      return;
    }
    if (_bgmReportsPlaying || (!kIsWeb && FlameAudio.bgm.isPlaying)) {
      if (kIsWeb && _pendingBgm == target) {
        _pendingBgm = null;
        _webPendingResumeTried = false;
      }
      return;
    }
    if (kIsWeb) {
      _pendingBgm = target;
    }
    if (!replayFallback) return;
    await playBgm(target);
  }

  /// 음소거 해제 시 BGM 재생. pause 상태면 resume, stop 상태면 play.
  static Future<void> playBgmIfUnmuted() async {
    if (_bgmAutoResumeBlockDepth > 0) return;
    final current = _currentBgm;
    if (current == null) return;
    await playBgm(current);
  }

  /// BGM 볼륨을 설정에 맞게 적용. 볼륨 슬라이더 변경 시 호출.
  static void applyBgmVolume() {
    if (GameSettings.bgmMuted) return;
    if (kIsWeb) {
      _webBgmPlayer?.setVolume(GameSettings.bgmVolume);
      return;
    }
    FlameAudio.bgm.audioPlayer.setVolume(GameSettings.bgmVolume);
  }

  /// 효과음 재생. 음소거 시 무시, 볼륨은 GameSettings.sfxVolume 적용.
  /// 웹: unlock 전이면 무시 (카운트다운 등 자동 재생 방지).
  ///
  /// **웹(kIsWeb):** [FlameAudio.playLongAudio]와 [AssetSource]는
  /// [AudioCache.loadPath]를 거쳐 `dart:io` 파일 체크를 호출할 수 있다.
  /// 브라우저에서는 asset URL을 직접 재생해 그 경로를 피한다.
  static void playSfx(String path) {
    if (GameSettings.sfxMuted) return;
    if (kIsWeb && !_webUnlocked) return;
    final vol = GameSettings.sfxVolume;
    if (_shouldUseSfxPool(path)) {
      unawaited(_playSfxFromPool(path, vol));
      return;
    }
    try {
      if (kIsWeb) {
        _playSfxWeb(path, vol);
      } else {
        FlameAudio.play(path, volume: vol);
      }
    } catch (_) {}
  }

  static Future<void> _playSfxFromPool(String path, double volume) async {
    final poolFuture = _sfxPools.putIfAbsent(path, () => _createSfxPool(path));
    try {
      final pool = await poolFuture;
      await pool.start(volume: volume);
    } catch (_) {
      if (identical(_sfxPools[path], poolFuture)) {
        _sfxPools.remove(path);
      }
      try {
        if (kIsWeb) {
          _playSfxWeb(path, volume);
        } else {
          await FlameAudio.play(path, volume: volume);
        }
      } catch (_) {}
    }
  }

  static Future<AudioPool> _createSfxPool(String path) {
    if (kIsWeb) {
      return AudioPool.create(
        source: UrlSource(_webAudioAssetUrl(path)),
        minPlayers: 1,
        maxPlayers: _sfxPoolMaxPlayers,
      );
    }
    return FlameAudio.createPool(
      path,
      minPlayers: 1,
      maxPlayers: _sfxPoolMaxPlayers,
    );
  }

  /// 웹 전용 SFX — AudioCache를 거치지 않도록 asset URL을 직접 재생한다.
  static void _playSfxWeb(String path, double volume) {
    final player = AudioPlayer();
    _webSfxPlayers.add(player);

    StreamSubscription<void>? completionSub;
    Future<void> disposePlayer() async {
      await completionSub?.cancel();
      _webSfxPlayers.remove(player);
      await player.dispose();
    }

    completionSub = player.onPlayerComplete.listen((_) {
      unawaited(disposePlayer());
    });

    unawaited(
      (() async {
        try {
          await player.setReleaseMode(ReleaseMode.release);
          await player.play(
            UrlSource(_webAudioAssetUrl(path)),
            volume: volume,
            mode: PlayerMode.mediaPlayer,
          );
        } catch (_) {
          await disposePlayer();
        }
      })(),
    );
  }
}
