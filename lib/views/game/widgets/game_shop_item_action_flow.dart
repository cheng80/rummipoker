part of 'game_shop_screen.dart';

extension _GameShopItemActionFlow on _GameShopScreenState {
  void _startMarketDenyFeedback(String target, String reason) {
    final tick = _marketDenyTick + 1;
    _mutate(() {
      _marketDenyTick = tick;
      _marketDenyTarget = target;
      _marketDenyReason = reason;
    });
    Future<void>.delayed(GamePresentationTimings.marketDenyFeedbackHold, () {
      if (!mounted || _marketDenyTick != tick) return;
      _mutate(() {
        _marketDenyTarget = null;
        _marketDenyReason = null;
      });
    });
  }

  void _startEffectPresentation(ItemPresentationEvent event) {
    final tick = _effectPresentationTick + 1;
    _effectPresentationTick = tick;
    _mutate(() {
      _effectPresentation = _MarketEffectPresentation(tick: tick, event: event);
    });
    Future<void>.delayed(GamePresentationTimings.marketUseFeedbackHold, () {
      if (!mounted || _effectPresentation?.tick != tick) return;
      _mutate(() => _effectPresentation = null);
    });
  }

  ItemPresentationEvent? _marketRerollPresentation(
    RummiMarketRuntimeFacade market,
    _MarketOfferLane lane,
  ) {
    final source = _activeItemSlotWhere(
      (item) =>
          item.effect.timing == 'market_reroll' &&
          (item.effect.op == 'free_next_reroll' ||
              item.effect.op == 'discount_next_reroll'),
    );
    if (source == null) return null;
    final item = source.item;
    if (item == null) return null;
    return ItemPresentationEvent(
      itemId: item.id,
      sourceKind: _presentationSourceKind(source.placement),
      sourceLabel: localizedItemSlotName(context, source),
      target: ItemPresentationTarget(
        kind: ItemPresentationTargetKind.marketReroll,
        label: _offerLaneLabel(lane),
      ),
      resultLabel: market.rerollCost <= 0 ? '리롤 무료 적용' : '리롤 비용 할인',
    );
  }

  ItemPresentationEvent? _marketPurchasePresentation({
    required RummiMarketRuntimeFacade market,
    required String category,
    required String targetLabel,
    required String? discountSourceLabel,
  }) {
    final purchaseSource = _activeItemSlotWhere(
      (item) =>
          item.effect.op == 'discount_next_purchase' &&
          (item.effect.timing == 'market_buy' ||
              (item.effect.timing == 'market_buy_if_category' &&
                  item.effect.value('category') == category)),
    );
    final compassSource = discountSourceLabel == '나침반'
        ? _activeItemSlotWhere((item) => item.id == 'market_compass')
        : null;
    final source = purchaseSource ?? compassSource;
    final item = source?.item;
    if (source == null || item == null) {
      if (discountSourceLabel == null) return null;
      return ItemPresentationEvent(
        itemId: discountSourceLabel == '나침반'
            ? 'market_compass'
            : discountSourceLabel,
        sourceKind: ItemPresentationSourceKind.passive,
        sourceLabel: discountSourceLabel,
        target: ItemPresentationTarget(
          kind: category == 'jester'
              ? ItemPresentationTargetKind.marketOffer
              : ItemPresentationTargetKind.itemOffer,
          label: targetLabel,
        ),
        resultLabel: '구매가 -1G',
      );
    }
    final labels = <String>[
      localizedItemSlotName(context, source),
      if (purchaseSource != null && compassSource != null)
        localizedItemSlotName(context, compassSource),
    ];
    final discount = _marketPurchaseDiscountAmount(
      item: purchaseSource?.item,
      compassActive: compassSource != null,
    );
    return ItemPresentationEvent(
      itemId: item.id,
      sourceKind: _presentationSourceKind(source.placement),
      sourceLabel: labels.join(' + '),
      target: ItemPresentationTarget(
        kind: category == 'jester'
            ? ItemPresentationTargetKind.marketOffer
            : ItemPresentationTargetKind.itemOffer,
        label: targetLabel,
      ),
      resultLabel: discount > 0 ? '구매가 -${discount}G' : '할인 적용',
    );
  }

  int _marketPurchaseDiscountAmount({
    required ItemDefinition? item,
    required bool compassActive,
  }) {
    var total = 0;
    if (item != null) {
      total += (item.effect.value('amount') as num?)?.toInt() ?? 0;
    }
    if (compassActive) {
      total += 1;
    }
    return total;
  }

  RummiMarketItemSlotView? _activeItemSlotWhere(
    bool Function(ItemDefinition item) test,
  ) {
    for (final slot in _market.itemSlots) {
      final item = slot.item;
      if (item == null || slot.locked || slot.count <= 0) continue;
      if (test(item)) return slot;
    }
    return null;
  }

  ItemPresentationSourceKind _presentationSourceKind(ItemPlacement placement) {
    return switch (placement) {
      ItemPlacement.quickSlot => ItemPresentationSourceKind.quickSlot,
      ItemPlacement.passiveRack => ItemPresentationSourceKind.passive,
      ItemPlacement.inventory => ItemPresentationSourceKind.tool,
      ItemPlacement.equipped => ItemPresentationSourceKind.gear,
    };
  }

