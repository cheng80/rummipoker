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

class _MarketSectionBox extends StatelessWidget {
  const _MarketSectionBox({
    required this.title,
    required this.child,
    this.trailing,
    this.padding = const EdgeInsets.fromLTRB(8, 6, 8, 6),
  });

  final String? title;
  final String? trailing;
  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: GameUiPalette.textPrimary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: GameUiPalette.textPrimary.withValues(alpha: 0.10),
        ),
      ),
      child: Padding(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title != null || trailing != null) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Row(
                  children: [
                    if (title != null) _MarketSectionTitleBadge(label: title!),
                    const Spacer(),
                    if (trailing != null)
                      Text(
                        trailing!,
                        style: const TextStyle(
                          color: GameUiPalette.actionGoldBright,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
            ],
            child,
          ],
        ),
      ),
    );
  }
}

class _MarketSectionTitleBadge extends StatelessWidget {
  const _MarketSectionTitleBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final background = _marketSectionTitleBackground(label);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: GameUiPalette.marketSectionStroke,
          width: 1.4,
        ),
      ),
      child: Text(
        label,
        maxLines: 1,
        style: const TextStyle(
          color: GameUiPalette.marketSectionTextDark,
          fontSize: 10,
          fontWeight: FontWeight.w900,
          height: 1,
        ),
      ),
    );
  }
}

Color _marketSectionTitleBackground(String label) {
  return switch (label) {
    'Jester Slots' => GameUiPalette.marketSelectedTab,
    'Q-SLT' => _itemOfferSurface(ItemPlacement.quickSlot),
    'PSV' => _itemOfferSurface(ItemPlacement.passiveRack),
    'Tool Slots' => _itemOfferSurface(ItemPlacement.inventory),
    'Gear Slots' => _itemOfferSurface(ItemPlacement.equipped),
    _ => GameUiPalette.marketSelectedTab,
  };
}

class _MarketQuickPassiveSlotsSection extends StatelessWidget {
  const _MarketQuickPassiveSlotsSection({
    required this.slots,
    required this.selectedItemSlotIndex,
    required this.pulsingSlotLabel,
    required this.slotKeyForLabel,
    required this.onTap,
  });

  final List<RummiMarketItemSlotView> slots;
  final int selectedItemSlotIndex;
  final String? pulsingSlotLabel;
  final GlobalKey Function(String slotLabel) slotKeyForLabel;
  final ValueChanged<RummiMarketItemSlotView> onTap;

  @override
  Widget build(BuildContext context) {
    final quickSlots = slots
        .where((slot) => slot.placement == ItemPlacement.quickSlot)
        .toList(growable: false);
    final passiveSlots = slots
        .where((slot) => slot.placement == ItemPlacement.passiveRack)
        .toList(growable: false);
    return _MarketSectionBox(
      title: null,
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: _MarketSlotGroup(
              label: 'Q-SLT',
              slots: quickSlots,
              selectedItemSlotIndex: selectedItemSlotIndex,
              pulsingSlotLabel: pulsingSlotLabel,
              slotKeyForLabel: slotKeyForLabel,
              onTap: onTap,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: _MarketSlotGroup(
              label: 'PSV',
              slots: passiveSlots,
              selectedItemSlotIndex: selectedItemSlotIndex,
              pulsingSlotLabel: pulsingSlotLabel,
              slotKeyForLabel: slotKeyForLabel,
              onTap: onTap,
            ),
          ),
        ],
      ),
    );
  }
}

class _MarketSlotGroup extends StatelessWidget {
  const _MarketSlotGroup({
    required this.label,
    required this.slots,
    required this.selectedItemSlotIndex,
    required this.pulsingSlotLabel,
    required this.slotKeyForLabel,
    required this.onTap,
  });

