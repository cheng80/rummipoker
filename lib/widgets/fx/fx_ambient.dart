import 'dart:math' as math;
import 'dart:async';

import 'package:flutter/widgets.dart';

import '../../views/game/game_presentation_timings.dart';
import '../../views/game/widgets/game_ui_palette.dart';

/// 배경이 현재 화면에서 느껴야 하는 분위기.
enum FxAmbientMood { battle, market, boss, reward, menu }

/// 별 반짝임과 분위기 전환을 소유하는 테스트 가능한 presentation controller.
///
/// 저장 가능한 게임 상태를 가지지 않는다. 실제 ticker는 [StarryBackground]가
/// 소유하고, 이 객체는 한 화면에 필요한 시간과 알림만 관리한다.
class FxAmbientController extends ChangeNotifier {
  FxAmbientController({FxAmbientMood initialMood = FxAmbientMood.menu})
    : _mood = initialMood,
      _fromColor = initialMood.tint,
      _toColor = initialMood.tint;

  static const Duration transitionDuration =
      GamePresentationTimings.t5AmbientTransition;
  static const Duration pulseDuration = GamePresentationTimings.t5AmbientPulse;
  static const Duration tickDuration = GamePresentationTimings.t5AmbientTick;
  static const Duration starPeriod = GamePresentationTimings.t5StarPeriod;

  final _AmbientRepaint _moodRepaint = _AmbientRepaint();

  FxAmbientMood _mood;
  Color _fromColor;
  Color _toColor;
  double _transitionElapsed = transitionDuration.inMicroseconds.toDouble();
  double _pulseElapsed = pulseDuration.inMicroseconds.toDouble();
  double _elapsed = 0;
  double _tickRemainder = 0;
  int _tickCount = 0;
  bool _motionEnabled = true;
  bool _lifecycleActive = true;
  bool _tickerModeEnabled = true;
  bool _hasAnimatedStars = true;

  FxAmbientMood get mood => _mood;
  Color get moodColor => Color.lerp(_fromColor, _toColor, moodProgress)!;
  Color get moodTargetColor => _toColor;
  double get moodTintStrength =>
      !motionEnabled && mood == FxAmbientMood.menu ? 0 : 0.10;
  double get moodProgress =>
      (transitionDuration.inMicroseconds == 0
              ? 1.0
              : _transitionElapsed / transitionDuration.inMicroseconds)
          .clamp(0.0, 1.0)
          .toDouble();
  double get pulseValue {
    if (_pulseElapsed >= pulseDuration.inMicroseconds) return 0;
    final remaining =
        1 - _pulseElapsed / pulseDuration.inMicroseconds.toDouble();
    return remaining.clamp(0.0, 1.0);
  }

  double get pulseStrength => pulseValue == 0 ? 0 : _pulseStrength;
  double get elapsed => _elapsed;
  int get tickCount => _tickCount;
  bool get motionEnabled => _motionEnabled;
  bool get lifecycleActive => _lifecycleActive;
  bool get tickerModeEnabled => _tickerModeEnabled;
  bool get hasAnimatedStars => _hasAnimatedStars;
  bool get motionAllowed =>
      _motionEnabled && _lifecycleActive && _tickerModeEnabled;
  bool get shouldAnimate =>
      motionAllowed && (_hasAnimatedStars || isTransitioning || pulseValue > 0);
  bool get isTransitioning => moodProgress < 1;

  /// 배경 gradient만 다시 그릴 때 쓰는 별도 listenable이다.
  Listenable get moodRepaint => _moodRepaint;

  void setMood(FxAmbientMood mood) {
    if (mood == _mood) return;
    _mood = mood;
    if (!motionAllowed) {
      _fromColor = mood.tint;
      _toColor = mood.tint;
      _transitionElapsed = transitionDuration.inMicroseconds.toDouble();
    } else {
      _fromColor = moodColor;
      _toColor = mood.tint;
      _transitionElapsed = 0;
    }
    _moodRepaint.ping();
    notifyListeners();
  }

  /// 큰 점수·보상 순간에만 짧게 밝기를 올린다.
  void pulse(double strength) {
    if (!motionAllowed) return;
    final next = strength.clamp(0.0, 1.5).toDouble();
    if (next <= 0) return;
    _pulseElapsed = 0;
    _pulseStrength = math.max(_pulseStrength, next);
    notifyListeners();
  }

  double _pulseStrength = 0;

  /// [seconds]만큼 진행한다. 실제 프레임 알림은 T5 tick 간격으로 제한한다.
  @visibleForTesting
  void advance(double seconds) {
    if (!shouldAnimate || seconds <= 0) return;
    final dt = seconds.clamp(0.0, 1.0).toDouble();
    final wasTransitioning = isTransitioning;
    _elapsed += dt;
    _transitionElapsed = math.min(
      transitionDuration.inMicroseconds.toDouble(),
      _transitionElapsed + dt * 1e6,
    );
    _pulseElapsed = math.min(
      pulseDuration.inMicroseconds.toDouble(),
      _pulseElapsed + dt * 1e6,
    );
    if (_pulseElapsed >= pulseDuration.inMicroseconds) _pulseStrength = 0;
    _tickRemainder += dt;
    final tickSeconds = tickDuration.inMicroseconds / 1e6;
    var ticked = false;
    while (_tickRemainder >= tickSeconds) {
      _tickRemainder -= tickSeconds;
      _tickCount++;
      ticked = true;
    }
    if (wasTransitioning) _moodRepaint.ping();
    if (ticked) notifyListeners();
  }

