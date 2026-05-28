part of 'game_shop_screen.dart';

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
