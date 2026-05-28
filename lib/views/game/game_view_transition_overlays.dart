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
                  offset: Offset(0, 14 * (1 - value)),
                  child: child,
                ),
              );
            },
            child: Container(
              width: 282,
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
              decoration: BoxDecoration(
                color: GameUiPalette.surfaceDark,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: GameUiPalette.scoringPreview.withValues(alpha: 0.66),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: GameUiPalette.ink.withValues(alpha: 0.34),
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.storefront_rounded,
                    color: GameUiPalette.scoringPreview,
                    size: 32,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Market 준비',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: GameUiPalette.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '정산 보상 +${breakdown.totalGold} Gold',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: GameUiPalette.textPrimary.withValues(alpha: 0.76),
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 14),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0, end: 1),
                      duration:
                          GamePresentationTimings.settlementToMarketOverlayIn,
                      curve: Curves.easeOutCubic,
                      builder: (context, value, _) {
                        return LinearProgressIndicator(
                          value: value,
                          minHeight: 5,
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
            borderRadius: BorderRadius.all(Radius.circular(18)),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 22, vertical: 16),
            child: Text(
              '일시정지',
              style: TextStyle(
                color: GameUiPalette.textPrimary,
                fontSize: 18,
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
                  offset: Offset(0, 16 * (1 - value)),
                  child: child,
                ),
              );
            },
            child: Container(
              width: 280,
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
              decoration: BoxDecoration(
                color: GameUiPalette.surfaceDark,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: GameUiPalette.scoringPreview.withValues(alpha: 0.65),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: GameUiPalette.ink.withValues(alpha: 0.36),
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.route_rounded,
                    color: GameUiPalette.scoringPreview,
                    size: 32,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    '다음 Station 준비',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: GameUiPalette.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Station Select로 이동',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: GameUiPalette.textPrimary.withValues(alpha: 0.72),
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 14),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0, end: 1),
                      duration: GamePresentationTimings.nextStationOverlayIn,
                      curve: Curves.easeOutCubic,
                      builder: (context, value, _) {
                        return LinearProgressIndicator(
                          value: value,
                          minHeight: 5,
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
