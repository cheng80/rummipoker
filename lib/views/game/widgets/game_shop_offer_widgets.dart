part of 'game_shop_screen.dart';

class _MarketOfferRow extends StatelessWidget {
  const _MarketOfferRow({required this.itemCount, required this.children});

  final int itemCount;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) {
      return const SizedBox.shrink();
    }

    final pageWidth =
        kMarketShopCellWidth * kMarketOfferRowPageSlots +
        kMarketOfferRowGap * (kMarketOfferRowPageSlots - 1);
    return Align(
      alignment: Alignment.topCenter,
      child: SizedBox(
        width: pageWidth,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < children.length; i++) ...[
              children[i],
              if (i < children.length - 1)
                const SizedBox(width: kMarketOfferRowGap),
            ],
          ],
        ),
      ),
    );
  }
}

String _offerEntrySignature(
  RummiMarketRuntimeFacade market,
  _MarketOfferEntry entry,
) {
  return switch (entry.kind) {
    _MarketOfferEntryKind.jester =>
      'j:${entry.jesterIndex}:${market.offers[entry.jesterIndex!].contentId}:${market.offers[entry.jesterIndex!].price}',
    _MarketOfferEntryKind.item =>
      'i:${entry.itemIndex}:${market.itemOffers[entry.itemIndex!].contentId}:${market.itemOffers[entry.itemIndex!].price}',
    _MarketOfferEntryKind.tile =>
      't:${entry.tileIndex}:${market.tileOffers[entry.tileIndex!].tile.code}:${market.tileOffers[entry.tileIndex!].price}',
  };
}

class _MarketOfferReveal extends StatefulWidget {
  const _MarketOfferReveal({
    required this.index,
    required this.signature,
    required this.child,
  });

  final int index;
  final String signature;
  final Widget child;

  @override
  State<_MarketOfferReveal> createState() => _MarketOfferRevealState();
}

class _MarketOfferRevealState extends State<_MarketOfferReveal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _offset;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: GamePresentationCues.marketOfferReveal.duration,
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    _offset = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _play();
  }

  @override
  void didUpdateWidget(covariant _MarketOfferReveal oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.signature != widget.signature) {
      _play();
    }
  }

  Future<void> _play() async {
    _controller.value = 0;
    final delay = GamePresentationCues.marketOfferReveal.delayFor(widget.index);
    await Future<void>.delayed(delay);
    if (!mounted) return;
    unawaited(_controller.forward());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      key: ValueKey<String>('market-offer-stagger-${widget.index}'),
      opacity: _fade,
      child: SlideTransition(position: _offset, child: widget.child),
    );
  }
}

String _activeRunSummaryLabel(RummiActiveRunSaveFacade summary) {
  return summary.snapshotSummaryLabel();
}

class _GameShopOfferCard extends StatelessWidget {
  const _GameShopOfferCard({
    required this.offer,
    required this.selected,
    required this.canAfford,
    required this.onTap,
  });

