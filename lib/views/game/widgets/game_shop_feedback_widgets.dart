part of 'game_shop_screen.dart';

class _MarketEntryMotion extends StatelessWidget {
  const _MarketEntryMotion({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      key: const ValueKey('market-entry-motion'),
      tween: Tween<double>(begin: 0, end: 1),
      duration: GamePresentationTimings.marketEntryIntro,
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        final opacity = (value / 0.72).clamp(0.0, 1.0);
        return Opacity(
          opacity: opacity,
          child: Transform.translate(
            offset: Offset(0, 8 * (1 - value)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

class _MarketTutorialTarget extends StatelessWidget {
  const _MarketTutorialTarget({required this.showcaseKey, required this.child});

  final GlobalKey showcaseKey;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(key: showcaseKey, child: child);
  }
}

class _MarketUseFeedbackToast extends StatelessWidget {
  const _MarketUseFeedbackToast({required this.label, this.deltaLabel});

  final String label;
  final String? deltaLabel;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Align(
        alignment: const Alignment(0, 0.16),
        child: TweenAnimationBuilder<double>(
          key: const ValueKey('market-use-feedback'),
          tween: Tween<double>(begin: 0, end: 1),
          duration: GamePresentationTimings.marketUseFeedbackIn,
          curve: Curves.easeOutCubic,
          builder: (context, value, child) {
            return Opacity(
              opacity: value,
              child: Transform.translate(
                offset: Offset(0, 8 * (1 - value)),
                child: child,
              ),
            );
          },
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: GameUiPalette.cardEmptyFace,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: GameUiPalette.settlementActive.withValues(alpha: 0.72),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: GameUiPalette.ink.withValues(alpha: 0.26),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                spacing: 8,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: GameUiPalette.specialMintPale,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      height: 1,
                    ),
                  ),
                  if (deltaLabel != null)
                    Text(
                      deltaLabel!,
                      style: const TextStyle(
                        color: GameUiPalette.actionGoldBright,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        height: 1,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MarketEffectPresentationToast extends StatelessWidget {
  const _MarketEffectPresentationToast({required this.presentation});

  final _MarketEffectPresentation presentation;

  @override
  Widget build(BuildContext context) {
    final event = presentation.event;
    final accent = _effectAccent(event.sourceKind);
    return IgnorePointer(
      child: Align(
        alignment: const Alignment(0, -0.68),
        child: TweenAnimationBuilder<double>(
          key: ValueKey('market-effect-presentation-${presentation.tick}'),
          tween: Tween<double>(begin: 0, end: 1),
          duration: GamePresentationTimings.marketUseFeedbackIn,
          curve: Curves.easeOutCubic,
          builder: (context, value, child) {
            return Opacity(
              opacity: value,
              child: Transform.translate(
                offset: Offset(0, -8 * (1 - value)),
                child: child,
              ),
            );
          },
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 330),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: GameUiPalette.surfaceToastDark.withValues(alpha: 0.96),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: accent.withValues(alpha: 0.72)),
                boxShadow: [
                  BoxShadow(
                    color: GameUiPalette.ink.withValues(alpha: 0.32),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 9,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.sourceLabel,
                      key: const ValueKey('market-effect-source'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: accent,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            event.target.label,
                            key: const ValueKey('market-effect-target'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: GameUiPalette.textPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              height: 1.1,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.arrow_forward_rounded,
                          color: accent,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          event.resultLabel,
                          key: const ValueKey('market-effect-result'),
                          maxLines: 1,
                          style: TextStyle(
                            color: accent,
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            height: 1.1,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _effectAccent(ItemPresentationSourceKind kind) {
    return switch (kind) {
      ItemPresentationSourceKind.quickSlot => GameUiPalette.actionGold,
      ItemPresentationSourceKind.passive => GameUiPalette.marketSourcePassive,
      ItemPresentationSourceKind.tool => GameUiPalette.marketSourceTool,
      ItemPresentationSourceKind.gear => GameUiPalette.marketSourceGear,
      ItemPresentationSourceKind.jester => GameUiPalette.marketSourceJester,
    };
  }
}
