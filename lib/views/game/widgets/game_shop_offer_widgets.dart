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
      key: ValueKey(
        'market-item-offer-${offer.item.placement.name}-${offer.contentId}-${offer.price}',
      ),
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
      key: ValueKey(
        'market-tile-offer-${offer.slotIndex}-${offer.tile.code}-${offer.price}',
      ),
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
  return '$base ${tileModifierBadgeDescriptionText(tile)}';
}
