import 'package:flutter/widgets.dart';

import 'motion_policy.dart';

/// 처음 그려질 때 한 번 들어오는 등장 연출.
///
/// [delay] 뒤 [duration] 동안 [offset](자기 크기 비율)에서 제자리로 오며
/// fade·scale된다. 타이머 없이 한 컨트롤러의 Interval로 지연을 표현해서
/// 테스트의 pending timer가 남지 않는다. 연출 강도 끔이나 동작 줄이기에서는
/// 처음부터 끝 상태로 그린다. [enabled]가 false여도 같다.
class EntranceIn extends StatefulWidget {
  const EntranceIn({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 320),
    this.offset = const Offset(0, 0.12),
    this.scaleFrom = 1,
    this.curve = Curves.easeOutCubic,
    this.enabled = true,
  });

  final Widget child;
  final Duration delay;
  final Duration duration;
  final Offset offset;
  final double scaleFrom;
  final Curve curve;
  final bool enabled;

  @override
  State<EntranceIn> createState() => _EntranceInState();
}

class _EntranceInState extends State<EntranceIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _t;
  late final bool _static;

  @override
  void initState() {
    super.initState();
    final total = widget.delay + widget.duration;
    _controller = AnimationController(vsync: this, duration: total);
    final start = total.inMicroseconds == 0
        ? 0.0
        : widget.delay.inMicroseconds / total.inMicroseconds;
    _t = CurvedAnimation(
      parent: _controller,
      curve: Interval(start, 1, curve: widget.curve),
    );
    _static = !widget.enabled || MotionPolicy.juiceScale <= 0;
    if (_static) {
      _controller.value = 1;
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_static) return widget.child;
    return FadeTransition(
      opacity: _t,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: widget.offset,
          end: Offset.zero,
        ).animate(_t),
        child: widget.scaleFrom == 1
            ? widget.child
            : ScaleTransition(
                scale: Tween<double>(
                  begin: widget.scaleFrom,
                  end: 1,
                ).animate(_t),
                child: widget.child,
              ),
      ),
    );
  }
}
