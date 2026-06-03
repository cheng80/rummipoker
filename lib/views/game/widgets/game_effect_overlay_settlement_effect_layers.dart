part of 'game_effect_overlay.dart';

bool _showsSettlementEffectLinePulse(ScoringPresentationStep step) {
  return step == ScoringPresentationStep.jester ||
      step == ScoringPresentationStep.tile ||
      step == ScoringPresentationStep.item;
}

class _SettlementEffectLinePulseLayer extends StatelessWidget {
  const _SettlementEffectLinePulseLayer({
    required this.centers,
    required this.tick,
  });

  final List<Offset> centers;
  final int tick;

  @override
  Widget build(BuildContext context) {
    return Stack(
      key: const ValueKey('settlement-effect-line-pulse-layer'),
      fit: StackFit.expand,
      children: [
        for (var i = 0; i < centers.length; i++)
          _SettlementEffectLinePulseCell(
            key: ValueKey<String>('settlement-effect-line-pulse-$tick-$i'),
            center: centers[i],
            delay: GamePresentationCues.lineConfirmSweep.delayFor(i),
          ),
      ],
    );
  }
}

class _SettlementEffectLinePulseCell extends StatelessWidget {
  const _SettlementEffectLinePulseCell({
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
      duration: GamePresentationTimings.settlementEffectBurst,
      curve: Curves.easeOutCubic,
      builder: (context, rawValue, child) {
        final delayRatio =
            delay.inMilliseconds /
            GamePresentationTimings.settlementEffectBurst.inMilliseconds;
        final value = ((rawValue - delayRatio) / (1 - delayRatio)).clamp(
          0.0,
          1.0,
        );
        final opacity = value < 0.7 ? 1.0 : 1.0 - ((value - 0.7) / 0.3);
        final pulse = value < 0.5 ? value * 2 : (1 - value) * 2;
        return Positioned(
          left: center.dx - 20,
          top: center.dy - 20,
          width: 40,
          height: 40,
          child: Opacity(
            opacity: opacity.clamp(0.0, 1.0),
            child: Transform.scale(
              scale: 0.82 + pulse * 0.2,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: GameUiPalette.settlementEffectSurface.withValues(
                    alpha: 0.14,
                  ),
                  borderRadius: BorderRadius.circular(7),
                  border: Border.all(
                    color: GameUiPalette.settlementActive.withValues(
                      alpha: 0.86,
                    ),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: GameUiPalette.settlementActive.withValues(
                        alpha: 0.28 + pulse * 0.18,
                      ),
                      blurRadius: 14 + pulse * 8,
                      spreadRadius: 1.2 + pulse,
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
