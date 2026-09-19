import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'motion_policy.dart';

/// 찌그러짐 → 감쇠 진동 곡선.
///
/// t=0에서 먼저 살짝 찌그러진 뒤 약 8Hz로 흔들리며 3차 감쇠로 0.4초 안에 멈춘다.
class JuiceCurve {
  JuiceCurve._();

  static const Duration duration = Duration(milliseconds: 400);
  static const double frequencyHz = 8;
  static const double scaleAmplitude = 0.08;
  static const double rotationAmplitude = 0.05;

  /// 누르고 있는 동안의 찌그러짐 배율.
  static const double pressedScale = 0.94;

  static double _decay(double seconds) {
    final remaining = 1 - seconds / (duration.inMicroseconds / 1e6);
    if (remaining <= 0) return 0;
    return remaining * remaining * remaining;
  }

  static double scaleAt(double seconds, double strength) {
    final decay = _decay(seconds);
    if (decay == 0 || strength == 0) return 1;
    return 1 -
        strength *
            scaleAmplitude *
            math.cos(2 * math.pi * frequencyHz * seconds) *
            decay;
  }

  static double rotationAt(double seconds, double strength) {
    final decay = _decay(seconds);
    if (decay == 0 || strength == 0) return 0;
    return strength *
        rotationAmplitude *
        math.sin(2 * math.pi * frequencyHz * seconds) *
        decay;
  }
}

/// [trigger]가 바뀔 때마다 자식에 juice를 준다.
///
/// 세기는 [strength] × 설정 강도이며, OS 동작 줄이기에서는 0이다.
/// [pressed]가 true인 동안에는 살짝 찌그러진 상태를 유지한다.
class Juice extends StatefulWidget {
  const Juice({
    super.key,
    required this.child,
    this.trigger,
    this.strength = 1,
    this.pressed = false,
  });

  final Widget child;
  final Object? trigger;
  final double strength;
  final bool pressed;

  @override
  State<Juice> createState() => _JuiceState();
}

class _JuiceState extends State<Juice> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: JuiceCurve.duration,
    value: 1,
  );
  double _strength = 0;

  @override
  void didUpdateWidget(covariant Juice oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.trigger != oldWidget.trigger) {
      _strength = widget.strength * MotionPolicy.juiceScale;
      if (_strength > 0) _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pressedScale = widget.pressed && MotionPolicy.juiceScale > 0
        ? JuiceCurve.pressedScale
        : 1.0;
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) {
        final seconds =
            _controller.value * JuiceCurve.duration.inMicroseconds / 1e6;
        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..rotateZ(JuiceCurve.rotationAt(seconds, _strength))
            ..scaleByDouble(
              pressedScale * JuiceCurve.scaleAt(seconds, _strength),
              pressedScale * JuiceCurve.scaleAt(seconds, _strength),
              1,
              1,
            ),
          child: child,
        );
      },
    );
  }
}
