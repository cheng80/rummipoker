import 'dart:async';

/// 연출 순서를 기다리는 단일 시계.
///
/// - pause 중에는 시간이 흐르지 않는다. pause 도중 끝난 조각은 세지 않는다.
/// - [speed] 배율만큼 빨리 흐른다. `double.infinity`면 기다리지 않는다.
/// - [hitStop]은 짧은 정지를 쌓아 두고, 다음 대기에서 먼저 소모한다.
///
/// Flutter 전역 `timeDilation`은 쓰지 않는다. 화면 결과 state는 이 시계에 의존하지 않는다.
class PresentationClock {
  PresentationClock({
    this.tick = const Duration(milliseconds: 50),
    double Function()? speed,
  }) : _speed = speed ?? _unitSpeed;

  static double _unitSpeed() => 1;

  /// 기본 hit-stop 길이.
  static const Duration defaultHitStop = Duration(milliseconds: 80);

  final Duration tick;
  final double Function() _speed;

  bool _paused = false;
  bool _disposed = false;
  Completer<void>? _resume;
  Duration _pendingHitStop = Duration.zero;

  bool get isPaused => _paused;
  double get speed => _speed();
  Duration get pendingHitStop => _pendingHitStop;

  void pause() {
    if (_paused) return;
    _paused = true;
    _resume ??= Completer<void>();
  }

  void resume() {
    if (!_paused) return;
    _paused = false;
    _completeResume();
  }

  /// 60~100ms 정지를 권장한다. 연속 호출은 더 긴 쪽만 남긴다.
  void hitStop([Duration duration = defaultHitStop]) {
    if (duration > _pendingHitStop) _pendingHitStop = duration;
  }

  /// 대기 중인 모든 [delay]를 즉시 끝낸다. 화면 dispose 때 호출한다.
  void dispose() {
    _disposed = true;
    _completeResume();
  }

  void _completeResume() {
    final completer = _resume;
    _resume = null;
    if (completer != null && !completer.isCompleted) completer.complete();
  }

  Future<void> waitWhilePaused() async {
    while (!_disposed && _paused) {
      final completer = _resume;
      if (completer == null) return;
      await completer.future;
    }
  }

  /// 연출 시간 [duration]만큼 기다린다. 실제 대기는 배율·pause·hit-stop을 반영한다.
  Future<void> delay(Duration duration) async {
    var remaining = duration.inMicroseconds.toDouble();
    while (!_disposed && remaining > 0) {
      await waitWhilePaused();
      if (_disposed) return;
      final hitStop = _pendingHitStop;
      final rate = speed;
      if (hitStop == Duration.zero && rate.isInfinite) return;
      final Duration chunk;
      if (hitStop > Duration.zero) {
        chunk = hitStop < tick ? hitStop : tick;
      } else {
        final wall = remaining / rate;
        chunk = wall < tick.inMicroseconds
            ? Duration(microseconds: wall.ceil())
            : tick;
      }
      await Future<void>.delayed(chunk);
      if (_paused) continue;
      if (hitStop > Duration.zero) {
        final left = _pendingHitStop - chunk;
        _pendingHitStop = left > Duration.zero ? left : Duration.zero;
      } else {
        remaining -= chunk.inMicroseconds * rate;
      }
    }
  }
}
