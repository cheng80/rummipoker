import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flame_audio/flame_audio.dart';

import '../services/game_settings.dart';
import 'asset_paths.dart';
import 'web_sfx_bridge.dart';

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
  static int _debugUserGestureBgmResumeCount = 0;
  static AudioPlayer? _webBgmPlayer;
  static final Map<String, Future<AudioPool>> _sfxPools =
      <String, Future<AudioPool>>{};
  static final math.Random _pitchRandom = math.Random();
  static double _globalPitch = 1;
  static Timer? _globalPitchRamp;

  static const List<String> _sfxPaths = <String>[
    AssetPaths.sfxTimeTic,
    AssetPaths.sfxStart,
    AssetPaths.sfxCollect,
    AssetPaths.sfxFail,
    AssetPaths.sfxBtnSnd,
    AssetPaths.sfxClear,
    AssetPaths.sfxTimeUp,
  ];

  /// 테스트에서 실제 재생 대신 (path, volume, rate)를 받는다.
  @visibleForTesting
  static void Function(String path, double volume, double rate)? debugSfxSink;

  @visibleForTesting
  static String? get debugCurrentBgm => _currentBgm;

  @visibleForTesting
  static int get debugUserGestureBgmResumeCount =>
      _debugUserGestureBgmResumeCount;

  @visibleForTesting
  static bool get debugBgmAutoResumeBlocked => _bgmAutoResumeBlockDepth > 0;

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
    _debugUserGestureBgmResumeCount = 0;
    _webBgmPlayer = null;
    _sfxPools.clear();
    _globalPitchRamp?.cancel();
    _globalPitchRamp = null;
    _globalPitch = 1;
    debugSfxSink = null;
  }

  @visibleForTesting
  static bool debugShouldUseSfxPool(String path, {required bool isWeb}) {
    return _shouldUseSfxPool(path, isWeb: isWeb);
  }

  static bool _shouldUseSfxPool(String path, {required bool isWeb}) {
    return !isWeb && _pooledSfxPaths.contains(path);
  }

  @visibleForTesting
  static bool debugShouldHandleWebAudioGesture({required bool isWeb}) {
    return _shouldHandleWebAudioGesture(isWeb: isWeb);
  }

  static bool _shouldHandleWebAudioGesture({required bool isWeb}) => isWeb;

  @visibleForTesting
  static bool debugShouldForwardWebSfxUnlock({required bool isWeb}) =>
      _shouldForwardWebSfxUnlock(isWeb: isWeb);

  static bool _shouldForwardWebSfxUnlock({required bool isWeb}) => isWeb;

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
  static bool debugShouldRestartBgmFromUserGesture({required bool isWeb}) {
    return _shouldRestartBgmFromUserGesture(isWeb: isWeb);
  }

  static bool _shouldRestartBgmFromUserGesture({required bool isWeb}) => isWeb;

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
    if (!_shouldHandleWebAudioGesture(isWeb: kIsWeb)) return;
    if (_shouldForwardWebSfxUnlock(isWeb: kIsWeb)) {
      unlockWebSfx();
    }
    _webUnlocked = true;
    if (_bgmAutoResumeBlockDepth > 0) return;
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

  /// 실제 게임 복귀 사용자 제스처에서 웹 BGM을 다시 시작한다.
  static void resumeBgmFromUserGesture({String? onlyIfCurrent}) {
    assert(() {
      _debugUserGestureBgmResumeCount++;
      return true;
    }());
    if (!_shouldRestartBgmFromUserGesture(isWeb: kIsWeb)) {
      resumeBgm(onlyIfCurrent: onlyIfCurrent);
      return;
    }
    if (onlyIfCurrent != null && _currentBgm != onlyIfCurrent) return;
    if (GameSettings.bgmMuted) return;
    final target = _currentBgm;
    if (target == null) return;
    _webUnlocked = true;
    _pendingBgm = target;
    _playBgmImmediatelyForWeb(target);
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
    if (kIsWeb) {
      for (final path in _sfxPaths) {
        initializeWebSfx(path);
      }
      return;
    }
    await Future.wait([
      FlameAudio.audioCache.load(AssetPaths.bgmMenu),
      FlameAudio.audioCache.load(AssetPaths.bgmMain),
      for (final path in _sfxPaths) FlameAudio.audioCache.load(path),
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
  /// [pitch]는 재생 배율(1 = 원음)이고 [pitchVariance]는 ±비율의 무작위 변주다.
  /// 여기에 전역 배율 [globalPitch]를 곱한다.
  ///
  /// **웹(kIsWeb):** Web Audio `playbackRate`로 음높이를 바꾼다.
  /// [FlameAudio.playLongAudio]와 [AssetSource]는 [AudioCache.loadPath]를 거쳐
  /// `dart:io` 파일 체크를 호출할 수 있어 브라우저에서는 JS 브리지를 쓴다.
  ///
  /// **네이티브:** pitch를 무시하고 원음으로 재생한다. iOS audioplayers는
  /// `timeDomain` 알고리즘으로 음높이를 유지한 채 속도만 바꾸고, [AudioPool]은
  /// 재생별 rate를 받지 않기 때문이다.
  static void playSfx(
    String path, {
    double pitch = 1,
    double pitchVariance = 0,
  }) {
    if (GameSettings.sfxMuted) return;
    final vol = GameSettings.sfxVolume;
    final rate = resolveSfxRate(
      pitch: pitch,
      pitchVariance: pitchVariance,
      globalPitch: _globalPitch,
      random: _pitchRandom.nextDouble(),
    );
    final sink = debugSfxSink;
    if (sink != null) {
      sink(path, vol, rate);
      return;
    }
    if (kIsWeb && !_webUnlocked) return;
    if (kIsWeb) {
      playWebSfx(path, vol, rate);
      return;
    }
    if (_shouldUseSfxPool(path, isWeb: false)) {
      unawaited(_playSfxFromPool(path, vol));
      return;
    }
    try {
      FlameAudio.play(path, volume: vol);
    } catch (_) {}
  }

  /// [random]은 0..1 값이다. 결과는 0.25..4로 제한한다.
  @visibleForTesting
  static double resolveSfxRate({
    required double pitch,
    required double pitchVariance,
    required double globalPitch,
    required double random,
  }) {
    final variation = 1 + (random * 2 - 1) * pitchVariance;
    return (pitch * variation * globalPitch).clamp(0.25, 4.0);
  }

  /// 전역 pitch 배율. 모든 효과음에 곱한다.
  static double get globalPitch => _globalPitch;

  /// 전역 pitch를 [target]으로 [duration] 동안 선형으로 옮긴다.
  ///
  /// 게임오버 때 `rampGlobalPitch(0.5, ...)`로 소리를 끌어내리고, 다음 run이나 재시도에서
  /// `rampGlobalPitch(1, Duration.zero)`로 되돌린다. BGM에는 재생 속도로 근사한다
  /// (웹 BGM은 HTMLAudio라 음높이 대신 속도만 바뀐다).
  static void rampGlobalPitch(double target, Duration duration) {
    _globalPitchRamp?.cancel();
    _globalPitchRamp = null;
    final start = _globalPitch;
    const step = Duration(milliseconds: 50);
    final steps = duration.inMilliseconds ~/ step.inMilliseconds;
    if (steps <= 0) {
      _setGlobalPitch(target);
      return;
    }
    var i = 0;
    _globalPitchRamp = Timer.periodic(step, (timer) {
      i++;
      _setGlobalPitch(start + (target - start) * (i / steps));
      if (i >= steps) {
        timer.cancel();
        _globalPitchRamp = null;
      }
    });
  }

  static void _setGlobalPitch(double value) {
    _globalPitch = value.clamp(0.25, 4.0);
    if (debugSfxSink != null) return;
    final player = kIsWeb ? _webBgmPlayer : FlameAudio.bgm.audioPlayer;
    if (player == null) return;
    unawaited(player.setPlaybackRate(_globalPitch).catchError((Object _) {}));
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
        await FlameAudio.play(path, volume: volume);
      } catch (_) {}
    }
  }

  static Future<AudioPool> _createSfxPool(String path) {
    return FlameAudio.createPool(
      path,
      minPlayers: 1,
      maxPlayers: _sfxPoolMaxPlayers,
    );
  }
}
