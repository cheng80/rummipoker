import 'dart:math' as math;

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import 'motion_policy.dart';

/// trauma 기반 화면 흔들림.
///
/// trauma(0~1)는 이벤트마다 더해지고 초당 [decayPerSecond]씩 선형으로 줄어든다.
/// 실제 흔들림 크기는 trauma²이며, 난수 지터 대신 서로 다른 주기의 사인파를 섞는다.
class ScreenShake extends ChangeNotifier {
  ScreenShake();

  static final ScreenShake instance = ScreenShake();

  static const double decayPerSecond = 1.6;

  /// trauma 1일 때 최대 이동량(논리 px).
  static const double maxOffset = 7;

  double _trauma = 0;
  double _time = 0;
  Ticker? _ticker;
  Duration _lastTick = Duration.zero;

  double get trauma => _trauma;

  /// 현재 흔들림 오프셋. 흔들림이 꺼져 있으면 0이다.
  Offset get offset {
    if (_trauma <= 0) return Offset.zero;
    final shake = _trauma * _trauma * maxOffset;
    final t = _time;
    final x = (math.sin(t * 47) + 0.5 * math.sin(t * 83 + 1.3)) / 1.5;
    final y = (math.sin(t * 53 + 0.7) + 0.5 * math.sin(t * 71 + 2.1)) / 1.5;
    return Offset(x * shake, y * shake);
  }

  /// trauma를 더한다. 권장값: 가벼운 타격 0.2, 큰 점수 0.4, 보스 0.6.
  void add(double amount) {
    final scaled = amount * MotionPolicy.shakeScale;
    if (scaled <= 0) return;
    _trauma = math.min(1, _trauma + scaled);
    _ensureTicking();
    notifyListeners();
  }

  /// [dt]초만큼 흔들림을 진행한다. 테스트와 티커가 함께 쓴다.
  @visibleForTesting
  void advance(double dt) {
    _time += dt;
    _trauma = math.max(0, _trauma - decayPerSecond * dt);
    notifyListeners();
  }

  void reset() {
    _trauma = 0;
    _ticker?.stop();
    notifyListeners();
  }

  void _ensureTicking() {
    final ticker = _ticker ??= Ticker(_onTick, debugLabel: 'ScreenShake');
    if (ticker.isActive) return;
    _lastTick = Duration.zero;
    ticker.start();
  }

  void _onTick(Duration elapsed) {
    final dt = (elapsed - _lastTick).inMicroseconds / 1e6;
    _lastTick = elapsed;
    advance(dt);
    if (_trauma <= 0) _ticker?.stop();
  }
}

/// 흔들림을 적용하는 호스트. [PhoneFrame] 안에 하나만 둔다.
class ScreenShakeHost extends StatelessWidget {
  const ScreenShakeHost({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ScreenShake.instance,
      child: child,
      // 순수 이동 Transform은 layer를 만들지 않는다. 트리 모양을 유지하려고 항상 감싼다.
      builder: (context, child) => Transform.translate(
        offset: ScreenShake.instance.offset,
        child: child,
      ),
    );
  }
}
