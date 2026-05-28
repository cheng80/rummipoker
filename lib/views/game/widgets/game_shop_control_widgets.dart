part of 'game_shop_screen.dart';

class _MarketTabBar extends StatelessWidget {
  const _MarketTabBar({required this.currentTab, required this.onChanged});

  final _MarketShopTab currentTab;
  final ValueChanged<_MarketShopTab> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: GameChromeButton(
            label: 'Jester / Slots',
            backgroundColor: currentTab == _MarketShopTab.cardsAndQuickSlots
                ? GameUiPalette.actionGold
                : GameUiPalette.marketNeutralButton,
            foregroundColor: currentTab == _MarketShopTab.cardsAndQuickSlots
                ? GameUiPalette.ink
                : GameUiPalette.textPrimary,
            onPressed: () => onChanged(_MarketShopTab.cardsAndQuickSlots),
            height: 30,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: GameChromeButton(
            label: 'Tool / Gear',
            backgroundColor: currentTab == _MarketShopTab.toolsAndGear
                ? GameUiPalette.actionGold
                : GameUiPalette.marketNeutralButton,
            foregroundColor: currentTab == _MarketShopTab.toolsAndGear
                ? GameUiPalette.ink
                : GameUiPalette.textPrimary,
            onPressed: () => onChanged(_MarketShopTab.toolsAndGear),
            height: 30,
          ),
        ),
      ],
    );
  }
}

class _MarketOfferLaneBar extends StatelessWidget {
  const _MarketOfferLaneBar({
    required this.lanes,
    required this.selectedLane,
    required this.onChanged,
  });

  final List<_MarketOfferLane> lanes;
  final _MarketOfferLane selectedLane;
  final ValueChanged<_MarketOfferLane> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      spacing: 6,
      children: [
        for (final lane in lanes)
          Expanded(
            child: GameActionButton(
              label: _offerLaneLabel(lane),
              background: lane == selectedLane
                  ? GameUiPalette.marketSelectedTab
                  : GameUiPalette.marketUnselectedTab,
              foreground: lane == selectedLane
                  ? GameUiPalette.marketTabTextDark
                  : GameUiPalette.textPrimary.withValues(alpha: 0.78),
              compact: true,
              onPressed: () => onChanged(lane),
            ),
          ),
      ],
    );
  }
}

String _rerollButtonLabel(int rerollCost) {
  return rerollCost <= 0 ? '첫 리롤 무료' : '리롤 $rerollCost';
}

String _rerollConfirmActionLabel(int rerollCost) {
  return rerollCost <= 0 ? '무료 리롤' : '리롤';
}

String _rerollConfirmMessage(String laneLabel, int rerollCost) {
  if (rerollCost > 0) return '$laneLabel 후보를 리롤할까요?';
  return '$laneLabel 후보를 리롤할까요?\n상점 입장 보너스로 첫 리롤은 무료입니다.';
}

class _MarketPagerBar extends StatelessWidget {
  const _MarketPagerBar({
    required this.currentPage,
    required this.pageCount,
    required this.onPrev,
    required this.onNext,
    required this.rerollCost,
    required this.feedbackTick,
    required this.bonusLabel,
    required this.onReroll,
  });

  final int currentPage;
  final int pageCount;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final int rerollCost;
  final int feedbackTick;
  final String? bonusLabel;
  final VoidCallback? onReroll;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        GameIconButtonChip(
          icon: Icons.chevron_left_rounded,
          onPressed: currentPage > 0 ? onPrev : null,
          size: 32,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Center(
            child: Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 6,
              runSpacing: 3,
              children: [
                if (bonusLabel != null)
                  _MarketOfferBonusBadge(label: bonusLabel!),
                Text(
                  '${currentPage + 1} / $pageCount',
                  style: TextStyle(
                    color: GameUiPalette.textPrimary.withValues(alpha: 0.72),
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 86,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              GameActionButton(
                label: _rerollButtonLabel(rerollCost),
                background: GameUiPalette.tileChipInlaid,
                compact: true,
                onPressed: onReroll,
              ),
              if (feedbackTick > 0)
                _MarketRerollSuccessFeedback(tick: feedbackTick),
            ],
          ),
        ),
        const SizedBox(width: 8),
        GameIconButtonChip(
          icon: Icons.chevron_right_rounded,
          onPressed: currentPage < pageCount - 1 ? onNext : null,
          size: 32,
        ),
      ],
    );
  }
}

class _MarketOfferBonusBadge extends StatelessWidget {
  const _MarketOfferBonusBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      key: ValueKey<String>('market-offer-bonus-pulse-$label'),
      tween: Tween<double>(begin: 0, end: 1),
      duration: GamePresentationTimings.marketPassiveEffectPulse,
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        final pulse = math.sin(math.pi * value);
        return Transform.scale(
          scale: 1 + (0.08 * pulse),
          child: DecoratedBox(
            key: const ValueKey('market-offer-bonus-lane-flash'),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              boxShadow: [
                BoxShadow(
                  color: GameUiPalette.marketSourceGear.withValues(
                    alpha: 0.34 * pulse,
                  ),
                  blurRadius: 14 * pulse,
                  spreadRadius: 2 * pulse,
                ),
              ],
            ),
            child: child,
          ),
        );
      },
      child: Container(
        key: const ValueKey('market-item-offer-bonus-badge'),
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: GameUiPalette.marketSourceGear.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: GameUiPalette.marketSourceGear.withValues(alpha: 0.72),
          ),
        ),
        child: Text(
          label,
          maxLines: 1,
          style: const TextStyle(
            color: GameUiPalette.specialGoldPale,
            fontSize: 10,
            fontWeight: FontWeight.w900,
            height: 1,
          ),
        ),
      ),
    );
  }
}

class _MarketRerollSuccessFeedback extends StatelessWidget {
  const _MarketRerollSuccessFeedback({required this.tick});

  final int tick;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      key: const ValueKey<String>('market-reroll-success-feedback'),
      child: IgnorePointer(
        child: TweenAnimationBuilder<double>(
          key: ValueKey<String>('market-reroll-success-feedback-$tick'),
          tween: Tween<double>(begin: 0, end: 1),
          duration: GamePresentationTimings.marketRerollSuccess,
          curve: Curves.easeOutCubic,
          builder: (context, value, child) {
            final opacity = (1 - value).clamp(0.0, 1.0);
            final scale = 1.0 + (value * 0.18);
            return Opacity(
              opacity: opacity,
              child: Transform.scale(
                scale: scale,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: GameUiPalette.specialGoldPulse.withValues(
                        alpha: 0.9,
                      ),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: GameUiPalette.specialGoldPulse.withValues(
                          alpha: 0.35,
                        ),
                        blurRadius: 12,
                        spreadRadius: 1,
                      ),
                    ],
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

String _offerLaneLabel(_MarketOfferLane lane) {
  return switch (lane) {
    _MarketOfferLane.jester => 'Jester',
    _MarketOfferLane.tile => 'Tile',
    _MarketOfferLane.quickSlot => 'Q-Slot',
    _MarketOfferLane.passive => 'Passive',
    _MarketOfferLane.tool => 'Tool',
    _MarketOfferLane.gear => 'Gear',
  };
}

String? _offerLaneBonusLabel(
  RummiMarketRuntimeFacade market,
  _MarketOfferLane lane,
) {
  return switch (lane) {
    _MarketOfferLane.jester => market.jesterOfferSlotBonusLabel,
    _MarketOfferLane.tile => null,
    _ => market.itemOfferSlotBonusLabel,
  };
}
