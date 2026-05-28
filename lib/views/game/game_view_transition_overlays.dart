part of '../game_view.dart';

class _SettlementToMarketTransitionOverlay extends StatelessWidget {
  const _SettlementToMarketTransitionOverlay({required this.breakdown});

  final RummiCashOutBreakdown breakdown;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: GameUiPalette.ink.withValues(alpha: 0.50),
        ),
        child: Center(
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: 1),
            duration: GamePresentationTimings.settlementToMarketOverlayIn,
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(
                    0,
                    kSettlementToMarketTransitionYOffset * (1 - value),
                  ),
                  child: child,
                ),
              );
            },
            child: Container(
              width: kGameTransitionCardWidth,
              padding: kGameTransitionCardPadding,
              decoration: BoxDecoration(
                color: GameUiPalette.surfaceDark,
                borderRadius: BorderRadius.circular(kGameTransitionCardRadius),
                border: Border.all(
                  color: GameUiPalette.scoringPreview.withValues(alpha: 0.66),
                  width: kGameTransitionCardBorderWidth,
                ),
                boxShadow: [
                  BoxShadow(
                    color: GameUiPalette.ink.withValues(alpha: 0.34),
                    blurRadius: kGameTransitionCardShadowBlur,
                    offset: kGameTransitionCardShadowOffset,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.storefront_rounded,
                    color: GameUiPalette.scoringPreview,
                    size: kGameTransitionIconSize,
                  ),
                  const SizedBox(height: kGameTransitionIconTitleGap),
                  const Text(
                    'Market 준비',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: GameUiPalette.textPrimary,
                      fontSize: kGameTransitionTitleFontSize,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: kGameTransitionTitleBodyGap),
                  Text(
                    '정산 보상 +${breakdown.totalGold} Gold',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: GameUiPalette.textPrimary.withValues(alpha: 0.76),
                      fontSize: kGameTransitionBodyFontSize,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: kGameTransitionBodyProgressGap),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(
                      kGameTransitionProgressRadius,
                    ),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0, end: 1),
                      duration:
                          GamePresentationTimings.settlementToMarketOverlayIn,
                      curve: Curves.easeOutCubic,
                      builder: (context, value, _) {
                        return LinearProgressIndicator(
                          value: value,
                          minHeight: kGameTransitionProgressHeight,
                          backgroundColor: GameUiPalette.textPrimary.withValues(
                            alpha: 0.12,
                          ),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            GameUiPalette.scoringPreview,
                          ),
                        );
                      },
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

class _GamePresentationPauseVeil extends StatelessWidget {
  const _GamePresentationPauseVeil();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: GameUiPalette.ink.withValues(alpha: 0.8),
      child: const Center(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: GameUiPalette.surfacePanel,
            borderRadius: BorderRadius.all(
              Radius.circular(kGamePauseVeilRadius),
            ),
          ),
          child: Padding(
            padding: kGamePauseVeilPadding,
            child: Text(
              '일시정지',
              style: TextStyle(
                color: GameUiPalette.textPrimary,
                fontSize: kGamePauseVeilFontSize,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NextStationTransitionOverlay extends StatelessWidget {
  const _NextStationTransitionOverlay();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: GameUiPalette.ink.withValues(alpha: 0.54),
        ),
        child: Center(
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: 1),
            duration: GamePresentationTimings.nextStationOverlayIn,
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(
                    0,
                    kNextStationTransitionYOffset * (1 - value),
                  ),
                  child: child,
                ),
              );
            },
            child: Container(
              width: kGameTransitionCardCompactWidth,
              padding: kGameTransitionCardPadding,
              decoration: BoxDecoration(
                color: GameUiPalette.surfaceDark,
                borderRadius: BorderRadius.circular(kGameTransitionCardRadius),
                border: Border.all(
                  color: GameUiPalette.scoringPreview.withValues(alpha: 0.65),
                  width: kGameTransitionCardBorderWidth,
                ),
                boxShadow: [
                  BoxShadow(
                    color: GameUiPalette.ink.withValues(alpha: 0.36),
                    blurRadius: kGameTransitionCardShadowBlur,
                    offset: kGameTransitionCardShadowOffset,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.route_rounded,
                    color: GameUiPalette.scoringPreview,
                    size: kGameTransitionIconSize,
                  ),
                  const SizedBox(height: kGameTransitionIconTitleGap),
                  const Text(
                    '다음 Station 준비',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: GameUiPalette.textPrimary,
                      fontSize: kGameTransitionTitleFontSize,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: kGameTransitionTitleBodyGap),
                  Text(
                    'Station Select로 이동',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: GameUiPalette.textPrimary.withValues(alpha: 0.72),
                      fontSize: kGameTransitionBodyFontSize,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: kGameTransitionBodyProgressGap),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(
                      kGameTransitionProgressRadius,
                    ),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0, end: 1),
                      duration: GamePresentationTimings.nextStationOverlayIn,
                      curve: Curves.easeOutCubic,
                      builder: (context, value, _) {
                        return LinearProgressIndicator(
                          value: value,
                          minHeight: kGameTransitionProgressHeight,
                          backgroundColor: GameUiPalette.textPrimary.withValues(
                            alpha: 0.12,
                          ),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            GameUiPalette.scoringPreview,
                          ),
                        );
                      },
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
