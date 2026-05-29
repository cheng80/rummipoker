part of 'game_jester_widgets.dart';

class GameJesterEffectBurst extends StatelessWidget {
  const GameJesterEffectBurst({
    super.key,
    required this.effect,
    required this.sourceName,
  });

  final RummiJesterEffectBreakdown effect;
  final String sourceName;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: GamePresentationTimings.settlementEffectBurst,
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        final fade = value < 0.18
            ? value / 0.18
            : value > 0.82
            ? (1 - value) / 0.18
            : 1.0;
        final dy = -6 * value;
        final scale = 0.88 + value * 0.12;
        return Opacity(
          opacity: fade.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, dy),
            child: Transform.scale(scale: scale, child: child),
          ),
        );
      },
      child: Center(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: GameUiPalette.surfaceDark.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(7),
            border: Border.all(
              color: GameUiPalette.actionGoldBright.withValues(alpha: 0.72),
            ),
            boxShadow: [
              BoxShadow(
                color: GameUiPalette.actionGoldBright.withValues(alpha: 0.18),
                blurRadius: 10,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(0, 5, 8, 5),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 3,
                  height: 30,
                  color: GameUiPalette.actionGoldBright,
                ),
                const SizedBox(width: 7),
                Flexible(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _GameOutlinedLabel(
                        sourceName,
                        fillColor: GameUiPalette.textPrimary.withValues(
                          alpha: 0.92,
                        ),
                        strokeColor: GameUiPalette.surfacePanel,
                        fontSize: 7.5,
                        fontWeight: FontWeight.w900,
                      ),
                      const SizedBox(height: 2),
                      _GameOutlinedLabel(
                        jesterEffectBadge(effect),
                        fillColor: GameUiPalette.cardNameWarm,
                        strokeColor: GameUiPalette.surfacePanel,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GameOutlinedLabel extends StatelessWidget {
  const _GameOutlinedLabel(
    this.text, {
    required this.fillColor,
    required this.strokeColor,
    required this.fontSize,
    required this.fontWeight,
  });

  final String text;
  final Color fillColor;
  final Color strokeColor;
  final double fontSize;
  final FontWeight fontWeight;

  @override
  Widget build(BuildContext context) {
    final strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.2
      ..color = strokeColor;

    return Stack(
      children: [
        Text(
          text,
          style: TextStyle(
            foreground: strokePaint,
            fontSize: fontSize,
            fontWeight: fontWeight,
          ),
        ),
        Text(
          text,
          style: TextStyle(
            color: fillColor,
            fontSize: fontSize,
            fontWeight: fontWeight,
            shadows: [
              Shadow(
                color: GameUiPalette.ink.withValues(alpha: 0.35),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
