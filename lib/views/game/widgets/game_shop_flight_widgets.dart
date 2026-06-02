part of 'game_shop_screen.dart';

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
            curve: Curves.linear,
            builder: (context, value, child) {
              if (startOffset != null && endOffset != null) {
                final offset = GamePresentationMotion.flightOffset(
                  startOffset,
                  endOffset,
                  value,
                );
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
              final alignment = GamePresentationMotion.flightAlignment(
                start,
                end,
                value,
              );
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
            curve: Curves.linear,
            builder: (context, value, child) {
              if (startOffset != null && endOffset != null) {
                final offset = GamePresentationMotion.flightOffset(
                  startOffset,
                  endOffset,
                  value,
                );
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
                alignment: GamePresentationMotion.flightAlignment(
                  const Alignment(-0.48, -0.10),
                  const Alignment(0.58, -0.84),
                  value,
                ),
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
            curve: Curves.linear,
            builder: (context, value, child) {
              if (startOffset != null && endOffset != null) {
                final offset = GamePresentationMotion.flightOffset(
                  startOffset,
                  endOffset,
                  value,
                );
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
                alignment: GamePresentationMotion.flightAlignment(
                  const Alignment(-0.48, -0.10),
                  flight.goldGain == null
                      ? const Alignment(0, 0.08)
                      : const Alignment(0.58, -0.84),
                  value,
                ),
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
