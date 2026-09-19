import 'dart:math' as math;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../logic/rummi_poker_grid/jester_meta.dart';
import '../../../widgets/fx/fx_sprites.dart';
import '../../../widgets/fx/motion_policy.dart';
import '../game_presentation_timings.dart';
import 'game_card_metrics.dart';
import 'game_market_metrics.dart';
import 'game_ui_palette.dart';

class MarketDenyBadge extends StatelessWidget {
  const MarketDenyBadge({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: GamePresentationTimings.marketDenyBadgeIn,
      curve: Curves.easeOutCubic,
      builder: (context, value, _) {
        return Transform.scale(
          scale: 0.9 + (0.1 * value),
          child: _MarketFeedbackBadgeBox(
            opacity: value,
            surface: GameUiPalette.surfaceDangerDeep.withValues(alpha: 0.96),
            border: GameUiPalette.specialDangerBright,
            shadowAlpha: 0.24,
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
            label: label,
            textColor: GameUiPalette.specialDenyText,
            fontSize: 10,
            maxLines: 1,
          ),
        );
      },
    );
  }
}

class MarketGoldSpendBadge extends StatelessWidget {
  const MarketGoldSpendBadge({super.key, required this.spentGold});

  final int spentGold;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      key: const ValueKey('market-gold-spend-badge'),
      tween: Tween<double>(begin: 0, end: 1),
      duration: GamePresentationTimings.marketGoldBadge,
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        final opacity = value < 0.72 ? 1.0 : (1 - value) / 0.28;
        return Transform.translate(
          offset: Offset(0, -16 * value),
          child: _MarketFeedbackBadgeBox(
            opacity: opacity.clamp(0.0, 1.0),
            surface: GameUiPalette.specialGoldSurface.withValues(alpha: 0.94),
            border: GameUiPalette.actionGoldBright,
            shadowAlpha: 0.26,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            label: '-${spentGold}G',
            textColor: GameUiPalette.specialGoldLabel,
            fontSize: 12,
          ),
        );
      },
    );
  }
}

class MarketGoldGainBadge extends StatelessWidget {
  const MarketGoldGainBadge({super.key, required this.gold, this.opacity = 1});

  final int gold;

  /// 바깥 연출이 곱할 투명도. Opacity로 감싸지 않고 색에 직접 곱한다.
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      key: const ValueKey('market-gold-gain-badge'),
      tween: Tween<double>(begin: 0, end: 1),
      duration: GamePresentationTimings.marketGoldGainBadge,
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        final fade = value < 0.72 ? 1.0 : (1 - value) / 0.28;
        return Transform.translate(
          offset: Offset(0, -16 * value),
          child: _MarketFeedbackBadgeBox(
            opacity: (fade * opacity).clamp(0.0, 1.0),
            surface: GameUiPalette.specialSuccessSurface.withValues(
              alpha: 0.94,
            ),
            border: GameUiPalette.settlementActive,
            shadowAlpha: 0.26,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            label: '+${gold}G',
            textColor: GameUiPalette.actionSuccessText,
            fontSize: 12,
          ),
        );
      },
    );
  }
}

class MarketCoinBurst extends StatelessWidget {
  const MarketCoinBurst({super.key});

