part of 'game_shop_screen.dart';

extension _GameShopPurchaseFlow on _GameShopScreenState {
  Future<void> _reroll() async {
    final lane = _currentOfferLane;
    final laneLabel = _offerLaneLabel(lane);
    final rerollQuote = _rerollCostQuoteForLane(_market, lane);
    final hadCurrentLaneOfferSelection = switch (lane) {
      _MarketOfferLane.jester => _selectedOfferIndex != null,
      _MarketOfferLane.tile => _selectedTileOfferIndex >= 0,
      _ => _selectedItemOfferIndex >= 0,
    };
    final confirmed = await showGameFramedDialog<bool>(
      context: context,
      builder: (dialogContext) => GameModalCard(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              '리롤 확인',
              style: TextStyle(
                color: GameUiPalette.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _rerollConfirmMessage(laneLabel, rerollQuote),
              style: const TextStyle(
                color: GameUiPalette.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w700,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: GameActionButton(
                    label: '취소',
                    background: GameUiPalette.disabledControl,
                    onPressed: () => Navigator.of(dialogContext).pop(false),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GameActionButton(
                    label: _rerollConfirmActionLabel(rerollQuote),
                    background: GameUiPalette.actionGold,
                    foreground: GameUiPalette.ink,
                    onPressed: () => Navigator.of(dialogContext).pop(true),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
    if (!mounted || confirmed != true) return;

    final placement = _placementForOfferLane(lane);
    if (placement != null && widget.onRerollItemOffers == null) return;
    if (lane == _MarketOfferLane.tile && widget.onRerollTileOffers == null) {
      return;
    }
    final effectPresentation = _marketRerollPresentation(_market, lane);
    final failMessage = lane == _MarketOfferLane.tile
        ? widget.onRerollTileOffers!()
        : placement == null
        ? widget.onReroll()
        : widget.onRerollItemOffers!(placement);
    if (failMessage != null) {
      showBottomNotice(context, failMessage);
      return;
    }
    _mutate(() {
      if (placement != null) {
        _pinnedItemOffers = null;
      }
      final market = _market;
      _marketRerollFeedbackTick++;
      _clampOfferPageForLane(market, lane);
      _clearMarketSelection();
      if (hadCurrentLaneOfferSelection) {
        _selectFirstEntry(_offerEntriesForLane(market, lane));
      }
    });
    if (effectPresentation != null) {
      _startEffectPresentation(effectPresentation);
    }
    await widget.onStateChanged();
  }

  void _buySelected() {
    final index = _selectedOfferIndex;
    if (index == null) return;
    final offers = _market.offers;
    if (index < 0 || index >= offers.length) return;
    final marketBeforePurchase = _market;
    final boughtOffer = offers[index];
    final flightLabel = localizedJesterName(context, boughtOffer.card);
    final sourceEntry = _MarketOfferEntry.jester(index);
    final sourceIndex = _visibleOfferLaneIndex(sourceEntry);
    final sourceCount = _visibleOfferLaneCount();
    final startOffset = _flightCenterForKey(_offerKey(sourceEntry));
    final effectPresentation = _marketPurchasePresentation(
      market: _market,
      category: 'jester',
      targetLabel: flightLabel,
      discountSourceLabel: boughtOffer.discountSourceLabel,
    );
    final failMessage = widget.onBuyOffer(boughtOffer);
    if (failMessage != null) {
      _startMarketDenyFeedback('jester-buy', failMessage);
      showBottomNotice(context, failMessage);
      return;
    }
    _mutate(() {
      final market = _market;
      _clampOfferPageForLane(market, _MarketOfferLane.jester);
      final purchasedSlot = _findPurchasedJesterSlot(market, boughtOffer);
      if (purchasedSlot != null) {
        final endOffset = _flightCenterForKey(
          _jesterSlotKey(purchasedSlot.slotIndex),
        );
        _shopTab = _MarketShopTab.cardsAndQuickSlots;
        _selectedOwnedIndex = purchasedSlot.slotIndex;
        _selectedOfferIndex = null;
        _selectedItemOfferIndex = -1;
        _selectedItemSlotIndex = -1;
        _startPurchaseFlight(
          label: flightLabel,
          slotLabel: 'J${purchasedSlot.slotIndex + 1}',
          item: false,
          spentGold: _spentGoldForPurchase(
            before: marketBeforePurchase,
            after: market,
            fallback: boughtOffer.price,
          ),
          startAlignment: _offerFlightStartAlignment(sourceIndex, sourceCount),
          endAlignment: _jesterSlotFlightEndAlignment(purchasedSlot.slotIndex),
          marketBeforePurchase: marketBeforePurchase,
          sourceVisibleIndex: sourceIndex,
          startOffset: startOffset,
          endOffset: endOffset,
          jesterCard: boughtOffer.card,
        );
      } else if (market.ownedEntries.isNotEmpty) {
        _selectedOwnedIndex = market.ownedEntries.length - 1;
        _selectedOfferIndex = null;
      } else {
        _selectedOfferIndex = market.offers.isEmpty ? null : 0;
      }
    });
    if (effectPresentation != null) {
      _startEffectPresentation(effectPresentation);
    }
    _queueStateSave();
  }

  void _buySelectedItem() {
    final offers = _market.itemOffers;
    final index = _selectedItemOfferIndex;
    if (index < 0 || index >= offers.length) return;
    final marketBeforePurchase = _market;
    final boughtOffer = offers[index];
    final flightLabel = localizedItemName(context, boughtOffer);
    final sourceEntry = _MarketOfferEntry.item(index);
    final sourceIndex = _visibleOfferLaneIndex(sourceEntry);
    final sourceCount = _visibleOfferLaneCount();
    final startOffset = _flightCenterForKey(_offerKey(sourceEntry));
    final effectPresentation = _marketPurchasePresentation(
      market: _market,
      category: 'item',
      targetLabel: flightLabel,
      discountSourceLabel: boughtOffer.discountSourceLabel,
    );
    final failMessage = widget.onBuyItemOffer(boughtOffer);
    if (failMessage != null) {
      _startMarketDenyFeedback('item-buy', failMessage);
      showBottomNotice(context, failMessage);
      return;
    }
    _mutate(() {
      _pinnedItemOffers = null;
      final market = _market;
      _clampOfferPageForLane(market, _currentOfferLane);
      final purchasedSlot = _findPurchasedItemSlot(market, boughtOffer);
      if (purchasedSlot != null) {
        final endOffset = _flightCenterForKey(
          _itemSlotKey(purchasedSlot.slotLabel),
        );
        _shopTab = switch (purchasedSlot.placement) {
          ItemPlacement.quickSlot ||
          ItemPlacement.passiveRack => _MarketShopTab.cardsAndQuickSlots,
          ItemPlacement.inventory ||
          ItemPlacement.equipped => _MarketShopTab.toolsAndGear,
        };
        _setOfferLaneForPlacement(purchasedSlot.placement);
        _selectedItemSlotIndex = purchasedSlot.slotIndex;
        _selectedItemOfferIndex = -1;
        _selectedOfferIndex = null;
        _selectedOwnedIndex = null;
        _startPurchaseFlight(
          label: flightLabel,
          slotLabel: purchasedSlot.slotLabel,
          item: true,
          spentGold: _spentGoldForPurchase(
            before: marketBeforePurchase,
            after: market,
            fallback: boughtOffer.price,
          ),
          startAlignment: _offerFlightStartAlignment(sourceIndex, sourceCount),
          endAlignment: _itemSlotFlightEndAlignment(purchasedSlot),
          marketBeforePurchase: marketBeforePurchase,
          sourceVisibleIndex: sourceIndex,
          startOffset: startOffset,
          endOffset: endOffset,
          itemPlacement: boughtOffer.item.placement,
          itemRarity: boughtOffer.item.rarity,
          itemId: boughtOffer.item.id,
        );
      } else {
        final nextEntries = _offerEntriesForLane(market, _currentOfferLane);
        final stillSelected = nextEntries.any(
          (entry) =>
              entry.kind == _MarketOfferEntryKind.item &&
              entry.itemIndex == _selectedItemOfferIndex,
        );
        if (!stillSelected) {
          _selectFirstEntry(nextEntries);
        }
      }
    });
    if (effectPresentation != null) {
      _startEffectPresentation(effectPresentation);
    }
    _queueStateSave();
  }

  void _buySelectedTile() {
    final offers = _market.tileOffers;
    final index = _selectedTileOfferIndex;
    if (index < 0 || index >= offers.length) return;
    final marketBeforePurchase = _market;
    final boughtOffer = offers[index];
    final sourceEntry = _MarketOfferEntry.tile(index);
    final sourceIndex = _visibleOfferLaneIndex(sourceEntry);
    final sourceCount = _visibleOfferLaneCount();
    final startOffset = _flightCenterForKey(_offerKey(sourceEntry));
    final failMessage = widget.onBuyTileOffer(index);
    if (failMessage != null) {
      _startMarketDenyFeedback('tile-buy', failMessage);
      showBottomNotice(context, failMessage);
      return;
    }
    _mutate(() {
      final market = _market;
      _clampOfferPageForLane(market, _MarketOfferLane.tile);
      _selectFirstEntry(_offerEntriesForLane(market, _MarketOfferLane.tile));
      _startPurchaseFlight(
        label: _tileLabel(boughtOffer.tile),
        slotLabel: 'Deck',
        item: false,
        spentGold: boughtOffer.isFreeReward ? 0 : boughtOffer.price,
        startAlignment: _offerFlightStartAlignment(sourceIndex, sourceCount),
        endAlignment: const Alignment(1.36, -0.04),
        marketBeforePurchase: marketBeforePurchase,
        sourceVisibleIndex: sourceIndex,
        startOffset: startOffset,
        endOffset: _deckTileFlightEndOffset(),
        tile: boughtOffer.tile,
      );
    });
    _queueStateSave();
    showBottomNotice(context, '${_tileLabel(boughtOffer.tile)} 덱 추가');
  }

  RummiMarketItemSlotView? _findPurchasedItemSlot(
    RummiMarketRuntimeFacade market,
    RummiMarketItemOfferView offer,
  ) {
    for (final slot in market.itemSlots) {
      if (slot.contentId == offer.contentId &&
          slot.placement == offer.item.placement) {
        return slot;
      }
    }
    return null;
  }

  RummiMarketOwnedEntryView? _findPurchasedJesterSlot(
    RummiMarketRuntimeFacade market,
    RummiMarketOfferView offer,
  ) {
    for (final entry in market.ownedEntries.reversed) {
      if (entry.contentId == offer.contentId) {
        return entry;
      }
    }
    return null;
  }

  int _spentGoldForPurchase({
    required RummiMarketRuntimeFacade before,
    required RummiMarketRuntimeFacade after,
    required int fallback,
  }) {
    final spent = before.gold - after.gold;
    if (spent < 0) return fallback;
    return spent;
  }

  void _startPurchaseFlight({
    required String label,
    required String slotLabel,
    required bool item,
    required int spentGold,
    required Alignment startAlignment,
    required Alignment endAlignment,
    required RummiMarketRuntimeFacade marketBeforePurchase,
    required int sourceVisibleIndex,
    Offset? startOffset,
    Offset? endOffset,
    RummiJesterCard? jesterCard,
    Tile? tile,
    ItemPlacement? itemPlacement,
    ItemRarity? itemRarity,
    String? itemId,
  }) {
    final tick = _purchaseFlightTick + 1;
    _purchaseFlightTick = tick;
    _purchaseFlight = _MarketPurchaseFlight(
      tick: tick,
      label: label,
      slotLabel: slotLabel,
      item: item,
      spentGold: spentGold,
      startAlignment: startAlignment,
      endAlignment: endAlignment,
      marketBeforePurchase: marketBeforePurchase,
      sourceVisibleIndex: sourceVisibleIndex,
      startOffset: startOffset,
      endOffset: endOffset,
      jesterCard: jesterCard,
      tile: tile,
      itemId: itemId,
      itemPlacement: itemPlacement,
      itemRarity: itemRarity,
    );
    Future<void>.delayed(kMarketPurchaseFlightDuration, () {
      if (!mounted || _purchaseFlight?.tick != tick) return;
      _mutate(() => _purchaseFlight = null);
    });
  }

  void _startSaleFlight({
    required RummiMarketItemSlotView slot,
    required ItemDefinition item,
    required Offset? startOffset,
    required Offset? endOffset,
  }) {
    final tick = _saleFlightTick + 1;
    _saleFlightTick = tick;
    _saleFlight = _MarketSaleFlight(
      tick: tick,
      label: localizedItemSlotName(context, slot),
      item: true,
      sellGold: item.sellPrice,
      startOffset: startOffset,
      endOffset: endOffset,
      itemPlacement: slot.placement,
      itemRarity: item.rarity,
      itemId: item.id,
    );
    Future<void>.delayed(kMarketPurchaseFlightDuration, () {
      if (!mounted || _saleFlight?.tick != tick) return;
      _mutate(() => _saleFlight = null);
    });
  }

  void _startJesterSaleFlight({
    required RummiMarketOwnedEntryView entry,
    required Offset? startOffset,
    required Offset? endOffset,
  }) {
    final tick = _saleFlightTick + 1;
    _saleFlightTick = tick;
    _saleFlight = _MarketSaleFlight(
      tick: tick,
      label: localizedJesterName(context, entry.card),
      item: false,
      sellGold: entry.sellPrice,
      startOffset: startOffset,
      endOffset: endOffset,
      jesterCard: entry.card,
    );
    Future<void>.delayed(kMarketPurchaseFlightDuration, () {
      if (!mounted || _saleFlight?.tick != tick) return;
      _mutate(() => _saleFlight = null);
    });
  }

  void _startMarketItemUseFlight({
    required RummiMarketItemSlotView slot,
    required ItemDefinition item,
    required int? goldGain,
    required Offset? startOffset,
    required Offset? endOffset,
  }) {
    final tick = _itemUseFlightTick + 1;
    _itemUseFlightTick = tick;
    _itemUseFlight = _MarketItemUseFlight(
      tick: tick,
      label: localizedItemSlotName(context, slot),
      goldGain: goldGain,
      startOffset: startOffset,
      endOffset: endOffset,
      itemPlacement: slot.placement,
      itemRarity: item.rarity,
      itemId: item.id,
    );
    final overlayHold = goldGain == null
        ? kMarketPurchaseFlightDuration
        : GamePresentationTimings.marketGoldGainBadge;
    Future<void>.delayed(overlayHold, () {
      if (!mounted || _itemUseFlight?.tick != tick) return;
      _mutate(() => _itemUseFlight = null);
    });
  }

  int _visibleOfferLaneCount() {
    final lane = _currentOfferLane;
    final entries = _offerEntriesForLane(_market, lane);
    final page = _offerPageFor(lane);
    return _pagedItems(entries, page).length;
  }

  int _visibleOfferLaneIndex(_MarketOfferEntry target) {
    final lane = _currentOfferLane;
    final entries = _offerEntriesForLane(_market, lane);
    final page = _offerPageFor(lane);
    final visible = _pagedItems(entries, page);
    final index = visible.indexWhere(
      (entry) =>
          entry.kind == target.kind &&
          entry.jesterIndex == target.jesterIndex &&
          entry.itemIndex == target.itemIndex &&
          entry.tileIndex == target.tileIndex,
    );
    return index < 0 ? 0 : index;
  }

  Alignment _offerFlightStartAlignment(int visibleIndex, int visibleCount) {
    if (visibleCount <= 1) return const Alignment(0, 0.64);
    if (visibleCount == 2) {
      return Alignment(visibleIndex == 0 ? -0.36 : 0.36, 0.64);
    }
    return Alignment((-0.52 + (visibleIndex.clamp(0, 2) * 0.52)), 0.64);
  }

  Alignment _jesterSlotFlightEndAlignment(int slotIndex) {
    return Alignment((-0.52 + (slotIndex.clamp(0, 4) * 0.30)), -0.48);
  }

  Alignment _itemSlotFlightEndAlignment(RummiMarketItemSlotView slot) {
    final label = slot.slotLabel;
    final number = label.length > 1 ? int.tryParse(label.substring(1)) ?? 1 : 1;
    final index = (number - 1).clamp(0, 2);
    if (label.startsWith('Q')) {
      return Alignment(-0.52 + (index * 0.30), -0.27);
    }
    if (label.startsWith('P')) {
      return Alignment(0.38 + (index.clamp(0, 1) * 0.30), -0.27);
    }
    if (label.startsWith('G')) {
      return Alignment(-0.52 + (index * 0.30), -0.12);
    }
    return Alignment(-0.52 + (index * 0.30), -0.28);
  }

  Offset? _flightCenterForKey(GlobalKey key) {
    final surfaceContext = _marketSurfaceKey.currentContext;
    final targetContext = key.currentContext;
    if (surfaceContext == null || targetContext == null) return null;
    final surfaceBox = surfaceContext.findRenderObject();
    final targetBox = targetContext.findRenderObject();
    if (surfaceBox is! RenderBox || targetBox is! RenderBox) return null;
    final targetCenter = targetBox.localToGlobal(
      targetBox.size.center(Offset.zero),
    );
    return surfaceBox.globalToLocal(targetCenter);
  }

  Offset? _deckTileFlightEndOffset() {
    final surfaceContext = _marketSurfaceKey.currentContext;
    if (surfaceContext == null) return null;
    final surfaceBox = surfaceContext.findRenderObject();
    if (surfaceBox is! RenderBox) return null;
    return Offset(surfaceBox.size.width + 54, surfaceBox.size.height * 0.46);
  }

  bool _isPurchaseSourceIndex(int visibleIndex) {
    final flight = _purchaseFlight;
    if (flight == null) return false;
    return flight.sourceVisibleIndex == visibleIndex;
  }
}
