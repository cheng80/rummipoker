part of 'game_shared_widgets.dart';

class _GameBattleItemCardFace extends StatelessWidget {
  const _GameBattleItemCardFace({
    required this.itemSlot,
    required this.itemName,
  });

  final RummiBattleItemSlotView itemSlot;
  final String itemName;

  @override
  Widget build(BuildContext context) {
    final rarityColor = gameItemRarityColor(itemSlot.item.rarity);
    return DecoratedBox(
      key: ValueKey('battle-item-card-${itemSlot.contentId}'),
      decoration: BoxDecoration(
        color: GameUiPalette.cardFace,
        borderRadius: BorderRadius.circular(kRuntimeCardOuterRadius),
        border: Border.all(
          color: rarityColor.withValues(alpha: 0.9),
          width: 1.2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(3.5, 3, 3.5, 3.5),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: kRuntimeCardBarHeight,
                    decoration: BoxDecoration(
                      gradient: gameItemRarityBarGradient(rarityColor),
                      borderRadius: BorderRadius.circular(
                        kRuntimeCardSmallRadius,
                      ),
                      border: Border.all(
                        color: GameUiPalette.textPrimary.withValues(alpha: 0.2),
                        width: 0.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 3),
                _GameBattleItemTypeBadge(placement: itemSlot.placement),
              ],
            ),
            const SizedBox(height: 2.5),
            RepaintBoundary(
              child: Container(
                width: kRuntimeCardArtWidth,
                height: kBattleRuntimeCardArtHeight,
                padding: const EdgeInsets.all(2.5),
                decoration: BoxDecoration(
                  color: GameUiPalette.cardArtSurfaceDeep,
                  borderRadius: BorderRadius.circular(kRuntimeCardArtRadius),
                  border: Border.all(
                    color: GameUiPalette.textPrimary.withValues(alpha: 0.12),
                    width: 0.8,
                  ),
                ),
                child: Image.asset(
                  CardEmblemAssets.item(itemSlot.contentId),
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                  gaplessPlayback: true,
                  frameBuilder:
                      (context, child, frame, wasSynchronouslyLoaded) {
                        if (wasSynchronouslyLoaded || frame != null) {
                          return child;
                        }
                        return _GameBattleItemEmblemFallback(
                          color: rarityColor,
                        );
                      },
                  errorBuilder: (context, error, stackTrace) =>
                      _GameBattleItemEmblemFallback(color: rarityColor),
                ),
              ),
            ),
            const SizedBox(height: 3),
            Expanded(
              child: Align(
                alignment: Alignment.topCenter,
                child: GameCardNameText(
                  itemName,
                  maxLines: 2,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: GameUiPalette.cardName,
                    fontSize: 5,
                    fontWeight: FontWeight.w900,
                    height: 1.12,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GameBattleItemEmblemFallback extends StatelessWidget {
  const _GameBattleItemEmblemFallback({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Icon(
        Icons.auto_awesome_rounded,
        size: 14,
        color: color.withValues(alpha: 0.72),
      ),
    );
  }
}

class _GameBattleEmptyItemSlotFace extends StatelessWidget {
  const _GameBattleEmptyItemSlotFace({
    required this.label,
    required this.locked,
  });

  final String label;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: GameUiPalette.cardEmptyFace.withValues(
          alpha: locked ? 0.58 : 0.82,
        ),
        borderRadius: BorderRadius.circular(kRuntimeCardOuterRadius),
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
              locked ? 'LOCKED' : _battleEmptyItemTypeText(label),
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
                locked ? _battleLockedSlotOrdinal(label) : label,
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

String _battleEmptyItemTypeText(String label) {
  return switch (label.isEmpty ? null : label[0]) {
    'Q' => 'Q-SLOT',
    'P' => 'PASSIVE',
    'T' => 'TOOL',
    'G' => 'GEAR',
    _ => label,
  };
}

String _battleLockedSlotOrdinal(String label) {
  final match = RegExp(r'\d+').firstMatch(label);
  final value = match == null ? null : int.tryParse(match.group(0)!);
  return switch (value) {
    1 => '1st',
    2 => '2nd',
    3 => '3rd',
    4 => '4th',
    5 => '5th',
    _ => label,
  };
}

class _GameBattleItemTypeBadge extends StatelessWidget {
  const _GameBattleItemTypeBadge({required this.placement});

  final ItemPlacement placement;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: kRuntimeCardTypeBadgeWidth,
      height: kRuntimeCardTypeBadgeHeight,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: _battleItemTypeBadgeGradient(placement),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: GameUiPalette.textPrimary.withValues(alpha: 0.5),
          width: 0.7,
        ),
      ),
      child: Text(
        _battleItemTypeBadgeText(placement),
        style: const TextStyle(
          color: GameUiPalette.textPrimary,
          fontSize: 3.8,
          fontWeight: FontWeight.w900,
          height: 1,
        ),
      ),
    );
  }
}

LinearGradient _battleItemTypeBadgeGradient(ItemPlacement placement) {
  final colors = switch (placement) {
    ItemPlacement.quickSlot => (
      GameUiPalette.itemBadgeQuickTop,
      GameUiPalette.itemBadgeQuickBottom,
    ),
    ItemPlacement.inventory => (
      GameUiPalette.itemBadgeToolTop,
      GameUiPalette.itemBadgeToolBottom,
    ),
    ItemPlacement.equipped => (
      GameUiPalette.itemBadgeGearTop,
      GameUiPalette.itemBadgeGearBottom,
    ),
    ItemPlacement.passiveRack => (
      GameUiPalette.itemBadgePassiveTop,
      GameUiPalette.itemBadgePassiveBottom,
    ),
  };
  return LinearGradient(colors: [colors.$1, colors.$2]);
}

String _battleItemTypeBadgeText(ItemPlacement placement) {
  return switch (placement) {
    ItemPlacement.quickSlot => 'Q',
    ItemPlacement.inventory => 'T',
    ItemPlacement.equipped => 'G',
    ItemPlacement.passiveRack => 'P',
  };
}
