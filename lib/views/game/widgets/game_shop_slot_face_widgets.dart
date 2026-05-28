part of 'game_shop_screen.dart';

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