  final String label;
  final List<RummiMarketItemSlotView> slots;
  final int selectedItemSlotIndex;
  final String? pulsingSlotLabel;
  final GlobalKey Function(String slotLabel) slotKeyForLabel;
  final ValueChanged<RummiMarketItemSlotView> onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _MarketSectionTitleBadge(label: label),
        const SizedBox(height: 5),
        Row(
          children: [
            for (var i = 0; i < slots.length; i++) ...[
              if (i > 0) const SizedBox(width: 8),
              _MarketItemGhostChip(
                key: slotKeyForLabel(slots[i].slotLabel),
                slot: slots[i],
                selected: selectedItemSlotIndex == slots[i].slotIndex,
                pulse:
                    pulsingSlotLabel == slots[i].slotLabel ||
                    slots[i].recentlyUnlocked,
                showUnlockLock: slots[i].recentlyUnlocked,
                onTap: onTap,
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _MarketItemSlotsSection extends StatelessWidget {
  const _MarketItemSlotsSection({
    required this.title,
    required this.slots,
    required this.selectedItemSlotIndex,
    required this.pulsingSlotLabel,
    required this.slotKeyForLabel,
    required this.onTap,
  });

  final String title;
  final List<RummiMarketItemSlotView> slots;
  final int selectedItemSlotIndex;
  final String? pulsingSlotLabel;
  final GlobalKey Function(String slotLabel) slotKeyForLabel;
  final ValueChanged<RummiMarketItemSlotView> onTap;

  @override
  Widget build(BuildContext context) {
    return _MarketSectionBox(
      title: title,
      padding: const EdgeInsets.fromLTRB(14, 6, 14, 6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Row(
          children: [
            for (var i = 0; i < slots.length; i++) ...[
              if (i > 0) const SizedBox(width: 8),
              _MarketItemGhostChip(
                key: slotKeyForLabel(slots[i].slotLabel),
                slot: slots[i],
                selected: selectedItemSlotIndex == slots[i].slotIndex,
                pulse:
                    pulsingSlotLabel == slots[i].slotLabel ||
                    slots[i].recentlyUnlocked,
                showUnlockLock: slots[i].recentlyUnlocked,
                onTap: onTap,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MarketSpeechPanel extends StatelessWidget {
  const _MarketSpeechPanel({
    required this.title,
    required this.subtitle,
    required this.body,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final Widget body;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: GameUiPalette.surfacePanel,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: GameUiPalette.textPrimary.withValues(alpha: 0.10),
        ),
      ),
      child: SizedBox(
        height: kMarketSpeechPanelHeight,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 14, 16, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      style: const TextStyle(
                        color: GameUiPalette.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: 1,
                      style: TextStyle(
                        color: GameUiPalette.textPrimary.withValues(
                          alpha: 0.62,
                        ),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Expanded(child: body),
                  ],
                ),
              ),
              if (trailing != null) ...[const SizedBox(width: 10), trailing!],
            ],
          ),
        ),
      ),
    );
  }
}

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

class _MarketItemGhostChip extends StatelessWidget {
  const _MarketItemGhostChip({
    super.key,
    required this.slot,
    this.selected = false,
    this.pulse = false,
    this.showUnlockLock = false,
    this.onTap,
  });

  final RummiMarketItemSlotView slot;
  final bool selected;
  final bool pulse;
  final bool showUnlockLock;
  final ValueChanged<RummiMarketItemSlotView>? onTap;

  @override
  Widget build(BuildContext context) {
    final locked = slot.locked;
    final displayName = slot.displayName == null
        ? null
        : localizedItemSlotName(context, slot);
    final occupiedCard = displayName == null || slot.item == null
        ? null
        : SizedBox(
            width: kMarketOfferCardWidth + (kMarketCardSelectionInset * 2),
            height: kMarketOfferCardHeight + (kMarketCardSelectionInset * 2),
            child: _MarketSelectableCardFrame(
              selected: selected,
              width: kMarketOfferCardWidth,
              height: kMarketOfferCardHeight,
              child: _MarketItemCardFace(
                label: displayName,
                placement: slot.placement,
                rarity: slot.item!.rarity,
                selected: false,
                imageAssetPath: slot.contentId == null
                    ? null
                    : CardEmblemAssets.item(slot.contentId!),
              ),
            ),
          );
    final previewCard = displayName == null || slot.item == null
        ? null
        : SizedBox(
            width: kMarketOfferCardWidth,
            height: kMarketOfferCardHeight,
            child: _MarketItemCardFace(
              label: displayName,
              placement: slot.placement,
              rarity: slot.item!.rarity,
              selected: false,
              imageAssetPath: slot.contentId == null
                  ? null
                  : CardEmblemAssets.item(slot.contentId!),
            ),
          );
    final emptyCard = SizedBox(
      width: kMarketOfferCardWidth + (kMarketCardSelectionInset * 2),
      height: kMarketOfferCardHeight + (kMarketCardSelectionInset * 2),
      child: _MarketSelectableCardFrame(
        selected: false,
        width: kMarketOfferCardWidth,
        height: kMarketOfferCardHeight,
        child: _MarketEmptyItemSlotFace(slot: slot),
      ),
    );
    final slotBox = SizedBox(
      width: kMarketOwnedCardWidth + 6,
      height: kMarketOwnedCardHeight + 6,
      child: Center(child: occupiedCard ?? emptyCard),
    );
    final child = slot.count > 1 && occupiedCard != null
        ? Stack(
            clipBehavior: Clip.none,
            children: [
              slotBox,
              Positioned(
                right: -1,
                bottom: -1,
                child: _MarketItemCountBadge(count: slot.count),
              ),
            ],
          )
        : slotBox;

    return Expanded(
      child: Center(
        child: GestureDetector(
          key: ValueKey<String>('market-item-slot-${slot.slotLabel}'),
          behavior: HitTestBehavior.opaque,
          onTap: locked || slot.item == null || onTap == null
              ? null
              : () => onTap!(slot),
          onLongPress: occupiedCard == null
              ? null
              : () => _showMarketCardPreview(
                  context,
                  previewCard!,
                  title: displayName!,
                  effectText: localizedItemSlotEffect(context, slot),
                  tags: [
                    slot.slotLabel,
                    'x${slot.count}',
                    ..._itemSynergyTags(slot.item!),
                  ],
                ),
          child: MarketSlotPulse(
            active: pulse,
            showUnlockLock: showUnlockLock,
            child: child,
          ),
        ),
      ),
    );
  }
}

class _MarketItemCountBadge extends StatelessWidget {
  const _MarketItemCountBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: GameUiPalette.surfaceDark.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: GameUiPalette.textPrimary.withValues(alpha: 0.24),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
        child: Text(
          'x$count',
          style: const TextStyle(
            color: GameUiPalette.textPrimary,
            fontSize: 9,
            fontWeight: FontWeight.w900,
            height: 1,
          ),
        ),
      ),
    );
  }
}

class _MarketEmptyItemSlotFace extends StatelessWidget {
  const _MarketEmptyItemSlotFace({required this.slot});

  final RummiMarketItemSlotView slot;

  @override
  Widget build(BuildContext context) {
    final locked = slot.locked;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: GameUiPalette.cardEmptyFace.withValues(
          alpha: locked ? 0.58 : 0.82,
        ),
        borderRadius: BorderRadius.circular(kRuntimeCardInnerRadius),
        border: Border.all(
          color: GameUiPalette.textPrimary.withValues(
            alpha: locked ? 0.12 : 0.18,
          ),
          width: 1.2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              locked ? 'LOCKED' : _itemPlacementCardLabel(slot.placement),
              maxLines: 1,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: GameUiPalette.textPrimary.withValues(
                  alpha: locked ? 0.46 : 0.62,
                ),
                fontSize: 7.4,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.2,
                height: 1,
              ),
            ),
            const Spacer(),
            Center(
              child: Icon(
                locked ? Icons.lock_rounded : Icons.add_box_outlined,
                color: GameUiPalette.textPrimary.withValues(
                  alpha: locked ? 0.36 : 0.28,
                ),
                size: 20,
              ),
            ),
            const SizedBox(height: 4),
            Center(
              child: Text(
                locked
                    ? _lockedItemSlotOrdinal(slot.slotLabel)
                    : slot.slotLabel,
                maxLines: 1,
                style: TextStyle(
                  color: GameUiPalette.textPrimary.withValues(
                    alpha: locked ? 0.48 : 0.42,
                  ),
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  height: 1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
