import 'dart:math' as math;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../logic/rummi_poker_grid/jester_meta.dart';
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
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.scale(scale: 0.9 + (0.1 * value), child: child),
        );
      },
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: GameUiPalette.surfaceDangerDeep.withValues(alpha: 0.96),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: GameUiPalette.specialDangerBright,
            width: 1.1,
          ),
          boxShadow: [
            BoxShadow(
              color: GameUiPalette.ink.withValues(alpha: 0.24),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
          child: Text(
            label,
            maxLines: 1,
            style: const TextStyle(
              color: GameUiPalette.specialDenyText,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
        ),
      ),
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
        return Opacity(
          opacity: opacity.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, -16 * value),
            child: child,
          ),
        );
      },
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: GameUiPalette.specialGoldSurface.withValues(alpha: 0.94),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: GameUiPalette.actionGoldBright, width: 1.1),
          boxShadow: [
            BoxShadow(
              color: GameUiPalette.ink.withValues(alpha: 0.26),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Text(
            '-${spentGold}G',
            style: const TextStyle(
              color: GameUiPalette.specialGoldLabel,
              fontSize: 12,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
        ),
      ),
    );
  }
}

class MarketGoldGainBadge extends StatelessWidget {
  const MarketGoldGainBadge({super.key, required this.gold});

  final int gold;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      key: const ValueKey('market-gold-gain-badge'),
      tween: Tween<double>(begin: 0, end: 1),
      duration: GamePresentationTimings.marketGoldBadge,
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        final opacity = value < 0.72 ? 1.0 : (1 - value) / 0.28;
        return Opacity(
          opacity: opacity.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, -16 * value),
            child: child,
          ),
        );
      },
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: GameUiPalette.specialSuccessSurface.withValues(alpha: 0.94),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: GameUiPalette.settlementActive, width: 1.1),
          boxShadow: [
            BoxShadow(
              color: GameUiPalette.ink.withValues(alpha: 0.26),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Text(
            '+${gold}G',
            style: const TextStyle(
              color: GameUiPalette.actionSuccessText,
              fontSize: 12,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
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
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(kRuntimeCardOuterRadius + 2),
              border: Border.all(
                color: GameUiPalette.actionGoldBright.withValues(
                  alpha: (0.34 + 0.46 * pulse).clamp(0.0, 0.82),
                ),
                width: 1.4 + 1.8 * pulse,
              ),
              boxShadow: [
                BoxShadow(
                  color: GameUiPalette.actionGoldBright.withValues(
                    alpha: 0.42 * pulse,
                  ),
                  blurRadius: 22 * pulse,
                  spreadRadius: 3 * pulse,
                ),
              ],
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
                            child: Opacity(
                              opacity: lockOpacity,
                              child: DecoratedBox(
                                key: const ValueKey('market-slot-unlock-lock'),
                                decoration: BoxDecoration(
                                  color: GameUiPalette.specialToastSurface
                                      .withValues(alpha: 0.88),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: GameUiPalette.actionGoldBright,
                                    width: 1.6,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: GameUiPalette.actionGoldBright
                                          .withValues(alpha: 0.38 * flash),
                                      blurRadius: 16,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: const Padding(
                                  padding: EdgeInsets.all(7),
                                  child: Icon(
                                    Icons.lock_open_rounded,
                                    color: GameUiPalette.actionGoldBright,
                                    size: 24,
                                  ),
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
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, -12 * (1 - value)),
          child: Opacity(opacity: value.clamp(0, 1), child: child),
        );
      },
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: GameUiPalette.specialToastSurface.withValues(alpha: 0.94),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: GameUiPalette.actionGoldBright, width: 1.4),
          boxShadow: [
            BoxShadow(
              color: GameUiPalette.actionGoldBright.withValues(alpha: 0.22),
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
              const Icon(
                Icons.lock_open_rounded,
                color: GameUiPalette.actionGoldBright,
                size: 18,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  labels,
                  key: const ValueKey('market-slot-unlock-label'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: GameUiPalette.textPrimary,
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
  }

  String _slotUnlockLabel(BuildContext context, RummiSlotUnlockKind kind) {
    return switch (kind) {
      RummiSlotUnlockKind.jester => context.tr('marketSlotUnlockJester'),
      RummiSlotUnlockKind.quickSlot => context.tr('marketSlotUnlockQuickItem'),
      RummiSlotUnlockKind.passiveRelic => context.tr('marketSlotUnlockPassive'),
    };
  }
}