  /// 별 레이어가 없을 때의 유휴 상태를 테스트한다.
  void setHasAnimatedStars(bool value) {
    if (_hasAnimatedStars == value) return;
    _hasAnimatedStars = value;
    notifyListeners();
  }

  void setMotionEnabled(bool value) {
    if (_motionEnabled == value) return;
    _motionEnabled = value;
    if (!value) {
      _fromColor = _toColor;
      _transitionElapsed = transitionDuration.inMicroseconds.toDouble();
      _pulseElapsed = pulseDuration.inMicroseconds.toDouble();
      _pulseStrength = 0;
    }
    _moodRepaint.ping();
    notifyListeners();
  }

  void setLifecycleActive(bool value) {
    if (_lifecycleActive == value) return;
    _lifecycleActive = value;
    notifyListeners();
  }

  void setTickerModeEnabled(bool value) {
    if (_tickerModeEnabled == value) return;
    _tickerModeEnabled = value;
    notifyListeners();
  }

  @visibleForTesting
  void debugReset() {
    _mood = FxAmbientMood.menu;
    _fromColor = FxAmbientMood.menu.tint;
    _toColor = FxAmbientMood.menu.tint;
    _transitionElapsed = transitionDuration.inMicroseconds.toDouble();
    _pulseElapsed = pulseDuration.inMicroseconds.toDouble();
    _pulseStrength = 0;
    _elapsed = 0;
    _tickRemainder = 0;
    _tickCount = 0;
    _motionEnabled = true;
    _lifecycleActive = true;
    _tickerModeEnabled = true;
    _hasAnimatedStars = true;
    _moodRepaint.ping();
    notifyListeners();
  }

  @override
  void dispose() {
    _moodRepaint.dispose();
    super.dispose();
  }
}

/// 화면에서 직접 호출하는 분위기 API.
class FxAmbient {
  FxAmbient._();

  static final FxAmbientController controller = FxAmbientController();

  static void setMood(FxAmbientMood mood) => controller.setMood(mood);

  /// build 중에도 안전하도록 첫 프레임 뒤에 mood를 바꾼다. 화면 진입에서 쓴다.
  static void setMoodAfterFrame(FxAmbientMood mood) =>
      WidgetsBinding.instance.addPostFrameCallback((_) => setMood(mood));

  static void pulse(double strength) => controller.pulse(strength);

  @visibleForTesting
  static void debugReset() => controller.debugReset();
}

class _AmbientRepaint extends ChangeNotifier {
  void ping() => notifyListeners();
}

extension on FxAmbientMood {
  Color get tint => switch (this) {
    FxAmbientMood.battle => GameUiPalette.actionInfoBlue,
    FxAmbientMood.market => GameUiPalette.actionSuccess,
    FxAmbientMood.boss => GameUiPalette.specialDanger,
    FxAmbientMood.reward => GameUiPalette.actionGoldBright,
    FxAmbientMood.menu => GameUiPalette.starBlue,
  };
}

/// [FxAmbientController]를 별도 테스트 위젯 없이 직접 구동할 수 있는 작은 ticker.
class FxAmbientTicker {
  FxAmbientTicker({required this.controller}) {
    controller.addListener(_sync);
  }

  final FxAmbientController controller;
  Timer? _timer;

  void attach() => _sync();

  void _sync() {
    if (controller.shouldAnimate) {
      if (_timer != null) return;
      _timer = Timer.periodic(
        FxAmbientController.tickDuration,
        (_) => controller.advance(
          FxAmbientController.tickDuration.inMicroseconds / 1e6,
        ),
      );
    } else {
      _timer?.cancel();
      _timer = null;
    }
  }

  void dispose() {
    controller.removeListener(_sync);
    _timer?.cancel();
    _timer = null;
  }
}

/// 별 하나의 고정 데이터. 모든 화면 크기에서 같은 정규화 좌표를 쓴다.
@immutable
class FxAmbientStar {
  const FxAmbientStar({
    required this.nx,
    required this.ny,
    required this.radius,
    required this.alpha,
    required this.phase,
    required this.color,
    required this.glow,
  });

  final double nx;
  final double ny;
  final double radius;
  final double alpha;
  final double phase;
  final Color color;
  final bool glow;
}

List<FxAmbientStar> createFxAmbientStars() {
  final random = math.Random(42);
  return List<FxAmbientStar>.generate(100, (index) {
    final nx = random.nextDouble();
    final ny = random.nextDouble();
    final radius = random.nextDouble() * 1.6 + 0.3;
    final alpha = random.nextDouble() * 0.5 + 0.3;
    final roll = random.nextDouble();
    final color = roll < .7
        ? GameUiPalette.textPrimary
        : roll < .85
        ? GameUiPalette.starBlue
        : roll < .95
        ? GameUiPalette.starWarm
        : GameUiPalette.starRed;
    return FxAmbientStar(
      nx: nx,
      ny: ny,
      radius: radius,
      alpha: alpha,
      phase: index * 2.399963,
      color: color,
      glow: radius > 1.2,
    );
  });
}

extension FxAmbientControllerTwinkle on FxAmbientController {
  double starTwinkle(double phase) {
    if (!motionEnabled || !hasAnimatedStars) return 1;
    final cycle = elapsed / FxAmbientController.starPeriod.inMicroseconds * 1e6;
    return 0.72 + 0.28 * math.sin(cycle * math.pi * 2 + phase);
  }
}
