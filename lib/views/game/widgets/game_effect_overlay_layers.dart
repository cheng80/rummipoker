part of 'game_effect_overlay.dart';

class _LineConfirmSweepLayer extends StatelessWidget {
  const _LineConfirmSweepLayer({required this.centers, required this.tick});

  final List<Offset> centers;
  final int tick;

  @override
  Widget build(BuildContext context) {
    return Stack(
      key: const ValueKey('line-confirm-sweep-layer'),
      fit: StackFit.expand,
      children: [
        for (var i = 0; i < centers.length; i++)
          _LineConfirmSweepCell(
            key: ValueKey<String>('line-confirm-sweep-$tick-$i'),
            center: centers[i],
            delay: GamePresentationCues.lineConfirmSweep.delayFor(i),
          ),
      ],
    );
  }
}

class _LineConfirmSweepCell extends StatelessWidget {
  const _LineConfirmSweepCell({
    super.key,
    required this.center,
    required this.delay,
  });

  final Offset center;
  final Duration delay;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: GamePresentationCues.lineConfirmSweep.duration,
      curve: Curves.easeOutCubic,
      builder: (context, rawValue, child) {
        final delayRatio =
            delay.inMilliseconds /
            GamePresentationCues.lineConfirmSweep.duration.inMilliseconds;
        final value = ((rawValue - delayRatio) / (1 - delayRatio)).clamp(
          0.0,
          1.0,
        );
        final opacity = value < 0.72 ? 1.0 : 1.0 - ((value - 0.72) / 0.28);
        return Positioned(
          left: center.dx - 18,
          top: center.dy - 18,
          width: 36,
          height: 36,
          child: Opacity(
            opacity: opacity.clamp(0.0, 1.0),
            child: Transform.scale(
              scale: 0.72 + (value * 0.34),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(7),
                  border: Border.all(
                    color: GameUiPalette.actionGoldBright.withValues(
                      alpha: 0.86,
                    ),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: GameUiPalette.actionGoldBright.withValues(
                        alpha: 0.34,
                      ),
                      blurRadius: 14,
                      spreadRadius: 1.2,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ConstraintImpactBadgeLayer extends StatelessWidget {
  const _ConstraintImpactBadgeLayer({
    required this.centers,
    required this.center,
    required this.label,
    required this.tick,
  });

  final List<Offset> centers;
  final Offset center;
  final String label;
  final int tick;

  @override
  Widget build(BuildContext context) {
    return Stack(
      key: const ValueKey('constraint-impact-badge-layer'),
      fit: StackFit.expand,
      children: [
        for (var i = 0; i < centers.length; i++)
          _ConstraintImpactCellFlash(
            key: ValueKey<String>('constraint-impact-cell-$tick-$i'),
            center: centers[i],
            delay: GamePresentationCues.constraintCellFlash.delayFor(i),
          ),
        _ConstraintImpactBadge(
          key: ValueKey<String>('constraint-impact-badge-$tick'),
          center: center,
          label: label,
        ),
      ],
    );
  }
}

class _ConstraintImpactCellFlash extends StatelessWidget {
  const _ConstraintImpactCellFlash({
    super.key,
    required this.center,
    required this.delay,
  });

  final Offset center;
  final Duration delay;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: GamePresentationCues.constraintCellFlash.duration,
      curve: Curves.easeOutCubic,
      builder: (context, rawValue, child) {
        final delayRatio =
            delay.inMilliseconds /
            GamePresentationCues.constraintCellFlash.duration.inMilliseconds;
        final value = ((rawValue - delayRatio) / (1 - delayRatio)).clamp(
          0.0,
          1.0,
        );
        final opacity = value < 0.72 ? 1.0 : 1.0 - ((value - 0.72) / 0.28);
        final scale = 0.72 + value * 0.42;
        return Positioned(
          left: center.dx - 20,
          top: center.dy - 20,
          width: 40,
          height: 40,
          child: Opacity(
            opacity: opacity.clamp(0.0, 1.0),
            child: Transform.scale(
              scale: scale,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: GameUiPalette.specialDangerEffect.withValues(
                    alpha: 0.13,
                  ),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: GameUiPalette.specialDangerEffectBorder.withValues(
                      alpha: 0.9,
                    ),
                    width: 2.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: GameUiPalette.specialDangerEffect.withValues(
                        alpha: 0.34,
                      ),
                      blurRadius: 18,
                      spreadRadius: 1.4,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ConstraintImpactBadge extends StatelessWidget {
  const _ConstraintImpactBadge({
    super.key,
    required this.center,
    required this.label,
  });

  final Offset center;
  final String label;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: GamePresentationTimings.constraintImpactBadge,
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        final opacity = value < 0.84 ? 1.0 : 1.0 - ((value - 0.84) / 0.16);
        final dy = -12 * value;
        final scale = 0.78 + (value * 0.26);
        return Positioned(
          left: center.dx - 42,
          top: center.dy - 25 + dy,
          width: 84,
          height: 38,
          child: Opacity(
            opacity: opacity.clamp(0.0, 1.0),
            child: Transform.scale(
              scale: scale,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: GameUiPalette.surfaceDangerDeep.withValues(
                    alpha: 0.92,
                  ),
                  borderRadius: BorderRadius.circular(7),
                  border: Border.all(
                    color: GameUiPalette.specialDangerEffectBorder.withValues(
                      alpha: 0.95,
                    ),
                    width: 2.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: GameUiPalette.specialDangerEffectBorder.withValues(
                        alpha: 0.35,
                      ),
                      blurRadius: 18,
                      spreadRadius: 1.4,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'BOSS',
                      style: TextStyle(
                        color: GameUiPalette.specialDangerSoft,
                        fontSize: 8,
                        fontWeight: FontWeight.w900,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      label,
                      style: const TextStyle(
                        color: GameUiPalette.specialDangerWarm,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        height: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _LargeScoreBurstBadgeLayer extends StatelessWidget {
  const _LargeScoreBurstBadgeLayer({
    required this.center,
    required this.label,
    required this.tick,
  });

  final Offset center;
  final String label;
  final int tick;

  @override
  Widget build(BuildContext context) {
    return Stack(
      key: const ValueKey('large-score-burst-badge-layer'),
      fit: StackFit.expand,
      children: [
        _LargeScoreBurstBadge(
          key: ValueKey<String>('large-score-burst-badge-$tick'),
          center: center,
          label: label,
        ),
      ],
    );
  }
}

class _LargeScoreBurstBadge extends StatelessWidget {
  const _LargeScoreBurstBadge({
    super.key,
    required this.center,
    required this.label,
  });

  final Offset center;
  final String label;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: GamePresentationTimings.largeScoreBurstBadge,
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        final opacity = value < 0.76 ? 1.0 : 1.0 - ((value - 0.76) / 0.24);
        final dy = -16 * value;
        final scale = 0.78 + (value * 0.32);
        return Positioned(
          left: center.dx - 42,
          top: center.dy - 24 + dy,
          width: 84,
          height: 38,
          child: Opacity(
            opacity: opacity.clamp(0.0, 1.0),
            child: Transform.scale(
              scale: scale,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: GameUiPalette.stationClearSurface.withValues(
                    alpha: 0.94,
                  ),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: GameUiPalette.settlementActive.withValues(
                      alpha: 0.95,
                    ),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: GameUiPalette.settlementActive.withValues(
                        alpha: 0.36,
                      ),
                      blurRadius: 18,
                      spreadRadius: 1.4,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    label,
                    style: const TextStyle(
                      color: GameUiPalette.specialSuccessText,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SettlementScoreMoteLayer extends StatelessWidget {
  const _SettlementScoreMoteLayer({required this.centers, required this.tick});

  final List<Offset> centers;
  final int tick;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      key: const ValueKey('settlement-score-mote-layer'),
      builder: (context, constraints) {
        final target = Offset(
          constraints.maxWidth / 2,
          constraints.maxHeight * 0.12,
        );
        return Stack(
          fit: StackFit.expand,
          children: [
            for (var i = 0; i < centers.length; i++)
              _SettlementScoreMote(
                key: ValueKey<String>('settlement-score-mote-$tick-$i'),
                start: centers[i],
                target: target,
                delay: GamePresentationCues.settlementScoreMote.delayFor(i),
              ),
          ],
        );
      },
    );
  }
}

class _SettlementScoreMote extends StatelessWidget {
  const _SettlementScoreMote({
    super.key,
    required this.start,
    required this.target,
    required this.delay,
  });

  final Offset start;
  final Offset target;
  final Duration delay;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: GamePresentationCues.settlementScoreMote.duration,
      curve: Curves.linear,
      builder: (context, rawValue, child) {
        final delayRatio =
            delay.inMilliseconds /
            GamePresentationCues.settlementScoreMote.duration.inMilliseconds;
        final value = ((rawValue - delayRatio) / (1 - delayRatio)).clamp(
          0.0,
          1.0,
        );
        final position = GamePresentationMotion.flightOffset(
          start,
          target,
          value,
        );
        final opacity = value < 0.82 ? 1.0 : 1.0 - ((value - 0.82) / 0.18);
        final scale = 1.0 - (value * 0.22);
        return Positioned(
          left: position.dx - 4,
          top: position.dy - 4,
          width: 8,
          height: 8,
          child: Opacity(
            opacity: opacity.clamp(0.0, 1.0),
            child: Transform.scale(
              scale: scale,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: GameUiPalette.actionGoldBright.withValues(alpha: 0.9),
                  boxShadow: [
                    BoxShadow(
                      color: GameUiPalette.actionGoldBright.withValues(
                        alpha: 0.42,
                      ),
                      blurRadius: 9,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