  static const List<Offset> _targets = <Offset>[
    Offset(-14, -10),
    Offset(-4, -17),
    Offset(8, -14),
    Offset(15, -4),
  ];

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: SizedBox(
        width: 34,
        height: 30,
        child: TweenAnimationBuilder<double>(
          key: const ValueKey('market-coin-burst'),
          tween: Tween<double>(begin: 0, end: 1),
          duration: GamePresentationTimings.marketGoldBadge,
          curve: Curves.easeOutCubic,
          builder: (context, value, _) {
            final fade = (1 - value).clamp(0.0, 1.0);
            return Stack(
              clipBehavior: Clip.none,
              children: [
                for (final target in _targets)
                  Positioned(
                    left: 15 + target.dx * value,
                    top: 13 + target.dy * value,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: GameUiPalette.actionGoldBright.withValues(
                          alpha: 0.9 * fade,
                        ),
                        border: Border.all(
                          color: GameUiPalette.specialGoldBorder.withValues(
                            alpha: fade,
                          ),
                        ),
                      ),
                      child: const SizedBox.square(dimension: 5),
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

class MarketNewAcquisitionReveal extends StatelessWidget {
  const MarketNewAcquisitionReveal({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Align(
        alignment: const Alignment(0, -0.08),
        child: TweenAnimationBuilder<double>(
          key: const ValueKey('market-new-acquisition-reveal'),
          tween: Tween<double>(begin: 0, end: 1),
          duration: GamePresentationTimings.marketNewReveal,
          curve: Curves.easeOutBack,
          builder: (context, value, _) {
            final fade = (1 - ((value - 0.76) / 0.24)).clamp(0.0, 1.0);
            return Transform.scale(
              scale: 0.82 + (0.18 * value),
              child: FxBoxGlow(
                color: GameUiPalette.actionGoldBright.withValues(
                  alpha: 0.28 * fade,
                ),
                blurRadius: 18,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: GameUiPalette.specialGoldSurface.withValues(
                      alpha: 0.96 * fade,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: GameUiPalette.actionGoldBright.withValues(
                        alpha: fade,
                      ),
                      width: 1.4,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 10,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          context.tr('t3MarketNew'),
                          style: TextStyle(
                            color: GameUiPalette.actionGoldBright.withValues(
                              alpha: fade,
                            ),
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2,
                            height: 1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          label,
                          style: TextStyle(
                            color: GameUiPalette.textPrimary.withValues(
                              alpha: fade,
                            ),
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class MarketDirectionalSwitcher extends StatelessWidget {
  const MarketDirectionalSwitcher({
    super.key,
    required this.direction,
    required this.child,
  });

  final int direction;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final duration = MotionPolicy.reduceMotion || MotionPolicy.juiceScale == 0
        ? Duration.zero
        : GamePresentationTimings.marketDetailSwitch;
    final sign = direction < 0 ? -1.0 : 1.0;
    return AnimatedSwitcher(
      duration: duration,
      layoutBuilder: (currentChild, previousChildren) => Stack(
        alignment: Alignment.topCenter,
        children: <Widget>[
          ...previousChildren.map((child) => IgnorePointer(child: child)),
          currentChild ?? const SizedBox.shrink(),
        ],
      ),
      transitionBuilder: (entry, animation) {
        final offset = Tween<Offset>(
          begin: Offset(sign, 0),
          end: Offset.zero,
        ).animate(animation);
        return ClipRect(
          child: FadeTransition(
            opacity: animation,
            child: SlideTransition(position: offset, child: entry),
          ),
        );
      },
      child: child,
    );
  }
}

/// Market 피드백 배지 공통 골격. 투명도를 색에 곱해 Opacity 합성을 피한다.
class _MarketFeedbackBadgeBox extends StatelessWidget {
  const _MarketFeedbackBadgeBox({
    required this.opacity,
    required this.surface,
    required this.border,
    required this.shadowAlpha,
    required this.padding,
    required this.label,
    required this.textColor,
    required this.fontSize,
    this.maxLines,
  });

  final double opacity;
  final Color surface;
  final Color border;
  final double shadowAlpha;
  final EdgeInsets padding;
  final String label;
  final Color textColor;
  final double fontSize;
  final int? maxLines;

  Color _fade(Color color) => color.withValues(alpha: color.a * opacity);

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: _fade(surface),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _fade(border), width: 1.1),
        boxShadow: [
          BoxShadow(
            color: GameUiPalette.ink.withValues(alpha: shadowAlpha * opacity),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: padding,
        child: Text(
          label,
          maxLines: maxLines,
          style: TextStyle(
            color: _fade(textColor),
            fontSize: fontSize,
            fontWeight: FontWeight.w900,
            height: 1,
          ),
        ),
      ),
    );
  }
}

class MarketSlotPulse extends StatelessWidget {
  const MarketSlotPulse({
    super.key,
    required this.active,
    required this.child,
    this.showUnlockLock = false,
  });

  final bool active;
  final Widget child;
  final bool showUnlockLock;

  @override
  Widget build(BuildContext context) {
    if (!active) return child;
    final duration = showUnlockLock
        ? kMarketSlotUnlockPulseDuration
        : GamePresentationTimings.marketSlotPulse;
    return TweenAnimationBuilder<double>(
      key: const ValueKey('market-slot-pulse'),
      tween: Tween<double>(begin: 0, end: 1),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        final pulse = math.sin(math.pi * value);
        final flash = showUnlockLock ? 1.0 : (1 - value).clamp(0.0, 1.0);
        final lockFadeProgress = ((value - 0.55) / 0.45).clamp(0.0, 1.0);
        final lockOpacity = 1 - lockFadeProgress;
        return Transform.scale(
          scale: 1 + (0.08 * pulse),
          child: FxBoxGlow(
            color: GameUiPalette.actionGoldBright.withValues(
              alpha: 0.42 * pulse,
            ),
            blurRadius: 22 * pulse,
            spreadRadius: 3 * pulse,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(
                  kRuntimeCardOuterRadius + 2,
                ),
                border: Border.all(
                  color: GameUiPalette.actionGoldBright.withValues(
                    alpha: (0.34 + 0.46 * pulse).clamp(0.0, 0.82),
                  ),
                  width: 1.4 + 1.8 * pulse,
                ),
              ),
              child: Stack(
                fit: StackFit.passthrough,
                children: [
                  child!,
                  Positioned.fill(
                    child: IgnorePointer(
                      child: DecoratedBox(
                        key: const ValueKey('market-slot-pulse-flash'),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(
                            kRuntimeCardOuterRadius,
                          ),
                          color: GameUiPalette.actionGoldBright.withValues(
                            alpha: 0.18 * flash,
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (showUnlockLock)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: Center(
                          child: Transform.translate(
                            offset: Offset(0, -10 * value),
                            child: Transform.scale(
                              scale: 1 + 0.38 * value,
                              child: DecoratedBox(
                                key: const ValueKey('market-slot-unlock-lock'),
                                decoration: BoxDecoration(
                                  color: GameUiPalette.specialToastSurface
                                      .withValues(alpha: 0.88 * lockOpacity),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: GameUiPalette.actionGoldBright
                                        .withValues(alpha: lockOpacity),
                                    width: 1.6,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: GameUiPalette.actionGoldBright
                                          .withValues(
                                            alpha: 0.38 * flash * lockOpacity,
                                          ),
                                      blurRadius: 16,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(7),
                                  child: Icon(
                                    Icons.lock_open_rounded,
                                    color: GameUiPalette.actionGoldBright
                                        .withValues(alpha: lockOpacity),
                                    size: 24,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
      child: child,
    );
  }
}

class MarketSlotUnlockBanner extends StatelessWidget {
  const MarketSlotUnlockBanner({super.key, required this.unlocks});

  final Set<RummiSlotUnlockKind> unlocks;

  @override
  Widget build(BuildContext context) {
    final labels = unlocks
        .map((kind) => _slotUnlockLabel(context, kind))
        .join(' · ');
    return TweenAnimationBuilder<double>(
      key: const ValueKey('market-slot-unlock-banner'),
      tween: Tween<double>(begin: 0, end: 1),
      duration: kMarketSlotUnlockBannerIn,
      curve: Curves.easeOutBack,
      builder: (context, value, _) {
        final opacity = value.clamp(0.0, 1.0);
        return Transform.translate(
          offset: Offset(0, -12 * (1 - value)),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: GameUiPalette.specialToastSurface.withValues(
                alpha: 0.94 * opacity,
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: GameUiPalette.actionGoldBright.withValues(
                  alpha: opacity,
                ),
                width: 1.4,
              ),
              boxShadow: [
                BoxShadow(
                  color: GameUiPalette.actionGoldBright.withValues(
                    alpha: 0.22 * opacity,
                  ),
                  blurRadius: 18,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.lock_open_rounded,
                    color: GameUiPalette.actionGoldBright.withValues(
                      alpha: opacity,
                    ),
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      labels,
                      key: const ValueKey('market-slot-unlock-label'),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: GameUiPalette.textPrimary.withValues(
                          alpha: opacity,
                        ),
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        height: 1.1,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _slotUnlockLabel(BuildContext context, RummiSlotUnlockKind kind) {
    return switch (kind) {
      RummiSlotUnlockKind.jester => context.tr('marketSlotUnlockJester'),
      RummiSlotUnlockKind.quickSlot => context.tr('marketSlotUnlockQuickItem'),
      RummiSlotUnlockKind.passiveRelic => context.tr('marketSlotUnlockPassive'),
    };
  }
}
