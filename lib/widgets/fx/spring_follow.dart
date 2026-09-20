import 'dart:math' as math;

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import 'motion_policy.dart';

/// 목표를 지수적으로 따라간다. [rate]가 클수록 빨리 붙는다(1/초).
double springFollowStep(
  double current,
  double target,
  double rate,
  double dtSeconds,
) => target + (current - target) * math.exp(-rate * dtSeconds);

/// 고정 시간 트윈 대신 목표 위치·스케일·회전을 축마다 다른 계수로 추종한다.
///
/// 목표가 바뀌면 현재 값에서 부드럽게 따라가고, 수렴하면 티커를 멈춘다.
/// OS 동작 줄이기에서는 목표로 바로 붙는다.
class SpringFollow extends StatefulWidget {
  const SpringFollow({
    super.key,
    required this.child,
    this.offset = Offset.zero,
    this.scale = 1,
    this.rotation = 0,
    this.positionRate = 18,
    this.scaleRate = 22,
    this.rotationRate = 14,
  });

  final Widget child;
  final Offset offset;
  final double scale;
  final double rotation;
  final double positionRate;
  final double scaleRate;
  final double rotationRate;

  @override
  State<SpringFollow> createState() => _SpringFollowState();
}

class _SpringFollowState extends State<SpringFollow>
    with SingleTickerProviderStateMixin {
  static const double _epsilon = 0.001;

  late final Ticker _ticker;
  late double _dx = widget.offset.dx;
  late double _dy = widget.offset.dy;
  late double _scale = widget.scale;
  late double _rotation = widget.rotation;
  Duration _last = Duration.zero;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick);
  }

  @override
  void didUpdateWidget(covariant SpringFollow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (MotionPolicy.reduceMotion) {
      _snap();
      return;
    }
    if (!_converged && !_ticker.isActive) {
      _last = Duration.zero;
      _ticker.start();
    }
  }

  bool get _converged =>
      (_dx - widget.offset.dx).abs() < _epsilon &&
      (_dy - widget.offset.dy).abs() < _epsilon &&
      (_scale - widget.scale).abs() < _epsilon &&
      (_rotation - widget.rotation).abs() < _epsilon;

  void _snap() {
    _dx = widget.offset.dx;
    _dy = widget.offset.dy;
    _scale = widget.scale;
    _rotation = widget.rotation;
    if (_ticker.isActive) _ticker.stop();
  }

  void _onTick(Duration elapsed) {
    final dt = (elapsed - _last).inMicroseconds / 1e6;
    _last = elapsed;
    setState(() {
      _dx = springFollowStep(_dx, widget.offset.dx, widget.positionRate, dt);
      _dy = springFollowStep(_dy, widget.offset.dy, widget.positionRate, dt);
      _scale = springFollowStep(_scale, widget.scale, widget.scaleRate, dt);
      _rotation = springFollowStep(
        _rotation,
        widget.rotation,
        widget.rotationRate,
        dt,
      );
      if (_converged) _snap();
    });
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.translationValues(_dx, _dy, 0)
        ..rotateZ(_rotation)
        ..scaleByDouble(_scale, _scale, 1, 1),
      child: widget.child,
    );
  }
}