  void _useSelectedMarketItem(RummiMarketItemSlotView slot) {
    final item = slot.item;
    if (item == null) return;
    final startOffset = _flightCenterForKey(_itemSlotKey(slot.slotLabel));
    final failMessage = widget.onUseMarketItem(item);
    if (failMessage != null) {
      _startMarketDenyFeedback('item-use', failMessage);
      showBottomNotice(context, failMessage);
      return;
    }
    final feedbackTick = _marketUseFeedbackTick + 1;
    final goldGain = _marketUseGoldGain(item);
    final effectPresentation = _marketUsePresentation(slot, item);
    final endOffset = goldGain == null
        ? null
        : _flightCenterForKey(_goldChipKey);
    _mutate(() {
      if (item.effect.op == 'reroll_item_offers_only') {
        _pinnedItemOffers = null;
      }
      _marketUseFeedbackTick = feedbackTick;
      _marketUseFeedbackLabel = '사용 완료';
      _marketUseFeedbackDelta = _marketUseFeedbackDeltaLabel(item);
      _startMarketItemUseFlight(
        slot: slot,
        item: item,
        goldGain: goldGain,
        startOffset: startOffset,
        endOffset: endOffset,
      );
      final market = _market;
      final stillExists = market.itemSlots.any(
        (nextSlot) =>
            nextSlot.slotIndex == slot.slotIndex && nextSlot.item != null,
      );
      if (!stillExists) {
        _selectedItemSlotIndex = -1;
        _selectFirstEntry(_offerEntriesForLane(market, _currentOfferLane));
      }
    });
    if (effectPresentation != null) {
      _startEffectPresentation(effectPresentation);
    }
    Future<void>.delayed(GamePresentationTimings.marketUseFeedbackHold, () {
      if (!mounted || _marketUseFeedbackTick != feedbackTick) return;
      _mutate(() {
        _marketUseFeedbackLabel = null;
        _marketUseFeedbackDelta = null;
      });
    });
    _queueStateSave();
  }

  String? _marketUseFeedbackDeltaLabel(ItemDefinition item) {
    final amount = _marketUseGoldGain(item);
    return switch (item.effect.op) {
      'gain_gold' when amount != null => '+${amount}G',
      'reroll_item_offers_only' => 'Item 후보 교체',
      _ => null,
    };
  }

  ItemPresentationEvent? _marketUsePresentation(
    RummiMarketItemSlotView slot,
    ItemDefinition item,
  ) {
    if (item.effect.op != 'reroll_item_offers_only') return null;
    return ItemPresentationEvent(
      itemId: item.id,
      sourceKind: _presentationSourceKind(slot.placement),
      sourceLabel: localizedItemSlotName(context, slot),
      target: const ItemPresentationTarget(
        kind: ItemPresentationTargetKind.itemOffer,
        label: 'Item 후보 영역',
      ),
      resultLabel: '후보 교체 완료',
    );
  }

  int? _marketUseGoldGain(ItemDefinition item) {
    final amount = item.effect.amount;
    if (item.effect.op != 'gain_gold' || amount == null) return null;
    return amount.toInt();
  }

  Widget? _ownedMarketItemActionPane(
    BuildContext context,
    RummiMarketItemSlotView slot,
  ) {
    final item = slot.item;
    if (item == null) return null;
    final sellAction = _MarketActionPane(
      priceLabel: '+${item.sellPrice}',
      buttonLabel: '판매',
      buttonColor: GameUiPalette.actionDanger,
      onPressed: () => _sellMarketItem(slot),
    );
    if (item.effect.timing == 'use_market' ||
        item.effect.timing == 'use_market_if_gold_lte') {
      return _MarketUseSellActionPane(
        count: slot.count,
        sellPrice: item.sellPrice,
        onUse: () => _useSelectedMarketItem(slot),
        onSell: () => _sellMarketItem(slot),
        denyActive: _marketDenyTarget == 'item-use',
        denyTick: _marketDenyTick,
        denyReason: _marketDenyReason,
      );
    }
    if (item.effect.timing == 'market_buy' ||
        item.effect.timing == 'market_buy_if_category') {
      return sellAction;
    }
    return sellAction;
  }

  void _sellOwned(int index) {
    final marketBeforeSell = _market;
    if (index < 0 || index >= marketBeforeSell.ownedEntries.length) return;
    final soldEntry = marketBeforeSell.ownedEntries[index];
    final startOffset = _flightCenterForKey(_jesterSlotKey(index));
    final endOffset = _flightCenterForKey(_goldChipKey);
    final ok = widget.onSellOwnedJester(index);
    if (!ok) return;
    showBottomNotice(context, '제스터를 판매했습니다.');
    _mutate(() {
      _pinnedItemOffers = marketBeforeSell.itemOffers;
      _startJesterSaleFlight(
        entry: soldEntry,
        startOffset: startOffset,
        endOffset: endOffset,
      );
      final market = _market;
      if (market.ownedEntries.isEmpty) {
        _selectedOwnedIndex = null;
        _selectedOfferIndex = market.offers.isEmpty ? null : 0;
      } else {
        _selectedOwnedIndex = index.clamp(0, market.ownedEntries.length - 1);
      }
    });
    _queueStateSave();
  }

  void _sellMarketItem(RummiMarketItemSlotView slot) {
    final marketBeforeSell = _market;
    final item = slot.item;
    if (item == null) return;
    final startOffset = _flightCenterForKey(_itemSlotKey(slot.slotLabel));
    final endOffset = _flightCenterForKey(_goldChipKey);
    final ok = widget.onSellMarketItem(item);
    if (!ok) return;
    showBottomNotice(context, '아이템을 판매했습니다.');
    _mutate(() {
      _pinnedItemOffers = marketBeforeSell.itemOffers;
      _startSaleFlight(
        slot: slot,
        item: item,
        startOffset: startOffset,
        endOffset: endOffset,
      );
      final market = _market;
      _selectedItemSlotIndex = -1;
      _selectFirstEntry(_offerEntriesForLane(market, _currentOfferLane));
    });
    _queueStateSave();
  }
}