  final RummiMarketOfferView offer;
  final bool selected;
  final bool canAfford;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final card = SizedBox(
      width: kMarketOfferCardWidth + (kMarketCardSelectionInset * 2),
      height: kMarketOfferCardHeight + (kMarketCardSelectionInset * 2),
      child: _MarketSelectableCardFrame(
        selected: selected,
        width: kMarketOfferCardWidth,
        height: kMarketOfferCardHeight,
        child: GameJesterSlot(
          card: offer.card,
          runtimeValueText: null,
          extended: false,
          activeEffect: null,
          settlementSequenceTick: 0,
          selected: false,
        ),
      ),
    );
    final previewCard = SizedBox(
      width: kMarketOfferCardWidth,
      height: kMarketOfferCardHeight,
      child: GameJesterSlot(
        card: offer.card,
        runtimeValueText: null,
        extended: false,
        activeEffect: null,
        settlementSequenceTick: 0,
        selected: false,
      ),
    );
    return GestureDetector(
      onTap: onTap,
      onLongPress: () => _showMarketCardPreview(
        context,
        previewCard,
        title: localizedJesterName(context, offer.card),
        effectText: localizedJesterEffect(context, offer.card),
        tags: _jesterSynergyTags(offer.card),
      ),
      child: SizedBox(
        width: kMarketShopCellWidth,
        height: kMarketShopCellHeight,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _MarketDiscountTargetPulse(
              active: offer.discountSourceLabel != null,
              child: _MarketOfferCardDisplay(child: card),
            ),
            const SizedBox(height: 3),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: _MarketOfferPriceLabel(
                price: offer.price,
                originalPrice: offer.originalPrice,
                isAffordable: canAfford,
                discountSourceLabel: offer.discountSourceLabel,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MarketEmptyOfferCard extends StatelessWidget {
  const _MarketEmptyOfferCard();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: const ValueKey('market-purchase-source-empty'),
      width: kMarketShopCellWidth,
      height: kMarketShopCellHeight,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: kMarketOfferCardDisplayWidth,
            height: kMarketOfferCardDisplayHeight,
            child: FittedBox(
              fit: BoxFit.contain,
              child: SizedBox(
                width: kMarketOfferCardWidth + (kMarketCardSelectionInset * 2),
                height:
                    kMarketOfferCardHeight + (kMarketCardSelectionInset * 2),
                child: Center(
                  child: Container(
                    width: kMarketOfferCardWidth,
                    height: kMarketOfferCardHeight,
                    decoration: BoxDecoration(
                      color: GameUiPalette.ink.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(
                        kRuntimeCardInnerRadius,
                      ),
                      border: Border.all(
                        color: GameUiPalette.textPrimary.withValues(
                          alpha: 0.14,
                        ),
                        width: 1.4,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 3),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}

class _MarketOfferCardDisplay extends StatelessWidget {
  const _MarketOfferCardDisplay({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: kMarketOfferCardDisplayWidth,
      height: kMarketOfferCardDisplayHeight,
      child: FittedBox(fit: BoxFit.contain, child: child),
    );
  }
}

void _showMarketCardPreview(
  BuildContext context,
  Widget card, {
  required String title,
  required String effectText,
  required List<String> tags,
}) {
  showGameFramedDialog<void>(
    context: context,
    semanticLabel: '상점 카드 정보',
    builder: (dialogContext) {
      final previewMaxHeight = math
          .min(MediaQuery.sizeOf(dialogContext).height - 96, 720.0)
          .clamp(520.0, 720.0);
      return GameModalCard(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: previewMaxHeight),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: GameCardNameText(
                        title,
                        textAlign: TextAlign.start,
                        style: const TextStyle(
                          color: GameUiPalette.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      icon: const Icon(Icons.close_rounded),
                      color: GameUiPalette.textPrimary,
                      visualDensity: VisualDensity.compact,
                      tooltip: '닫기',
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Center(
                  child: SizedBox(
                    width: kMarketOfferCardWidth * 3,
                    height: kMarketOfferCardHeight * 3,
                    child: FittedBox(fit: BoxFit.contain, child: card),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  effectText,
                  style: TextStyle(
                    color: GameUiPalette.textPrimary.withValues(alpha: 0.82),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    height: 1.3,
                  ),
                ),
                if (tags.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  _MarketDetailTagWrap(tags: tags),
                ],
              ],
            ),
          ),
        ),
      );
    },
  );
}

class _MarketItemOfferCard extends StatelessWidget {
  const _MarketItemOfferCard({
    required this.offer,
    required this.selected,
    required this.onTap,
  });

  final RummiMarketItemOfferView offer;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final itemName = localizedItemName(context, offer);
    final card = SizedBox(
      width: kMarketOfferCardWidth + (kMarketCardSelectionInset * 2),
      height: kMarketOfferCardHeight + (kMarketCardSelectionInset * 2),
      child: _MarketSelectableCardFrame(
        selected: selected,
        width: kMarketOfferCardWidth,
        height: kMarketOfferCardHeight,
        child: _MarketItemCardFace(
          label: itemName,
          placement: offer.item.placement,
          rarity: offer.item.rarity,
          selected: false,
          imageAssetPath: CardEmblemAssets.item(offer.item.id),
        ),
      ),
    );
    final previewCard = SizedBox(
      width: kMarketOfferCardWidth,
      height: kMarketOfferCardHeight,
      child: _MarketItemCardFace(
        label: itemName,
        placement: offer.item.placement,
        rarity: offer.item.rarity,
        selected: false,
        imageAssetPath: CardEmblemAssets.item(offer.item.id),
      ),
    );
    return GestureDetector(
      onTap: onTap,
      onLongPress: () => _showMarketCardPreview(
        context,
        previewCard,
        title: itemName,
        effectText: localizedItemEffect(context, offer),
        tags: _itemSynergyTags(offer.item),
      ),
      child: SizedBox(
        width: kMarketShopCellWidth,
        height: kMarketShopCellHeight,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _MarketDiscountTargetPulse(
              active: offer.discountSourceLabel != null,
              child: _MarketOfferCardDisplay(child: card),
            ),
            const SizedBox(height: 3),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: _MarketOfferPriceLabel(
                price: offer.price,
                originalPrice: offer.originalPrice,
                isAffordable: offer.isAffordable,
                discountSourceLabel: offer.discountSourceLabel,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MarketDiscountTargetPulse extends StatelessWidget {
  const _MarketDiscountTargetPulse({required this.active, required this.child});

  final bool active;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!active) return child;
    return TweenAnimationBuilder<double>(
      key: const ValueKey('market-discount-offer-pulse'),
      tween: Tween<double>(begin: 0, end: 1),
      duration: GamePresentationTimings.marketPassiveEffectPulse,
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        final pulse = math.sin(math.pi * value);
        return Transform.scale(
          scale: 1 + (0.05 * pulse),
          child: DecoratedBox(
            key: const ValueKey('market-discount-offer-flash'),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(kRuntimeCardOuterRadius),
              border: Border.all(
                color: GameUiPalette.settlementActive.withValues(
                  alpha: 0.24 + (0.52 * pulse),
                ),
                width: 1 + (1.6 * pulse),
              ),
              boxShadow: [
                BoxShadow(
                  color: GameUiPalette.settlementActive.withValues(
                    alpha: 0.24 * pulse,
                  ),
                  blurRadius: 18 * pulse,
                  spreadRadius: 2 * pulse,
                ),
              ],
            ),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

class _MarketOfferPriceLabel extends StatelessWidget {
  const _MarketOfferPriceLabel({
    required this.price,
    required this.originalPrice,
    required this.isAffordable,
    this.discountSourceLabel,
  });

  final int price;
  final int originalPrice;
  final bool isAffordable;
  final String? discountSourceLabel;

  @override
  Widget build(BuildContext context) {
    final priceColor = isAffordable
        ? GameUiPalette.actionGoldBright
        : GameUiPalette.textPrimary.withValues(alpha: 0.38);
    if (originalPrice <= price) {
      return Text(
        '${price}G',
        maxLines: 1,
        style: TextStyle(
          color: priceColor,
          fontSize: 10,
          fontWeight: FontWeight.w900,
          height: 1.0,
        ),
      );
    }

    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 3,
        children: [
          Text(
            '${originalPrice}G',
            maxLines: 1,
            style: TextStyle(
              color: GameUiPalette.textPrimary.withValues(alpha: 0.45),
              fontSize: 8,
              fontWeight: FontWeight.w800,
              height: 1.0,
              decoration: TextDecoration.lineThrough,
              decorationColor: GameUiPalette.textPrimary.withValues(
                alpha: 0.55,
              ),
            ),
          ),
          Text(
            '${price}G',
            maxLines: 1,
            style: TextStyle(
              color: priceColor,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              height: 1.0,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
            decoration: BoxDecoration(
              color: GameUiPalette.tileChipInlaid,
              borderRadius: BorderRadius.circular(3),
            ),
            child: Text(
              discountSourceLabel ?? '할인',
              maxLines: 1,
              style: const TextStyle(
                color: GameUiPalette.textPrimary,
                fontSize: 7,
                fontWeight: FontWeight.w900,
                height: 1.0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MarketTileOfferCard extends StatelessWidget {
  const _MarketTileOfferCard({
    required this.offer,
    required this.selected,
    required this.onTap,
  });

  final RummiMarketTileOfferView offer;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: kMarketShopCellWidth,
        height: kMarketShopCellHeight,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: kMarketOfferCardDisplayWidth,
              height: kMarketOfferCardDisplayHeight,
              child: FittedBox(
                fit: BoxFit.contain,
                child: SizedBox(
                  width:
                      kMarketOfferCardWidth + (kMarketCardSelectionInset * 2),
                  height:
                      kMarketOfferCardHeight + (kMarketCardSelectionInset * 2),
                  child: _MarketTileFace(tile: offer.tile, selected: selected),
                ),
              ),
            ),
            const SizedBox(height: 3),
            Text(
              _tileOfferCompactLabel(offer),
              maxLines: 1,
              style: TextStyle(
                color: offer.isAffordable
                    ? GameUiPalette.actionGoldBright
                    : GameUiPalette.textPrimary.withValues(alpha: 0.38),
                fontSize: 10,
                fontWeight: FontWeight.w900,
                height: 1.0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _tileLabel(Tile tile) => '${tile.color.code}${tile.number}';

String _tileOfferCompactLabel(RummiMarketTileOfferView offer) {
  final price = offer.isFreeReward ? '무료' : '${offer.price}G';
  if (!offer.tile.hasModifier) {
    return '칩 ${offer.tile.baseChipValue} · $price';
  }
  final modifier = offer.tile.enhancement != null
      ? tileEnhancementDisplayName(offer.tile.enhancement!)
      : tileSealDisplayName(offer.tile.seal!);
  return '$modifier · $price';
}

String _tileOfferDetailText(Tile tile) {
  const base = '다음 블라인드부터 드로우 덱에 추가됩니다.';
  if (!tile.hasModifier) return base;
  return '$base ${tileModifierEffectText(tile)}';
}

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
            Text(
              _itemPlacementCardLabel(placement),
              maxLines: 1,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: GameUiPalette.cardName.withValues(alpha: 0.72),
                fontSize: 3.5,
                fontWeight: FontWeight.w800,
                height: 1,
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
    return Center(
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
                  errorBuilder: (_, _, _) => const _MarketCardEmblemFallback(),
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

class _MarketPurchaseFlightOverlay extends StatelessWidget {
  const _MarketPurchaseFlightOverlay({required this.flight});

  final _MarketPurchaseFlight flight;

  @override
  Widget build(BuildContext context) {
    final start = flight.startAlignment;
    final end = flight.endAlignment;
    final startOffset = flight.startOffset;
    final endOffset = flight.endOffset;
    return IgnorePointer(
      child: Stack(
        children: [
          if (flight.spentGold > 0)
            Positioned(
              top: 16,
              right: 42,
              child: MarketGoldSpendBadge(spentGold: flight.spentGold),
            ),
          TweenAnimationBuilder<double>(
            key: ValueKey<int>(flight.tick),
            tween: Tween<double>(begin: 0, end: 1),
            duration: kMarketPurchaseFlightDuration,
            curve: Curves.easeInOutCubic,
            builder: (context, value, child) {
              if (startOffset != null && endOffset != null) {
                final offset = Offset.lerp(startOffset, endOffset, value)!;
                return Positioned(
                  left:
                      offset.dx -
                      ((kMarketOfferCardWidth + kMarketCardSelectionInset * 2) /
                          2),
                  top:
                      offset.dy -
                      ((kMarketOfferCardHeight +
                              kMarketCardSelectionInset * 2) /
                          2),
                  child: child!,
                );
              }
              final alignment = Alignment.lerp(start, end, value)!;
              return Align(alignment: alignment, child: child);
            },
            child: _MarketPurchaseFlightCard(flight: flight),
          ),
        ],
      ),
    );
  }
}

class _MarketPurchaseFlightCard extends StatelessWidget {
  const _MarketPurchaseFlightCard({required this.flight});

  final _MarketPurchaseFlight flight;

  @override
  Widget build(BuildContext context) {
    final tile = flight.tile;
    if (tile != null) {
      return SizedBox(
        key: const ValueKey('market-purchase-flight'),
        width: kMarketOfferCardWidth + (kMarketCardSelectionInset * 2),
        height: kMarketOfferCardHeight + (kMarketCardSelectionInset * 2),
        child: _MarketTileFace(tile: tile, selected: true),
      );
    }

    final face = _purchaseFlightFace();
    return SizedBox(
      key: const ValueKey('market-purchase-flight'),
      width: kMarketOfferCardWidth + (kMarketCardSelectionInset * 2),
      height: kMarketOfferCardHeight + (kMarketCardSelectionInset * 2),
      child: KeyedSubtree(
        key: const ValueKey('market-purchase-flight-frame'),
        child: _MarketSelectableCardFrame(
          selected: true,
          width: kMarketOfferCardWidth,
          height: kMarketOfferCardHeight,
          child: face,
        ),
      ),
    );
  }

  Widget _purchaseFlightFace() {
    final jesterCard = flight.jesterCard;
    if (!flight.item && jesterCard != null) {
      return GameJesterSlot(
        card: jesterCard,
        runtimeValueText: null,
        extended: false,
        activeEffect: null,
        settlementSequenceTick: 0,
        selected: false,
      );
    }

    final placement = flight.itemPlacement;
    final rarity = flight.itemRarity;
    if (flight.item && placement != null && rarity != null) {
      return _MarketItemCardFace(
        label: flight.label,
        placement: placement,
        rarity: rarity,
        selected: true,
        imageAssetPath: flight.itemId == null
            ? null
            : CardEmblemAssets.item(flight.itemId!),
      );
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: GameUiPalette.specialGoldCard,
        borderRadius: BorderRadius.circular(kRuntimeCardInnerRadius),
        border: Border.all(color: GameUiPalette.actionGoldBright, width: 1.2),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: GameCardNameText(
            flight.label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: GameUiPalette.specialGoldCardText,
              fontSize: 9,
              fontWeight: FontWeight.w900,
              height: 1.05,
            ),
          ),
        ),
      ),
    );
  }
}

class _MarketSaleFlightOverlay extends StatelessWidget {
  const _MarketSaleFlightOverlay({required this.flight});

  final _MarketSaleFlight flight;

  @override
  Widget build(BuildContext context) {
    final startOffset = flight.startOffset;
    final endOffset = flight.endOffset;
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            top: 16,
            right: 42,
            child: MarketGoldGainBadge(gold: flight.sellGold),
          ),
          TweenAnimationBuilder<double>(
            key: ValueKey<int>(flight.tick),
            tween: Tween<double>(begin: 0, end: 1),
            duration: kMarketPurchaseFlightDuration,
            curve: Curves.easeInOutCubic,
            builder: (context, value, child) {
              if (startOffset != null && endOffset != null) {
                final offset = Offset.lerp(startOffset, endOffset, value)!;
                return Positioned(
                  left:
                      offset.dx -
                      ((kMarketOfferCardWidth + kMarketCardSelectionInset * 2) /
                          2),
                  top:
                      offset.dy -
                      ((kMarketOfferCardHeight +
                              kMarketCardSelectionInset * 2) /
                          2),
                  child: child!,
                );
              }
              return Align(
                alignment: Alignment.lerp(
                  const Alignment(-0.48, -0.10),
                  const Alignment(0.58, -0.84),
                  value,
                )!,
                child: child,
              );
            },
            child: _MarketSaleFlightCard(flight: flight),
          ),
        ],
      ),
    );
  }
}

class _MarketSaleFlightCard extends StatelessWidget {
  const _MarketSaleFlightCard({required this.flight});

  final _MarketSaleFlight flight;

  @override
  Widget build(BuildContext context) {
    final jesterCard = flight.jesterCard;
    if (!flight.item && jesterCard != null) {
      return SizedBox(
        key: const ValueKey('market-sale-flight'),
        width: kMarketOfferCardWidth + (kMarketCardSelectionInset * 2),
        height: kMarketOfferCardHeight + (kMarketCardSelectionInset * 2),
        child: KeyedSubtree(
          key: const ValueKey('market-sale-flight-jester-card'),
          child: _MarketSelectableCardFrame(
            selected: true,
            width: kMarketOfferCardWidth,
            height: kMarketOfferCardHeight,
            child: GameJesterSlot(
              card: jesterCard,
              runtimeValueText: null,
              extended: false,
              activeEffect: null,
              settlementSequenceTick: 0,
              selected: false,
            ),
          ),
        ),
      );
    }
    final placement = flight.itemPlacement;
    final rarity = flight.itemRarity;
    if (placement == null || rarity == null) {
      return const SizedBox.shrink();
    }
    return SizedBox(
      key: const ValueKey('market-sale-flight'),
      width: kMarketOfferCardWidth + (kMarketCardSelectionInset * 2),
      height: kMarketOfferCardHeight + (kMarketCardSelectionInset * 2),
      child: _MarketSelectableCardFrame(
        selected: true,
        width: kMarketOfferCardWidth,
        height: kMarketOfferCardHeight,
        child: _MarketItemCardFace(
          label: flight.label,
          placement: placement,
          rarity: rarity,
          selected: true,
          imageAssetPath: flight.itemId == null
              ? null
              : CardEmblemAssets.item(flight.itemId!),
        ),
      ),
    );
  }
}

class _MarketItemUseFlightOverlay extends StatelessWidget {
  const _MarketItemUseFlightOverlay({required this.flight});

  final _MarketItemUseFlight flight;

  @override
  Widget build(BuildContext context) {
    final startOffset = flight.startOffset;
    final endOffset = flight.endOffset;
    return IgnorePointer(
      child: Stack(
        children: [
          if (flight.goldGain != null)
            Positioned(
              top: 16,
              right: 42,
              child: MarketGoldGainBadge(gold: flight.goldGain!),
            ),
          TweenAnimationBuilder<double>(
            key: ValueKey<int>(flight.tick),
            tween: Tween<double>(begin: 0, end: 1),
            duration: kMarketPurchaseFlightDuration,
            curve: Curves.easeInOutCubic,
            builder: (context, value, child) {
              if (startOffset != null && endOffset != null) {
                final offset = Offset.lerp(startOffset, endOffset, value)!;
                return Positioned(
                  left:
                      offset.dx -
                      ((kMarketOfferCardWidth + kMarketCardSelectionInset * 2) /
                          2),
                  top:
                      offset.dy -
                      ((kMarketOfferCardHeight +
                              kMarketCardSelectionInset * 2) /
                          2),
                  child: child!,
                );
              }
              return Align(
                alignment: Alignment.lerp(
                  const Alignment(-0.48, -0.10),
                  flight.goldGain == null
                      ? const Alignment(0, 0.08)
                      : const Alignment(0.58, -0.84),
                  value,
                )!,
                child: child,
              );
            },
            child: _MarketItemUseFlightCard(flight: flight),
          ),
        ],
      ),
    );
  }
}

class _MarketItemUseFlightCard extends StatelessWidget {
  const _MarketItemUseFlightCard({required this.flight});

  final _MarketItemUseFlight flight;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: const ValueKey('market-item-use-flight'),
      width: kMarketOfferCardWidth + (kMarketCardSelectionInset * 2),
      height: kMarketOfferCardHeight + (kMarketCardSelectionInset * 2),
      child: _MarketSelectableCardFrame(
        selected: true,
        width: kMarketOfferCardWidth,
        height: kMarketOfferCardHeight,
        child: _MarketItemCardFace(
          label: flight.label,
          placement: flight.itemPlacement,
          rarity: flight.itemRarity,
          selected: true,
          imageAssetPath: CardEmblemAssets.item(flight.itemId),
        ),
      ),
    );
  }
}

class _MarketGoldChip extends StatelessWidget {
  const _MarketGoldChip({required this.gold});

  final int gold;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 118,
      height: 48,
      child: GameHudChip(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'GOLD',
              style: gameHudLabelStyle,
              maxLines: 1,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 1),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Semantics(
                    label: 'Gold',
                    value: '$gold',
                    child: ExcludeSemantics(
                      child: Image.asset(
                        AssetPaths.uiGreed,
                        width: 20,
                        height: 20,
                        fit: BoxFit.contain,
                        errorBuilder: (_, _, _) =>
                            const _MarketGoldFallbackIcon(size: 20),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '$gold',
                      maxLines: 1,
                      textAlign: TextAlign.right,
                      style: gameHudValueStyle.copyWith(fontSize: 20),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MarketGoldFallbackIcon extends StatelessWidget {
  const _MarketGoldFallbackIcon({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: GameUiPalette.actionGoldBright,
      ),
      child: Text(
        'G',
        style: TextStyle(
          fontFamily: AssetPaths.fontNexonLv2Gothic,
          fontSize: size * 0.58,
          fontWeight: FontWeight.w900,
          color: GameUiPalette.surfaceDeepGreen,
          height: 1,
        ),
      ),
    );
  }
}
