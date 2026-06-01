part of 'game_shop_screen.dart';

class _MarketTileFace extends StatelessWidget {
  const _MarketTileFace({required this.tile, required this.selected});

  final Tile tile;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox.square(
        key: const ValueKey('market-tile-face-frame'),
        dimension: kMarketOfferCardWidth,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            SizedBox.square(
              key: const ValueKey('market-tile-face'),
              dimension: kMarketOfferCardWidth - 8,
              child: GameRummiTileCard(
                tile: tile,
                selected: false,
                accent: false,
              ),
            ),
            if (selected)
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    key: const ValueKey('market-tile-selector'),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(
                        (kMarketOfferCardWidth - 8) * 0.11,
                      ),
                      border: Border.all(
                        color: GameUiPalette.userSelection,
                        width: kJesterSelectionBorderWidth,
                      ),
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

class _MarketItemCardFace extends StatelessWidget {
  const _MarketItemCardFace({
    required this.label,
    required this.placement,
    required this.rarity,
    required this.selected,
    this.imageAssetPath,
  });

  final String label;
  final ItemPlacement placement;
  final ItemRarity rarity;
  final bool selected;
  final String? imageAssetPath;

  @override
  Widget build(BuildContext context) {
    final accent = _itemOfferAccent(placement);
    final rarityColor = gameItemRarityColor(rarity);
    return Container(
      key: const ValueKey('market-item-card-face'),
      decoration: BoxDecoration(
        color: GameUiPalette.cardFace,
        borderRadius: BorderRadius.circular(kRuntimeCardInnerRadius),
        border: Border.all(
          color: selected
              ? GameUiPalette.userSelection
              : rarityColor.withValues(alpha: 0.78),
          width: selected ? 1.5 : 1.1,
        ),
        boxShadow: [
          BoxShadow(
            color: (selected ? GameUiPalette.userSelection : accent).withValues(
              alpha: selected ? 0.26 : 0.12,
            ),
            blurRadius: selected ? 10 : 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(3.5, 3, 3.5, 3.5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: kRuntimeCardBarHeight,
                    decoration: BoxDecoration(
                      gradient: gameCardRarityBarGradient(rarityColor),
                      borderRadius: BorderRadius.circular(
                        kRuntimeCardSmallRadius,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: GameUiPalette.textPrimary.withValues(
                            alpha: 0.18,
                          ),
                          blurRadius: 0,
                          spreadRadius: 0.4,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 2),
                _MarketCardTypeBadge(
                  label: _itemPlacementBadge(placement),
                  gradient: _itemPlacementBadgeGradient(placement),
                ),
              ],
            ),
            const SizedBox(height: 2.5),
            _MarketCardEmblemImage(assetPath: imageAssetPath),
            const SizedBox(height: 2.5),
            Expanded(
              child: Align(
                alignment: Alignment.topCenter,
                child: _MarketRuntimeCardNameText(
                  label,
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

class _MarketSynergyChip extends StatelessWidget {
  const _MarketSynergyChip({required this.label, required this.dense});

  final String label;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? 3 : 5,
        vertical: dense ? 1 : 2,
      ),
      decoration: BoxDecoration(
        color: GameUiPalette.actionGoldBright.withValues(
          alpha: dense ? 0.18 : 0.16,
        ),
        borderRadius: BorderRadius.circular(dense ? 4 : 5),
        border: Border.all(
          color: GameUiPalette.actionGoldBright.withValues(alpha: 0.42),
          width: 1,
        ),
      ),
      child: Text(
        label,
        maxLines: null,
        softWrap: true,
        style: TextStyle(
          color: GameUiPalette.actionGoldText,
          fontSize: dense ? 7 : 9,
          fontWeight: FontWeight.w900,
          height: 1.0,
        ),
      ),
    );
  }
}

class _MarketCardEmblemImage extends StatelessWidget {
  const _MarketCardEmblemImage({this.assetPath});

  final String? assetPath;

  @override
  Widget build(BuildContext context) {
    final path = assetPath;
    return RepaintBoundary(
      child: Center(
        child: Container(
          width: 47,
          height: kRuntimeCardArtHeight,
          padding: const EdgeInsets.all(1.5),
          decoration: BoxDecoration(
            color: GameUiPalette.cardArtSurface,
            borderRadius: BorderRadius.circular(kRuntimeCardArtRadius),
            border: Border.all(
              color: GameUiPalette.cardArtBorder.withValues(alpha: 0.28),
              width: 0.8,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(kRuntimeCardArtRadius - 2),
            child: path == null
                ? const SizedBox.expand()
                : Image.asset(
                    path,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.high,
                    gaplessPlayback: true,
                    frameBuilder:
                        (context, child, frame, wasSynchronouslyLoaded) {
                          if (wasSynchronouslyLoaded || frame != null) {
                            return child;
                          }
                          return const _MarketCardEmblemFallback();
                        },
                    errorBuilder: (_, _, _) =>
                        const _MarketCardEmblemFallback(),
                  ),
          ),
        ),
      ),
    );
  }
}

class _MarketCardEmblemFallback extends StatelessWidget {
  const _MarketCardEmblemFallback();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Icon(
        Icons.auto_awesome_rounded,
        size: 16,
        color: GameUiPalette.cardFallback.withValues(alpha: 0.48),
      ),
    );
  }
}

class _MarketCardTypeBadge extends StatelessWidget {
  const _MarketCardTypeBadge({required this.label, required this.gradient});

  final String label;
  final LinearGradient gradient;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: kRuntimeCardTypeBadgeWidth,
      height: kRuntimeCardTypeBadgeHeight,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(kRuntimeCardSmallRadius),
        boxShadow: [
          BoxShadow(
            color: GameUiPalette.textPrimary.withValues(alpha: 0.34),
            blurRadius: 0,
            spreadRadius: 0.35,
          ),
        ],
      ),
      child: Text(
        label,
        maxLines: 1,
        style: TextStyle(
          color: GameUiPalette.cardBadgeText,
          fontSize: 3.5,
          fontWeight: FontWeight.w900,
          height: 1,
        ),
      ),
    );
  }
}

class _MarketRuntimeCardNameText extends StatelessWidget {
  const _MarketRuntimeCardNameText(this.text, {required this.style});

  final String text;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      maxLines: 2,
      softWrap: true,
      overflow: TextOverflow.visible,
      textAlign: TextAlign.center,
      style: style,
    );
  }
}

class _MarketSelectableCardFrame extends StatelessWidget {
  const _MarketSelectableCardFrame({
    required this.selected,
    required this.width,
    required this.height,
    required this.child,
  });

  final bool selected;
  final double width;
  final double height;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(
          child: Padding(
            padding: const EdgeInsets.all(kMarketCardSelectionInset),
            child: SizedBox(width: width, height: height, child: child),
          ),
        ),
        if (selected)
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(kRuntimeCardOuterRadius),
                  border: Border.all(
                    color: GameUiPalette.userSelection,
                    width: kJesterSelectionBorderWidth,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
