part of '../game_view.dart';

class _ItemEffectFeedback {
  const _ItemEffectFeedback({
    required this.title,
    required this.detail,
    this.sourceLabel,
    required this.passive,
  });

  final String title;
  final String detail;
  final String? sourceLabel;
  final bool passive;
}

class _ItemEffectFeedbackToast extends StatelessWidget {
  const _ItemEffectFeedbackToast({super.key, required this.feedback});

  final _ItemEffectFeedback feedback;

  @override
  Widget build(BuildContext context) {
    final accent = feedback.passive
        ? GameUiPalette.marketSourcePassive
        : GameUiPalette.actionGold;
    return Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: 16,
              top: -12,
              child: _ItemEffectSparkBurst(accent: accent),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                color: GameUiPalette.surfaceDark.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: accent.withValues(alpha: 0.75),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: accent.withValues(alpha: 0.22),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                  BoxShadow(
                    color: GameUiPalette.ink.withValues(alpha: 0.28),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Icon(
                      feedback.passive
                          ? Icons.shield_rounded
                          : Icons.bolt_rounded,
                      color: accent,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (feedback.sourceLabel != null) ...[
                            DecoratedBox(
                              key: const ValueKey('item-effect-source-label'),
                              decoration: BoxDecoration(
                                color: accent.withValues(alpha: 0.16),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: accent.withValues(alpha: 0.52),
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                child: Text(
                                  feedback.sourceLabel!,
                                  style: TextStyle(
                                    color: accent,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                    height: 1,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            _ItemEffectSourceToResultTrail(accent: accent),
                            const SizedBox(height: 4),
                          ],
                          Text(
                            feedback.title,
                            maxLines: 1,
                            style: const TextStyle(
                              color: GameUiPalette.textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              height: 1,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            feedback.detail,
                            key: const ValueKey('item-effect-result-label'),
                            maxLines: 1,
                            style: TextStyle(
                              color: accent,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              height: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (feedback.passive)
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: accent.withValues(alpha: 0.35),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 5,
                          ),
                          child: Text(
                            '패시브',
                            style: TextStyle(
                              color: accent,
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              height: 1,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        )
        .animate()
        .fadeIn(
          duration: GamePresentationTimings.itemEffectToastIn,
          curve: Curves.easeOutCubic,
        )
        .slideY(
          begin: 0.12,
          end: 0,
          duration: GamePresentationTimings.itemEffectToastIn,
          curve: Curves.easeOutCubic,
        );
  }
}

class _ItemEffectSparkBurst extends StatelessWidget {
  const _ItemEffectSparkBurst({required this.accent});

  final Color accent;

  static const List<Offset> _targets = [
    Offset(-14, -10),
    Offset(2, -18),
    Offset(18, -8),
    Offset(24, 8),
    Offset(-8, 12),
  ];

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      key: const ValueKey('item-effect-spark-burst'),
      tween: Tween<double>(begin: 0, end: 1),
      duration: GamePresentationTimings.itemEffectSparkBurst,
      curve: Curves.easeOutCubic,
      builder: (context, value, _) {
        final opacity = value < 0.7 ? 1.0 : (1 - value) / 0.3;
        return SizedBox(
          width: 52,
          height: 42,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              for (var i = 0; i < _targets.length; i++)
                Positioned(
                  left: 22 + _targets[i].dx * value,
                  top:
                      18 +
                      _targets[i].dy * value -
                      math.sin(value * math.pi) * 4,
                  child: Opacity(
                    opacity: opacity.clamp(0.0, 1.0),
                    child: Transform.rotate(
                      angle: value * math.pi * (i.isEven ? 0.35 : -0.3),
                      child: _ItemEffectSpark(accent: accent),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _ItemEffectSpark extends StatelessWidget {
  const _ItemEffectSpark({required this.accent});

  final Color accent;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: accent,
        borderRadius: BorderRadius.circular(3),
        boxShadow: [
          BoxShadow(color: accent.withValues(alpha: 0.32), blurRadius: 7),
        ],
      ),
      child: const SizedBox(width: 4, height: 10),
    );
  }
}

class _ItemEffectSourceToResultTrail extends StatelessWidget {
  const _ItemEffectSourceToResultTrail({required this.accent});

  final Color accent;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: const ValueKey('item-effect-source-result-trail'),
      height: 12,
      width: 118,
      child: ClipRect(
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0, end: 1),
          duration: GamePresentationTimings.itemEffectSparkBurst,
          curve: Curves.easeOutCubic,
          builder: (context, value, child) {
            return Stack(
              children: [
                Positioned(
                  left: 0,
                  right: 0,
                  top: 5,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(
                          color: accent.withValues(alpha: 0.34),
                          width: 1.2,
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 8 + (74 * value),
                  top: 0,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(3, (index) {
                      final opacity = (0.34 + (index * 0.22)).clamp(0.0, 1.0);
                      return Padding(
                        padding: const EdgeInsets.only(right: 2),
                        child: Icon(
                          Icons.chevron_right_rounded,
                          size: 12,
                          color: accent.withValues(alpha: opacity),
                        ),
                      );
                    }),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
