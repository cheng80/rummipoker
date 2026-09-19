part of 'game_jester_widgets.dart';

/// Jester 발동 모션 3종. 카드별 개별 연출 대신 효과 유형으로만 나눈다.
enum GameJesterFireKind {
  /// 칩 가산: 도장 찍듯 내려찍기.
  stamp,

  /// % 가산: 부풀기.
  inflate,

  /// ×N 곱연산: 회전 섬광.
  spin;

  static GameJesterFireKind of(RummiJesterEffectBreakdown effect) {
    if (effect.xmultBonus > 1.0) return spin;
    if (effect.multBonus > 0) return inflate;
    return stamp;
  }
}

/// [effect]가 있으면 [tick]마다 유형별 발동 모션을 한 번 준다. 동작 줄이기에서는 멈춰 있다.
class GameJesterFireMotion extends StatelessWidget {
  const GameJesterFireMotion({
    super.key,
    required this.effect,
    required this.tick,
    required this.child,
  });

  final RummiJesterEffectBreakdown? effect;
  final int tick;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final effect = this.effect;
    final strength = MotionPolicy.juiceScale;
    if (effect == null || strength <= 0) return child;
    final kind = GameJesterFireKind.of(effect);
    return TweenAnimationBuilder<double>(
      key: ValueKey('jester-fire-${kind.name}-${effect.jesterId}-$tick'),
      tween: Tween<double>(begin: 0, end: 1),
      duration: GamePresentationTimings.jesterFireMotion,
      builder: (context, t, child) {
        final wave = sin(pi * t);
        switch (kind) {
          case GameJesterFireKind.stamp:
            // 들어 올렸다가 0.35에서 내려찍고 살짝 눌린 뒤 돌아온다.
            final lift = t < 0.35 ? t / 0.35 : 0.0;
            final squash = t < 0.35
                ? 0.0
                : sin(pi * ((t - 0.35) / 0.65)) * (1 - t);
            return Transform.translate(
              offset: Offset(0, (-10 * lift + 4 * squash) * strength),
              child: Transform.scale(
                scale: 1 + (0.16 * lift - 0.1 * squash) * strength,
                child: child,
              ),
            );
          case GameJesterFireKind.inflate:
            return Transform.scale(
              scale: 1 + 0.22 * wave * strength,
              child: child,
            );
          case GameJesterFireKind.spin:
            return FxBoxGlow(
              color: GameUiPalette.actionGoldBright.withValues(
                alpha: 0.75 * wave,
              ),
              blurRadius: 18 * wave,
              spreadRadius: 3 * wave,
              child: Transform.rotate(
                angle: 2 * pi * Curves.easeOutCubic.transform(t) * strength,
                child: Transform.scale(
                  scale: 1 + 0.12 * wave * strength,
                  child: child,
                ),
              ),
            );
        }
      },
      child: child,
    );
  }
}

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
